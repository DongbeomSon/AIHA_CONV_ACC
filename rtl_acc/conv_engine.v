//
//
//# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
//# SPDX-License-Identifier: X11
//
//

`timescale 1ns/1ps

module conv_engine #(
	parameter IFM_TILE_ROW = 16,
	parameter KERNEL_SIZE = 3,
    parameter WIFM_DATA_WIDTH = 512,
    parameter WWGT_DATA_WIDTH = 512,
	parameter IFM_DATA_WIDTH = 8*IFM_TILE_ROW*4,
    parameter WGT_DATA_WIDTH = 8*KERNEL_SIZE*32*4,

    parameter IFM_BUFF_WORD_NUM = 64,
    parameter IFM_BUFF_ADDR_WIDTH  = $clog2(IFM_BUFF_WORD_NUM) + 1,
    parameter WGT_BUFF_WORD_NUM = 64,
    parameter WGT_BUFF_ADDR_WIDTH  = $clog2(WGT_BUFF_WORD_NUM) + 1,
	
	

    parameter OUT_DATA_WIDTH = 32,
    parameter TI = 28
) (
    input           clk,
    input           rst_n,
    
// Operation control
    input           op_start,               // AES/CBC operation start, one-cycle pulse
    input   [63:0]  write_addr,             // axi master write address
    input  [31:0] cfg_ci,
    input  [31:0] cfg_co,

// AXI stream slave port, receive data from AXI read master for IFM
    input           axis_slv_ifm_tvalid,
    input   [511:0] axis_slv_ifm_tdata,
    output          axis_slv_ifm_tready,

// AXI stream slave port, receive data from AXI read master for WGT
    input           axis_slv_wgt_tvalid,
    input   [511:0] axis_slv_wgt_tdata,
    output          axis_slv_wgt_tready,

// AXI stream master port, send data to AXI write master for OFM
    output          axis_mst_ofm_tvalid,
    input           axis_mst_ofm_tready,
    output  [511:0] axis_mst_ofm_tdata,

// global memory write master control    
    output ofm_req,
    input [63:0] ofm_addr_base,
    input ofm_done,
    output [63:0]  ofm_offset,  //reg?
    output [63:0]  ofm_xfer_size,

//    output  [63:0]  wmst_xfer_size,

//global memroy read master control, req, done

    output ifm_req,
    input [63:0] ifm_addr_base,
    input ifm_done,
    output [63:0]  ifm_offset,  //reg?

    output wgt_req,
    input [63:0] wgt_addr_base,
    input wgt_done,
    output [63:0]  wgt_offset, //reg?

// end_conv , clear singnal
    output end_conv,
    output write_buffer_wait
);



// control signal registing
    reg     [1:0]   r_cfg_ci;
    reg     [1:0]   r_cfg_co; 


    // assign axis_slv_rmst_tready = !in_fifo_full;
    // assign axis_mst_wmst_tvalid = !in_fifo_empty;
    // assign axis_mst_wmst_tdata = (in_word_counter == 0) ? r_cnt_data:
    //                             (in_word_counter == words_num - 1) ? w_cnt_data : in_fifo_pop_data;

    wire   wrapped_ifm_req;
    wire  [WIFM_DATA_WIDTH-1:0] wrapped_ifm;
    wire ifm_buf_rdy;
    wire wgt_rdy;
    wire ifm_read;
    wire wgt_read;
    wire    [IFM_DATA_WIDTH-1:0] ifm;

    switch_buffer  #(
        .DATA_WIDTH (WIFM_DATA_WIDTH),
        .DATA_NUM_BYTE (491520),
   //     .DATA_NUM (IFM_BUFF_WORD_NUM),
        .FIFO_ADDR_WIDTH (13)
    ) ifm_buffer (
        .clk        (clk),
        .rst_n      (rst_n),

        .tdata       (axis_slv_ifm_tdata),
        .valid       (axis_slv_ifm_tvalid),
        .ready       (axis_slv_ifm_tready),

        .addr_base (ifm_addr_base),

        .rmst_req   (ifm_req),
        .rmst_done  (ifm_done),

        .addr_offset (ifm_offset),

        .pop_req   (ifm_read),
        .o_data     (ifm), 

        .op_start   (op_start),
        .end_conv   (end_conv),

        .buf_rdy    (ifm_buf_rdy)
    );

    wire   wrapped_wgt_req;
    wire  [WWGT_DATA_WIDTH-1:0] wrapped_wgt;
    wire wgt_buf_rdy;

    switch_buffer #(
        .DATA_WIDTH (WWGT_DATA_WIDTH),
        .DATA_NUM_BYTE (9216)
    //    .DATA_NUM (WGT_BUFF_WORD_NUM),
    //    .FIFO_ADDR_WIDTH (WGT_BUFF_ADDR_WIDTH) //log_2 DATANUM + 1
        ) wgt_buffer(
        .clk        (clk),
        .rst_n      (rst_n),

        .tdata       (axis_slv_wgt_tdata),
        .valid       (axis_slv_wgt_tvalid),
        .ready       (axis_slv_wgt_tready),

        .addr_base (wgt_addr_base),    

        .rmst_req   (wgt_req),
        .rmst_done  (wgt_done),

        .pop_req   (wrapped_wgt_req),
        .o_data     (wrapped_wgt), 

        .addr_offset (wgt_offset),

        .op_start   (op_start),
        .end_conv   (end_conv),

        .buf_rdy    (wgt_buf_rdy)
    );

    wire start_conv = ifm_buf_rdy & wgt_rdy;
    reg r_start_conv;
    reg start_conv_pulse;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            r_start_conv <= 0;
            start_conv_pulse <= 0;
        end else begin
            start_conv_pulse <= r_start_conv ? 0 : start_conv;
            r_start_conv <= end_conv ? 0 : 
                            r_start_conv ? 1 : start_conv;
        end
    end


    wire    [WGT_DATA_WIDTH-1:0] wgt;
    wgt_resizebuffer #(.INPUT_WIDTH(512), .OUTPUT_WIDTH(WGT_DATA_WIDTH)) wgt_resizebuffer(
        .clk    (clk),
        .rst_n  (rst_n),
        .fm     (wrapped_wgt),
        .wgt_read (wgt_read),
        .buf_rdy (wgt_buf_rdy),

        .parse_out (wgt),
        .input_req (wrapped_wgt_req),
        .buf_full   (wgt_rdy)
    );

    wire [511:0] out_ofm0_port0;
    wire [511:0] out_ofm0_port1;
    wire [511:0] out_ofm0_port2;
    wire [511:0] out_ofm0_port3;
    wire [511:0] out_ofm0_port4;
    wire [511:0] out_ofm0_port5;
    wire [511:0] out_ofm0_port6;
    wire [511:0] out_ofm0_port7;
    wire [511:0] out_ofm0_port8;
    wire [511:0] out_ofm0_port9;
    wire [511:0] out_ofm0_port10;
    wire [511:0] out_ofm0_port11;
    wire [511:0] out_ofm0_port12;
    wire [511:0] out_ofm0_port13;
    wire [511:0] out_ofm1_port0;
    wire [511:0] out_ofm1_port1;
    wire [511:0] out_ofm1_port2;
    wire [511:0] out_ofm1_port3;
    wire [511:0] out_ofm1_port4;
    wire [511:0] out_ofm1_port5;
    wire [511:0] out_ofm1_port6;
    wire [511:0] out_ofm1_port7;
    wire [511:0] out_ofm1_port8;
    wire [511:0] out_ofm1_port9;
    wire [511:0] out_ofm1_port10;
    wire [511:0] out_ofm1_port11;
    wire [511:0] out_ofm1_port12;
    wire [511:0] out_ofm1_port13;
    wire out_ofm_port_v0;
    wire out_ofm_port_v1;
    wire out_ofm_port_v2;
    wire out_ofm_port_v3;
    wire out_ofm_port_v4;
    wire out_ofm_port_v5;
    wire out_ofm_port_v6;
    wire out_ofm_port_v7;
    wire out_ofm_port_v8;
    wire out_ofm_port_v9;
    wire out_ofm_port_v10;
    wire out_ofm_port_v11;
    wire out_ofm_port_v12;
    wire out_ofm_port_v13;
    wire [31:0] out_ofm0_port0_debug[0:13];

    CONV_ACC #(
        .out_data_width(OUT_DATA_WIDTH),
        .buf_addr_width(5),
        .buf_depth(TI),
		.IFM_DATA_WIDTH(IFM_DATA_WIDTH),
		.WGT_DATA_WIDTH(WGT_DATA_WIDTH)
    ) conv_acc (
        .clk(clk),
        .rst_n(rst_n),
        .start_conv(start_conv_pulse),
        .cfg_ci(r_cfg_ci),
        .cfg_co(r_cfg_co),
        .ifm(ifm),
        .weight(wgt),
        .out_ofm0_port0(out_ofm0_port0),
        .out_ofm0_port1(out_ofm0_port1),
        .out_ofm0_port2(out_ofm0_port2),
        .out_ofm0_port3(out_ofm0_port3),
        .out_ofm0_port4(out_ofm0_port4),
        .out_ofm0_port5(out_ofm0_port5),
        .out_ofm0_port6(out_ofm0_port6),
        .out_ofm0_port7(out_ofm0_port7),
        .out_ofm0_port8(out_ofm0_port8),
        .out_ofm0_port9(out_ofm0_port9),
        .out_ofm0_port10(out_ofm0_port10),
        .out_ofm0_port11(out_ofm0_port11),
        .out_ofm0_port12(out_ofm0_port12),
        .out_ofm0_port13(out_ofm0_port13),
        .out_ofm1_port0(out_ofm1_port0),
        .out_ofm1_port1(out_ofm1_port1),
        .out_ofm1_port2(out_ofm1_port2),
        .out_ofm1_port3(out_ofm1_port3),
        .out_ofm1_port4(out_ofm1_port4),
        .out_ofm1_port5(out_ofm1_port5),
        .out_ofm1_port6(out_ofm1_port6),
        .out_ofm1_port7(out_ofm1_port7),
        .out_ofm1_port8(out_ofm1_port8),
        .out_ofm1_port9(out_ofm1_port9),
        .out_ofm1_port10(out_ofm1_port10),
        .out_ofm1_port11(out_ofm1_port11),
        .out_ofm1_port12(out_ofm1_port12),
        .out_ofm1_port13(out_ofm1_port13),
        .out_ofm_port_v0(out_ofm_port_v0),
        .out_ofm_port_v1(out_ofm_port_v1),
        .out_ofm_port_v2(out_ofm_port_v2),
        .out_ofm_port_v3(out_ofm_port_v3),
        .out_ofm_port_v4(out_ofm_port_v4),
        .out_ofm_port_v5(out_ofm_port_v5),
        .out_ofm_port_v6(out_ofm_port_v6),
        .out_ofm_port_v7(out_ofm_port_v7),
        .out_ofm_port_v8(out_ofm_port_v8),
        .out_ofm_port_v9(out_ofm_port_v9),
        .out_ofm_port_v10(out_ofm_port_v10),
        .out_ofm_port_v11(out_ofm_port_v11),
        .out_ofm_port_v12(out_ofm_port_v12),
        .out_ofm_port_v13(out_ofm_port_v13),        
        .ifm_read(ifm_read),
        .wgt_read(wgt_read),
        .end_op(end_conv)
    );

    assign out_ofm0_port0_debug[0] = out_ofm0_port0[31:0];
    assign out_ofm0_port0_debug[1] = out_ofm0_port1[31:0];
    assign out_ofm0_port0_debug[2] = out_ofm0_port2[31:0];
    assign out_ofm0_port0_debug[3] = out_ofm0_port3[31:0];
    assign out_ofm0_port0_debug[4] = out_ofm0_port4[31:0];
    assign out_ofm0_port0_debug[5] = out_ofm0_port5[31:0];
    assign out_ofm0_port0_debug[6] = out_ofm0_port6[31:0];
    assign out_ofm0_port0_debug[7] = out_ofm0_port7[31:0];
    assign out_ofm0_port0_debug[8] = out_ofm0_port8[31:0];
    assign out_ofm0_port0_debug[9] = out_ofm0_port9[31:0];
    assign out_ofm0_port0_debug[10] = out_ofm0_port10[31:0];
    assign out_ofm0_port0_debug[11] = out_ofm0_port11[31:0];
    assign out_ofm0_port0_debug[12] = out_ofm0_port12[31:0];
    assign out_ofm0_port0_debug[13] = out_ofm0_port13[31:0];




    wire [63:0] wmst_addr;

    flatter ofm_flat(
        .clk(clk),
        .rst_n(rst_n),

        .out_ofm0_port0(out_ofm0_port0),
        .out_ofm0_port1(out_ofm0_port1),
        .out_ofm0_port2(out_ofm0_port2),
        .out_ofm0_port3(out_ofm0_port3),
        .out_ofm0_port4(out_ofm0_port4),
        .out_ofm0_port5(out_ofm0_port5),
        .out_ofm0_port6(out_ofm0_port6),
        .out_ofm0_port7(out_ofm0_port7),
        .out_ofm0_port8(out_ofm0_port8),
        .out_ofm0_port9(out_ofm0_port9),
        .out_ofm0_port10(out_ofm0_port10),
        .out_ofm0_port11(out_ofm0_port11),
        .out_ofm0_port12(out_ofm0_port12),
        .out_ofm0_port13(out_ofm0_port13),
        .out_ofm1_port0(out_ofm1_port0),
        .out_ofm1_port1(out_ofm1_port1),
        .out_ofm1_port2(out_ofm1_port2),
        .out_ofm1_port3(out_ofm1_port3),
        .out_ofm1_port4(out_ofm1_port4),
        .out_ofm1_port5(out_ofm1_port5),
        .out_ofm1_port6(out_ofm1_port6),
        .out_ofm1_port7(out_ofm1_port7),
        .out_ofm1_port8(out_ofm1_port8),
        .out_ofm1_port9(out_ofm1_port9),
        .out_ofm1_port10(out_ofm1_port10),
        .out_ofm1_port11(out_ofm1_port11),
        .out_ofm1_port12(out_ofm1_port12),
        .out_ofm1_port13(out_ofm1_port13),
        .out_ofm_port_v0(out_ofm_port_v0),
        .out_ofm_port_v1(out_ofm_port_v1),
        .out_ofm_port_v2(out_ofm_port_v2),
        .out_ofm_port_v3(out_ofm_port_v3),
        .out_ofm_port_v4(out_ofm_port_v4),
        .out_ofm_port_v5(out_ofm_port_v5),
        .out_ofm_port_v6(out_ofm_port_v6),
        .out_ofm_port_v7(out_ofm_port_v7),
        .out_ofm_port_v8(out_ofm_port_v8),
        .out_ofm_port_v9(out_ofm_port_v9),
        .out_ofm_port_v10(out_ofm_port_v10),
        .out_ofm_port_v11(out_ofm_port_v11),
        .out_ofm_port_v12(out_ofm_port_v12),
        .out_ofm_port_v13(out_ofm_port_v13),  

        .end_conv(end_conv),

        .tdata(axis_mst_ofm_tdata),
        .ready(axis_mst_ofm_tready),
        .valid(axis_mst_ofm_tvalid),

        .wmst_offset(ofm_addr_base),
        .wmst_done(ofm_done),
        .wmst_req(ofm_req),
        .wmst_addr(ofm_offset),
        .wmst_xfer_size(ofm_xfer_size),
        .write_buffer_wait(write_buffer_wait)
    );

    assign ofm_xfer_addr = wmst_addr;

// control signals registering
    always @ (posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            r_cfg_ci <= 0;
            r_cfg_ci <= 0;
//            ofm_xfer_addr <= 0;
        end else begin
            if (op_start) begin
            r_cfg_ci <= cfg_ci[1:0];
            r_cfg_co <= cfg_co[1:0];
//            ofm_xfer_addr <= wmst_addr;
            end
        end
    end

endmodule
