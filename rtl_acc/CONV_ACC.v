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

    parameter NUM_WGT = K * S,

    parameter IFM_WIDTH = 8 * (K - 1 + R),
    parameter WGT_WIDTH = 8 * NUM_WGT,
    parameter OUT_WIDTH = out_data_width * S
) (
    input clk,
    input rst_n,
    input start_conv,
    input [31:0] cfg_ci,
    input [31:0] cfg_co,
    input [31:0] tile_num,
    input [IFM_WIDTH-1:0] ifm,
    input [WGT_WIDTH-1:0] weight,

    // output reg [OUT_WIDTH-1:0] out_ofm_port0,
    // output reg [OUT_WIDTH-1:0] out_ofm_port1,
    // output reg [OUT_WIDTH-1:0] out_ofm_port2,
    // output reg [OUT_WIDTH-1:0] out_ofm_port3,

    output [OUT_WIDTH-1:0] ofm_port,


    // output reg out_ofm_port_v0,
    // output reg out_ofm_port_v1,
    // output reg out_ofm_port_v2,
    // output reg out_ofm_port_v3,

    output ofm_port_v,

    output ifm_read,
    output wgt_read,
    output end_op,

    input stall
);


    /// Assign ifm and wgt to each pes
    parameter NUM_INPUT = R + K - 1;
    parameter buf_depth = T;
    wire [7:0] rows[0:NUM_INPUT-1];
    wire [7:0] wgts[0:S-1][0:K-1];

    genvar i, j, k;

    generate
        for (i = 0; i < NUM_INPUT; i = i + 1) begin
            assign rows[i] = ifm[i*8+:8];
        end
        for (j = 0; j < S; j = j + 1) begin
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
    wire [out_data_width-1:0] pe_data[0:S-1][0:R-1][0:K-1];
    wire p_filter_end, p_valid_data;
    wire start_again;
    /// PE FSM
    PE_FSM #(
        .K(K),
        .T(T),
        .S(S)
    ) pe_fsm (
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


    wire [7:0] ifm_buf0[0:NUM_INPUT-1];
    wire [7:0] ifm_buf1[0:NUM_INPUT-1];
    wire [7:0] ifm_buf2[0:NUM_INPUT-1];

    wire [7:0] wgt_buf0[0:S-1][0:K-1];
    wire [7:0] wgt_buf1[0:S-1][0:K-1];
    wire [7:0] wgt_buf2[0:S-1][0:K-1];

    generate
        for (i = 0; i < NUM_INPUT; i = i + 1) begin : IFM_XFER
            IFM_BUF ifm_buf (
                .clk(clk),
                .stall(stall),
                .rst_n(rst_n),
                .ifm_input(rows[i]),
                .ifm_read(ifm_read_en),
                .ifm_buf0(ifm_buf0[i]),
                .ifm_buf1(ifm_buf1[i]),
                .ifm_buf2(ifm_buf2[i])
            );
        end

        for (j = 0; j < S; j = j + 1) begin : WGT_XFER
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
        for (k = 0; k < S; k = k + 1) begin : PE_SET
            for (i = 0; i < K; i = i + 1) begin : PE_KERNEL
                for (j = 0; j < R; j = j + 1) begin : PE_ROW
                    PE pe (
                        .clk(clk),
                        .stall(stall),
                        .rst_n(rst_n),
                        .ifm_input0(ifm_buf0[i+j]),
                        .ifm_input1(ifm_buf1[i+j]),
                        .ifm_input2(ifm_buf2[i+j]),
                        .wgt_input0(wgt_buf0[k][i]),
                        .wgt_input1(wgt_buf1[k][i]),
                        .wgt_input2(wgt_buf2[k][i]),
                        .p_sum(pe_data[k][j][i])
                    );
                end
            end
        end
    endgenerate

    ///==-------------------------------------------------------------------------------------==
    /// Connection between the buffer and write back controllers
    wire [out_data_width-1:0] fifo_out[0:S-1][0:R-1];
    wire [R-1:0]valid_fifo_out[0:S-1];
    wire [R-1:0]p_write_zero[0:S-1];
    wire p_init;

    wire set_odd_cnt[0:S-1];
    wire odd_cnt = set_odd_cnt[0];

    wire [out_data_width*R-1:0] set_fifo_out[0:S-1];
    wire [R-1:0] set_fifo_out_valid[0:S-1];
    wire [R-1:0] set_p_write_zero[0:S-1];

    wire set_start_again[0:S-1];
    assign start_again = set_start_again[0];

    wire [out_data_width*R-1:0] set_ofm_port[0:S-1];
    wire [out_data_width-1:0] set_ofm_single_row[0:S-1];
    wire set_ofm_port_v[0:S-1];
    wire set_end_op[0:S-1];

    wire set_end_conv[0:S-1];
    // assign end_conv = set_end_conv[0];

    assign ofm_port_v = set_ofm_port_v[0];
    assign end_op = set_end_op[0];

    generate
        for(i=0; i < S; i=i+1) begin : ASSIGN_SET_OUT
            for(j=0; j < R; j=j+1) begin
                assign set_fifo_out[i][32*j +: 32] = fifo_out[i][j];
            end
            // assign set_fifo_out_valid[i][j] = valid_fifo_out[i][j];
            assign set_fifo_out_valid[i] = valid_fifo_out[i];
            //assign set_p_write_zero[i] = p_write_zero[i][0];
        end

        for(i=0; i < S; i=i+1) begin : ASSIGN_OFM_PORT
            assign ofm_port[out_data_width*i +: out_data_width] = set_ofm_single_row[i];
        end
    endgenerate

    /// Write back controller
    generate
        for (i = 0; i < S; i = i+1) begin : WB_GEN
            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(T),
                .R(R),
                .S(S)
            ) writeback_control (
                .clk(clk),
                .stall(stall),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row_valid(set_fifo_out_valid[i]),
                .row(set_fifo_out[i]),
                .p_write_zero(set_p_write_zero[i]),
                .p_init(p_init),
                .out_port(set_ofm_single_row[i]),
                .port_valid(set_ofm_port_v[i]),
                .start_conv(set_start_again[i]),
                .odd_cnt(set_odd_cnt[i]),

                .end_conv(end_conv),
                .end_op  (set_end_op[i])
            );
        end
    endgenerate

    /// Buffer
    generate
        for (j = 0; j < S; j = j + 1) begin : PSUM_SET
            for (i = 0; i < R; i = i + 1) begin : PSUM_XFER
                PSUM_BUFF #(
                    .data_width(out_data_width),
                    .addr_width(buf_addr_width),
                    .depth(T)
                ) psum_buff (
                    .clk(clk),
                    .stall(stall),
                    .rst_n(rst_n),
                    .p_valid_data(p_valid_data),
                    .p_write_zero(set_p_write_zero[j][i]),
                    .p_init(p_init),
                    .odd_cnt(odd_cnt),
                    .pe0_data(pe_data[j][i][0]),
                    .pe1_data(pe_data[j][i][1]),
                    .pe2_data(pe_data[j][i][2]),
                    .fifo_out(fifo_out[j][i]),
                    .valid_fifo_out(valid_fifo_out[j][i])
                );

            end
        end
    endgenerate

endmodule  //CONV_ACC
