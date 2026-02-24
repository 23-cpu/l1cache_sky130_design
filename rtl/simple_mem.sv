module simple_mem #(
    parameter int WORDS = 1024
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        mem_req_valid,
    input  logic        mem_req_rw,       // 0=read, 1=writeback
    input  logic [31:0] mem_req_addr,
    input  logic [31:0] mem_req_wdata,

    output logic        mem_req_ready,
    output logic        mem_resp_valid,
    output logic [31:0] mem_resp_rdata
);

    logic [31:0] mem [0:WORDS-1];

    // Always ready in this simple model
    assign mem_req_ready = 1'b1;

    // Word addressing: ignore byte offset bits [1:0]
    wire [$clog2(WORDS)-1:0] waddr = mem_req_addr[($clog2(WORDS)+1):2];

    // Optional: initialize memory with a known pattern
    integer i;
    initial begin
        for (i = 0; i < WORDS; i++) begin
            mem[i] = 32'h1000_0000 + i;   // deterministic contents
        end
    end

    // 1-cycle read response latency
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_resp_valid <= 1'b0;
            mem_resp_rdata <= '0;
        end else begin
            mem_resp_valid <= 1'b0; // default: pulse for 1 cycle only

            if (mem_req_valid) begin
                if (mem_req_rw) begin
                    // WRITEBACK
                    mem[waddr] <= mem_req_wdata;
                end else begin
                    // READ
                    mem_resp_rdata <= mem[waddr];
                    mem_resp_valid <= 1'b1;
                end
            end
        end
    end

endmodule