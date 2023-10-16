module new_parser #(
    parameter INPUT_WIDTH  = 512,
    parameter OUTPUT_WIDTH = 56
) (
    input clk,
    input rst_n,

    input [INPUT_WIDTH-1:0] fm,
    input ifm_read,
    //    input init_word, //first hand_shake of axis after conv_start assert

    output [OUTPUT_WIDTH-1:0] parse_out,
    output input_req,


    input stall
);
    reg [5:0] cnt;
    //ceil = (A+B-1)/B
    //$ceil(INPUT_WIDTH/OUTPUT_WIDTH) = (INPUT_WIDTH+OUTPUT_WIDTH-1)/OUTPUT_WIDTH
    parameter integer EXTEND_WIDTH = (INPUT_WIDTH+OUTPUT_WIDTH-1)/OUTPUT_WIDTH*OUTPUT_WIDTH;

    parameter integer MAX_CNT = (INPUT_WIDTH + OUTPUT_WIDTH - 1) / OUTPUT_WIDTH;

    parameter integer APPEND = EXTEND_WIDTH - INPUT_WIDTH;
    parameter integer REQ_BYTE = OUTPUT_WIDTH / 8;
    parameter integer REMAIN_BYTE = 64 % REQ_BYTE;
    parameter integer MUX_LEN = 2 * REQ_BYTE;

    wire [EXTEND_WIDTH-1:0] append_fm = {{APPEND{1'b0}}, fm};

    reg [OUTPUT_WIDTH-1:0] A, B;
    reg [OUTPUT_WIDTH-1:0] reg_B;
    reg cross_flag;
    reg [OUTPUT_WIDTH-1:0] r_parse[MAX_CNT-1:0];
    reg [OUTPUT_WIDTH-1:0] r_parse_out;

    reg [MUX_LEN-1:0] mux_sel;

    wire [REQ_BYTE-1:0] mux_a, mux_b;
    // assign mux_a = mux_sel [0:REQ_BYTE-1];
    assign mux_b = mux_sel[MUX_LEN-1:REQ_BYTE];

    integer i;
    always @(*) begin
        for (i = 0; i < MAX_CNT; i = i + 1) begin
            r_parse[i] <= append_fm[i*OUTPUT_WIDTH+:OUTPUT_WIDTH];
        end
    end

    always @(*) begin
        A <= r_parse[cnt];
        B <= r_parse[cnt+1];
    end
    reg [5:0] shift_cnt;
    wire [OUTPUT_WIDTH-1:0] temp_A = cross_flag ? reg_B : A;
    wire [OUTPUT_WIDTH-1:0] shitfed_B = B << shift_cnt * 8;


    wire [2*OUTPUT_WIDTH-1:0] shitfed_A = A << shift_cnt * 8;
    wire [OUTPUT_WIDTH-1:0] prev = shitfed_A[2*OUTPUT_WIDTH-1:OUTPUT_WIDTH];
    wire [OUTPUT_WIDTH-1:0] next = shitfed_B;
    wire [OUTPUT_WIDTH-1:0] prefix = prev | next;
    reg [OUTPUT_WIDTH-1:0] r_prefix;
    // always @(*) begin
    //     // r_parse_out <= r_parse[cnt];
    // end
    // assign parse_out = r_parse_out;

    genvar j;

    generate
        for (j = 0; j < REQ_BYTE; j = j + 1) begin
            assign parse_out[j*8 +: 8] = !mux_b[j] ? shitfed_A[j*8 +: 8] : r_prefix[j*8 +: 8];
        end
    endgenerate

    reg r_input_req;
    assign input_req = r_input_req & ifm_read;
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            r_input_req <= 0;
            cnt <= 0;
            reg_B <= 0;
            mux_sel <= {{REQ_BYTE{1'b0}}, {REQ_BYTE{1'b1}}};
            shift_cnt <= 0;
            r_prefix <= 0;
        end else begin
            if (ifm_read & !stall) begin
                reg_B <= shitfed_B;
                r_prefix <= prefix;

                if (shift_cnt + REMAIN_BYTE == REQ_BYTE) begin

                    if (cnt == MAX_CNT - 2) begin
                        r_input_req <= 1;
                    end else begin
                        r_input_req <= 0;
                    end
                    if (cnt == MAX_CNT - 1) begin
                        cnt <= 0;
                        mux_sel <= (mux_sel << (REQ_BYTE+REMAIN_BYTE)) | (mux_sel >> (MUX_LEN-(REQ_BYTE+REMAIN_BYTE)));
                        //mux_sel <= {{REQ_BYTE{1'b0}}, {REQ_BYTE{1'b1}}};
                        shift_cnt <= shift_cnt + REMAIN_BYTE >= REQ_BYTE ? shift_cnt + REMAIN_BYTE - REQ_BYTE : shift_cnt + REMAIN_BYTE;
                    end else begin
                        cnt <= cnt + 1;
                    end

                end else begin
                    if (cnt == MAX_CNT - 3) begin
                        r_input_req <= 1;
                    end else begin
                        r_input_req <= 0;
                    end
                    if (cnt == MAX_CNT - 2) begin
                        cnt <= 0;
                        mux_sel <= (mux_sel << REMAIN_BYTE) | (mux_sel >> (MUX_LEN-REMAIN_BYTE));
                        shift_cnt <= shift_cnt + REMAIN_BYTE >= REQ_BYTE ? shift_cnt + REMAIN_BYTE - REQ_BYTE : shift_cnt + REMAIN_BYTE;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end
            end
        end
    end

endmodule
