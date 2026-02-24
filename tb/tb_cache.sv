`timescale 1ns/1ps

module tb_cache;

    import cache_pkg::*;

    // Clock / reset
    logic clk;
    logic rst_n;

    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // CPU interface
    logic        cpu_req_valid;
    logic [31:0] cpu_req_addr;
    logic [31:0] cpu_req_wdata;
    logic [3:0]  cpu_req_wstrb;

    logic        cpu_req_ready;
    logic        cpu_resp_valid;
    logic [31:0] cpu_resp_rdata;

    // Arrays interface
    logic [3:0]  rd_set_idx;

    logic [25:0] rd_tag_way0, rd_tag_way1;
    logic [31:0] rd_data_way0, rd_data_way1;
    logic        rd_valid_way0, rd_valid_way1;
    logic        rd_dirty_way0, rd_dirty_way1;
    logic        rd_plru;

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

    // Memory interface
    logic        mem_req_valid;
    logic        mem_req_rw;
    logic [31:0] mem_req_addr;
    logic [31:0] mem_req_wdata;

    logic        mem_req_ready;
    logic        mem_resp_valid;
    logic [31:0] mem_resp_rdata;

    // tests, writes reads
    logic [31:0] r0, r1;
    logic [31:0] A;
     
    logic [31:0] B; 

    // DUT: arrays
    cache_arrays u_arrays (
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

    // DUT: controller
    cache_ctrl u_ctrl (
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

    // Memory model
    simple_mem u_mem (
        .clk(clk),
        .rst_n(rst_n),

        .mem_req_valid(mem_req_valid),
        .mem_req_rw(mem_req_rw),
        .mem_req_addr(mem_req_addr),
        .mem_req_wdata(mem_req_wdata),

        .mem_req_ready(mem_req_ready),
        .mem_resp_valid(mem_resp_valid),
        .mem_resp_rdata(mem_resp_rdata)
    );

    // -------------------------
    // CPU driver helper tasks
    // -------------------------
    task automatic cpu_read(input logic [31:0] addr, output logic [31:0] rdata);
        begin
            // present request until accepted
            cpu_req_addr  = addr;
            cpu_req_wdata = '0;
            cpu_req_wstrb = 4'b0000;
            cpu_req_valid = 1'b1;

            // wait for ready handshake
            while (!cpu_req_ready) @(posedge clk);
            @(posedge clk);
            cpu_req_valid = 1'b0;

            // wait for response pulse
            while (!cpu_resp_valid) @(posedge clk);
            rdata = cpu_resp_rdata;
            @(posedge clk);
        end
    endtask

    task automatic cpu_write(input logic [31:0] addr, input logic [31:0] wdata, input logic [3:0] wstrb);
        begin
            cpu_req_addr  = addr;
            cpu_req_wdata = wdata;
            cpu_req_wstrb = wstrb;
            cpu_req_valid = 1'b1;

            while (!cpu_req_ready) @(posedge clk);
            @(posedge clk);
            cpu_req_valid = 1'b0;

            // wait for completion response pulse (ack)
            while (!cpu_resp_valid) @(posedge clk);
            @(posedge clk);
        end
    endtask

    // Address helper: pick addresses that map to the same index (for eviction tests)
    // This assumes OFFSET_BITS=2 and INDEX_BITS=4 -> add 1<<(OFFSET+INDEX)=1<<6 = 0x40 changes tag, keeps same index+offset.
    function automatic logic [31:0] addr_same_index_diff_tag(input logic [3:0] idx, input int tag_step);
        logic [31:0] base;
        begin
            base = (idx << OFFSET_BITS); // offset=0
            addr_same_index_diff_tag = base + (tag_step << (OFFSET_BITS + INDEX_BITS));
        end
    endfunction

    // -------------------------
    // Test sequence
    // -------------------------
    initial begin
        // init
        cpu_req_valid = 0;
        cpu_req_addr  = 0;
        cpu_req_wdata = 0;
        cpu_req_wstrb = 0;

        // reset
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        $display("TEST1: Read miss then read hit (same addr)");

        A = addr_same_index_diff_tag(4'd3, 0);

        cpu_read(A, r0);
        cpu_read(A, r1);

        if (r0 !== r1) begin
            $fatal(1, "Read miss/hit mismatch: r0=%h r1=%h", r0, r1);
        end
        $display("  PASS: r0=%h r1=%h", r0, r1);

        $display("TEST2: Write hit then read back");
        // After TEST1, A should be in cache -> write should be hit
        cpu_write(A, 32'hDEAD_BEEF, 4'b1111);
        cpu_read(A, r0);
        if (r0 !== 32'hDEAD_BEEF) begin
            $fatal(1, "Write hit readback failed: got %h expected %h", r0, 32'hDEAD_BEEF);
        end
        $display("  PASS: readback=%h", r0);

        $display("TEST3: Write miss (new tag, same index), then read back");
        
        B = addr_same_index_diff_tag(4'd3, 1); // same index, different tag
        cpu_write(B, 32'hCAFEBABE, 4'b1111);   // should be a miss then allocate+refill+merge
        cpu_read(B, r0);
        if (r0 !== 32'hCAFEBABE) begin
            $fatal(1, "Write miss readback failed: got %h expected %h", r0, 32'hCAFEBABE);
        end
        $display("  PASS: readback=%h", r0);

        $display("ALL BASIC TESTS PASSED ✅");
        $finish;
    end

endmodule