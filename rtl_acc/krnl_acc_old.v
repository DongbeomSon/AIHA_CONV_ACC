//
//
//# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
//# SPDX-License-Identifier: X11
//
//

`timescale 1ns/1ps

module krnl_acc #(
  parameter integer DATA_WIDTH  = 512,
  parameter integer WORD_BYTE = DATA_WIDTH/8,
  parameter integer ADDR_WIDTH = 64,
  parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12 ,
  parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32 ,
  parameter integer C_RMST0_ADDR_WIDTH         = 64 ,
  parameter integer C_RMST0_DATA_WIDTH         = 512,
  parameter integer C_WMST0_ADDR_WIDTH         = 64 ,
  parameter integer C_WMST0_DATA_WIDTH         = 512
)( 
// System Signals
    input             ap_clk,
    input             ap_rst_n,

  // AXI4-Lite slave interface
    input  wire                                    s_axi_control_awvalid,
    output wire                                    s_axi_control_awready,
    input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_awaddr ,
    input  wire                                    s_axi_control_wvalid ,
    output wire                                    s_axi_control_wready ,
    input  wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_wdata  ,
    input  wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb  ,
    input  wire                                    s_axi_control_arvalid,
    output wire                                    s_axi_control_arready,
    input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_araddr ,
    output wire                                    s_axi_control_rvalid ,
    input  wire                                    s_axi_control_rready ,
    output wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_rdata  ,
    output wire [2-1:0]                            s_axi_control_rresp  ,
    output wire                                    s_axi_control_bvalid ,
    input  wire                                    s_axi_control_bready ,
    output wire [2-1:0]                            s_axi_control_bresp  ,

// AXI read master interface - ifm
    output wire                                    axi_rmst0_awvalid        ,
    input  wire                                    axi_rmst0_awready        ,
    output wire [ADDR_WIDTH-1:0]                   axi_rmst0_awaddr         ,
    output wire [8-1:0]                            axi_rmst0_awlen          ,
    output wire                                    axi_rmst0_wvalid         ,
    input  wire                                    axi_rmst0_wready         ,
    output wire [DATA_WIDTH-1:0]                   axi_rmst0_wdata          ,
    output wire [DATA_WIDTH/8-1:0]                 axi_rmst0_wstrb          ,
    output wire                                    axi_rmst0_wlast          ,
    input  wire                                    axi_rmst0_bvalid         ,
    output wire                                    axi_rmst0_bready         ,
    output wire                                    axi_rmst0_arvalid        ,
    input  wire                                    axi_rmst0_arready        ,
    output wire [ADDR_WIDTH-1:0]                   axi_rmst0_araddr         ,
    output wire [8-1:0]                            axi_rmst0_arlen          ,
    input  wire                                    axi_rmst0_rvalid         ,
    output wire                                    axi_rmst0_rready         ,
    input  wire [DATA_WIDTH-1:0]                   axi_rmst0_rdata          ,
    input  wire                                    axi_rmst0_rlast          ,

// AXI read master interface - wgt
    output wire                                    axi_rmst1_awvalid        ,
    input  wire                                    axi_rmst1_awready        ,
    output wire [ADDR_WIDTH-1:0]                   axi_rmst1_awaddr         ,
    output wire [8-1:0]                            axi_rmst1_awlen          ,
    output wire                                    axi_rmst1_wvalid         ,
    input  wire                                    axi_rmst1_wready         ,
    output wire [DATA_WIDTH-1:0]                   axi_rmst1_wdata          ,
    output wire [DATA_WIDTH/8-1:0]                 axi_rmst1_wstrb          ,
    output wire                                    axi_rmst1_wlast          ,
    input  wire                                    axi_rmst1_bvalid         ,
    output wire                                    axi_rmst1_bready         ,
    output wire                                    axi_rmst1_arvalid        ,
    input  wire                                    axi_rmst1_arready        ,
    output wire [ADDR_WIDTH-1:0]                   axi_rmst1_araddr         ,
    output wire [8-1:0]                            axi_rmst1_arlen          ,
    input  wire                                    axi_rmst1_rvalid         ,
    output wire                                    axi_rmst1_rready         ,
    input  wire [DATA_WIDTH-1:0]                   axi_rmst1_rdata          ,
    input  wire                                    axi_rmst1_rlast          ,


// AXI4 master interface ofm
    output wire                                    axi_wmst0_awvalid        ,
    input  wire                                    axi_wmst0_awready        ,
    output wire [ADDR_WIDTH-1:0]                   axi_wmst0_awaddr         ,
    output wire [8-1:0]                            axi_wmst0_awlen          ,
    output wire                                    axi_wmst0_wvalid         ,
    input  wire                                    axi_wmst0_wready         ,
    output wire [DATA_WIDTH-1:0]                   axi_wmst0_wdata          ,
    output wire [DATA_WIDTH/8-1:0]                 axi_wmst0_wstrb          ,
    output wire                                    axi_wmst0_wlast          ,
    input  wire                                    axi_wmst0_bvalid         ,
    output wire                                    axi_wmst0_bready         ,
    output wire                                    axi_wmst0_arvalid        ,
    input  wire                                    axi_wmst0_arready        ,
    output wire [ADDR_WIDTH-1:0]                   axi_wmst0_araddr         ,
    output wire [8-1:0]                            axi_wmst0_arlen          ,
    input  wire                                    axi_wmst0_rvalid         ,
    output wire                                    axi_wmst0_rready         ,
    input  wire [DATA_WIDTH-1:0]                   axi_wmst0_rdata          ,
    input  wire                                    axi_wmst0_rlast
);

// internel connection signals
    wire            ap_start;
    wire            ap_continue;
    wire            ap_idle;
    wire            ap_done;
    wire            ap_ready;

    wire    [63:0]  ifm_addr;
    wire    [63:0]  wgt_addr;
    wire    [63:0]  ofm_addr;
    wire    [31:0]  words_num;



// tie-off not used axi master signals
    assign axi_rmst0_awvalid = 1'b0;
    assign axi_rmst0_awaddr  = 64'b0;
    assign axi_rmst0_awlen   = 8'b0;
    assign axi_rmst0_wvalid  = 1'b0;
    assign axi_rmst0_wdata   = 512'b0;
    assign axi_rmst0_wstrb   = 16'b0;
    assign axi_rmst0_wlast   = 1'b0;
    assign axi_rmst0_bready  = 1'b1;   

    assign axi_rmst1_awvalid = 1'b0;
    assign axi_rmst1_awaddr  = 64'b0;
    assign axi_rmst1_awlen   = 8'b0;
    assign axi_rmst1_wvalid  = 1'b0;
    assign axi_rmst1_wdata   = 512'b0;
    assign axi_rmst1_wstrb   = 16'b0;
    assign axi_rmst1_wlast   = 1'b0;
    assign axi_rmst1_bready  = 1'b1;  

    assign axi_wmst0_arvalid = 1'b0;
    assign axi_wmst0_araddr  = 64'b0;
    assign axi_wmst0_arlen   = 8'b0;
    assign axi_wmst0_rready  = 1'b1;

// instantiation of axi control slave
// needs to be revised according to the parameter
  krnl_acc_axi_ctrl_slave  u_krnl_cbc_axi_ctrl_slave (
    .ACLK           (ap_clk),     
    .ARESETn        (ap_rst_n),

    .AWADDR         (s_axi_control_awaddr),
    .AWVALID        (s_axi_control_awvalid),
    .AWREADY        (s_axi_control_awready),
    .WDATA          (s_axi_control_wdata),
    .WSTRB          (s_axi_control_wstrb),
    .WVALID         (s_axi_control_wvalid),
    .WREADY         (s_axi_control_wready),
    .BRESP          (s_axi_control_bresp),
    .BVALID         (s_axi_control_bvalid),
    .BREADY         (s_axi_control_bready),
    .ARADDR         (s_axi_control_araddr),
    .ARVALID        (s_axi_control_arvalid),
    .ARREADY        (s_axi_control_arready),
    .RDATA          (s_axi_control_rdata),
    .RRESP          (s_axi_control_rresp),
    .RVALID         (s_axi_control_rvalid),
    .RREADY         (s_axi_control_rready),

    .ap_start       (ap_start),
    .ap_done        (ap_done),
    .ap_idle        (ap_idle),
    .ap_ready       (ap_ready),
    .ap_continue    (ap_continue),

    .mode           (mode),
    .src_addr0       (src_addr0),
    .dest_addr0      (dest_addr0),
    .words_num      (words_num)
);


  acc_wrapper u_acc(
    .aclk           (ap_clk),
    .areset_n       (ap_rst_n),

// write ch.
    .m_axi_awvalid  (axi_wmst0_awvalid),
    .m_axi_awready  (axi_wmst0_awready),
    .m_axi_awaddr   (axi_wmst0_awaddr),
    .m_axi_awlen    (axi_wmst0_awlen),
    .m_axi_wvalid   (axi_wmst0_wvalid),
    .m_axi_wready   (axi_wmst0_wready),
    .m_axi_wdata    (axi_wmst0_wdata),
    .m_axi_wstrb    (axi_wmst0_wstrb),
    .m_axi_wlast    (axi_wmst0_wlast),
    .m_axi_bvalid   (axi_wmst0_bvalid),
    .m_axi_bready   (axi_wmst0_bready),

//  read ch.
    .m_axi_arvalid  (axi_rmst0_arvalid),
    .m_axi_arready  (axi_rmst0_arready),
    .m_axi_araddr   (axi_rmst0_araddr),
    .m_axi_arlen    (axi_rmst0_arlen),
    .m_axi_rvalid   (axi_rmst0_rvalid),
    .m_axi_rready   (axi_rmst0_rready),
    .m_axi_rdata    (axi_rmst0_rdata),
    .m_axi_rlast    (axi_rmst0_rlast),

    .src_addr(src_addr0),
    .dest_addr(dest_addr0),
    .words_num(words_num),

    .ap_start(g_start),
    .ap_done(ap_done),
    .ap_idle(ap_idle),
    .ap_ready(ap_ready),
    .ap_continue(ap_continue),

    .mode(mode),

    .wmst_done(wmst_done[0]),
    .g_wmst_done(g_wmst_done),
    .wmst_req(wmst_req[0]),
    .g_wmst_req(g_wmst_req)
  );
  );

  


endmodule
