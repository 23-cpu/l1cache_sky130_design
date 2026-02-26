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

module cache_arrays (
    input  logic clk,
    input  logic rst_n,

    // Addressed by set index
    input  logic [3:0]  rd_set_idx,

    // Read outputs (registered)
    output logic [25:0] rd_tag_way0,
    output logic [25:0] rd_tag_way1,
    output logic [31:0] rd_data_way0,
    output logic [31:0] rd_data_way1,
    output logic        rd_valid_way0,
    output logic        rd_valid_way1,
    output logic        rd_dirty_way0,
    output logic        rd_dirty_way1,
    output logic        rd_plru,

    // Write controls
    input  logic        wr_en,
    input  logic        wr_way,        // 0=way0, 1=way1
    input  logic [3:0]  wr_set_idx,

    input  logic        wr_tag_en,
    input  logic [25:0] wr_tag,

    input  logic        wr_data_en,
    input  logic [31:0] wr_data,

    input  logic        wr_valid_en,
    input  logic        wr_valid,

    input  logic        wr_dirty_en,
    input  logic        wr_dirty,

    input  logic        wr_plru_en,
    input  logic        wr_plru
);

    // -------------------------
    // Storage declarations
    // -------------------------
    logic [25:0] tag_way0 [0:15];
    logic [25:0] tag_way1 [0:15];

    logic [31:0] data_way0 [0:15];
    logic [31:0] data_way1 [0:15];

    logic valid_way0 [0:15];
    logic valid_way1 [0:15];

    logic dirty_way0 [0:15];
    logic dirty_way1 [0:15];

    logic plru [0:15];

    // -------------------------
    // Reset + Read (registered)
    // -------------------------
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 16; i++) begin
                tag_way0[i]   <= '0;
                tag_way1[i]   <= '0;
                data_way0[i]  <= '0;
                data_way1[i]  <= '0;
                valid_way0[i] <= 1'b0;
                valid_way1[i] <= 1'b0;
                dirty_way0[i] <= 1'b0;
                dirty_way1[i] <= 1'b0;
                plru[i]       <= 1'b0;
            end

            rd_tag_way0   <= '0;
            rd_tag_way1   <= '0;
            rd_data_way0  <= '0;
            rd_data_way1  <= '0;
            rd_valid_way0 <= 1'b0;
            rd_valid_way1 <= 1'b0;
            rd_dirty_way0 <= 1'b0;
            rd_dirty_way1 <= 1'b0;
            rd_plru       <= 1'b0;

        end else begin
            // Registered readout for selected set
            rd_tag_way0   <= tag_way0[rd_set_idx];
            rd_tag_way1   <= tag_way1[rd_set_idx];
            rd_data_way0  <= data_way0[rd_set_idx];
            rd_data_way1  <= data_way1[rd_set_idx];
            rd_valid_way0 <= valid_way0[rd_set_idx];
            rd_valid_way1 <= valid_way1[rd_set_idx];
            rd_dirty_way0 <= dirty_way0[rd_set_idx];
            rd_dirty_way1 <= dirty_way1[rd_set_idx];
            rd_plru       <= plru[rd_set_idx];

            // Writes (single-port style)
            if (wr_en) begin
                if (wr_way == 1'b0) begin
                    if (wr_tag_en)   tag_way0[wr_set_idx]   <= wr_tag;
                    if (wr_data_en)  data_way0[wr_set_idx]  <= wr_data;
                    if (wr_valid_en) valid_way0[wr_set_idx] <= wr_valid;
                    if (wr_dirty_en) dirty_way0[wr_set_idx] <= wr_dirty;
                end else begin
                    if (wr_tag_en)   tag_way1[wr_set_idx]   <= wr_tag;
                    if (wr_data_en)  data_way1[wr_set_idx]  <= wr_data;
                    if (wr_valid_en) valid_way1[wr_set_idx] <= wr_valid;
                    if (wr_dirty_en) dirty_way1[wr_set_idx] <= wr_dirty;
                end

                if (wr_plru_en) plru[wr_set_idx] <= wr_plru;
            end
        end
    end

endmodule