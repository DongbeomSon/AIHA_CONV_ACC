module switch_buffer #(
    parameter DATA_WIDTH = 512,
    parameter DATA_NUM = 64,
    parameter DATA_NUM_BYTE = 63232,
    parameter FIFO_ADDR_WIDTH = 10,
    parameter BURST_LENGTH = 4,
    parameter INIT_LOOP = DATA_NUM_BYTE/DATA_NUM/BURST_LENGTH
    )(
    input clk,
    input rst_n,

    input [DATA_WIDTH-1:0] tdata,
    input valid,
    output ready,

    input [63:0] addr_base,

    output reg rmst_req,
    input rmst_done,

    output reg [63:0] addr_offset,

    input pop_req,
    output [DATA_WIDTH-1:0] o_data,

    input op_start,
    input end_conv,

    output reg buf_rdy
);

    wire            in_fifo0_full;
    wire            in_fifo0_empty;
    wire            in_fifo0_push_req;
    wire    [511:0] in_fifo0_push_data;
    wire            in_fifo0_pop_req;
    wire    [511:0] in_fifo0_pop_data;  
    wire    [FIFO_ADDR_WIDTH:0]  in_fifo0_data_cnt;

    FifoType0 #(.data_width (DATA_WIDTH), .addr_bits (FIFO_ADDR_WIDTH)) fifo_0 (
        .CLK        (clk),
        .nRESET     (rst_n),
        .PUSH_REQ   (in_fifo0_push_req),
        .POP_REQ    (in_fifo0_pop_req),
        .PUSH_DATA  (in_fifo0_push_data),
        .CLEAR      (end_conv),
  
        .POP_DATA   (in_fifo0_pop_data),
        .EMPTY      (in_fifo0_empty),
        .FULL       (in_fifo0_full),
        .ERROR      (),
        .DATA_CNT   (in_fifo0_data_cnt)
    );
    reg r_pop_req;
    assign in_fifo0_push_req = buf_rdy ? pop_req : valid & ready;

   

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            r_pop_req <= 0;
        end else begin
            r_pop_req <= pop_req;
        end
    end

    assign in_fifo0_pop_req = pop_req;

    assign in_fifo0_push_data = buf_rdy ? in_fifo0_pop_data : tdata;

    assign o_data = in_fifo0_pop_data;

    assign ready = !in_fifo0_full;

    reg rmst_rised;
    reg [31:0] addr_cnt;

    reg [31:0] init_word_cnt;

    always @(*) begin
        addr_offset <= addr_cnt * DATA_NUM * BURST_LENGTH + addr_base;
    end


    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            addr_cnt <= 0;
            init_word_cnt <= 0;
        end else begin
            if(rmst_done) begin
                addr_cnt <= addr_cnt + 1;
                init_word_cnt <= init_word_cnt + 1;
            end else begin
                    addr_cnt <= end_conv ? 0 : addr_cnt;
                    init_word_cnt <= end_conv ? 0 : init_word_cnt;
            end
        end
    end

    reg r_op_start;
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            rmst_req <= 0;
            rmst_rised <= 0;
            buf_rdy <= 0;
            r_op_start <= 0;
        end else begin

            if(end_conv) r_op_start <=0;
            else if(op_start) begin
                rmst_req <= 1;
                rmst_rised <= 1;
                r_op_start <= 1;
            end
            else if (rmst_req) 
                rmst_req <= 0;
            else if (r_op_start) begin
                if (!buf_rdy & !rmst_rised) begin
                    rmst_rised <= 1;
                    rmst_req <= 1;
                end else if (rmst_done) begin
                    rmst_rised <= 0;
                end
            end

            buf_rdy <= end_conv ? 0:
                        (init_word_cnt == INIT_LOOP) ? 1 : buf_rdy;
        end
    end
endmodule