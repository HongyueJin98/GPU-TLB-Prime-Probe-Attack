#define GLFW_INCLUDE_VULKAN

#include <GLFW/glfw3.h>
#include <iostream>
#include <vector>
#include <cstring>
#include <cuda_runtime.h>
#include <cuda.h>
#include <fstream>
#include <string>

// Define buffer sizes
#define BUF_SIZE    ((3L * 1024L + 512L)* 1024L * 1024L)  //For Prime Probe L3 pointer
#define FLUSH_SIZE  ((1L * 1024L + 256L) * 1024L * 1024L) //For L1 L2 flush pointer

// Vulkan-related global variables
VkInstance instance;
VkPhysicalDevice physicalDevice;
VkDevice device;
VkQueue graphicsQueue;
VkBuffer gpuBuffer;
VkDeviceMemory gpuBufferMemory;
VkBuffer flushBuffer;
VkDeviceMemory flushBufferMemory;

// CUDA prime probe function declaration
void CudaPrimeProbe(uint64_t *, size_t, uint64_t *, size_t);

const std::vector<const char *> deviceExtensions = {
    VK_KHR_EXTERNAL_MEMORY_EXTENSION_NAME,
    VK_KHR_EXTERNAL_SEMAPHORE_EXTENSION_NAME,
    VK_KHR_EXTERNAL_MEMORY_FD_EXTENSION_NAME,
    VK_KHR_EXTERNAL_SEMAPHORE_FD_EXTENSION_NAME

};

//Finds a suitable Vulkan memory type.

uint32_t 
findMemoryType(uint32_t typeFilter, VkMemoryPropertyFlags properties)
{
  VkPhysicalDeviceMemoryProperties memProperties;
  vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memProperties);

  for (uint32_t i = 0; i < memProperties.memoryTypeCount; ++i) {
    if ((typeFilter & (1 << i)) && (memProperties.memoryTypes[i].propertyFlags & properties) == properties) {
      return i;
    }
  }

  throw std::runtime_error("Failed to find suitable memory type");
}

//Initializes Vulkan.

void 
initVulkan()
{
  // Set application info
  VkApplicationInfo appInfo{};
  appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
  appInfo.pApplicationName = "Vulkan App";
  appInfo.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
  appInfo.pEngineName = "No Engine";
  appInfo.engineVersion = VK_MAKE_VERSION(1, 0, 0);
  appInfo.apiVersion = VK_API_VERSION_1_0;

  // Create Vulkan instance
  VkInstanceCreateInfo createInfo{};
  createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  createInfo.pApplicationInfo = &appInfo;

  VkResult result = vkCreateInstance(&createInfo, nullptr, &instance);
  if (result != VK_SUCCESS) {
    throw std::runtime_error("failed to create instance!");
  }

  // Retrieve available physical devices
  uint32_t deviceCount = 0;
  vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr);
  if (deviceCount == 0) {
    throw std::runtime_error("failed to find GPUs with Vulkan support!");
  }
  std::vector<VkPhysicalDevice> devices(deviceCount);
  vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data());

  // Select a discrete GPU
  for (const auto &device : devices) {
    VkPhysicalDeviceProperties deviceProperties;
    vkGetPhysicalDeviceProperties(device, &deviceProperties);
    if (deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
      physicalDevice = device;
      break;
    }
  }
  if (physicalDevice == VK_NULL_HANDLE) {
    throw std::runtime_error("Failed to find a suitable Vulkan physical device.");
  }

  // set up logical device and queue
  VkDeviceQueueCreateInfo queueCreateInfo{};
  queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
  queueCreateInfo.queueFamilyIndex = 0;
  queueCreateInfo.queueCount = 1;
  float queuePriority = 1.0f;
  queueCreateInfo.pQueuePriorities = &queuePriority;

  VkDeviceCreateInfo deviceCreateInfo{};
  deviceCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
  deviceCreateInfo.queueCreateInfoCount = 1;
  deviceCreateInfo.pQueueCreateInfos = &queueCreateInfo;
  deviceCreateInfo.enabledExtensionCount = static_cast<uint32_t>(deviceExtensions.size());
  deviceCreateInfo.ppEnabledExtensionNames = deviceExtensions.data();
  vkCreateDevice(physicalDevice, &deviceCreateInfo, nullptr, &device);

  vkGetDeviceQueue(device, 0, 0, &graphicsQueue);
}


// Creates the L1/L2 Flush Vulkan buffer and allocates memory.
void 
createFlushBuffer()
{
  // External memory info
  VkExternalMemoryBufferCreateInfo externalMemoryBufferCreateInfo = {};
  externalMemoryBufferCreateInfo.sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO;
  externalMemoryBufferCreateInfo.handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT;

  VkBufferCreateInfo bufferInfo = {};
  bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
  bufferInfo.size = FLUSH_SIZE;
  bufferInfo.usage = VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT_KHR;
  bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
  bufferInfo.pNext = &externalMemoryBufferCreateInfo;
  if (vkCreateBuffer(device, &bufferInfo, nullptr, &flushBuffer) != VK_SUCCESS) {
    throw std::runtime_error("Failed to create GPU buffer!");
  }

  // Get memory requirements and allocate memory
  VkMemoryRequirements memRequirements;
  vkGetBufferMemoryRequirements(device, flushBuffer, &memRequirements);

  VkExportMemoryAllocateInfo exportAllocInfo = {};
  exportAllocInfo.sType = VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO;
  exportAllocInfo.handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT_KHR;

  VkMemoryAllocateInfo allocInfo = {};
  allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  allocInfo.pNext = &exportAllocInfo; // Link the export allocation info here
  allocInfo.allocationSize = memRequirements.size;
  allocInfo.memoryTypeIndex = findMemoryType(memRequirements.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);

  // Allocate memory
  if (vkAllocateMemory(device, &allocInfo, nullptr, &flushBufferMemory) != VK_SUCCESS) {
    throw std::runtime_error("Failed to create buffer!");
  }

  vkBindBufferMemory(device, flushBuffer, flushBufferMemory, 0);
}


//Creates the L3 Prime Probe Vulkan buffer and allocates memory.
void 
createGPUBuffer()
{
  // External memory info
  VkExternalMemoryBufferCreateInfo externalMemoryBufferCreateInfo = {};
  externalMemoryBufferCreateInfo.sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO;
  externalMemoryBufferCreateInfo.handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT;

  VkBufferCreateInfo bufferInfo = {};
  bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
  bufferInfo.size = BUF_SIZE;
  bufferInfo.usage = VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT_KHR;
  bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
  bufferInfo.pNext = &externalMemoryBufferCreateInfo;
  if (vkCreateBuffer(device, &bufferInfo, nullptr, &gpuBuffer) != VK_SUCCESS) {
    throw std::runtime_error("Failed to create GPU buffer!");
  }

  // Get memory requirements and allocate memory
  VkMemoryRequirements memRequirements;
  vkGetBufferMemoryRequirements(device, gpuBuffer, &memRequirements);

  VkExportMemoryAllocateInfo exportAllocInfo = {};
  exportAllocInfo.sType = VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO;
  exportAllocInfo.handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT_KHR;

  VkMemoryAllocateInfo allocInfo = {};
  allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  allocInfo.pNext = &exportAllocInfo; // Link the export allocation info here
  allocInfo.allocationSize = memRequirements.size;
  allocInfo.memoryTypeIndex = findMemoryType(memRequirements.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);

  // Allocate memory
  if (vkAllocateMemory(device, &allocInfo, nullptr, &gpuBufferMemory) != VK_SUCCESS) {
    throw std::runtime_error("Failed to create buffer!");
  }

  vkBindBufferMemory(device, gpuBuffer, gpuBufferMemory, 0);
}


//Maps L3 Prime Probe Vulkan buffer to CUDA.
void *
mapGpuBufferToCuda()
{
  PFN_vkGetMemoryFdKHR vkGetMemoryFdKHR = (PFN_vkGetMemoryFdKHR)vkGetDeviceProcAddr(device, "vkGetMemoryFdKHR");
  if (vkGetMemoryFdKHR == nullptr) {
    throw std::runtime_error("Failed to load vkGetMemoryFdKHR");
  }
  int gpuBufferMemoryFd;
  VkMemoryGetFdInfoKHR getFdInfo = {};
  getFdInfo.sType = VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR;
  getFdInfo.memory = gpuBufferMemory;
  getFdInfo.handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT;
  if (vkGetMemoryFdKHR(device, &getFdInfo, &gpuBufferMemoryFd) != VK_SUCCESS) {
    throw std::runtime_error("Failed to get memory FD!");
  }

  cudaExternalMemoryHandleDesc extMemHandleDesc = {};
  extMemHandleDesc.type = cudaExternalMemoryHandleTypeOpaqueFd;
  extMemHandleDesc.handle.fd = gpuBufferMemoryFd;
  extMemHandleDesc.size = BUF_SIZE;

  cudaExternalMemory_t cudaExtMem;
  vkDeviceWaitIdle(device);
  int i = 0;
  i = (int)cudaImportExternalMemory(&cudaExtMem, &extMemHandleDesc);

  // Map the buffer to a CUDA pointer
  cudaExternalMemoryBufferDesc extBufferDesc = {};
  extBufferDesc.offset = 0;
  extBufferDesc.size = BUF_SIZE;
  extBufferDesc.flags = 0;

  uint64_t *d_buf;
  i=(int)cudaExternalMemoryGetMappedBuffer((void **)&d_buf, cudaExtMem, &extBufferDesc);
  return d_buf;
}


//Maps L1/L2 Flush Vulkan buffer to CUDA.
void *
mapFlushBufferToCuda()
{
  PFN_vkGetMemoryFdKHR vkGetMemoryFdKHR = (PFN_vkGetMemoryFdKHR)vkGetDeviceProcAddr(device, "vkGetMemoryFdKHR");
  if (vkGetMemoryFdKHR == nullptr) {
    throw std::runtime_error("Failed to load vkGetMemoryFdKHR");
  }
  int debugBufferMemoryFd;
  VkMemoryGetFdInfoKHR getFdInfo = {};
  getFdInfo.sType = VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR;
  getFdInfo.memory = flushBufferMemory;
  getFdInfo.handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT;
  if (vkGetMemoryFdKHR(device, &getFdInfo, &debugBufferMemoryFd) != VK_SUCCESS) {
    throw std::runtime_error("Failed to get memory FD!");
  }

  cudaExternalMemoryHandleDesc extMemHandleDesc = {};
  extMemHandleDesc.type = cudaExternalMemoryHandleTypeOpaqueFd;
  extMemHandleDesc.handle.fd = debugBufferMemoryFd;
  extMemHandleDesc.size = FLUSH_SIZE;

  cudaExternalMemory_t cudaExtMem;
  vkDeviceWaitIdle(device);
  if (cudaImportExternalMemory(&cudaExtMem, &extMemHandleDesc) ) {
    throw std::runtime_error("Failed to do cuda ImportExternalMemory");
  };

  // Map the buffer to a CUDA pointer
  cudaExternalMemoryBufferDesc extBufferDesc = {};
  extBufferDesc.offset = 0;
  extBufferDesc.size = FLUSH_SIZE;
  extBufferDesc.flags = 0;

  uint64_t *flush_buf;
  cudaExternalMemoryGetMappedBuffer((void **)&flush_buf, cudaExtMem, &extBufferDesc);
  return flush_buf;

}



int 
main(int argc, char *argv[])
{
  // Device memory addresses
  uint64_t *ppBufferAddr;
  uint64_t *flushBufferAddr;
  
  initVulkan();
  createFlushBuffer();
  createGPUBuffer();

  ppBufferAddr = (uint64_t *)mapGpuBufferToCuda();
  flushBufferAddr = (uint64_t *)mapFlushBufferToCuda();

  CudaPrimeProbe(ppBufferAddr, BUF_SIZE, flushBufferAddr, FLUSH_SIZE);
  
  return 0;
}

