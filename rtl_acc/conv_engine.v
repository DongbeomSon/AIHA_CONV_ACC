//
//
//# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
//# SPDX-License-Identifier: X11
//
//

`timescale 1ns/1ps

module conv_engine #(
	parameter IFM_TILE_ROW = 18,
	parameter KERNEL_SIZE = 3,
    parameter WIFM_DATA_WIDTH = 512,
    parameter WWGT_DATA_WIDTH = 512,
	parameter IFM_DATA_WIDTH = 8*IFM_TILE_ROW,
    parameter WGT_DATA_WIDTH = 8*KERNEL_SIZE,

    parameter IFM_BUFF_WORD_NUM = 64,
    parameter IFM_BUFF_ADDR_WIDTH  = $clog2(IFM_BUFF_WORD_NUM) + 1,
    parameter WGT_BUFF_WORD_NUM = 64,
    parameter WGT_BUFF_ADDR_WIDTH  = $clog2(WGT_BUFF_WORD_NUM) + 1,
	
	

    parameter OUT_DATA_WIDTH = 32,
    parameter TI = 16
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

    wire ifm_read;
    wire wgt_read;

    switch_buffer  #(
        .DATA_WIDTH (WIFM_DATA_WIDTH),
        .DATA_NUM_BYTE (41472)
   //     .DATA_NUM (IFM_BUFF_WORD_NUM),
   //     .FIFO_ADDR_WIDTH (IFM_BUFF_ADDR_WIDTH)
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

        .pop_req   (wrapped_ifm_req),
        .o_data     (wrapped_ifm), 

        .op_start   (op_start),
        .end_conv   (end_conv),

        .buf_rdy    (ifm_buf_rdy)
    );

    wire   wrapped_wgt_req;
    wire  [WWGT_DATA_WIDTH-1:0] wrapped_wgt;
    wire wgt_buf_rdy;

    switch_buffer #(
        .DATA_WIDTH (WWGT_DATA_WIDTH),
        .DATA_NUM_BYTE (18432)
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

    wire start_conv = ifm_buf_rdy & wgt_buf_rdy;
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

    wire    [IFM_DATA_WIDTH-1:0] ifm;
    ifm_parser #(.INPUT_WIDTH(512), .OUTPUT_WIDTH(IFM_DATA_WIDTH), .REG_NUM(9)) ifm_parser(
        .clk    (clk),
        .rst_n  (rst_n),
		.start_conv_pulse (start_conv_pulse),

        .fm     (wrapped_ifm),
        .ifm_read (ifm_read),
 //       .init_word  (start_conv_pulse),

        .parse_out (ifm),
        .input_req (wrapped_ifm_req)
    );


    wire    [WGT_DATA_WIDTH-1:0] wgt;
    ifm_parser #(.INPUT_WIDTH(512), .OUTPUT_WIDTH(WGT_DATA_WIDTH),  .REG_NUM(3)) wgt_parser(
        .clk    (clk),
        .rst_n  (rst_n),
		.start_conv_pulse (start_conv_pulse),

        .fm     (wrapped_wgt),
        .ifm_read (wgt_read),
 //       .init_word  (start_conv_pulse),

        .parse_out (wgt),
        .input_req (wrapped_wgt_req)
    );

    wire [511:0] ofm_port;
	wire         ofm_port_v;

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
        .ofm_port(ofm_port),
        .ofm_port_v(ofm_port_v),
        .ifm_read(ifm_read),
        .wgt_read(wgt_read),
        .end_op(end_conv)
    );

    //counter

    reg [31:0] ifm_counter;
    reg [31:0] wgt_counter;
    reg [31:0] ofm_counter;
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            ifm_counter <= 0;
            wgt_counter <= 0;
            ofm_counter <= 0;
        end else begin
            ifm_counter <= ifm_read ? ifm_counter + 1 : ifm_counter;
            wgt_counter <= wgt_read ? wgt_counter + 1 : wgt_counter;
            ofm_counter <= ofm_port_v ? ofm_counter + 16 : ofm_counter;
        end
    end

    wire [63:0] wmst_addr;

    flatter ofm_flat(
        .clk(clk),
        .rst_n(rst_n),

        .ofm_port_v(ofm_port_v),

        .ofm_port(ofm_port),

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
