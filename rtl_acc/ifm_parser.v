module ifm_parser #(
    parameter INPUT_WIDTH = 512,
    parameter OUTPUT_WIDTH = 80,
	parameter REG_NUM = 5,
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
    output reg input_req,

	input end_conv
);
    reg [2:0] reg_cnt;
	reg [6:0] fm_cnt;
	
	reg [COMMON_DEN-1:0]   reg_fm;
    reg [OUTPUT_WIDTH-1:0] r_parse_out;
	reg [INPUT_WIDTH-1:0] reg_file [0:REG_NUM-1];

	always @(*) begin
		reg_file[reg_cnt] <= fm;
	end
	
	wire [OUTPUT_WIDTH-1:0] fm_array [MAX_CNT-1:0];

	genvar i;
    generate
        for(i = 0; i < MAX_CNT; i=i+1) begin
            assign fm_array[i] = reg_fm[OUTPUT_WIDTH*(i+1)-1:OUTPUT_WIDTH*i];
        end
    endgenerate

    always @(*) begin
		r_parse_out <= fm_array[fm_cnt];
    end

	wire [INPUT_WIDTH-1:0] r_file [0:REG_NUM-1];

    generate
        for(i = 0; i < REG_NUM; i=i+1) begin
            assign r_file[i] = reg_fm[INPUT_WIDTH*(i+1)-1:INPUT_WIDTH*i];
        end
    endgenerate

    always @(*) begin
		r_parse_out <= fm_array[fm_cnt];
    end

    assign parse_out = r_parse_out;

	reg [INPUT_WIDTH-1:0] last_reg_file;
	reg fm_used_n;
	always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            input_req <= 0;
            fm_cnt <= 0;
        end else begin
            if (ifm_read) begin
//				input_req <= (fm_cnt > MAX_CNT - 1 - REG_NUM) ? 1 : 0;
				input_req <= (fm_cnt > MAX_CNT - 1 - REG_NUM) & !fm_used_n ? 1 : 0;
                fm_cnt <= (fm_cnt == MAX_CNT-1) ? 0 : fm_cnt + 1;
			end else if (input_req) begin
				input_req <= (reg_cnt == REG_NUM-1) ? 0 : 1;
			end
			if (start_conv_pulse) input_req<=1;
        end
    end
	
	
	
	always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            reg_cnt <= 0;
            reg_fm <= 0;
			last_reg_file <= 0;
			fm_used_n <= 0;
			input_req <= 0;
			fm_cnt <= 0;
	    end else begin
			if(start_conv_pulse) input_req <= 1;
			else begin
				case({input_req, ifm_read})
					2'b01:
						begin
							fm_cnt <= (fm_cnt == MAX_CNT-1) ? 0 : fm_cnt + 1;
							input_req <= (fm_cnt == MAX_CNT - 1 - REG_NUM) ? 1 : 0;
							reg_fm[INPUT_WIDTH*(REG_NUM-1)+:INPUT_WIDTH] <= (fm_cnt == MAX_CNT-1) | (fm_cnt == 0) ? 
																			((reg_cnt==REG_NUM-1) ? fm : last_reg_file) : reg_fm[INPUT_WIDTH*(REG_NUM-1)+:INPUT_WIDTH];							
						end
					2'b11:
						begin
							input_req <= (reg_cnt == REG_NUM-1) ? 0 : 1;
							reg_cnt <= (reg_cnt == REG_NUM-1) ? 0 : reg_cnt + 1;
							last_reg_file <= (reg_cnt == REG_NUM-1) ? fm : last_reg_file;
							if(reg_cnt < REG_NUM-1) reg_fm[INPUT_WIDTH*reg_cnt+:INPUT_WIDTH] <= fm;
							reg_fm[INPUT_WIDTH*(REG_NUM-1)+:INPUT_WIDTH] <= (fm_cnt == MAX_CNT-1) | (fm_cnt == 0) ? 
																			((reg_cnt==REG_NUM-1) ? fm : last_reg_file) : reg_fm[INPUT_WIDTH*(REG_NUM-1)+:INPUT_WIDTH];
						end
					2'b10:
						begin
							input_req <= (reg_cnt == REG_NUM-1) ? 0 : 1;
							reg_cnt <= (reg_cnt == REG_NUM-1) ? 0 : reg_cnt + 1;
							if(reg_cnt < REG_NUM-1) reg_fm[INPUT_WIDTH*reg_cnt+:INPUT_WIDTH] <= fm;
							last_reg_file <= (reg_cnt == REG_NUM-1) ? fm : last_reg_file;
						end
					default:
						begin
							reg_cnt <= reg_cnt;
							reg_fm <= reg_fm;
							last_reg_file <= last_reg_file;
							fm_cnt <= fm_cnt;
						end
				endcase
			end
			// if(input_req) begin
			// 	if(reg_cnt == REG_NUM - 2) begin
			// 		fm_used_n <= 1;
			// 	end
			// 	if(reg_cnt == REG_NUM - 1) begin
			// 		reg_cnt <= 0;
			// 		last_reg_file <= fm;
			// 	end else begin
			// 		reg_fm[INPUT_WIDTH*reg_cnt+:INPUT_WIDTH] <= fm;
			// 		reg_cnt <= reg_cnt + 1;
			// 	end
			// end
			// if (ifm_read) begin
			// 	if(fm_cnt == 1) begin
			// 		reg_fm[INPUT_WIDTH*(REG_NUM-1)+:INPUT_WIDTH] <= last_reg_file;
			// 		fm_used_n <= 0;
			// 	end
			// end
			// end else begin
			// 	 reg_fm <= reg_fm; reg_cnt <= reg_cnt;
			// end
		end
	end
	
	
endmodule