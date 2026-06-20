# GPU TLB Prime+Probe

## Overview

GPU TLB Prime+Probe is a research artifact accompanying our work on cross-VM side-channel attacks in virtualized GPU environments.

This project investigates how Translation Lookaside Buffers (TLBs) in modern GPUs can be exploited as a timing side channel. By carefully constructing Prime+Probe primitives and timing measurements, the attack can infer victim activity across virtual machine boundaries.

Research areas:

* GPU Security
* Side-Channel Attacks
* Computer Architecture
* Virtualization Security

---

## Repository Structure

### prime_probe_tools/

Core Prime+Probe implementation and GPU-side attack primitives.

### timing_measurement/

Microbenchmarking and timing characterization tools used to evaluate GPU memory translation behavior.

### website_fingerprinting/

Proof-of-concept applications demonstrating practical side-channel leakage.

### data_processing/

Data extraction, processing, and visualization scripts used in experimental evaluation.

### figures/

Architecture diagrams and experimental results.

---

## Experimental Environment

* NVIDIA GPU Platform
* CUDA
* Vulkan
* Linux

Additional hardware and software configuration details will be released alongside the final artifact.

---

## Research Contributions

This artifact demonstrates:

1. GPU TLB timing characterization
2. Prime+Probe primitive construction
3. Cross-VM information leakage
4. Proof-of-concept attack scenarios
5. Experimental data analysis and visualization

---

## Publication

Exploiting TLBs in Virtualized GPUs for Cross-VM Side-Channel Attacks

NDSS 2026

Paper link:https://www.ndss-symposium.org/ndss-paper/exploiting-tlbs-in-virtualized-gpus-for-cross-vm-side-channel-attacks/.

---

## Citation

Citation information will be released after publication.

---

## Disclaimer

This repository is released for academic research purposes only. The provided code and artifacts are intended to support reproducibility and further research on GPU security and side-channel analysis.
