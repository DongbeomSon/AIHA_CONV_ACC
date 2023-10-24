module wgt_resizebuffer #(
    parameter INPUT_WIDTH = 512,
    parameter OUTPUT_WIDTH = 1536,
	parameter REG_NUM = 3

)(
    input clk,
    input rst_n,
	input wgt_read,
    input [INPUT_WIDTH-1:0] fm,
	input g_stall,
	input valid_input,
	input op_start,
	input end_conv,
//    input init_word, //first hand_shake of axis after conv_start assert

    output [OUTPUT_WIDTH-1:0] parse_out,
    output reg input_req,
	output stall
);

	reg[2:0] reg_cnt;
	reg push_buff_r;
	reg[OUTPUT_WIDTH-1:0] reg_fm;
	reg r_op_start;

	wire in_fifo0_push_req;
	wire in_fifo0_pop_req;
	wire [OUTPUT_WIDTH-1:0] in_fifo0_push_data;
	wire [OUTPUT_WIDTH-1:0] in_fifo0_pop_data;
	wire in_fifo0_empty;
	wire in_fifo0_full;
	wire[10:0] in_fifo0_data_cnt;

	always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
           input_req <= 0;
		   r_op_start <= 0; end
        else if(op_start) begin
		    input_req <= 1;
			r_op_start <=1; end
		else if(end_conv) begin 
		   input_req <= 0;
		   r_op_start <= 0; end
		else if(in_fifo0_full) input_req <= 0;
		else if(r_op_start) input_req <=1;
		else r_op_start <= r_op_start;
	end
	
	always @(posedge clk, negedge rst_n) begin
        if(!rst_n)
           reg_cnt <= 0;
		else if(valid_input) begin
			if(input_req) begin
				if(reg_cnt==2) reg_cnt <= 0;
				else reg_cnt <= reg_cnt + 1;
			end
			else reg_cnt <= reg_cnt;
		end
	end	


	always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
        	reg_fm <= 0;
			push_buff_r <= 0;
		end
		else if(valid_input) begin
			if(input_req) begin
			if(reg_cnt == 0) begin
				reg_fm[1535:512] <= 0;
				reg_fm[511:0] <= fm;
				push_buff_r <= 0;
			end
			else if(reg_cnt==1) begin
				reg_fm[511:0] <= reg_fm[511:0];
				reg_fm[1023:512] <= fm;
				reg_fm[1535:1024] <= 0;
				push_buff_r <= 0;
			end
			else if(reg_cnt==2) begin
				reg_fm[1023:0] <= reg_fm[1023:0];
				reg_fm[1535:1024] <= fm;
				push_buff_r <= 1;
			end
			end
		end
		else push_buff_r <= 0;
	end	




	assign stall = in_fifo0_data_cnt <1;
	assign parse_out = in_fifo0_pop_data;
	assign in_fifo0_pop_req = !g_stall & wgt_read;

	assign in_fifo0_push_req = push_buff_r;
	assign in_fifo0_push_data = reg_fm;

	FifoType0 #(.data_width (OUTPUT_WIDTH), .addr_bits (10)) fifo_0 (
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
	
endmodule