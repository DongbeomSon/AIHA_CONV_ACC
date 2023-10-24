//
//
//# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
//# SPDX-License-Identifier: X11
//
//

`timescale 1ns / 1ps

module conv_engine #(
    parameter WIFM_DATA_WIDTH = 512,
    parameter WWGT_DATA_WIDTH = 512,

    parameter IFM_BUFF_WORD_NUM   = 64,
    parameter IFM_BUFF_ADDR_WIDTH = $clog2(IFM_BUFF_WORD_NUM) + 1,
    parameter WGT_BUFF_WORD_NUM   = 64,
    parameter WGT_BUFF_ADDR_WIDTH = $clog2(WGT_BUFF_WORD_NUM) + 1,


    parameter OUT_DATA_WIDTH = 32,
    parameter OUT_PORT_WIDTH = 512,
    parameter T = 14,  //Tile_length
    parameter R = 14,    //ROW
    parameter S = 64,    //parallelize channel_output
    parameter P = 1,    //parallelize channel_input
    parameter K = 3     //kernel size
) (
    input clk,
    input rst_n,

    // Operation control
    input        op_start,    // AES/CBC operation start, one-cycle pulse
    input [63:0] write_addr,  // axi master write address
    input [31:0] cfg_ci,
    input [31:0] cfg_co,
    // input   [31:0] input_width,
    input [31:0] ifm_size,
    input [31:0] wgt_size,
    input [31:0] ofm_size,
    input [31:0] tile_num,

    // AXI stream slave port, receive data from AXI read master for IFM
    input          axis_slv_ifm_tvalid,
    input  [511:0] axis_slv_ifm_tdata,
    output         axis_slv_ifm_tready,

    // AXI stream slave port, receive data from AXI read master for WGT
    input          axis_slv_wgt_tvalid,
    input  [511:0] axis_slv_wgt_tdata,
    output         axis_slv_wgt_tready,

    // AXI stream master port, send data to AXI write master for OFM
    output         axis_mst_ofm_tvalid,
    input          axis_mst_ofm_tready,
    output [511:0] axis_mst_ofm_tdata,

    // global memory write master control    
    output ofm_req,
    input [63:0] ofm_addr_base,
    input ofm_done,
    output [63:0] ofm_offset,  //reg?
    output [63:0] ofm_xfer_size,

    //    output  [63:0]  wmst_xfer_size,

    //global memroy read master control, req, done

    output ifm_req,
    input [63:0] ifm_addr_base,
    input ifm_done,
    output [63:0] ifm_offset,  //reg?
    output [63:0] ifm_xfer_size,

    output wgt_req,
    input [63:0] wgt_addr_base,
    input wgt_done,
    output [63:0] wgt_offset,  //reg?
    output [63:0] wgt_xfer_size,

    // end_conv , clear singnal
    output end_conv,
    output write_buffer_wait
);



    // control signal registing
    reg [31:0] r_cfg_ci;
    reg [31:0] r_cfg_co;
    reg [31:0] r_ifm_size;
    reg [31:0] r_wgt_size;
    reg [31:0] r_ofm_size;
    reg [31:0] r_tile_num;
    reg [63:0] r_ifm_addr_base;
    reg [63:0] r_wgt_addr_base;
    reg [63:0] r_ofm_addr_base;

    reg p_op_start;

    // assign axis_slv_rmst_tready = !in_fifo_full;
    // assign axis_mst_wmst_tvalid = !in_fifo_empty;
    // assign axis_mst_wmst_tdata = (in_word_counter == 0) ? r_cnt_data:
    //                             (in_word_counter == words_num - 1) ? w_cnt_data : in_fifo_pop_data;

    wire wrapped_ifm_req;
    wire [WIFM_DATA_WIDTH-1:0] wrapped_ifm;
    wire wrapped_ifm_v;
    wire ifm_buf_rdy;

    wire ifm_read;
    wire wgt_read;


    // stall signal 
    wire ifm_stall;
    wire wgt_stall;
    wire ofm_stall;
    wire wgt_input_stall;

    wire g_stall = ifm_stall | wgt_stall | ofm_stall;

    wire ifm_xfer_clear;
    wire wgt_xfer_clear;

    input_buffer #(
        .DATA_WIDTH(WIFM_DATA_WIDTH)
        //     .DATA_NUM_BYTE (1011712)
        //     .DATA_NUM (IFM_BUFF_WORD_NUM),
        //     .FIFO_ADDR_WIDTH (IFM_BUFF_ADDR_WIDTH)
    ) ifm_buffer (
        .clk  (clk),
        .rst_n(rst_n),

        .tdata(axis_slv_ifm_tdata),
        .valid(axis_slv_ifm_tvalid),
        .ready(axis_slv_ifm_tready),

        .addr_base(r_ifm_addr_base),

        .rmst_req (ifm_req),
        .rmst_done(ifm_done),

        .xfer_size(ifm_xfer_size),

        .input_byte(r_ifm_size),

        .addr_offset(ifm_offset),

        .pop_req(wrapped_ifm_req),
        .o_data (wrapped_ifm),
        .o_data_v(wrapped_ifm_v),

        .op_start(p_op_start),
        .end_conv(end_conv),

        .g_stall(g_stall),

        .xfer_clear(ifm_xfer_clear),

        .stall(ifm_stall)
    );

    wire wrapped_wgt_req;
    wire [WWGT_DATA_WIDTH-1:0] wrapped_wgt;
    wire wrapped_wgt_v;
    wire wgt_buf_rdy;

    input_buffer #(
        .DATA_WIDTH(WWGT_DATA_WIDTH)
        //    .DATA_NUM_BYTE (851968)
        //    .DATA_NUM (WGT_BUFF_WORD_NUM),
        //    .FIFO_ADDR_WIDTH (WGT_BUFF_ADDR_WIDTH) //log_2 DATANUM + 1
    ) wgt_buffer (
        .clk  (clk),
        .rst_n(rst_n),

        .tdata(axis_slv_wgt_tdata),
        .valid(axis_slv_wgt_tvalid),
        .ready(axis_slv_wgt_tready),

        .addr_base(r_wgt_addr_base),

        .input_byte(r_wgt_size),

        .rmst_req (wgt_req),
        .rmst_done(wgt_done),

        .xfer_size(wgt_xfer_size),

        .pop_req(wrapped_wgt_req),
        .o_data (wrapped_wgt),
        .o_data_v(wrapped_wgt_v),

        .addr_offset(wgt_offset),

        .op_start(p_op_start),
        .end_conv(end_conv),

        .g_stall(0),
        .xfer_clear(wgt_xfer_clear),

        .stall(wgt_input_stall)
    );

    wire start_conv = ifm_buf_rdy & wgt_buf_rdy;
    reg r_start_conv;
    reg start_conv_pulse;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            r_start_conv <= 0;
            start_conv_pulse <= 0;
        end else begin
            start_conv_pulse <= r_start_conv ? 0 : start_conv;
            r_start_conv <= end_conv ? 0 : r_start_conv ? 1 : start_conv;
        end
    end

    wire [127:0] ifm;
    new_parser #(
        .OUTPUT_WIDTH(128)
    ) ifm_parser (
        .clk  (clk),
        .rst_n(rst_n),

        .fm      (wrapped_ifm),
        .ifm_read(ifm_read),
        //       .init_word  (start_conv_pulse),

        .parse_out(ifm),
        .input_req(wrapped_ifm_req),

        .stall(g_stall)
    );


    wire [1535:0] wgt;
    wgt_resizebuffer #(.INPUT_WIDTH(512), .OUTPUT_WIDTH(1536)) wgt_resizebuffer(
        .clk    (clk),
        .rst_n  (rst_n),
        .fm     (wrapped_wgt),
        .wgt_read (wgt_read),

        .g_stall (g_stall),
        .valid_input (wrapped_wgt_v),

        .op_start(p_op_start),
        .end_conv(end_conv),

        .parse_out (wgt),
        .input_req (wrapped_wgt_req),
        .stall(wgt_stall)
    );

    wire [OUT_PORT_WIDTH-1:0] ofm_port0;
    wire [OUT_PORT_WIDTH-1:0] ofm_port1;
    wire [OUT_PORT_WIDTH-1:0] ofm_port2;
    wire [OUT_PORT_WIDTH-1:0] ofm_port3;
    
    wire ofm_port_v0;
    wire ofm_port_v1;
    wire ofm_port_v2;
    wire ofm_port_v3;


    reg r_op_start;
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            r_op_start <= 0;
        end else begin
            if (g_stall) begin
                r_op_start <= p_op_start ? 1 : r_op_start;
            end else if (r_op_start) begin
                r_op_start <= 0;
            end
        end
    end

    CONV_ACC #(
        .out_data_width(OUT_DATA_WIDTH),
        .buf_addr_width(5),
        .T(T),
        .R(R),
        .S(S),
        .P(P),
        .K(K)

    ) conv_acc (
        .clk(clk),
        .rst_n(rst_n),
        // .start_conv(start_conv_pulse),
        .start_conv(r_op_start),
        .cfg_ci(r_cfg_ci),
        .cfg_co(r_cfg_co),
        .tile_num(tile_num),
        .ifm(ifm),
        .weight(wgt),
        .out_ofm_port0(ofm_port0),
        .out_ofm_port1(ofm_port1),
        .out_ofm_port2(ofm_port2),
        .out_ofm_port3(ofm_port3),
        .out_ofm_port_v0(ofm_port_v0),
        .out_ofm_port_v1(ofm_port_v1),
        .out_ofm_port_v2(ofm_port_v2),
        .out_ofm_port_v3(ofm_port_v3),
        .ifm_read(ifm_read),
        .wgt_read(wgt_read),
        .end_op(end_conv),

        .stall(g_stall)
    );



    // //counter

    // reg [31:0] ifm_counter;
    // reg [31:0] wgt_counter;
    // reg [31:0] ofm_counter;
    // always @(posedge clk, negedge rst_n) begin
    //     if(!rst_n) begin
    //         ifm_counter <= 0;
    //         wgt_counter <= 0;
    //         ofm_counter <= 0;
    //     end else begin
    //         ifm_counter <= ifm_read ? ifm_counter + 1 : ifm_counter;
    //         wgt_counter <= wgt_read ? wgt_counter + 1 : wgt_counter;
    //         ofm_counter <= ofm_port0_v ? (ofm_port1_v ? ofm_counter + 2 : ofm_counter + 1) 
    //                                     : ofm_counter;
    //     end
    // end

    wire [63:0] wmst_addr;
    wire write_xfer_wait;
    assign write_buffer_wait = !write_xfer_wait & ifm_xfer_clear & wgt_xfer_clear;

    flatter ofm_flat (
        .clk(clk),
        .rst_n(rst_n),
        .g_stall(g_stall),

        .out_ofm_port_v0(ofm_port_v0),
        .out_ofm_port_v1(ofm_port_v1),
        .out_ofm_port_v2(ofm_port_v2),
        .out_ofm_port_v3(ofm_port_v3),

        .out_ofm_port0(ofm_port0),
        .out_ofm_port1(ofm_port1),
        .out_ofm_port2(ofm_port2),
        .out_ofm_port3(ofm_port3),
        
        .op_start (p_op_start),
        .end_conv (end_conv),
        .ofm_size (r_ofm_size),

        .tdata(axis_mst_ofm_tdata),
        .ready(axis_mst_ofm_tready),
        .valid(axis_mst_ofm_tvalid),

        .wmst_offset(r_ofm_addr_base),
        .wmst_done(ofm_done),
        .wmst_req(ofm_req),
        .wmst_addr(ofm_offset),
        .wmst_xfer_size(ofm_xfer_size),
        .write_buffer_wait(write_xfer_wait),

        .stall(ofm_stall)
    );

    assign ofm_xfer_addr = wmst_addr;

    // control signals registering
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            r_cfg_ci <= 0;
            r_cfg_ci <= 0;
            r_ifm_size <= 0;
            r_wgt_size <= 0;
            r_ofm_size <= 0;
            r_tile_num <= 0;
            //            ofm_xfer_addr <= 0;
            r_ifm_addr_base <= 0;
            r_wgt_addr_base <= 0;
            r_ofm_addr_base <= 0;
            p_op_start <= 0;
        end else begin
            if (op_start) begin
                r_cfg_ci <= cfg_ci;
                r_cfg_co <= cfg_co;
                r_ifm_size <= ifm_size;
                r_wgt_size <= wgt_size;
                r_ofm_size <= ofm_size;
                r_tile_num <= tile_num;
                r_ifm_addr_base <= ifm_addr_base;
                r_wgt_addr_base <= wgt_addr_base;
                r_ofm_addr_base <= ofm_addr_base;
            end
            p_op_start <= op_start;
        end
    end


    // // ILA monitoring combinatorial adder
    // ila_0 i_ila_0 (
    // 	.clk(clk),              // input wire        clk
    // 	.probe0(op_start),           // input wire [0:0]  probe0  
    // 	.probe1(r_ifm_addr_base), // input wire [63:0]  probe1 
    // 	.probe2(r_wgt_addr_base),   // input wire [63:0]  probe2 
    // 	.probe3(r_ofm_addr_base),    // input wire [63:0] probe3 
    //     .probe4(ifm_req),      // input wire [0:0] probe4
    //     .probe5(wgt_req),       // input wire [0:0] probe5
    //     .probe6(ofm_req),       // input wire [0:0] probe6
    //     .probe7(ifm_offset),    // input wire [63:0] probe7
    //     .probe8(wgt_offset),    // input wire [63:0] probe8
    //     .probe9(ofm_offset),    // input wire [63:0] probe9
    //     .probe10(ifm_xfer_clear),   // input wire [0:0] probe10
    //     .probe11(wgt_xfer_clear),   // input wire [0:0] probe11
    //     .probe12(wrapped_ifm),      // input wire [511:0] probe12
    //     .probe13(wrapped_wgt)       // input wire [511:0] probe13
    // );


    //counter
    reg [31:0] run_cycle;
    reg [31:0] ifm_stall_cnt;
    reg [31:0] wgt_stall_cnt;
    reg [31:0] ofm_stall_cnt;
    reg [31:0] stall_cnt;
    reg [31:0] ifm_cycle;
    reg [31:0] wgt_cycle;
    reg [31:0] ofm_cycle;

    reg flag_op_start;
    reg flag_end_conv;

    wire flag_ifm = axis_slv_ifm_tready & axis_slv_ifm_tvalid;
    wire flag_wgt = axis_slv_wgt_tready & axis_slv_wgt_tvalid;
    wire flag_ofm = axis_mst_ofm_tready & axis_mst_ofm_tvalid;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            run_cycle <= 0;
            ifm_stall_cnt <= 0;
            wgt_stall_cnt <= 0;
            ofm_stall_cnt <= 0;
            stall_cnt <= 0;
            ifm_cycle <= 0;
            wgt_cycle <= 0;
            ofm_cycle <= 0;
            flag_op_start <= 0;
            flag_end_conv <= 0;
            // flag_ifm <= 0;
            // flag_wgt <= 0;
            // flag_ofm <= 0;
        end else begin
            // if (flag_op_start) begin
            //     if (ifm_req) begin
            //         flag_ifm <= 1;
            //     end else if (ifm_done) begin
            //         flag_ifm <= 0;
            //     end

            //     if (wgt_req) begin
            //         flag_wgt <= 1;
            //     end else if (wgt_done) begin
            //         flag_wgt <= 0;
            //     end

            //     if (ofm_req) begin
            //         flag_ofm <= 1;
            //     end else if (ofm_done) begin
            //         flag_ofm <= 0;
            //     end
            // end



            if (op_start) begin
                flag_op_start <= 1;
                run_cycle <= 0;
                ifm_stall_cnt <= 0;
                wgt_stall_cnt <= 0;
                ofm_stall_cnt <= 0;
                stall_cnt <= 0;
                ifm_cycle <= 0;
                wgt_cycle <= 0;
                ofm_cycle <= 0;
                flag_end_conv <= 0;
            end else if (end_conv) begin
                flag_end_conv <= 1;
            end else if (flag_end_conv & write_buffer_wait) begin
                flag_op_start <= 0;
            end else if (flag_op_start) begin
                run_cycle <= run_cycle + 1;
                if (ifm_stall) ifm_stall_cnt <= ifm_stall_cnt + 1;
                if (wgt_stall) wgt_stall_cnt <= wgt_stall_cnt + 1;
                if (ofm_stall) ofm_stall_cnt <= ofm_stall_cnt + 1;
                if (g_stall) stall_cnt <= stall_cnt + 1;

                if (flag_ifm) ifm_cycle <= ifm_cycle + 1;
                if (flag_wgt) wgt_cycle <= wgt_cycle + 1;
                if (flag_ofm) ofm_cycle <= ofm_cycle + 1;

            end
        end
    end

    // ila_0 i_ila_0 (
    //     .clk    (clk),                // input wire        clk
    //     .probe0 (op_start),           // input wire [0:0]  probe0  
    //     .probe1 (end_conv),           // input wire [0:0]  probe1 
    //     .probe2 (flag_op_start),      // input wire [0:0]  probe2 
    //     .probe3 (flag_end_conv),      // input wire [0:0] probe3 
    //     .probe4 (write_buffer_wait),  // input wire [0:0] probe4
    //     .probe5 (run_cycle),          // input wire [31:0]  probe5
    //     .probe6 (ifm_stall_cnt),      // input wire [31:0]  probe6 
    //     .probe7 (wgt_stall_cnt),      // input wire [31:0] probe7 
    //     .probe8 (ofm_stall_cnt),      // input wire [31:0] probe8
    //     .probe9 (stall_cnt),          // input wire [31:0] probe9
    //     .probe10(ifm_cycle),          // input wire [31:0]  probe10 
    //     .probe11(wgt_cycle),          // input wire [31:0] probe11 
    //     .probe12(ofm_cycle)           // input wire [31:0] probe12  
    // );

endmodule
