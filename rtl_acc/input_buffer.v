module input_buffer #(
    parameter DATA_WIDTH = 512,
    parameter DATA_WIDTH_BYTE = DATA_WIDTH / 8,
    parameter DATA_NUM = 64,  //eqeaul to burst len
    parameter FIFO_ADDR_WIDTH = 7,
    parameter BURST_LENGTH = 64,
    parameter BURST_LENGTH_BYTE = DATA_WIDTH_BYTE * BURST_LENGTH,
    parameter TEST_BYTE = 63232
) (
    input clk,
    input rst_n,

    input [DATA_WIDTH-1:0] tdata,
    input valid,

    input [31:0] input_byte,  //byte input

    output ready,

    input [63:0] addr_base,

    output reg rmst_req,
    input rmst_done,

    output [63:0] addr_offset,
    output reg [63:0] xfer_size,

    input pop_req,
    output [DATA_WIDTH-1:0] o_data,
    output o_data_v,

    input g_stall,

    input op_start,
    input end_conv,

    output xfer_clear,

    output stall
);

    wire [31:0] data_byte = input_byte + {20'b0, addr_base[11:0]};

    wire in_fifo0_full;
    wire in_fifo0_empty;
    wire in_fifo0_push_req;
    wire [511:0] in_fifo0_push_data;
    wire in_fifo0_pop_req;
    wire [511:0] in_fifo0_pop_data;
    wire [FIFO_ADDR_WIDTH:0] in_fifo0_data_cnt;

    assign stall = in_fifo0_empty;

    reg r_end_conv;
    reg r_op_start;

    reg fifo_clear;

    FifoType0 #(
        .data_width(DATA_WIDTH),
        .addr_bits (FIFO_ADDR_WIDTH)
    ) fifo_0 (
        .CLK      (clk),
        .nRESET   (rst_n),
        .PUSH_REQ (in_fifo0_push_req),
        .POP_REQ  (in_fifo0_pop_req),
        .PUSH_DATA(in_fifo0_push_data),
        .CLEAR    (fifo_clear),

        .POP_DATA(in_fifo0_pop_data),
        .EMPTY   (in_fifo0_empty),
        .FULL    (in_fifo0_full),
        .ERROR   (),
        .DATA_CNT(in_fifo0_data_cnt)
    );
    reg r_pop_req;
    assign ready = !in_fifo0_full;
    assign in_fifo0_push_req = r_op_start & valid & ready;


    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            r_pop_req <= 0;
        end else begin
            r_pop_req <= pop_req;
        end
    end


    assign in_fifo0_pop_req   = !g_stall & pop_req & !in_fifo0_empty;
    assign in_fifo0_push_data = tdata;

    reg [511:0] r_o_data;
    reg [511:0] bypass_input;
    reg bypass_flag;
    reg r_o_data_v;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            bypass_flag  <= 0;
            bypass_input <= 0;
        end else begin
            if (in_fifo0_push_req) begin
                if(in_fifo0_empty | (in_fifo0_data_cnt == 1 & in_fifo0_pop_req & in_fifo0_push_req)) begin
                    bypass_flag  <= 1;
                    bypass_input <= in_fifo0_push_data;
                end else begin
                    bypass_flag <= 0;
                end
            end else begin
                bypass_flag <= 0;
            end
        end
    end

    always @(*) begin
        r_o_data <= bypass_flag ? bypass_input : in_fifo0_pop_data;
        // r_o_data_v = (!stall || bypass_flag) && pop_req;
        r_o_data_v = !stall && pop_req;
    end
    assign o_data = r_o_data;
    assign o_data_v = r_o_data_v;
    reg rmst_rised;
    reg [31:0] addr_cnt;

    reg [63:0] r_addr_offset;
    assign addr_offset = r_addr_offset;

    always @(*) begin
        r_addr_offset = addr_base;
    end

    assign xfer_clear = in_fifo0_empty;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            r_end_conv <= 0;
            fifo_clear <= 0;
        end else begin

            if ((end_conv | r_end_conv)) begin
                fifo_clear <= 1;
            end else begin
                fifo_clear <= 0;
            end
            if (end_conv) begin
                r_end_conv <= end_conv;
            end else if (!rmst_rised) begin
                r_end_conv <= 0;
            end
        end
    end

    // always @(posedge clk, negedge rst_n) begin
    //     if (!rst_n) begin
    //         align_addr_cnt <= 0;
    //     end else begin
    //         if (rmst_req & !(|addr_cnt)) begin
    //             align_addr_cnt <= addr_base[11:6];
    //         end else if (ready & valid & (|align_addr_cnt)) begin
    //             align_addr_cnt <= align_addr_cnt - 1;
    //         end
    //     end
    // end


    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            rmst_req   <= 0;
            rmst_rised <= 0;
            //               buf_rdy <= 0;
            r_op_start <= 0;
            xfer_size  <= 0;
        end else begin
            if (end_conv) r_op_start <= 0;
            else if (op_start) begin
                rmst_req   <= 1;
                rmst_rised <= 1;
                r_op_start <= 1;
                xfer_size  <= data_byte;
            end else if (rmst_req) rmst_req <= 0;
            else if (rmst_done) begin
                rmst_rised <= 0;
            end else if (r_op_start) begin
                // if (in_fifo0_data_cnt < BURST_LENGTH & !rmst_rised) begin
                if (!rmst_rised) begin
                    rmst_rised <= 1;
                    rmst_req   <= 1;
                end
            end
        end
    end

    // // ILA monitoring combinatorial adder
    // ila_0 i_ila_0 (
    // 	.clk(clk),              // input wire        clk
    // 	.probe0(fifo_clear),           // input wire [0:0]  probe0  
    // 	.probe1(rmst_rised), // input wire [0:0]  probe1 
    //     .probe6(op_start),       // input wire probe2
    // 	.probe2(in_fifo0_data_cnt),   // input wire [63:0]  probe3
    // 	.probe3(addr_base),    // input wire [63:0] probe4
    // 	.probe4(addr_offset),    // input wire [63:0] probe5 
    //     .probe5(addr_cnt)      // input wire [31:0] probe6
    // );
endmodule
