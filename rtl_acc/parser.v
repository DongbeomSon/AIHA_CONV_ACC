module parser #(
    parameter INPUT_WIDTH = 512,
    parameter OUTPUT_WIDTH = 64,
    parameter MAX_CNT = INPUT_WIDTH/OUTPUT_WIDTH
)(
    input clk,
    input rst_n,

    input [INPUT_WIDTH-1:0] fm,
    input ifm_read,
//    input init_word, //first hand_shake of axis after conv_start assert

    output [OUTPUT_WIDTH-1:0] parse_out,
    output reg input_req,


    input stall
);
    reg [5:0] cnt;

    reg [OUTPUT_WIDTH-1:0] r_parse [MAX_CNT-1:0];
    reg [OUTPUT_WIDTH-1:0] r_parse_out;

    integer i;
    always @(*) begin
        for(i = 0; i < MAX_CNT; i=i+1) begin
            r_parse[i] <= fm[i*OUTPUT_WIDTH +: OUTPUT_WIDTH];
        end
    end

    always @(*) begin
        r_parse_out <= r_parse[cnt];
    end

    assign parse_out = r_parse_out;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            input_req <= 0;
//            r_parse_out <= 0;
            cnt <= 0;
        end else begin
            if (ifm_read & !stall) begin
                input_req <= (cnt == MAX_CNT - 2) ? 1 : 0;
                cnt <= (cnt == MAX_CNT-1) ? 0 : cnt + 1;
            end
        end
    end

endmodule