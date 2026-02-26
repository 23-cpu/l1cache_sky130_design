# 2-Way Set-Associative Write-Back Cache (Sky130 Hardened)

## Overview

This project implements a parameterized 2-way set-associative write-back cache in SystemVerilog.  
The design was functionally verified through directed and randomized testing and physically implemented using the OpenLane ASIC flow targeting the SkyWater 130nm (Sky130) PDK.

The goal was to bridge RTL microarchitectural design with full backend physical implementation and signoff.

---

## Architecture Features

- 2-way set associativity  
- Write-allocate policy  
- Write-back (dirty line management)  
- PLRU replacement policy  
- Parameterized cache structure  
- 4-byte cache line size
- 128 bytes total capacity 
- 50 MHz target clock (20 ns period)

---

## Verification

Simulation performed using Icarus Verilog.

Test coverage includes:

- Read hit / read miss handling  
- Write hit behavior  
- Write miss with allocation  
- Dirty eviction and write-back correctness  
- Replacement policy validation  

All directed tests passed prior to physical implementation.

---

## Physical Implementation (OpenLane Flow)

Complete RTL-to-GDSII flow executed:

1. Synthesis (Yosys)
2. Floorplanning
3. Placement
4. Clock Tree Synthesis (CTS)
5. Detailed Routing
6. Signoff Checks

### Technology
- SkyWater 130nm (Sky130) PDK

### Signoff Results
- Clean DRC
- Clean LVS
- Positive setup slack at signoff
- Positive hold slack at signoff
---

## Ongoing Improvements
- Adding step-by-step instructions to reproduce the full RTL-to-GDS flow.
- Expanding verification with a UVM-based constrained-random testbench.