module parser #(
    parameter INPUT_WIDTH = 512,
    parameter OUTPUT_WIDTH = 64,
    parameter MAX_CNT = INPUT_WIDTH/OUTPUT_WIDTH
)(
    input clk,
    input rst_n,

    input [INPUT_WIDTH-1:0] fm,
    input ifm_read,
    input init_word, //first hand_shake of axis after conv_start assert

    output [OUTPUT_WIDTH-1:0] parse_out,
    output reg input_req
);
    reg [5:0] cnt;

    reg [OUTPUT_WIDTH-1:0] r_parse [MAX_CNT-1:0];
    reg [OUTPUT_WIDTH-1:0] r_parse_out;
    reg [INPUT_WIDTH-1:0] r_fm;

    integer i;
    always @(*) begin
        for(i = 0; i < MAX_CNT; i=i+1) begin
            r_parse[i] <= r_fm[i*OUTPUT_WIDTH +: OUTPUT_WIDTH];
        end
    end


    reg r_input_req;
    assign parse_out = r_parse_out;
    reg r_init_word;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            input_req <= 0;
            r_parse_out <= 0;
            r_input_req <= 0;
            cnt <= 0;
            r_init_word <= 0;
        end else begin
            r_parse_out <= r_parse[cnt];
            if(init_word) begin
                input_req <= 1;
                r_init_word <= 1;
            end else if (ifm_read) begin
                input_req <= (cnt == MAX_CNT-2) ? 1 : 0;
                cnt <= (cnt == MAX_CNT-1) ? 0 : cnt + 1;
                r_input_req <= r_input_req ? 0 : input_req;
                r_fm <= r_input_req ? fm : r_fm;
            end else if(r_init_word) begin
                input_req <= 0;
                r_fm <= fm;
            end
        end
    end

endmodule