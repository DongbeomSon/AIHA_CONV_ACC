module wgt_parser #(
    parameter INPUT_WIDTH = 512,
    parameter OUTPUT_WIDTH = 24,
	parameter REG_NUM = 3,
	parameter COMMON_DEN = INPUT_WIDTH * REG_NUM,
    parameter MAX_CNT = COMMON_DEN / OUTPUT_WIDTH


)(
    input clk,
    input rst_n,
	input start_conv_pulse,
    input [INPUT_WIDTH-1:0] fm,
    input ifm_read,
//    input init_word, //first hand_shake of axis after conv_start assert

    output [OUTPUT_WIDTH-1:0] parse_out,
    output reg input_req
);
    reg [2:0] reg_cnt;
	reg [5:0] fm_cnt;
	
	reg [COMMON_DEN-1:0]   reg_fm;
    reg [OUTPUT_WIDTH-1:0] r_parse_out;
	
	reg  [INPUT_WIDTH-1:0] temp_fm;
	wire [OUTPUT_WIDTH-1:0] fm_array [MAX_CNT-1:0];


    always @(*) begin
		r_parse_out <= fm_array[fm_cnt];
    end
	
	genvar i;
    generate
        for(i = 0; i < MAX_CNT; i=i+1) begin
            assign fm_array[i] = reg_fm[OUTPUT_WIDTH*(i+1)-1:OUTPUT_WIDTH*i];
        end
    endgenerate

    assign parse_out = r_parse_out;

	always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            input_req <= 0;
            fm_cnt <= 0;
        end else begin
            if (ifm_read) begin
				if(fm_cnt == MAX_CNT - 4) input_req <= 1;
                fm_cnt <= (fm_cnt == MAX_CNT-1) ? 0 : fm_cnt + 1;
            end
			if (start_conv_pulse) input_req<=1;
        end
    end
	
	
	always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            reg_cnt <= 0;
            reg_fm <= 0;
			temp_fm <= 0;
	    end else begin
			if(input_req) begin
				case(reg_cnt)
					0: begin reg_fm[INPUT_WIDTH*1-1:INPUT_WIDTH*0] <= fm; 
							 reg_fm[COMMON_DEN-1:INPUT_WIDTH*1] <= reg_fm[COMMON_DEN-1:INPUT_WIDTH*1];
							 reg_cnt <= reg_cnt+1; input_req<=1; end
					1: begin reg_fm[INPUT_WIDTH*1-1:0] <= reg_fm[INPUT_WIDTH*1-1:0];
							 reg_fm[INPUT_WIDTH*2-1:INPUT_WIDTH*1] <= fm; 
							 reg_fm[COMMON_DEN-1:INPUT_WIDTH*2] <= reg_fm[COMMON_DEN-1:INPUT_WIDTH*2];
					         reg_cnt <= reg_cnt+1; input_req<=1; end
					2: begin reg_fm <= reg_fm;
							 reg_cnt <= 3; input_req<=0; 
							 temp_fm <= fm;end
					default: begin reg_cnt<=0; reg_fm<=0; input_req<=0; end
				endcase
			end
			else if(reg_cnt==3&&ifm_read) begin 
					reg_fm <= reg_fm;
					reg_cnt <=4;
					temp_fm <= temp_fm;
			end
			else if(reg_cnt==4&&ifm_read&&(fm_cnt<20||fm_cnt==31)) begin 
					reg_fm[INPUT_WIDTH*2-1:0] <= reg_fm[INPUT_WIDTH*2-1:0];
					reg_fm[INPUT_WIDTH*3-1:INPUT_WIDTH*2] <= temp_fm; 
					reg_cnt <= 0; 
			end
				
			else begin	
				 reg_fm <= reg_fm; reg_cnt <= reg_cnt; temp_fm<=temp_fm;
			end
		end
	end
	
	
endmodule