module flatter #(
    parameter WORD_BYTE = 64,
    parameter WORD_NUM = 16
    )
    (
    input clk,
    input rst_n,

    input ofm0_port_v,
    input ofm1_port_v,

    input [255:0] ofm0_port,
    input [255:0] ofm1_port,

    input end_conv,

    output [511:0] tdata,
    input ready,
    output valid,

    input [63:0] wmst_offset,
    input wmst_done,
    output wmst_req,
    output reg [63:0] wmst_addr,
    output reg [63:0] wmst_xfer_size,
    output write_buffer_wait
);



    wire out_fifo_push_req;
    wire out_fifo_pop_req;
    wire [511:0] out_fifo_push_data;
    wire [511:0] out_fifo_pop_data;
    wire out_fifo_empty;
    wire out_fifo_full;
    wire [9:0] out_fifo_data_cnt;

    FifoType0 #(.data_width (512), .addr_bits (9)) ofm_fifo (
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


    assign write_buffer_wait = !out_fifo_empty;
    assign tdata = out_fifo_pop_data;
    assign valid = !out_fifo_empty;
    assign out_fifo_pop_req = ready & valid;
    assign out_fifo_push_req = ofm0_port_v & ofm1_port_v;
    assign out_fifo_push_data = {ofm0_port,ofm1_port};
	
    
	reg r_end_conv;
    reg r_wmst_req;
    reg flag_wmst_req;
    assign wmst_req = r_wmst_req;


    reg [31:0] addr_cnt;

    always @(*) begin
        wmst_addr = wmst_offset + addr_cnt * WORD_BYTE; // 64 byte = 512bit
        wmst_xfer_size = WORD_BYTE * WORD_NUM; //addr_cnt_temp * WORD_BYTE;
    end
	
	    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            r_wmst_req <=0;
            flag_wmst_req <= 0;
            addr_cnt <= 0;
        end else begin
            if(wmst_done) begin
                flag_wmst_req <= 0;
                if(r_end_conv & out_fifo_empty) begin
                    addr_cnt <= 0;
                end else begin
                    addr_cnt <= addr_cnt + WORD_NUM;
                end
            end else if(out_fifo_data_cnt > WORD_NUM-1 & !flag_wmst_req) begin
                flag_wmst_req <= 1;
                r_wmst_req <= 1;
            end else if (r_wmst_req) begin
                r_wmst_req <= 0;
            end
        end
    end
	
	
	
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            r_end_conv <= 0;
        end else begin
            if(end_conv) r_end_conv <= 1;
            else if (wmst_done & r_end_conv & out_fifo_empty) begin
                r_end_conv <= 0;
            end
        end
    end



	// // ILA monitoring combinatorial adder
	// ila_0 i_ila_0 (
	// 	.clk(clk),              // input wire        clk
	// 	.probe0(wmst_addr),           // input wire [63:0]  probe0  
	// 	.probe1(end_conv), // input wire [0:0]  probe1 
	// 	.probe2(r_end_conv),   // input wire [0:0]  probe2 
	// 	.probe3(addr_cnt),    // input wire [31:0] probe3 
	// 	.probe4(out_fifo_push_data),     // input wire [511:0]  probe4 
	// 	.probe5(ofm0_port_v),   // input wire [0:0]  probe5 
	// 	.probe6(ofm1_port_v),       // input wire [0:0] probe6
  	// 	.probe7(out_fifo_data_cnt),     // input wire [9:0]  probe7 
	// 	.probe8(tdata),   // input wire [511:0]  probe8 
    //     .probe9(wmst_req), // input wire [0:0] probe9
    //     .probe10(out_fifo_empty), // input wire[0:0] probe10
    //     .probe11(out_fifo_full) // input wire[0:0] probe11
	// );
endmodule