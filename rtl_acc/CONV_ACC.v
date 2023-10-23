///==------------------------------------------------------------------==///
/// Conv kernel: top level module
///==------------------------------------------------------------------==///

`timescale 1ns / 1ps

module CONV_ACC #(
    parameter out_data_width = 32,
    parameter buf_addr_width = 5,


    parameter K = 3,
    parameter T = 14,
    parameter R = 14,
    parameter S = 64,
    parameter P = 1,
    parameter NUM_WGT = K*S*P,

    parameter IFM_WIDTH = 8*(K-1+R)*P,
    parameter WGT_WIDTH = 8*NUM_WGT,
    parameter OUT_WIDTH = out_data_width * 16
) (
    input clk,
    input rst_n,
    input start_conv,
    input [31:0] cfg_ci,
    input [31:0] cfg_co,
    input [31:0] tile_num,

    input [IFM_WIDTH-1:0] ifm,
    input [WGT_WIDTH-1:0] weight,

    output reg [OUT_WIDTH-1:0] out_ofm_port0,
    output reg [OUT_WIDTH-1:0] out_ofm_port1,
    output reg [OUT_WIDTH-1:0] out_ofm_port2,
    output reg [OUT_WIDTH-1:0] out_ofm_port3,


    output reg out_ofm_port_v0,
    output reg out_ofm_port_v1,
    output reg out_ofm_port_v2,
    output reg out_ofm_port_v3,


    output ifm_read,
    output wgt_read,
    output end_op,

    input stall
);


    /// Assign ifm and wgt to each pes
    parameter NUM_INPUT = (R + K - 1);
    parameter buf_depth = T;
    wire [7:0] rows[0:P-1][0:NUM_INPUT-1];
    wire [7:0] wgts[0:S*P-1][0:K-1];

    genvar i, j, k;

    generate
        for(j = 0; j < P; j = j + 1) begin
            for (i = 0; i < NUM_INPUT; i = i + 1) begin
                assign rows[j][i] = ifm[i*8+:8];
            end
        end
        for(j = 0; j < S * P; j = j + 1) begin
            for (i = 0; i < K; i = i + 1) begin
                assign wgts[j][i] = weight[(24*j)+(i*8)+:8];
            end
        end
    endgenerate

    ///==-------------------------------------------------------------------------------------==
    /// Connect between PE and PE_FSM
    wire ifm_read_en;
    wire wgt_read_en;
    assign ifm_read = ifm_read_en;
    assign wgt_read = wgt_read_en;
    /// Connection between PEs+PE_FSM and WRITEBACK+BUFF
    wire [out_data_width-1:0] pe_data[0:S*P-1][0:R*K-1];
    wire p_filter_end, p_valid_data;
    wire start_again[0:S*P/16-1];
    /// PE FSM
    PE_FSM #(
        .K(K),
        .T(T),
        .S(S),
        .P(P)
    )pe_fsm (
        .clk(clk),
        .stall(stall),
        .rst_n(rst_n),
        .start_conv(start_conv),
        .start_again(start_again[0]),
        .cfg_ci(cfg_ci),
        .cfg_co(cfg_co),
        .tile_num(tile_num),
        .ifm_read(ifm_read_en),
        .wgt_read(wgt_read_en),
        .p_valid_output(p_valid_data),
        .last_chanel_output(p_filter_end),
        .end_conv(end_conv)
    );

    wire [7:0] ifm_buf0[0:P-1][0:NUM_INPUT-1];
    wire [7:0] ifm_buf1[0:P-1][0:NUM_INPUT-1];
    wire [7:0] ifm_buf2[0:P-1][0:NUM_INPUT-1];

    wire [7:0] wgt_buf0[0:S*P-1][0:K-1];
    wire [7:0] wgt_buf1[0:S*P-1][0:K-1];
    wire [7:0] wgt_buf2[0:S*P-1][0:K-1];

    generate
        for (j = 0; j < P; j = j + 1) begin : IFM_XFER
            for (i = 0; i < NUM_INPUT; i = i + 1) begin
                IFM_BUF ifm_buf (
                    .clk(clk),
                    .stall(stall),
                    .rst_n(rst_n),
                    .ifm_input(rows[j][i]),
                    .ifm_read(ifm_read_en),
                    .ifm_buf0(ifm_buf0[j][i]),
                    .ifm_buf1(ifm_buf1[j][i]),
                    .ifm_buf2(ifm_buf2[j][i])
                );
            end
        end

        for (j = 0; j < S * P; j = j + 1) begin : WGT_XFER
            for (i = 0; i < K; i = i + 1) begin
                WGT_BUF wgt_buf (
                    .clk(clk),
                    .stall(stall),
                    .rst_n(rst_n),
                    .wgt_input(wgts[j][i]),
                    .wgt_read(wgt_read_en),
                    .wgt_buf0(wgt_buf0[j][i]),
                    .wgt_buf1(wgt_buf1[j][i]),
                    .wgt_buf2(wgt_buf2[j][i])
                );
            end
        end
    endgenerate

    generate
        for(k = 0; k < S * P; k = k + 1) begin : PE_SET
            for (i = 0; i < K; i = i + 1) begin : PE_COL
                for (j = 0; j < R; j = j + 1) begin : PE_ROW
                    PE pe (
                        .clk(clk),
                        .stall(stall),
                        .rst_n(rst_n),
                        .ifm_input0(ifm_buf0[k/S][i+j]),
                        .ifm_input1(ifm_buf1[k/S][i+j]),
                        .ifm_input2(ifm_buf2[k/S][i+j]),
                        .wgt_input0(wgt_buf0[k][i]),
                        .wgt_input1(wgt_buf1[k][i]),
                        .wgt_input2(wgt_buf2[k][i]),
                        .p_sum(pe_data[k][R*i+j])
                    );
                end
            end
        end
    endgenerate

    ///==-------------------------------------------------------------------------------------==
    /// Connection between the buffer and write back controllers
    wire [out_data_width-1:0] fifo_out[0:S*P-1][0:R-1];
    wire valid_fifo_out[0:S*P-1][0:R-1];
    wire p_write_zero[0:S*P/16-1][0:R-1];
    wire p_init[0:S*P/16-1];
    wire odd_cnt[0:S*P/16-1];
    wire w_end_op[0:S*P/16-1];
    reg [out_data_width-1:0] row_fifo_out[0:S*P-1];
    reg row_fifo_valid[0: S*P-1];
    wire [OUT_WIDTH-1:0] ofm_port[0: S*P/16-1];
    wire ofm_port_v[0: S*P/16-1];
    assign end_op = w_end_op[0];

    assign out_ofm_port0 = ofm_port[0];
    assign out_ofm_port1 = ofm_port[1];
    assign out_ofm_port2 = ofm_port[2];
    assign out_ofm_port3 = ofm_port[3];

    assign out_ofm_port_v0 = ofm_port_v[0];
    assign out_ofm_port_v1 = ofm_port_v[1];
    assign out_ofm_port_v2 = ofm_port_v[2];
    assign out_ofm_port_v3 = ofm_port_v[3];

    generate
        for (j = 0; j < P * S; j = j + 1) begin
            always @(*) begin
                case({valid_fifo_out[j][0],valid_fifo_out[j][1],valid_fifo_out[j][2],valid_fifo_out[j][3],valid_fifo_out[j][4],
                    valid_fifo_out[j][5],valid_fifo_out[j][6],valid_fifo_out[j][7],valid_fifo_out[j][8],valid_fifo_out[j][9],
                    valid_fifo_out[j][10],valid_fifo_out[j][11],valid_fifo_out[j][12],valid_fifo_out[j][13]})
                    14'b10000000000000: begin
                        row_fifo_out[j] <= fifo_out[j][0];
                        row_fifo_valid[j] <= 1; end
                    14'b01000000000000: begin
                        row_fifo_out[j] <= fifo_out[j][1];
                        row_fifo_valid[j] <= 1; end
                    14'b00100000000000: begin
                        row_fifo_out[j] <= fifo_out[j][2];
                        row_fifo_valid[j] <= 1; end
                    14'b00010000000000: begin
                        row_fifo_out[j] <= fifo_out[j][3];
                        row_fifo_valid[j] <= 1; end
                    14'b00001000000000: begin
                        row_fifo_out[j] <= fifo_out[j][4];
                        row_fifo_valid[j] <= 1; end
                    14'b00000100000000: begin
                        row_fifo_out[j] <= fifo_out[j][5];
                        row_fifo_valid[j] <= 1; end
                    14'b00000010000000: begin
                        row_fifo_out[j] <= fifo_out[j][6];
                        row_fifo_valid[j] <= 1; end
                    14'b00000001000000: begin
                        row_fifo_out[j] <= fifo_out[j][7];
                        row_fifo_valid[j] <= 1; end
                    14'b00000000100000: begin
                        row_fifo_out[j] <= fifo_out[j][8];
                        row_fifo_valid[j] <= 1; end
                    14'b00000000010000: begin
                        row_fifo_out[j] <= fifo_out[j][9];
                        row_fifo_valid[j] <= 1; end
                    14'b00000000001000: begin
                        row_fifo_out[j] <= fifo_out[j][10];
                        row_fifo_valid[j] <= 1; end
                    14'b00000000000100: begin
                        row_fifo_out[j] <= fifo_out[j][11];
                        row_fifo_valid[j] <= 1; end
                    14'b00000000000010: begin
                        row_fifo_out[j] <= fifo_out[j][12];
                        row_fifo_valid[j] <= 1; end
                    14'b00000000000001: begin
                        row_fifo_out[j] <= fifo_out[j][13];
                        row_fifo_valid[j] <= 1; end
                    default: begin
                        row_fifo_out[j] <= 0;
                        row_fifo_valid[j] <= 0; end
                endcase
            end
        end
    endgenerate

    /// Write back controller
    generate   
        for (i = 0; i < S * P; i = i + 16) begin : WB_GEN
                WRITE_BACK #(
                    .data_width(out_data_width),
                    .depth(T)
                ) writeback_control (
                    .clk(clk),
                    .stall(stall),
                    .rst_n(rst_n),
                    .start_init(start_conv),
                    .p_filter_end(p_filter_end),
                    .row_valid(row_fifo_valid[i]),
                    .row0(row_fifo_out[i]),
                    .row1(row_fifo_out[i+1]),
                    .row2(row_fifo_out[i+2]),
                    .row3(row_fifo_out[i+3]),
                    .row4(row_fifo_out[i+4]),
                    .row5(row_fifo_out[i+5]),
                    .row6(row_fifo_out[i+6]),
                    .row7(row_fifo_out[i+7]),
                    .row8(row_fifo_out[i+8]),
                    .row9(row_fifo_out[i+9]),
                    .row10(row_fifo_out[i+10]),
                    .row11(row_fifo_out[i+11]),
                    .row12(row_fifo_out[i+12]),
                    .row13(row_fifo_out[i+13]),
                    .row14(row_fifo_out[i+14]),
                    .row15(row_fifo_out[i+15]),
                    .p_write_zero0(p_write_zero[i/16][0]),
                    .p_write_zero1(p_write_zero[i/16][1]),
                    .p_write_zero2(p_write_zero[i/16][2]),
                    .p_write_zero3(p_write_zero[i/16][3]),
                    .p_write_zero4(p_write_zero[i/16][4]),
                    .p_write_zero5(p_write_zero[i/16][5]),
                    .p_write_zero6(p_write_zero[i/16][6]),
                    .p_write_zero7(p_write_zero[i/16][7]),
                    .p_write_zero8(p_write_zero[i/16][8]),
                    .p_write_zero9(p_write_zero[i/16][9]),
                    .p_write_zero10(p_write_zero[i/16][10]),
                    .p_write_zero11(p_write_zero[i/16][11]),
                    .p_write_zero12(p_write_zero[i/16][12]),
                    .p_write_zero13(p_write_zero[i/16][13]),
                    .p_init(p_init[i/16]),
                    .out_port(ofm_port[i/16]),
                    .port_valid(ofm_port_v[i/16]),
                    .start_conv(start_again[i/16]),
                    .odd_cnt(odd_cnt[i/16]),

                    .end_conv(end_conv),
                    .end_op  (w_end_op[i/16])
                );
        end
    endgenerate

    /// Buffer
    generate
        for (j = 0; j < P * S ; j = j + 1) begin : PSUM_SET
            for (i = 0; i < R; i = i + 1) begin : PSUM_XFER
                PSUM_BUFF #(
                    .data_width(out_data_width),
                    .addr_width(buf_addr_width),
                    .depth(T)
                ) psum_buff0 (
                    .clk(clk),
                    .stall(stall),
                    .rst_n(rst_n),
                    .p_valid_data(p_valid_data),
                    .p_write_zero(p_write_zero[0][i]),
                    .p_init(p_init[0]),
                    .odd_cnt(odd_cnt[0]),
                    .pe0_data(pe_data[j][i]),
                    .pe1_data(pe_data[j][i+14]),
                    .pe2_data(pe_data[j][i+28]),
                    .fifo_out(fifo_out[j][i]),
                    .valid_fifo_out(valid_fifo_out[j][i])
                );

            end
        end
    endgenerate

endmodule  //CONV_ACC
