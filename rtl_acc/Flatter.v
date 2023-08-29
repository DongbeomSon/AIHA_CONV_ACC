module flatter(
    input clk,
    input rst_n,

    input ofm_port0_v,
    input ofm_port1_v,

    input [24:0] ofm_port0,
    input [24:0] ofm_port1,

    input start_conv,
    input [63:0] wmst_offset,

    output [511:0] tdata,
    input ready,
    output valid,

    output wmst_req,
    output reg [63:0] wmst_addr
);

    reg [3:0] cnt;
    reg [511:0] ofm0;
    reg [511:0] ofm1;


    wire out_fifo_push_req;
    wire out_fifo_pop_req;
    wire [511:0] out_fifo_push_data;
    wire [511:0] out_fifo_pop_data;
    wire out_fifo_empty;
    wire out_fifo_full;
    wire [3:0] out_fifo_data_cnt;

    FifoType0 #(.data_width (512), .addr_bits (3)) ofm_fifo (
        .CLK        (clk),
        .nRESET     (rst_n),
        .PUSH_REQ   (out_fifo_push_req),
        .POP_REQ    (out_fifo_pop_req),
        .PUSH_DATA  (out_fifo_push_data),
        .CLEAR      (),
  
        .POP_DATA   (out_fifo_pop_data),
        .EMPTY      (out_fifo_empty),
        .FULL       (out_fifo_full),
        .ERROR      (),
        .DATA_CNT   (out_fifo_data_cnt)
    );

    reg [511:0] ofm_temp;
    reg p_req;

    assign tdata = out_fifo_pop_data;
    assign valid = !out_fifo_empty;
    assign out_fifo_pop_req = ready & valid;
    assign out_fifo_push_req = p_req;
    assign out_fifo_push_data = ofm_temp;

    reg [2:0] flat_done;

    localparam WORD_READY = 2;
    localparam LAST_WORD = 3;
    

    reg r_wmst_req;

    assign wmst_req = r_wmst_req;


    reg [31:0] addr_cnt;

    always @(*) begin
        wmst_addr = wmst_offset + addr_cnt * 64; // 64 byte = 512bit
    end


    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            addr_cnt <= 0;
        end else begin
            addr_cnt <= start_conv ? 0 : out_fifo_pop_req ? addr_cnt + 1 : addr_cnt;
        end
    end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            ofm0 <= 0;
            ofm1 <= 0;
            ofm_temp <= 0;
            p_req <= 0;
            r_wmst_req <= 0;
        end else begin
            if (r_wmst_req) r_wmst_req <= 0;

            if (flat_done != 0) begin
                if (flat_done == WORD_READY || flat_done == LAST_WORD) begin
                    ofm_temp <= ofm0;
                    p_req <= 1;
                end else begin
                    ofm_temp <= ofm1;
                    p_req <= 1;
                end
                flat_done <= (flat_done == LAST_WORD) ? 0 : flat_done - 1;
            end else begin
                p_req <= 0;
            end
            if (cnt + 1 == 16) begin
                cnt <= 0;
                r_wmst_req <= 1;
                flat_done <= (ofm_port0_v ^ ofm_port1_v) ? LAST_WORD : WORD_READY;
            end else begin
                if (ofm_port0_v) ofm0[cnt * 32 +: 32] <= {7'b000_0000,ofm_port0};
                if (ofm_port1_v) ofm1[cnt * 32 +: 32] <= {7'b000_0000, ofm_port1};
                cnt <= (ofm_port0_v | ofm_port1_v) ? cnt + 1 : cnt;
            end
        end
    end

endmodule