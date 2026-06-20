#include <iostream>
#include <assert.h>
#include <algorithm> 
#include <array>
#include <vector>
#include <bitset>
#include <set>


#define STRIDE            (1L * 1024L * 1024L)                            // 1mB stride (64kB * 16)
#define TEMP_BUF_SIZE     (64 * 1024)                   
#define L3_ENTRY_NUM      8                                               // modify to measure the time

#define START_SET         0                                               // start L3 hash set
#define END_SET           (START_SET + 256)                               // end L3 hash set

/*******************************************************************************
 * Cuda kernel for the L3 hash pointer chasing
 ******************************************************************************/
__global__ void
loop(uint64_t *arg_l3)
{
  uint64_t *temp = NULL;
  uint64_t *ptr3 = NULL;
  uint32_t gid3 = 0;

  gid3 = threadIdx.x;
  ptr3 = (uint64_t *)arg_l3[gid3];

  #pragma unroll 1

  for (temp = (uint64_t *)ptr3[0]; temp != NULL; temp = (uint64_t *)temp[0]) {
    ++temp[2];
  }
    __syncthreads();

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
 * Chains eviction set in a linked list structure within a memory buffer.
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
}

/*******************************************************************************
 * Main function to do the L3 hash set pointer chasing
 ******************************************************************************/
void 
CudaPrimeProbe(uint64_t *d_buf_l3, size_t d_buf_l3_size, uint64_t *d_buf_l2, size_t d_buf_l2_size)
{
  uint64_t head_addr_l3 = (uint64_t)d_buf_l3;
  uint64_t tail_addr_l3 = head_addr_l3 + d_buf_l3_size;

  uint64_t *d_arg_l3 = NULL;
  uint64_t *h_arg_l3 = (uint64_t *)malloc(TEMP_BUF_SIZE); 
  uint64_t *h_buf_l3 = (uint64_t *)malloc(d_buf_l3_size);
  
  cudaMalloc(&d_arg_l3, TEMP_BUF_SIZE);
  
  std::vector<uint32_t> hash_vec;
  for (uint32_t i = START_SET; i < END_SET; ++i)
    hash_vec.push_back(i);
  
  for (uint64_t i = 0; i < hash_vec.size(); ++i) {
    uint32_t hash_l3 = hash_vec[i];
    std::vector<uint64_t> chase_vec;
    find_ev_set_l3(chase_vec, head_addr_l3, tail_addr_l3, hash_l3, L3_ENTRY_NUM);
    assert(chase_vec.size() == L3_ENTRY_NUM);
    chain_addrs(chase_vec, h_buf_l3, head_addr_l3);
    h_arg_l3[i] = chase_vec.front();
  }
  
  cudaMemcpy(d_arg_l3, h_arg_l3, TEMP_BUF_SIZE, cudaMemcpyHostToDevice);
  cudaMemcpy(d_buf_l3, h_buf_l3, d_buf_l3_size, cudaMemcpyHostToDevice);
  cudaDeviceSynchronize();

  std::cout << "get into kernel" << std::endl;
  loop<<<1, hash_vec.size()>>>(d_arg_l3);
  cudaDeviceSynchronize();
}


