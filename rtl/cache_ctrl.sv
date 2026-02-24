`include "cache_defs.svh"

module cache_ctrl (
    input  logic         clk,
    input  logic         rst_n,

    // CPU Interface
    input  logic         cpu_req_valid,
    input  logic [31:0]  cpu_req_addr,
    input  logic [31:0]  cpu_req_wdata,
    input  logic [3:0]   cpu_req_wstrb,

    output logic         cpu_req_ready,
    output logic         cpu_resp_valid,
    output logic [31:0]  cpu_resp_rdata,

    // Arrays: read address (set index)
    output logic [3:0]   rd_set_idx,

    // Arrays: read outputs (from cache_arrays)
    input  logic [25:0]  rd_tag_way0,
    input  logic [25:0]  rd_tag_way1,
    input  logic [31:0]  rd_data_way0,
    input  logic [31:0]  rd_data_way1,
    input  logic         rd_valid_way0,
    input  logic         rd_valid_way1,
    input  logic         rd_dirty_way0,
    input  logic         rd_dirty_way1,
    input  logic         rd_plru,

    // Arrays: write controls (to cache_arrays)
    output logic         wr_en,
    output logic         wr_way,
    output logic [3:0]   wr_set_idx,

    output logic         wr_tag_en,
    output logic [25:0]  wr_tag,

    output logic         wr_data_en,
    output logic [31:0]  wr_data,

    output logic         wr_valid_en,
    output logic         wr_valid,

    output logic         wr_dirty_en,
    output logic         wr_dirty,

    output logic         wr_plru_en,
    output logic         wr_plru,

    // Memory Interface
    output logic         mem_req_valid,
    output logic         mem_req_rw,     // 0=read, 1=writeback
    output logic [31:0]  mem_req_addr,
    output logic [31:0]  mem_req_wdata,

    input  logic         mem_req_ready,
    input  logic         mem_resp_valid,
    input  logic [31:0]  mem_resp_rdata
);
    
    logic [31:0] req_addr_q;
    logic [31:0] req_wdata_q;
    logic [3:0]  req_wstrb_q;
    logic        req_is_write_q;

    logic [TAG_BITS-1:0] req_tag_q;
    logic [INDEX_BITS-1:0] req_index_q;

    logic accept_req;

    logic hit0, hit1;
    logic hit_any;
    logic hit_way; // 0=way0, 1=way1

    // for write and read hits
    logic [31:0] hit_data;
    logic [31:0] wmask;
    logic [31:0] merged_wdata;
    
    // miss select
    logic        victim_way_q;   // 0=way0, 1=way1
    logic        victim_dirty_q;
    logic [25:0] victim_tag_q;
    logic [31:0] victim_data_q;

    //write back address
    logic [31:0] wb_addr;

    // refil address
    logic [31:0] refill_addr;

    typedef enum logic [3:0] {
        IDLE,
        LOOKUP,
        HIT_RESP,
        MISS_SELECT,
        WRITEBACK,
        REFILL_REQ,
        REFILL_WAIT,
        REFILL_UPDATE
    } state_t;

    state_t state, next_state;

    // State register
    // main state 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next-state logic (placeholder for now)

    always @* begin
        cpu_req_ready  = 1'b0;
        cpu_resp_valid = 1'b0;
        cpu_resp_rdata = '0;

        // default: no writes to arrays
        wr_en       = 1'b0;
        wr_way      = 1'b0;
        wr_set_idx  = '0;

        wr_tag_en   = 1'b0;
        wr_tag      = '0;

        wr_data_en  = 1'b0;
        wr_data     = '0;

        wr_valid_en = 1'b0;
        wr_valid    = 1'b0;

        wr_dirty_en = 1'b0;
        wr_dirty    = 1'b0;

        wr_plru_en  = 1'b0;
        wr_plru     = 1'b0;

        // default: no memory request
        mem_req_valid = 1'b0;
        mem_req_rw    = 1'b0;
        mem_req_addr  = '0;
        mem_req_wdata = '0;

        // drive array read index from the latched request
        rd_set_idx = req_index_q;
        next_state = state;

        // hits computation
        hit0    = rd_valid_way0 && (rd_tag_way0 == req_tag_q);
        hit1    = rd_valid_way1 && (rd_tag_way1 == req_tag_q);
        hit_any = hit0 || hit1;

        // If both hit (shouldn't happen), prefer way0
        //hit_way = hit1; // way1 if hit1=1 and hit0=0; otherwise way0
        hit_way = 1'b0; // default way0
        if (!hit0 && hit1) begin
            hit_way = 1'b1; // choose way1 only if way0 is not a hit
        end

        // Select the hit data (from the hit way)
        hit_data = (hit_way == 1'b0) ? rd_data_way0 : rd_data_way1;

        // Expand byte strobes into a 32-bit write mask
        wmask = { {8{req_wstrb_q[3]}},
                  {8{req_wstrb_q[2]}},
                  {8{req_wstrb_q[1]}},
                  {8{req_wstrb_q[0]}} };

        // Merge new write data into old word using mask
        merged_wdata = (hit_data & ~wmask) | (req_wdata_q & wmask);

        // Victim (writeback) address = {victim_tag, current set index, offset=0}
        wb_addr = { victim_tag_q, req_index_q, {OFFSET_BITS{1'b0}} };

        // Refill address = base address of the requested line (offset=0)
        refill_addr = { req_tag_q, req_index_q, {OFFSET_BITS{1'b0}} };

        case (state)
            IDLE: begin
                cpu_req_ready = 1'b1;
                if (cpu_req_valid) begin
                    next_state = LOOKUP;
                end
            end

            LOOKUP: begin
                if (hit_any) begin
                    next_state = HIT_RESP;
                end else begin
                    next_state = MISS_SELECT;
                end
            end

            HIT_RESP: begin
                // Placeholder response (we'll replace next step)
                cpu_resp_valid = 1'b1;
                cpu_resp_rdata = hit_data;
                                // replaced (hit_way == 1'b0) ? rd_data_way0 : rd_data_way1;

                // Update PLRU on hit
                wr_en      = 1'b1;
                wr_set_idx = req_index_q;
                wr_way = hit_way;

                wr_plru_en = 1'b1;
                wr_plru    = (hit_way == 1'b0) ? 1'b1 : 1'b0;

                // if write hit: update data and set dirty bit
                if (req_is_write_q) begin
                    wr_data_en = 1'b1;
                    wr_data = merged_wdata;

                    wr_dirty_en = 1'b1;
                    wr_dirty = 1'b1;

                    // for debug
                    cpu_resp_rdata = merged_wdata;
                end
                
                next_state = IDLE;
            end

            MISS_SELECT: begin
                // choose victim
                logic victim_way_c;
                logic victim_dirty_c;
                logic [25:0] victim_tag_c;
                logic [31:0] victim_data_c;

                if (!rd_valid_way0) begin
                    victim_way_c   = 1'b0;
                    victim_dirty_c = 1'b0;
                    victim_tag_c   = rd_tag_way0;
                    victim_data_c  = rd_data_way0;
                end else if (!rd_valid_way1) begin
                    victim_way_c   = 1'b1;
                    victim_dirty_c = 1'b0;
                    victim_tag_c   = rd_tag_way1;
                    victim_data_c  = rd_data_way1;
                end else begin
                    // Both valid: evict the LRU way using PLRU
                    // Our convention: plru=0 -> way0 is LRU, plru=1 -> way1 is LRU
                    victim_way_c   = rd_plru;
                    victim_tag_c   = (rd_plru == 1'b0) ? rd_tag_way0  : rd_tag_way1;
                    victim_data_c  = (rd_plru == 1'b0) ? rd_data_way0 : rd_data_way1;
                    victim_dirty_c = (rd_plru == 1'b0) ? rd_dirty_way0: rd_dirty_way1;
                end

                // Latch victim info (we'll store it in regs in the sequential block)
                // Decide next state:
                if (victim_dirty_c) begin
                    next_state = WRITEBACK;
                end else begin
                    next_state = REFILL_REQ;
                end
                // NOTE: no cpu_resp_valid here anymore; miss will be serviced via refill/writeback

            end

            WRITEBACK: begin
                // write dirty line
                // issue writeback request to memory(because we want to write old victim line out)
                mem_req_valid = 1'b1;
                mem_req_rw = 1'b1; // 1 = write request 0 for read request
                mem_req_addr = wb_addr;
                mem_req_wdata = victim_data_q;

                // wait until memory accepts the request
                if(mem_req_ready) begin
                    next_state = REFILL_REQ;
                end else begin
                    next_state = WRITEBACK; // stay here until accepted
                end
            end

            REFILL_REQ: begin

                // request memory 
                // Issue memory read to fetch the requested line
                mem_req_valid = 1'b1;
                mem_req_rw    = 1'b0;        // 0 = read
                mem_req_addr  = refill_addr;
                mem_req_wdata = '0;          // unused for reads

                // Advance once memory accepts the request
                if (mem_req_ready) begin
                    next_state = REFILL_WAIT;
                end else begin
                    next_state = REFILL_REQ; // keep requesting until accepted
                end
            end

            REFILL_WAIT: begin
                // Wait for memory to return the line
                if (mem_resp_valid) begin
                    next_state = REFILL_UPDATE;
                end else begin
                    next_state = REFILL_WAIT;
                end
            end

            REFILL_UPDATE: begin
                // Write the refilled line into the chosen victim way
                wr_en      = 1'b1;
                wr_way     = victim_way_q;
                wr_set_idx = req_index_q;

                // Update tag
                wr_tag_en = 1'b1;
                wr_tag    = req_tag_q;

                // Update data:
                //  If original request was a write miss, merge CPU write into the returned data
                // - Else, store the returned data as is
                wr_data_en = 1'b1;
                if (req_is_write_q) begin
                    // Reuse your existing merged_wdata computation (it uses hit_data/wmask)
                    // For refill, treat mem_resp_rdata as the "old" line data to merge into:
                    wr_data = (mem_resp_rdata & ~wmask) | (req_wdata_q & wmask);
                end else begin
                    wr_data = mem_resp_rdata;
                end

                // Set valid
                wr_valid_en = 1'b1;
                wr_valid    = 1'b1;

                // Set dirty:
                // read miss refill -> clean
                // write miss refill -> dirty (because we modify it)
                wr_dirty_en = 1'b1;
                wr_dirty    = req_is_write_q ? 1'b1 : 1'b0;

                // Update PLRU: mark the *other* way as LRU (same convention as before)
                wr_plru_en = 1'b1;
                wr_plru    = (victim_way_q == 1'b0) ? 1'b1 : 1'b0;

                // Respond to CPU:
                // On a miss, we respond now (same cycle as update) using the final value
                cpu_resp_valid = 1'b1;
                if (req_is_write_q) begin
                    // For stores, you may not need rdata; return merged data (or 0) for now
                    cpu_resp_rdata = (mem_resp_rdata & ~wmask) | (req_wdata_q & wmask);
                end else begin
                    cpu_resp_rdata = mem_resp_rdata;
                end
                
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // handshake event
    assign accept_req = (state == IDLE) && cpu_req_valid && cpu_req_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_addr_q     <= '0;
            req_wdata_q    <= '0;
            req_wstrb_q    <= '0;
            req_is_write_q <= 1'b0;
            req_tag_q      <= '0;
            req_index_q    <= '0;
        end else begin
            if (accept_req) begin
                req_addr_q     <= cpu_req_addr;
                req_wdata_q    <= cpu_req_wdata;
                req_wstrb_q    <= cpu_req_wstrb;
                req_is_write_q <= (cpu_req_wstrb != 4'b0000);

                req_tag_q      <= `ADDR_TAG(cpu_req_addr);
                req_index_q    <= `ADDR_INDEX(cpu_req_addr);
            end
        end
    end
        // latch victim info
        always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            victim_way_q   <= 1'b0;
            victim_dirty_q <= 1'b0;
            victim_tag_q   <= '0;
            victim_data_q  <= '0;
        end else begin
            if (state == MISS_SELECT) begin
                // Capture selected victim from current rd_* outputs
                if (!rd_valid_way0) begin
                    victim_way_q   <= 1'b0;
                    victim_dirty_q <= 1'b0;
                    victim_tag_q   <= rd_tag_way0;
                    victim_data_q  <= rd_data_way0;
                end else if (!rd_valid_way1) begin
                    victim_way_q   <= 1'b1;
                    victim_dirty_q <= 1'b0;
                    victim_tag_q   <= rd_tag_way1;
                    victim_data_q  <= rd_data_way1;
                end else begin
                    victim_way_q   <= rd_plru;
                    victim_tag_q   <= (rd_plru == 1'b0) ? rd_tag_way0   : rd_tag_way1;
                    victim_data_q  <= (rd_plru == 1'b0) ? rd_data_way0  : rd_data_way1;
                    victim_dirty_q <= (rd_plru == 1'b0) ? rd_dirty_way0 : rd_dirty_way1;
                end
            end
        end
    end

endmodule