//
//
//# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
//# SPDX-License-Identifier: X11
//
//

`timescale 1ns/1ps

// `define CI 0
// `define CO 0
`define TI 16
`define ROW 5
`define WIDTH 64
`define KK 4
`define TI_FACTOR int'((`WIDTH+`TI-1)/`TI)
`define ROW_FACTOR int'((`WIDTH+`ROW-1)/`ROW)
`define CFG_CI (`CI+1)*8
`define CFG_CO (`CO+1)*8
`define IFM_LEN int'(`CFG_CI*(`TI+`KK-1)*`TI_FACTOR*`ROW_FACTOR*(`ROW+`KK-1))
`define WGT_LEN int'(`KK*`KK*`CFG_CI*`CFG_CO*`ROW_FACTOR*`TI_FACTOR)

`define IFM_LEN_WORD `IFM_LEN/64
`define WGT_LEN_WORD `WGT_LEN/64

`define BUF_DEPTH 61
`define OFM_C `CFG_CO
`define OFM_H `BUF_DEPTH
`define OFM_W `BUF_DEPTH
`define OUT_DATA_WIDTH 25

//`define OFM_LEN `OFM_H*`OFM_W*`CFG_CO*4
`define OFM_LEN int'(4*`TI_FACTOR*`ROW_FACTOR*`CFG_CO*`TI*`ROW)

`define OFM_LEN_WORD `OFM_LEN/64


import axi_vip_pkg::*;
import axi_vip_mst_pkg::*;
import axi_vip_slv_pkg::*;

module tb_krnl_acc ();

// Kernel register address map
// Common Control Register 
parameter KRNL_CTRL_REG_ADDR     = 32'h00000000;
parameter CTRL_START_MASK        = 32'h00000001;
parameter CTRL_DONE_MASK         = 32'h00000002;
parameter CTRL_IDLE_MASK         = 32'h00000004;
parameter CTRL_READY_MASK        = 32'h00000008;
parameter CTRL_CONTINUE_MASK     = 32'h00000010; 
// krnl_acc argument
parameter ACC_CFG_CI      = 32'h0000_0010; 
parameter ACC_CFG_CO      = 32'h0000_0014;
parameter ACC_IFM_SIZE      = 32'h0000_0018; 
parameter ACC_WGT_SIZE      = 32'h0000_001C;  
parameter ACC_OFM_SIZE      = 32'h0000_0020;  
// parameter ACC_INPUT_WIDTH      = 32'h0000_001C; 
parameter ACC_ADDR_IFM_ADDR_BASE_0 = 32'h0000_0040;
parameter ACC_ADDR_IFM_ADDR_BASE_1 = 32'h0000_0044;
parameter ACC_ADDR_WGT_ADDR_BASE_0 = 32'h0000_0048;
parameter ACC_ADDR_WGT_ADDR_BASE_1 = 32'h0000_004C;
parameter ACC_ADDR_OFM_ADDR_BASE_0 = 32'h0000_0050;
parameter ACC_ADDR_OFM_ADDR_BASE_1 = 32'h0000_0054;

// input/output buffer base address definition
parameter IN_BUFFER_BASE0  = 64'h0000_0040_0000_0000;
parameter OUT_BUFFER_BASE0 = 64'h0000_0040_1000_0000;

parameter IN_BUFFER_BASE1  = 64'h0000_0050_0000_0000;
parameter OUT_BUFFER_BASE1 = 64'h0000_0050_1000_0000;

parameter IN_BUFFER_BASE2  = 64'h0000_0060_0000_0000;
parameter OUT_BUFFER_BASE2 = 64'h0000_0060_1000_0000;

parameter IN_BUFFER_BASE3  = 64'h0000_0070_0000_0000;
parameter OUT_BUFFER_BASE3 = 64'h0000_0070_1000_0000;

// clock frequency definition
parameter real CLK_PERIOD = 3.333; // 300MHz

//System Signals
logic ap_clk = 0;

initial begin: AP_CLK
  forever begin
    ap_clk = #(CLK_PERIOD/2) ~ap_clk;
  end
end
 
//System Signals
logic ap_rst_n = 0;

task automatic ap_rst_n_sequence(input integer unsigned width = 20);
  @(posedge ap_clk);
  #1ns;
  ap_rst_n = 0;
  repeat (width) @(posedge ap_clk);
  #1ns;
  ap_rst_n = 1;
endtask

initial begin: AP_RST
  ap_rst_n_sequence(50);
end


// connnection signal declare
  wire [31:0]   m_axi_acc_awaddr   ;   
  wire          m_axi_acc_awvalid  ;
  wire          m_axi_acc_awready  ;
  wire [31:0]   m_axi_acc_wdata    ;
  wire [3:0]    m_axi_acc_wstrb    ;
  wire          m_axi_acc_wvalid   ;
  wire          m_axi_acc_wready   ;
  wire [1:0]    m_axi_acc_bresp    ;
  wire          m_axi_acc_bvalid   ;
  wire          m_axi_acc_bready   ;
  wire [31:0]   m_axi_acc_araddr   ;
  wire          m_axi_acc_arvalid  ;
  wire          m_axi_acc_arready  ;
  wire [31:0]   m_axi_acc_rdata    ;
  wire [1:0]    m_axi_acc_rresp    ;
  wire          m_axi_acc_rvalid   ;
  wire          m_axi_acc_rready   ;

  wire [63:0]   s_axi_ifm_awaddr    ; 
  wire [7:0]    s_axi_ifm_awlen     ; 
  wire [1:0]    s_axi_ifm_awburst   ; 
  wire          s_axi_ifm_awvalid   ; 
  wire          s_axi_ifm_awready   ; 
  wire [511:0]  s_axi_ifm_wdata     ; 
  wire [63:0]   s_axi_ifm_wstrb     ; 
  wire          s_axi_ifm_wlast     ; 
  wire          s_axi_ifm_wvalid    ; 
  wire          s_axi_ifm_wready    ; 
  wire [1:0]    s_axi_ifm_bresp     ; 
  wire          s_axi_ifm_bvalid    ; 
  wire          s_axi_ifm_bready    ; 
  wire [63:0]   s_axi_ifm_araddr    ; 
  wire [7:0]    s_axi_ifm_arlen     ; 
  wire [1:0]    s_axi_ifm_arburst   ; 
  wire          s_axi_ifm_arvalid   ; 
  wire          s_axi_ifm_arready   ; 
  wire [511:0]  s_axi_ifm_rdata     ; 
  wire [1:0]    s_axi_ifm_rresp     ; 
  wire          s_axi_ifm_rlast     ; 
  wire          s_axi_ifm_rvalid    ; 
  wire          s_axi_ifm_rready    ;  

  wire [63:0]   s_axi_wgt_awaddr    ; 
  wire [7:0]    s_axi_wgt_awlen     ; 
  wire [1:0]    s_axi_wgt_awburst   ; 
  wire          s_axi_wgt_awvalid   ; 
  wire          s_axi_wgt_awready   ; 
  wire [511:0]  s_axi_wgt_wdata     ; 
  wire [63:0]   s_axi_wgt_wstrb     ; 
  wire          s_axi_wgt_wlast     ; 
  wire          s_axi_wgt_wvalid    ; 
  wire          s_axi_wgt_wready    ; 
  wire [1:0]    s_axi_wgt_bresp     ; 
  wire          s_axi_wgt_bvalid    ; 
  wire          s_axi_wgt_bready    ; 
  wire [63:0]   s_axi_wgt_araddr    ; 
  wire [7:0]    s_axi_wgt_arlen     ; 
  wire [1:0]    s_axi_wgt_arburst   ; 
  wire          s_axi_wgt_arvalid   ; 
  wire          s_axi_wgt_arready   ; 
  wire [511:0]  s_axi_wgt_rdata     ; 
  wire [1:0]    s_axi_wgt_rresp     ; 
  wire          s_axi_wgt_rlast     ; 
  wire          s_axi_wgt_rvalid    ; 
  wire          s_axi_wgt_rready    ; 

  wire [63:0]   s_axi_ofm_awaddr    ; 
  wire [7:0]    s_axi_ofm_awlen     ; 
  wire [1:0]    s_axi_ofm_awburst   ; 
  wire          s_axi_ofm_awvalid   ; 
  wire          s_axi_ofm_awready   ; 
  wire [511:0]  s_axi_ofm_wdata     ; 
  wire [63:0]   s_axi_ofm_wstrb     ; 
  wire          s_axi_ofm_wlast     ; 
  wire          s_axi_ofm_wvalid    ; 
  wire          s_axi_ofm_wready    ; 
  wire [1:0]    s_axi_ofm_bresp     ; 
  wire          s_axi_ofm_bvalid    ; 
  wire          s_axi_ofm_bready    ; 
  wire [63:0]   s_axi_ofm_araddr    ; 
  wire [7:0]    s_axi_ofm_arlen     ; 
  wire [1:0]    s_axi_ofm_arburst   ; 
  wire          s_axi_ofm_arvalid   ; 
  wire          s_axi_ofm_arready   ; 
  wire [511:0]  s_axi_ofm_rdata     ; 
  wire [1:0]    s_axi_ofm_rresp     ; 
  wire          s_axi_ofm_rlast     ; 
  wire          s_axi_ofm_rvalid    ; 
  wire          s_axi_ofm_rready    ;  


// instantiation of axi master vip for krnl_cbc
  axi_vip_mst axi_vip_mst_krnl_acc (
    .aclk           (ap_clk),           // input wire aclk
    .aresetn        (ap_rst_n),         // input wire aresetn
    .m_axi_awaddr   (m_axi_acc_awaddr),     // output wire [31 : 0] m_axi_awaddr
    .m_axi_awvalid  (m_axi_acc_awvalid),    // output wire m_axi_awvalid
    .m_axi_awready  (m_axi_acc_awready),    // input wire m_axi_awready
    .m_axi_wdata    (m_axi_acc_wdata),      // output wire [31 : 0] m_axi_wdata
    .m_axi_wstrb    (m_axi_acc_wstrb),      // output wire [3 : 0] m_axi_wstrb
    .m_axi_wvalid   (m_axi_acc_wvalid),     // output wire m_axi_wvalid
    .m_axi_wready   (m_axi_acc_wready),     // input wire m_axi_wready
    .m_axi_bresp    (m_axi_acc_bresp),      // input wire [1 : 0] m_axi_bresp
    .m_axi_bvalid   (m_axi_acc_bvalid),     // input wire m_axi_bvalid
    .m_axi_bready   (m_axi_acc_bready),     // output wire m_axi_bready
    .m_axi_araddr   (m_axi_acc_araddr),     // output wire [31 : 0] m_axi_araddr
    .m_axi_arvalid  (m_axi_acc_arvalid),    // output wire m_axi_arvalid
    .m_axi_arready  (m_axi_acc_arready),    // input wire m_axi_arready
    .m_axi_rdata    (m_axi_acc_rdata),      // input wire [31 : 0] m_axi_rdata
    .m_axi_rresp    (m_axi_acc_rresp),      // input wire [1 : 0] m_axi_rresp
    .m_axi_rvalid   (m_axi_acc_rvalid),     // input wire m_axi_rvalid
    .m_axi_rready   (m_axi_acc_rready)      // output wire m_axi_rready
);


// instantiation of axi slave vip for input buffer
  axi_vip_slv axi_vip_slv_ifm_buf (
    .aclk           (ap_clk),              // input wire aclk
    .aresetn        (ap_rst_n),            // input wire aresetn
    .s_axi_awaddr   (s_axi_ifm_awaddr),     // input wire [63 : 0] s_axi_awaddr
    .s_axi_awlen    (s_axi_ifm_awlen),      // input wire [7 : 0] s_axi_awlen
    .s_axi_awburst  (s_axi_ifm_awburst),    // input wire [1 : 0] s_axi_awburst
    .s_axi_awvalid  (s_axi_ifm_awvalid),    // input wire s_axi_awvalid
    .s_axi_awready  (s_axi_ifm_awready),    // output wire s_axi_awready
    .s_axi_wdata    (s_axi_ifm_wdata),      // input wire [127 : 0] s_axi_wdata
    .s_axi_wstrb    (s_axi_ifm_wstrb),      // input wire [15 : 0] s_axi_wstrb
    .s_axi_wlast    (s_axi_ifm_wlast),      // input wire s_axi_wlast
    .s_axi_wvalid   (s_axi_ifm_wvalid),     // input wire s_axi_wvalid
    .s_axi_wready   (s_axi_ifm_wready),     // output wire s_axi_wready
    .s_axi_bresp    (s_axi_ifm_bresp),      // output wire [1 : 0] s_axi_bresp
    .s_axi_bvalid   (s_axi_ifm_bvalid),     // output wire s_axi_bvalid
    .s_axi_bready   (s_axi_ifm_bready),     // input wire s_axi_bready
    .s_axi_araddr   (s_axi_ifm_araddr),     // input wire [63 : 0] s_axi_araddr
    .s_axi_arlen    (s_axi_ifm_arlen),      // input wire [7 : 0] s_axi_arlen
    .s_axi_arburst  (s_axi_ifm_arburst),    // input wire [1 : 0] s_axi_arburst
    .s_axi_arvalid  (s_axi_ifm_arvalid),    // input wire s_axi_arvalid
    .s_axi_arready  (s_axi_ifm_arready),    // output wire s_axi_arready
    .s_axi_rdata    (s_axi_ifm_rdata),      // output wire [127 : 0] s_axi_rdata
    .s_axi_rresp    (s_axi_ifm_rresp),      // output wire [1 : 0] s_axi_rresp
    .s_axi_rlast    (s_axi_ifm_rlast),      // output wire s_axi_rlast
    .s_axi_rvalid   (s_axi_ifm_rvalid),     // output wire s_axi_rvalid
    .s_axi_rready   (s_axi_ifm_rready)      // input wire s_axi_rready
);


// instantiation of axi slave vip for input buffer
  axi_vip_slv axi_vip_slv_wgt_buf (
    .aclk           (ap_clk),              // input wire aclk
    .aresetn        (ap_rst_n),            // input wire aresetn
    .s_axi_awaddr   (s_axi_wgt_awaddr),     // input wire [63 : 0] s_axi_awaddr
    .s_axi_awlen    (s_axi_wgt_awlen),      // input wire [7 : 0] s_axi_awlen
    .s_axi_awburst  (s_axi_wgt_awburst),    // input wire [1 : 0] s_axi_awburst
    .s_axi_awvalid  (s_axi_wgt_awvalid),    // input wire s_axi_awvalid
    .s_axi_awready  (s_axi_wgt_awready),    // output wire s_axi_awready
    .s_axi_wdata    (s_axi_wgt_wdata),      // input wire [127 : 0] s_axi_wdata
    .s_axi_wstrb    (s_axi_wgt_wstrb),      // input wire [15 : 0] s_axi_wstrb
    .s_axi_wlast    (s_axi_wgt_wlast),      // input wire s_axi_wlast
    .s_axi_wvalid   (s_axi_wgt_wvalid),     // input wire s_axi_wvalid
    .s_axi_wready   (s_axi_wgt_wready),     // output wire s_axi_wready
    .s_axi_bresp    (s_axi_wgt_bresp),      // output wire [1 : 0] s_axi_bresp
    .s_axi_bvalid   (s_axi_wgt_bvalid),     // output wire s_axi_bvalid
    .s_axi_bready   (s_axi_wgt_bready),     // input wire s_axi_bready
    .s_axi_araddr   (s_axi_wgt_araddr),     // input wire [63 : 0] s_axi_araddr
    .s_axi_arlen    (s_axi_wgt_arlen),      // input wire [7 : 0] s_axi_arlen
    .s_axi_arburst  (s_axi_wgt_arburst),    // input wire [1 : 0] s_axi_arburst
    .s_axi_arvalid  (s_axi_wgt_arvalid),    // input wire s_axi_arvalid
    .s_axi_arready  (s_axi_wgt_arready),    // output wire s_axi_arready
    .s_axi_rdata    (s_axi_wgt_rdata),      // output wire [127 : 0] s_axi_rdata
    .s_axi_rresp    (s_axi_wgt_rresp),      // output wire [1 : 0] s_axi_rresp
    .s_axi_rlast    (s_axi_wgt_rlast),      // output wire s_axi_rlast
    .s_axi_rvalid   (s_axi_wgt_rvalid),     // output wire s_axi_rvalid
    .s_axi_rready   (s_axi_wgt_rready)      // input wire s_axi_rready
);


  assign s_axi_ifm_awburst = 2'b01;
  assign s_axi_ifm_arburst = 2'b01;

  assign s_axi_wgt_awburst = 2'b01;
  assign s_axi_wgt_arburst = 2'b01;

// instantiation of axi slave vip for output buffer
  axi_vip_slv axi_vip_slv_ofm_buf (
    .aclk           (ap_clk),              // input wire aclk
    .aresetn        (ap_rst_n),            // input wire aresetn
    .s_axi_awaddr   (s_axi_ofm_awaddr),    // input wire [63 : 0] s_axi_awaddr
    .s_axi_awlen    (s_axi_ofm_awlen),     // input wire [7 : 0] s_axi_awlen
    .s_axi_awburst  (s_axi_ofm_awburst),   // input wire [1 : 0] s_axi_awburst
    .s_axi_awvalid  (s_axi_ofm_awvalid),   // input wire s_axi_awvalid
    .s_axi_awready  (s_axi_ofm_awready),   // output wire s_axi_awready
    .s_axi_wdata    (s_axi_ofm_wdata),     // input wire [127 : 0] s_axi_wdata
    .s_axi_wstrb    (s_axi_ofm_wstrb),     // input wire [15 : 0] s_axi_wstrb
    .s_axi_wlast    (s_axi_ofm_wlast),     // input wire s_axi_wlast
    .s_axi_wvalid   (s_axi_ofm_wvalid),    // input wire s_axi_wvalid
    .s_axi_wready   (s_axi_ofm_wready),    // output wire s_axi_wready
    .s_axi_bresp    (s_axi_ofm_bresp),     // output wire [1 : 0] s_axi_bresp
    .s_axi_bvalid   (s_axi_ofm_bvalid),    // output wire s_axi_bvalid
    .s_axi_bready   (s_axi_ofm_bready),    // input wire s_axi_bready
    .s_axi_araddr   (s_axi_ofm_araddr),    // input wire [63 : 0] s_axi_araddr
    .s_axi_arlen    (s_axi_ofm_arlen),     // input wire [7 : 0] s_axi_arlen
    .s_axi_arburst  (s_axi_ofm_arburst),   // input wire [1 : 0] s_axi_arburst
    .s_axi_arvalid  (s_axi_ofm_arvalid),   // input wire s_axi_arvalid
    .s_axi_arready  (s_axi_ofm_arready),   // output wire s_axi_arready
    .s_axi_rdata    (s_axi_ofm_rdata),     // output wire [127 : 0] s_axi_rdata
    .s_axi_rresp    (s_axi_ofm_rresp),     // output wire [1 : 0] s_axi_rresp
    .s_axi_rlast    (s_axi_ofm_rlast),     // output wire s_axi_rlast
    .s_axi_rvalid   (s_axi_ofm_rvalid),    // output wire s_axi_rvalid
    .s_axi_rready   (s_axi_ofm_rready)     // input wire s_axi_rready
);

  assign s_axi_ofm_awburst = 2'b01;
  assign s_axi_ofm_arburst = 2'b01;

// instantiation of krnl_cbc
 krnl_acc krnl_acc_inst (
// System Signals
    .ap_clk                 (ap_clk),
    .ap_rst_n               (ap_rst_n),

// AXI4-Lite slave interface
    .s_axi_control_awvalid   (m_axi_acc_awvalid),
    .s_axi_control_awready   (m_axi_acc_awready),
    .s_axi_control_awaddr    (m_axi_acc_awaddr[11:0]),
    .s_axi_control_wvalid    (m_axi_acc_wvalid),
    .s_axi_control_wready    (m_axi_acc_wready),
    .s_axi_control_wdata     (m_axi_acc_wdata),
    .s_axi_control_wstrb     (m_axi_acc_wstrb),
    .s_axi_control_arvalid   (m_axi_acc_arvalid),
    .s_axi_control_arready   (m_axi_acc_arready),
    .s_axi_control_araddr    (m_axi_acc_araddr[11:0]),
    .s_axi_control_rvalid    (m_axi_acc_rvalid),
    .s_axi_control_rready    (m_axi_acc_rready),
    .s_axi_control_rdata     (m_axi_acc_rdata),
    .s_axi_control_rresp     (m_axi_acc_rresp),
    .s_axi_control_bvalid    (m_axi_acc_bvalid),
    .s_axi_control_bready    (m_axi_acc_bready),
    .s_axi_control_bresp     (m_axi_acc_bresp),

// AXI read master interface
    .m_ifm_awvalid       (s_axi_ifm_awvalid),  
    .m_ifm_awready       (s_axi_ifm_awready),  
    .m_ifm_awaddr        (s_axi_ifm_awaddr), 
    .m_ifm_awlen         (s_axi_ifm_awlen),
    .m_ifm_wvalid        (s_axi_ifm_wvalid),
    .m_ifm_wready        (s_axi_ifm_wready),
    .m_ifm_wdata         (s_axi_ifm_wdata),
    .m_ifm_wstrb         (s_axi_ifm_wstrb),
    .m_ifm_wlast         (s_axi_ifm_wlast),
    .m_ifm_bvalid        (s_axi_ifm_bvalid),
    .m_ifm_bready        (s_axi_ifm_bready), 
    .m_ifm_arvalid       (s_axi_ifm_arvalid),
    .m_ifm_arready       (s_axi_ifm_arready),
    .m_ifm_araddr        (s_axi_ifm_araddr),
    .m_ifm_arlen         (s_axi_ifm_arlen),
    .m_ifm_rvalid        (s_axi_ifm_rvalid),
    .m_ifm_rready        (s_axi_ifm_rready),
    .m_ifm_rdata         (s_axi_ifm_rdata),
    .m_ifm_rlast         (s_axi_ifm_rlast),

// AXI read master interface
    .m_wgt_awvalid       (s_axi_wgt_awvalid),  
    .m_wgt_awready       (s_axi_wgt_awready),  
    .m_wgt_awaddr        (s_axi_wgt_awaddr), 
    .m_wgt_awlen         (s_axi_wgt_awlen),
    .m_wgt_wvalid        (s_axi_wgt_wvalid),
    .m_wgt_wready        (s_axi_wgt_wready),
    .m_wgt_wdata         (s_axi_wgt_wdata),
    .m_wgt_wstrb         (s_axi_wgt_wstrb),
    .m_wgt_wlast         (s_axi_wgt_wlast),
    .m_wgt_bvalid        (s_axi_wgt_bvalid),
    .m_wgt_bready        (s_axi_wgt_bready), 
    .m_wgt_arvalid       (s_axi_wgt_arvalid),
    .m_wgt_arready       (s_axi_wgt_arready),
    .m_wgt_araddr        (s_axi_wgt_araddr),
    .m_wgt_arlen         (s_axi_wgt_arlen),
    .m_wgt_rvalid        (s_axi_wgt_rvalid),
    .m_wgt_rready        (s_axi_wgt_rready),
    .m_wgt_rdata         (s_axi_wgt_rdata),
    .m_wgt_rlast         (s_axi_wgt_rlast),

// AXI write master interface
    .m_ofm_awvalid       (s_axi_ofm_awvalid),  
    .m_ofm_awready       (s_axi_ofm_awready),  
    .m_ofm_awaddr        (s_axi_ofm_awaddr), 
    .m_ofm_awlen         (s_axi_ofm_awlen),
    .m_ofm_wvalid        (s_axi_ofm_wvalid),
    .m_ofm_wready        (s_axi_ofm_wready),
    .m_ofm_wdata         (s_axi_ofm_wdata),
    .m_ofm_wstrb         (s_axi_ofm_wstrb),
    .m_ofm_wlast         (s_axi_ofm_wlast),
    .m_ofm_bvalid        (s_axi_ofm_bvalid),
    .m_ofm_bready        (s_axi_ofm_bready), 
    .m_ofm_arvalid       (s_axi_ofm_arvalid),
    .m_ofm_arready       (s_axi_ofm_arready),
    .m_ofm_araddr        (s_axi_ofm_araddr),
    .m_ofm_arlen         (s_axi_ofm_arlen),
    .m_ofm_rvalid        (s_axi_ofm_rvalid),
    .m_ofm_rready        (s_axi_ofm_rready),
    .m_ofm_rdata         (s_axi_ofm_rdata),
    .m_ofm_rlast         (s_axi_ofm_rlast)
);
  
  axi_vip_mst_mst_t krnl_acc_ctrl;
  axi_vip_slv_slv_mem_t ifm_buffer;
  axi_vip_slv_slv_mem_t wgt_buffer;
  axi_vip_slv_slv_mem_t ofm_buffer;


`include "tb_krnl_acc.vh"

  // handle the data processing for all groups
  task automatic conv_processing (input axi_vip_mst_mst_t ctrl, input bit [63:0] ifm_buffer, input bit [63:0] wgt_buffer, input bit [63:0] ofm_buffer);
    int input_groups = 0;
    int output_groups = 0;
    bit [31:0] rd_value;
    bit [63:0] temp_addr;
    bit [31:0] addr_lsb, addr_msb;

    forever begin
      read_register(ctrl, KRNL_CTRL_REG_ADDR, rd_value);

      //$display($time, "rd_value = %x", rd_value);

      // input sync
      if (input_groups < `GROUP_NUM) begin
        if (!(rd_value & CTRL_START_MASK)) begin
          temp_addr =  ifm_buffer + input_groups * `IFM_LEN;
          addr_msb = temp_addr[63:32];
          addr_lsb = temp_addr[31:0];
          blocking_write_register (ctrl, ACC_ADDR_IFM_ADDR_BASE_0, addr_lsb);// input buffer base address in axi slave vip
          blocking_write_register (ctrl, ACC_ADDR_IFM_ADDR_BASE_1, addr_msb);
          temp_addr =  wgt_buffer + input_groups * `WGT_LEN;
          addr_msb = temp_addr[63:32];
          addr_lsb = temp_addr[31:0];
          blocking_write_register (ctrl, ACC_ADDR_WGT_ADDR_BASE_0, addr_lsb);// input buffer base address in axi slave vip
          blocking_write_register (ctrl, ACC_ADDR_WGT_ADDR_BASE_1, addr_msb);
          temp_addr = ofm_buffer + input_groups * `OFM_LEN;
          addr_msb = temp_addr[63:32];
          addr_lsb = temp_addr[31:0];
          blocking_write_register (ctrl, ACC_ADDR_OFM_ADDR_BASE_0, addr_lsb);// output buffer base address in axi slave vip
          blocking_write_register (ctrl, ACC_ADDR_OFM_ADDR_BASE_1, addr_msb);   
          blocking_write_register (ctrl, KRNL_CTRL_REG_ADDR, CTRL_START_MASK);
          $display($time,, " [INPUT SYNC] ap_start low detected, assert ap_start for group %2d", input_groups);
          input_groups++;
        end
      end


      read_register(ctrl, KRNL_CTRL_REG_ADDR, rd_value);
      // output sync
      if (output_groups < `GROUP_NUM) begin
        if (rd_value & CTRL_DONE_MASK) begin
          blocking_write_register(ctrl, KRNL_CTRL_REG_ADDR, CTRL_CONTINUE_MASK);
          $write("%c[1;34m",27);
          $display($time,, " [OUTPUT SYNC] ap_done for group %2d detected, assert ap_continue", output_groups);
          $write("%c[0m",27); 
          output_groups++;
        end
      end
      
      if (output_groups == `GROUP_NUM) begin
        break;
      end
    end
  endtask


    reg signed [31:0] ofm [0:`OFM_C-1][0:`OFM_H-1][0:`OFM_W-1];
    integer toc;
    integer toh;
    integer tow;
    reg stop_flag;

initial  begin : main_test_routine
    
    int     i, j, k;
    int     temp;
    int     mismatch;
    int     start_time;
    int     finish_time;
    int     enc_fail;
    int     dec_fail;

    bit [511:0] ifm_data[0:`IFM_LEN_WORD * `GROUP_NUM - 1];
    bit [511:0] wgt_data[0:`WGT_LEN_WORD * `GROUP_NUM - 1];
    bit [511:0] ofm_data[0:`OFM_LEN_WORD * `GROUP_NUM - 1];
    
    bit [31:0]  reg_read_data;
    bit [31:0]  reg_rw_addr; 
  

    int file_ptr;
    int fp_w;

    int toc, toh, tow;
    int oc, oh, tw, index;
    int thcnt;

    int ifm_size = `IFM_LEN;
    int wgt_size = `WGT_LEN;
    int ofm_size = `OFM_LEN;
    int ofm_len_word = `OFM_LEN_WORD;

//    file_ptr = $fopen("./script/test/ifm.dat", "rb");
//    file_ptr = $fopen("../common/ifm.dat", "rb");
    file_ptr = $fopen("./data/ifm.dat", "rb");
    $display ("IFM_DATA SIZE : %d" , ifm_size);
    temp = $fread(ifm_data, file_ptr);
    $fclose(file_ptr);    
    file_ptr = $fopen("./data/wgt.dat", "rb");
      $display ("WGT_DATA SIZE : %d" , wgt_size);
    temp = $fread(wgt_data, file_ptr);
    $fclose(file_ptr); 

        $display ("OFM_DATA SIZE : %d" , ofm_size);
        $display ("INPUT SIZE : %d" , `IW);

        $display("OFM_LEN_WORD : %d", ofm_len_word);

    #2000
        init_vips();

    #1000


    #1000
    $display("-------------------------------------------------------------------------------------");
    $display("  CONVOLUTION ACCLEALATOR TEST, total %1d groups", `GROUP_NUM);
    $display("-------------------------------------------------------------------------------------");    
    // set kernel registers                      
    blocking_write_register (krnl_acc_ctrl, ACC_CFG_CI, 32'd`CI);                 // CI = 0 >> CFG_CI = 8 = 8*(CI+1)
    blocking_write_register (krnl_acc_ctrl, ACC_CFG_CO, 32'd`CO);                 // CO = 0 >> CFG_CI = 8 = 8*(CI+1)
    // blocking_write_register (krnl_acc_ctrl, ACC_INPUT_WIDTH, 32'd`IW);

    blocking_write_register (krnl_acc_ctrl, ACC_IFM_SIZE, ifm_size[31:0]);                 // ifm_size 63232
    blocking_write_register (krnl_acc_ctrl, ACC_WGT_SIZE, wgt_size[31:0]);                 // wgt_size 53248
    blocking_write_register (krnl_acc_ctrl, ACC_OFM_SIZE, ofm_size[31:0]);

    // fill input buffer memory with plain data
    in_buffer_fill_memory(ifm_buffer, IN_BUFFER_BASE0, ifm_data, 0, `IFM_LEN_WORD*`GROUP_NUM);   
    in_buffer_fill_memory(wgt_buffer, IN_BUFFER_BASE1, wgt_data, 0, `WGT_LEN_WORD*`GROUP_NUM);   

    // run ap_ctrl_chain mode processing     
    conv_processing (krnl_acc_ctrl, IN_BUFFER_BASE0, IN_BUFFER_BASE1, OUT_BUFFER_BASE2);

    // dump output buffer memory data
    out_buffer_dump_memory(ofm_buffer, OUT_BUFFER_BASE2, ofm_data, 0, `OFM_LEN_WORD*`GROUP_NUM);

    #1000
    $display("-------------------------------------------------------------------------------------");
    $display("  PROCESS COMPLITED    ");
    $display("-------------------------------------------------------------------------------------");
  

    //Data compare
    fp_w = $fopen("./data/conv_acc_out.txt");
            // if (oc <= `OFM_C-1) begin
//            if(!end_op) begin
            for(j=0; j < `GROUP_NUM; j++) begin
                  toc = 0;
                  toh = 0;
                  tow = 0;
                  oc = 0;
                  oh = 0;
                  tw = 0;
                  thcnt = 0;
                  for(index = 0; index < `OFM_LEN_WORD; index++) begin
                    for(i = 0; i < 16; i=i+1) begin
//                      ofm[oc][oh][i+tw*`TI] = ofm_data[`OFM_LEN_WORD*j + index][32*(i+1)-1 -: 32];
                      for(k = 0; k < 4; k=k+1)begin
                        ofm[oc][oh][i+tw*`TI][k*8 +: 8] = ofm_data[ofm_len_word*j + index][(32*(15-i)+(3-k)*8) +: 8];
                      end
                    end
                    oh = oh + 1;
                    thcnt = thcnt + 1;
                          if (thcnt == 5) begin
                              thcnt = 0;
                              tw = tw + 1;
                              oh = oh - 5;
                              if (tw == 4) begin
                                  tw = 0;
                                  oh = oh + 5;
                              end
                          end
                          if (oh == 65) begin
                              oh = 0;
                              oc = oc + 1;
                              $display("\033[33m[ConvKernel: ] Computing channel: %d\033[0m", oc);
                          end
                  end

                  for (toc=0; toc < `OFM_C; toc = toc + 1) begin
                      $fwrite(fp_w, "\n\n");
                      for (toh=0; toh < `OFM_H; toh = toh + 1) begin
                          for (tow=0; tow < `OFM_W; tow = tow + 1) begin
                              $fwrite(fp_w, "%d ", ofm[toc][toh][tow]);
                              if (tow == `OFM_W-1) begin
                                  $fwrite(fp_w, "\n");
                              end
                          end
                      end
                  end
                      $display("\033[32m[ConvKernel: %d] Finish writing results to conv_acc_out.txt\033[0m", j); 
            end
            $fclose(fp_w);

    #1000 $finish;

end


// Waveform dump
`ifdef DUMP_WAVEFORM
  initial begin
    $dumpfile("tb_krnl_acc.vcd");
    $dumpvars(0,tb_krnl_acc);
  end
`endif


endmodule
