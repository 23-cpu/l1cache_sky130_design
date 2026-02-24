// author : frederick adom

// cache_defs.svh
  // ------------------------
  // Cache configuration
  // ------------------------
  localparam int ADDR_W = 32;
  localparam int DATA_W = 32;

  localparam int WAYS        = 2;
  localparam int SETS        = 16;   // 16 sets
  localparam int LINE_BYTES  = 4;    // 1 word per line (4 bytes)

  // Derived
  localparam int OFFSET_BITS = 2;    // log2(4 bytes) = 2
  localparam int INDEX_BITS  = 4;    // log2(16 sets) = 4
  localparam int TAG_BITS    = ADDR_W - OFFSET_BITS - INDEX_BITS;

  // Bit slicing helpers
// Yosys-friendly helper macros
`define ADDR_INDEX(a)  (a[OFFSET_BITS + INDEX_BITS - 1 : OFFSET_BITS])
`define ADDR_TAG(a)    (a[ADDR_W-1 : OFFSET_BITS + INDEX_BITS])
