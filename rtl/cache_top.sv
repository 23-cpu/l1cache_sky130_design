/* ==========================================================================
 Top-Level Module: cache_top

 This module integrates the 2-way set associative cache and exposes
 the external interface used for simulation and ASIC hardening.

 Backend Implementation Flow:
   RTL => Synthesis => Floorplanning => Placement => CTS => Routing => Signoff

 Technology: SkyWater 130nm (Sky130)
 Clock: 20ns period (50MHz)
 Signoff Status:
   - DRC: Clean
   - LVS: Clean
   - Timing: Positive setup and hold slack

============================================================================*/

`include "cache_defs.svh"

module cache_top (
    input  logic         clk,
    input  logic         rst_n,

    // ========================
    // CPU Interface
    // ========================
    input  logic         cpu_req_valid,
    input  logic [31:0]  cpu_req_addr,
    input  logic [31:0]  cpu_req_wdata,
    input  logic [3:0]   cpu_req_wstrb,

    output logic         cpu_req_ready,
    output logic         cpu_resp_valid,
    output logic [31:0]  cpu_resp_rdata,

    // ========================
    // Memory Interface
    // ========================
    output logic         mem_req_valid,
    output logic         mem_req_rw,       // 0 = read, 1 = write
    output logic [31:0]  mem_req_addr,
    output logic [31:0]  mem_req_wdata,

    input  logic         mem_req_ready,
    input  logic         mem_resp_valid,
    input  logic [31:0]  mem_resp_rdata
);

    // =========================
    // Internal wires
    // =========================

    // Arrays read signals
    logic [3:0]  rd_set_idx;

    logic [25:0] rd_tag_way0;
    logic [25:0] rd_tag_way1;
    logic [31:0] rd_data_way0;
    logic [31:0] rd_data_way1;
    logic        rd_valid_way0;
    logic        rd_valid_way1;
    logic        rd_dirty_way0;
    logic        rd_dirty_way1;
    logic        rd_plru;

    // Arrays write signals
    logic        wr_en;
    logic        wr_way;
    logic [3:0]  wr_set_idx;

    logic        wr_tag_en;
    logic [25:0] wr_tag;

    logic        wr_data_en;
    logic [31:0] wr_data;

    logic        wr_valid_en;
    logic        wr_valid;

    logic        wr_dirty_en;
    logic        wr_dirty;

    logic        wr_plru_en;
    logic        wr_plru;


    cache_arrays arrays_inst (
        .clk(clk),
        .rst_n(rst_n),

        .rd_set_idx(rd_set_idx),

        .rd_tag_way0(rd_tag_way0),
        .rd_tag_way1(rd_tag_way1),
        .rd_data_way0(rd_data_way0),
        .rd_data_way1(rd_data_way1),
        .rd_valid_way0(rd_valid_way0),
        .rd_valid_way1(rd_valid_way1),
        .rd_dirty_way0(rd_dirty_way0),
        .rd_dirty_way1(rd_dirty_way1),
        .rd_plru(rd_plru),

        .wr_en(wr_en),
        .wr_way(wr_way),
        .wr_set_idx(wr_set_idx),

        .wr_tag_en(wr_tag_en),
        .wr_tag(wr_tag),

        .wr_data_en(wr_data_en),
        .wr_data(wr_data),

        .wr_valid_en(wr_valid_en),
        .wr_valid(wr_valid),

        .wr_dirty_en(wr_dirty_en),
        .wr_dirty(wr_dirty),

        .wr_plru_en(wr_plru_en),
        .wr_plru(wr_plru)
    );


    cache_ctrl ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),

        .cpu_req_valid(cpu_req_valid),
        .cpu_req_addr(cpu_req_addr),
        .cpu_req_wdata(cpu_req_wdata),
        .cpu_req_wstrb(cpu_req_wstrb),

        .cpu_req_ready(cpu_req_ready),
        .cpu_resp_valid(cpu_resp_valid),
        .cpu_resp_rdata(cpu_resp_rdata),

        .rd_set_idx(rd_set_idx),

        .rd_tag_way0(rd_tag_way0),
        .rd_tag_way1(rd_tag_way1),
        .rd_data_way0(rd_data_way0),
        .rd_data_way1(rd_data_way1),
        .rd_valid_way0(rd_valid_way0),
        .rd_valid_way1(rd_valid_way1),
        .rd_dirty_way0(rd_dirty_way0),
        .rd_dirty_way1(rd_dirty_way1),
        .rd_plru(rd_plru),

        .wr_en(wr_en),
        .wr_way(wr_way),
        .wr_set_idx(wr_set_idx),

        .wr_tag_en(wr_tag_en),
        .wr_tag(wr_tag),

        .wr_data_en(wr_data_en),
        .wr_data(wr_data),

        .wr_valid_en(wr_valid_en),
        .wr_valid(wr_valid),

        .wr_dirty_en(wr_dirty_en),
        .wr_dirty(wr_dirty),

        .wr_plru_en(wr_plru_en),
        .wr_plru(wr_plru),

        .mem_req_valid(mem_req_valid),
        .mem_req_rw(mem_req_rw),
        .mem_req_addr(mem_req_addr),
        .mem_req_wdata(mem_req_wdata),

        .mem_req_ready(mem_req_ready),
        .mem_resp_valid(mem_resp_valid),
        .mem_resp_rdata(mem_resp_rdata)
    );


endmodule