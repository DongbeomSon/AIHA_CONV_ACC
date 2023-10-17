module input_buffer #(
    parameter DATA_WIDTH = 512,
    parameter DATA_WIDTH_BYTE = DATA_WIDTH / 8,
    parameter DATA_NUM = 64,  //eqeaul to burst len
    //    parameter DATA_NUM_BYTE = 63232,
    parameter FIFO_ADDR_WIDTH = 7,
    parameter BURST_LENGTH = 64,
    parameter BURST_LENGTH_BYTE = DATA_WIDTH_BYTE * BURST_LENGTH,
    parameter TEST_BYTE = 63232
    //    parameter INIT_LOOP = DATA_NUM_BYTE/DATA_NUM/BURST_LENGTH
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

    input g_stall,

    input op_start,
    input end_conv,

    output xfer_clear,

    //   output reg buf_rdy,
    output stall
);

    wire [31:0] data_byte = input_byte + {20'b0, addr_base[11:0]};

    // reg [31:0] read_num;
    // reg final_read;
    // reg [31:0] final_read_num;
    // reg [31:0] final_xfer_size;
    // always @(*) begin
    //     read_num <= data_byte / BURST_LENGTH_BYTE;
    //     final_read_num <= (data_byte % BURST_LENGTH_BYTE) / DATA_WIDTH_BYTE;
    //     final_read <= |final_read_num;
    //     final_xfer_size <= data_byte % BURST_LENGTH_BYTE;
    // end

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
    // assign in_fifo0_push_req = buf_rdy ? pop_req : valid & ready;
    // reg [31:0] align_addr_cnt;
    assign ready = !in_fifo0_full;
    // wire addr_aligning = |align_addr_cnt;
    //!addr_aligning & 
    assign in_fifo0_push_req = r_op_start & valid & ready;


    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            r_pop_req <= 0;
        end else begin
            r_pop_req <= pop_req;
        end
    end


    assign in_fifo0_pop_req   = !g_stall & pop_req;
    assign in_fifo0_push_data = tdata;

    reg [511:0] r_o_data;
    reg [511:0] bypass_input;
    reg bypass_flag;


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
    end
    assign o_data = r_o_data;

    reg rmst_rised;
    reg [31:0] addr_cnt;

    reg [63:0] r_addr_offset;
    assign addr_offset = r_addr_offset;
    // always @(*) begin
    //     r_addr_offset = addr_cnt * DATA_NUM * BURST_LENGTH + {addr_base[63:12], 12'b0};
    // end

    always @(*) begin
        r_addr_offset = addr_base;
    end

    // always @(posedge clk, negedge rst_n) begin
    //     if (!rst_n) begin
    //         addr_cnt  <= 0;
    //         xfer_size <= BURST_LENGTH_BYTE;
    //     end else begin
    //         if (end_conv) begin
    //             addr_cnt  <= 0;
    //             xfer_size <= BURST_LENGTH_BYTE;
    //         end else if (!r_end_conv & rmst_done) begin
    //             if (addr_cnt == read_num - 1) begin
    //                 if (final_read) begin
    //                     addr_cnt  <= addr_cnt + 1;
    //                     xfer_size <= final_xfer_size;
    //                 end else begin
    //                     addr_cnt <= 0;
    //                 end
    //             end else begin
    //                 addr_cnt  <= (addr_cnt == read_num) ? 0 : addr_cnt + 1;
    //                 xfer_size <= BURST_LENGTH_BYTE;
    //             end
    //         end
    //     end
    // end

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
