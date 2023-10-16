///==------------------------------------------------------------------==///
/// Conv kernel: top level module
///==------------------------------------------------------------------==///

`timescale 1ns / 1ps

module CONV_ACC #(
    parameter out_data_width = 25,
    parameter buf_addr_width = 5,


    parameter K = 3,
    parameter T = 16,
    parameter R = 5,
    parameter S = 1,
    parameter P = 1,

    parameter IFM_WIDTH = 8*(K-1+R),
    parameter WGT_WIDTH = 8*K
) (
    input clk,
    input rst_n,
    input start_conv,
    input [31:0] cfg_ci,
    input [31:0] cfg_co,
    input [31:0] tile_num,
    input [IFM_WIDTH-1:0] ifm,
    input [WGT_WIDTH-1:0] weight,
    output [24:0] ofm_port0,
    output [24:0] ofm_port1,
    output ofm_port0_v,
    output ofm_port1_v,
    output ifm_read,
    output wgt_read,
    output end_op,

    input stall
);


    /// Assign ifm and wgt to each pes
    parameter NUM_INPUT = R + K - 1;
    parameter buf_depth = T;
    wire [7:0] rows[0:NUM_INPUT-1];
    wire [7:0] wgts[0:K-1];

    genvar i, j;

    generate

        for (i = 0; i < NUM_INPUT; i = i + 1) begin
            assign rows[i] = ifm[i*8+:8];
        end

        for (i = 0; i < K; i = i + 1) begin
            assign wgts[i] = weight[i*8+:8];
        end
    endgenerate

    ///==-------------------------------------------------------------------------------------==
    /// Connect between PE and PE_FSM
    wire ifm_read_en;
    wire wgt_read_en;
    assign ifm_read = ifm_read_en;
    assign wgt_read = wgt_read_en;
    /// Connection between PEs+PE_FSM and WRITEBACK+BUFF
    wire [out_data_width-1:0] pe_data[0:K-1][0:R-1];

    wire p_filter_end, p_valid_data, start_again;
    /// PE FSM
    PE_FSM pe_fsm (
        .clk(clk),
        .stall(stall),
        .rst_n(rst_n),
        .start_conv(start_conv),
        .start_again(start_again),
        .cfg_ci(cfg_ci),
        .cfg_co(cfg_co),
        .tile_num(tile_num),
        .ifm_read(ifm_read_en),
        .wgt_read(wgt_read_en),
        .p_valid_output(p_valid_data),
        .last_chanel_output(p_filter_end),
        .end_conv(end_conv)
    );

    /// PE Array
    /// wgt0 row0 pe00 pe01 pe02 pe03 pe04
    /// wgt1 row1 pe10 pe11 pe12 pe13 pe14
    /// wgt2 row2 pe20 pe21 pe22 pe23 pe24
    /// wgt3      pe30 pe31 pe32 pe33 pe34
    ///      row3      row4 row5 row6 row7

    wire [7:0] ifm_buf[0:NUM_INPUT-1][0:K-1];
    wire [7:0] wgt_buf[0:K-1][0:K-1];

    generate
        for (i = 0; i < NUM_INPUT; i = i + 1) begin : IFM_XFER
            IFM_BUF ifm_buf (
                .clk(clk),
                .stall(stall),
                .rst_n(rst_n),
                .ifm_input(rows[i]),
                .ifm_read(ifm_read_en),
                .ifm_buf0(ifm_buf[i][0]),
                .ifm_buf1(ifm_buf[i][1]),
                .ifm_buf2(ifm_buf[i][2])
            );
        end

        for (i = 0; i < K; i = i + 1) begin : WGT_XFER
            WGT_BUF wgt_buf (
                .clk(clk),
                .stall(stall),
                .rst_n(rst_n),
                .wgt_input(wgts[i]),
                .wgt_read(wgt_read_en),
                .wgt_buf0(wgt_buf[i][0]),
                .wgt_buf1(wgt_buf[i][1]),
                .wgt_buf2(wgt_buf[i][2])
            );
        end
    endgenerate

    generate
        for (i = 0; i < K; i = i + 1) begin : PE_COL
            for (j = 0; j < R; j = j + 1) begin : PE_ROW
                PE pe (
                    .clk(clk),
                    .stall(stall),
                    .rst_n(rst_n),
                    .ifm_input0(ifm_buf[i+j][0]),
                    .ifm_input1(ifm_buf[i+j][1]),
                    .ifm_input2(ifm_buf[i+j][2]),
                    .wgt_input0(wgt_buf[i][0]),
                    .wgt_input1(wgt_buf[i][1]),
                    .wgt_input2(wgt_buf[i][2]),
                    .p_sum(pe_data[i][j])
                );
            end
        end
    endgenerate

    ///==-------------------------------------------------------------------------------------==
    /// Connection between the buffer and write back controllers
    wire [out_data_width-1:0] fifo_out[0:R-1];
    wire valid_fifo_out[0:R-1];
    wire p_write_zero[0:R-1];
    wire p_init;
    wire odd_cnt;

    /// Write back controller
    WRITE_BACK #(
        .data_width(out_data_width),
        .depth(T)
    ) writeback_control (
        .clk(clk),
        .stall(stall),
        .rst_n(rst_n),
        .start_init(start_conv),
        .p_filter_end(p_filter_end),
        .row0(fifo_out[0]),
        .row0_valid(valid_fifo_out[0]),
        .row1(fifo_out[1]),
        .row1_valid(valid_fifo_out[1]),
        .row2(fifo_out[2]),
        .row2_valid(valid_fifo_out[2]),
        .row3(fifo_out[3]),
        .row3_valid(valid_fifo_out[3]),
        .row4(fifo_out[4]),
        .row4_valid(valid_fifo_out[4]),
        .p_write_zero0(p_write_zero[0]),
        .p_write_zero1(p_write_zero[1]),
        .p_write_zero2(p_write_zero[2]),
        .p_write_zero3(p_write_zero[3]),
        .p_write_zero4(p_write_zero[4]),
        .p_init(p_init),
        .out_port0(ofm_port0),
        .out_port1(ofm_port1),
        .port0_valid(ofm_port0_v),
        .port1_valid(ofm_port1_v),
        .start_conv(start_again),
        .odd_cnt(odd_cnt),

        .end_conv(end_conv),
        .end_op  (end_op)
    );

    /// Buffer
    generate
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
                .p_write_zero(p_write_zero[i]),
                .p_init(p_init),
                .odd_cnt(odd_cnt),
                .pe0_data(pe_data[0][i]),
                .pe1_data(pe_data[1][i]),
                .pe2_data(pe_data[2][i]),
                .fifo_out(fifo_out[i]),
                .valid_fifo_out(valid_fifo_out[i])
            );

        end
    endgenerate

endmodule  //CONV_ACC
