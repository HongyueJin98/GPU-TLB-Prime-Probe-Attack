# Compiler and flags
NVCC = nvcc

# Output executable name
TARGET = prime_probe

# Source files
CUDA_SRC = prime_probe.cu

VULKAN_SRC = vulkan_buffer.cpp
INSTRUCTION_SRC = instruction_chain.cu

LIBS = -lvulkan -lcuda

# Default rule
all: $(TARGET)

$(TARGET): cuda_obj.o vulkan_obj.o instruction_obj.o
	nvcc -arch=sm_80 -Xptxas -O0 $^ -o $@ $(LIBS)

# Link the object files to create the executable
cuda_obj.o: $(CUDA_SRC)
	nvcc -arch=sm_80 -Xptxas -O0 -dc $^ -o $@

vulkan_obj.o: $(VULKAN_SRC)
	nvcc -arch=sm_80 -Xptxas -O0 -dc $^ -o $@

instruction_obj.o: $(INSTRUCTION_SRC)
	nvcc -arch=sm_80 -Xptxas -O0 -dc $^ -o $@

# Clean rule to remove generated files
clean:
	rm -f $(TARGET)
