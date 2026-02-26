/* ==========================================================================
 Project: 2-Way Set Associative Cache (Sky130 Hardened)
 Author: Frederick Adom

 Description:
   RTL implementation of a parameterized 2-way set associative cache with
   write-allocate policy, dirty eviction handling, and PLRU replacement.

  Notes:
   - Synthesized and hardened using the OpenLane ASIC flow (Sky130 PDK).
   - Achieved clean DRC/LVS and positive setup/hold slack at signoff.
   - Developed for educational and research purposes.

 Date: 2026
============================================================================*/
package cache_pkg;
    `include "cache_defs.svh"
endpackage