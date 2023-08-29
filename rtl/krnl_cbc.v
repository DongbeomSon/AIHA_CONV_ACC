//
//
//# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
//# SPDX-License-Identifier: X11
//
//

`timescale 1ns/1ps

module krnl_cbc #(
  parameter integer DATA_WIDTH  = 512,
  parameter integer WORD_BYTE = DATA_WIDTH/8
)(
// System Signals
    input             ap_clk,
    input             ap_rst_n,

// AXI4-Lite slave interface
    input             s_axi_control_awvalid,
    output            s_axi_control_awready,
    input   [11:0]    s_axi_control_awaddr ,
    input             s_axi_control_wvalid ,
    output            s_axi_control_wready ,
    input   [31:0]    s_axi_control_wdata  ,
    input   [3:0]     s_axi_control_wstrb  ,
    input             s_axi_control_arvalid,
    output            s_axi_control_arready,
    input   [11:0]    s_axi_control_araddr ,
    output            s_axi_control_rvalid ,
    input             s_axi_control_rready ,
    output  [31:0]    s_axi_control_rdata  ,
    output  [1:0]     s_axi_control_rresp  ,
    output            s_axi_control_bvalid ,
    input             s_axi_control_bready ,
    output  [1:0]     s_axi_control_bresp,

// AXI read master interface
    // write channels (not used)
    output            axi_rmst_awvalid,
    input             axi_rmst_awready,
    output  [63:0]    axi_rmst_awaddr ,
    output  [7:0]     axi_rmst_awlen  ,
    output            axi_rmst_wvalid ,
    input             axi_rmst_wready ,
    output  [DATA_WIDTH-1:0]   axi_rmst_wdata  ,
    output  [63:0]    axi_rmst_wstrb  ,
    output            axi_rmst_wlast  ,
    input             axi_rmst_bvalid ,
    output            axi_rmst_bready ,   
    // read channels
    output            axi_rmst_arvalid,
    input             axi_rmst_arready,
    output  [63:0]    axi_rmst_araddr,
    output  [7:0]     axi_rmst_arlen,
    input             axi_rmst_rvalid,
    output            axi_rmst_rready,
    input   [DATA_WIDTH-1:0]   axi_rmst_rdata,
    input             axi_rmst_rlast,

// AXI write master interface
    // write channels
    output            axi_wmst_awvalid,
    input             axi_wmst_awready,
    output  [63:0]    axi_wmst_awaddr,
    output  [7:0]     axi_wmst_awlen,
    output            axi_wmst_wvalid,
    input             axi_wmst_wready,
    output  [DATA_WIDTH-1:0]   axi_wmst_wdata,
    output  [63:0]    axi_wmst_wstrb,
    output            axi_wmst_wlast,
    input             axi_wmst_bvalid,
    output            axi_wmst_bready,
    // read channels (not used)
    output            axi_wmst_arvalid,
    input             axi_wmst_arready,
    output  [63:0]    axi_wmst_araddr,
    output  [7:0]     axi_wmst_arlen,
    input             axi_wmst_rvalid,
    output            axi_wmst_rready,
    input   [DATA_WIDTH-1:0]   axi_wmst_rdata,
    input             axi_wmst_rlast
);

// internel connection signals
    wire            ap_start;
    wire            ap_continue;
    wire            ap_idle;
    wire            ap_done;
    wire            ap_ready;
    
    wire            mode;
    wire            cbc_mode;
    // wire    [DATA_WIDTH-1:0] iv;
    wire    [63:0]  src_addr;
    wire    [63:0]  dest_addr;
    wire    [31:0]  words_num;

    wire            rmst_start;
    wire            rmst_done;
    wire    [63:0]  rmst_addr_offset;
    wire    [63:0]  rmst_xfer_size_in_bytes;
    wire            rmst_axis_tvalid;
    wire            rmst_axis_tready;
    wire            rmst_axis_tlast;
    wire    [DATA_WIDTH-1:0] rmst_axis_tdata;
    wire    [DATA_WIDTH-1:0] rmst_axis_tdata_little_endian;  // in global memory, data are stored in little-endian
                                                    // so need to be reordered for AES definition

    wire            rmst_axis_tready_0;
    wire    [DATA_WIDTH-1:0] rmst_axis_tdata_0;
    wire            rmst_axis_tvalid_0;
    wire            wmst_axis_tvalid_0;
    wire    [DATA_WIDTH-1:0] wmst_axis_tdata_0;
    wire            wmst_axis_tready_0;

    // wire            rmst_axis_tready_1;
    // wire    [DATA_WIDTH-1:0] rmst_axis_tdata_1;
    // wire            rmst_axis_tvalid_1;
    // wire            wmst_axis_tvalid_1;
    // wire    [DATA_WIDTH-1:0] wmst_axis_tdata_1;
    // wire            wmst_axis_tready_1;

    // wire            rmst_axis_tready_2;
    // wire    [DATA_WIDTH-1:0] rmst_axis_tdata_2;
    // wire            rmst_axis_tvalid_2;
    // wire            wmst_axis_tvalid_2;
    // wire    [DATA_WIDTH-1:0] wmst_axis_tdata_2;
    // wire            wmst_axis_tready_2;

    // wire            rmst_axis_tready_3;
    // wire    [DATA_WIDTH-1:0] rmst_axis_tdata_3;
    // wire            rmst_axis_tvalid_3;
    // wire            wmst_axis_tvalid_3;
    // wire    [DATA_WIDTH-1:0] wmst_axis_tdata_3;
    // wire            wmst_axis_tready_3;        

    wire            wmst_start;
    wire            wmst_done;
    wire    [63:0]  wmst_addr_offset;
    wire    [63:0]  wmst_xfer_size_in_bytes;
    wire            wmst_axis_tvalid;
    wire            wmst_axis_tready;
    wire    [DATA_WIDTH-1:0] wmst_axis_tdata;
    wire    [DATA_WIDTH-1:0] wmst_axis_tdata_little_endian;  // in global memory, data are stored in little-endian
                                                    // so need to be reordered for AES definition

    wire            wmst_req_0;
    wire    [63:0]  wmst_xfer_addr_0;
    wire    [63:0]  wmst_xfer_size_0;
    wire            wmst_req_1;
    wire    [63:0]  wmst_xfer_addr_1;
    wire    [63:0]  wmst_xfer_size_1;
    wire            wmst_req_2;
    wire    [63:0]  wmst_xfer_addr_2;
    wire    [63:0]  wmst_xfer_size_2;
    wire            wmst_req_3;
    wire    [63:0]  wmst_xfer_addr_3;
    wire    [63:0]  wmst_xfer_size_3;

    wire            op_start_0;
    wire            op_start_1;
    wire            op_start_2;
    wire            op_start_3;


// tie-off not used axi master signals
    assign axi_rmst_awvalid = 1'b0;
    assign axi_rmst_awaddr  = 64'b0;
    assign axi_rmst_awlen   = 8'b0;
    assign axi_rmst_wvalid  = 1'b0;
    assign axi_rmst_wdata   = 512'b0;
    assign axi_rmst_wstrb   = 16'b0;
    assign axi_rmst_wlast   = 1'b0;
    assign axi_rmst_bready  = 1'b1;   

    assign axi_wmst_arvalid = 1'b0;
    assign axi_wmst_araddr  = 64'b0;
    assign axi_wmst_arlen   = 8'b0;
    assign axi_wmst_rready  = 1'b1;

// instantiation of axi control slave
  krnl_cbc_axi_ctrl_slave  u_krnl_cbc_axi_ctrl_slave (
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
    .cbc_mode       (cbc_mode),  
    .src_addr       (src_addr),
    .dest_addr      (dest_addr),
    .words_num      (words_num)
);


// instantiation of axi read master
  axi_read_master  #(
    .C_M_AXI_ADDR_WIDTH     (64),
    .C_M_AXI_DATA_WIDTH     (DATA_WIDTH),
    .C_XFER_SIZE_WIDTH      (WORD_BYTE),
    .C_MAX_BURST_LENGTH     (16),           // This affect ctrl_addr_offset alignment requirement. Set to 16 means 256-bytes alignment
    .C_INCLUDE_DATA_FIFO    (0)             // disable axi master fifo
  )
        u_axi_read_master (
    .aclk                       (ap_clk),
    .areset                     (!ap_rst_n),

    .ctrl_start                 (rmst_start),
    .ctrl_done                  (rmst_done),
    .ctrl_addr_offset           (rmst_addr_offset),
    .ctrl_xfer_size_in_bytes    (rmst_xfer_size_in_bytes),

    .m_axi_arvalid              (axi_rmst_arvalid),
    .m_axi_arready              (axi_rmst_arready),
    .m_axi_araddr               (axi_rmst_araddr),
    .m_axi_arlen                (axi_rmst_arlen),
    .m_axi_rvalid               (axi_rmst_rvalid),
    .m_axi_rready               (axi_rmst_rready),
    .m_axi_rdata                (axi_rmst_rdata),
    .m_axi_rlast                (axi_rmst_rlast),

    .m_axis_tvalid              (rmst_axis_tvalid),
    .m_axis_tready              (rmst_axis_tready),
    .m_axis_tlast               (rmst_axis_tlast),
    .m_axis_tdata               (rmst_axis_tdata_little_endian)
);  

    assign rmst_addr_offset = src_addr;
    assign rmst_xfer_size_in_bytes = words_num * 64;
    
    // data endian conversion
    generate
        genvar i;
        for (i = 0; i < WORD_BYTE; i = i + 1) begin : input_endian_convert
            assign rmst_axis_tdata[i*8+7 : i*8] = rmst_axis_tdata_little_endian[(WORD_BYTE-1-i)*8+7 : (WORD_BYTE-1-i)*8];
        end
    endgenerate

// instantiation of axi write master
  axi_write_master #(
    .C_M_AXI_ADDR_WIDTH     (64),
    .C_M_AXI_DATA_WIDTH     (DATA_WIDTH),
    .C_XFER_SIZE_WIDTH      (WORD_BYTE),
    .C_MAX_BURST_LENGTH     (16),           // This affect ctrl_addr_offset alignment requirement. Set to 16 means 256-bytes alignment
    .C_INCLUDE_DATA_FIFO    (0)             // disable axi master fifo
  )
        u_axi_write_master (
    .aclk                       (ap_clk),
    .areset                     (!ap_rst_n),

    .ctrl_start                 (wmst_start),              
    .ctrl_done                  (wmst_done),               
    .ctrl_addr_offset           (wmst_addr_offset),        
    .ctrl_xfer_size_in_bytes    (wmst_xfer_size_in_bytes), 

    .m_axi_awvalid              (axi_wmst_awvalid),
    .m_axi_awready              (axi_wmst_awready),
    .m_axi_awaddr               (axi_wmst_awaddr),
    .m_axi_awlen                (axi_wmst_awlen),
    .m_axi_wvalid               (axi_wmst_wvalid),
    .m_axi_wready               (axi_wmst_wready),
    .m_axi_wdata                (axi_wmst_wdata),
    .m_axi_wstrb                (axi_wmst_wstrb),
    .m_axi_wlast                (axi_wmst_wlast),
    .m_axi_bvalid               (axi_wmst_bvalid),
    .m_axi_bready               (axi_wmst_bready),
                
    .s_axis_tvalid              (wmst_axis_tvalid),
    .s_axis_tready              (wmst_axis_tready),
    .s_axis_tdata               (wmst_axis_tdata_little_endian)
);

    // data endian conversion
    generate
        genvar j;
        for (j = 0; j < WORD_BYTE; j = j + 1) begin : output_endian_convert
            assign wmst_axis_tdata_little_endian[j*8+7 : j*8] = wmst_axis_tdata[(WORD_BYTE-1-j)*8+7 : (WORD_BYTE-1-j)*8];
        end
    endgenerate

// instantiation of engine control
  engine_control u_engine_control (
    .aclk                       (ap_clk),
    .areset_n                   (ap_rst_n),

    .axis_slv_rmst_tvalid_in    (rmst_axis_tvalid),
    .axis_slv_rmst_tdata_in     (rmst_axis_tdata),
    .axis_slv_rmst_tready_out   (rmst_axis_tready),
    .axis_slv_rmst_tready_in_0  (rmst_axis_tready_0),
    // .axis_slv_rmst_tready_in_1  (rmst_axis_tready_1),
    // .axis_slv_rmst_tready_in_2  (rmst_axis_tready_2),
    // .axis_slv_rmst_tready_in_3  (rmst_axis_tready_3),
    .axis_slv_rmst_tvalid_out_0 (rmst_axis_tvalid_0),
    // .axis_slv_rmst_tvalid_out_1 (rmst_axis_tvalid_1),
    // .axis_slv_rmst_tvalid_out_2 (rmst_axis_tvalid_2),
    // .axis_slv_rmst_tvalid_out_3 (rmst_axis_tvalid_3),
    .axis_slv_rmst_tdata_out_0  (rmst_axis_tdata_0),
    // .axis_slv_rmst_tdata_out_1  (rmst_axis_tdata_1),
    // .axis_slv_rmst_tdata_out_2  (rmst_axis_tdata_2),
    // .axis_slv_rmst_tdata_out_3  (rmst_axis_tdata_3),

    .axis_mst_wmst_tready_in    (wmst_axis_tready),
    .axis_mst_wmst_tready_out_0 (wmst_axis_tready_0),
    // .axis_mst_wmst_tready_out_1 (wmst_axis_tready_1),
    // .axis_mst_wmst_tready_out_2 (wmst_axis_tready_2),
    // .axis_mst_wmst_tready_out_3 (wmst_axis_tready_3),
    .axis_mst_wmst_tvalid_out   (wmst_axis_tvalid),
    .axis_mst_wmst_tdata_out    (wmst_axis_tdata),
    .axis_mst_wmst_tvalid_in_0  (wmst_axis_tvalid_0),
    .axis_mst_wmst_tdata_in_0   (wmst_axis_tdata_0),
    // .axis_mst_wmst_tvalid_in_1  (wmst_axis_tvalid_1),
    // .axis_mst_wmst_tdata_in_1   (wmst_axis_tdata_1),
    // .axis_mst_wmst_tvalid_in_2  (wmst_axis_tvalid_2),
    // .axis_mst_wmst_tdata_in_2   (wmst_axis_tdata_2),
    // .axis_mst_wmst_tvalid_in_3  (wmst_axis_tvalid_3),
    // .axis_mst_wmst_tdata_in_3   (wmst_axis_tdata_3),             

    .rmst_req_out               (rmst_start),
    .rmst_done                  (rmst_done),

    .wmst_req_out               (wmst_start),
    .wmst_xfer_addr_out         (wmst_addr_offset),
    .wmst_xfer_size_out         (wmst_xfer_size_in_bytes),
    .wmst_done                  (wmst_done),
    .wmst_req_in_0              (wmst_req_0),
    .wmst_xfer_addr_in_0        (wmst_xfer_addr_0),
    .wmst_xfer_size_in_0        (wmst_xfer_size_0),
    // .wmst_req_in_1              (wmst_req_1),
    // .wmst_xfer_addr_in_1        (wmst_xfer_addr_1),
    // .wmst_xfer_size_in_1        (wmst_xfer_size_1),
    // .wmst_req_in_2              (wmst_req_2),
    // .wmst_xfer_addr_in_2        (wmst_xfer_addr_2),
    // .wmst_xfer_size_in_2        (wmst_xfer_size_2),
    // .wmst_req_in_3              (wmst_req_3),
    // .wmst_xfer_addr_in_3        (wmst_xfer_addr_3),
    // .wmst_xfer_size_in_3        (wmst_xfer_size_3),

    .ap_start                   (ap_start),
    .ap_continue                (ap_continue),
    .ap_ready                   (ap_ready),
    .ap_done                    (ap_done),
    .ap_idle                    (ap_idle),

    .op_start_0                 (op_start_0)
    // .op_start_1                 (op_start_1),
    // .op_start_2                 (op_start_2),
    // .op_start_3                 (op_start_3)
);


// instantiation of cbc_engine_0
  add_engine u_add_engine_0 (
    .aclk                   (ap_clk),
    .areset_n               (ap_rst_n),

    .mode                   (mode),  
    // .cbc_mode               (cbc_mode),                 
    // .IV                     (iv),                     
    .words_num              (words_num[9:0]),              
    .op_start               (op_start_0),                                  
    .write_addr             (dest_addr),             

    .axis_slv_rmst_tvalid   (rmst_axis_tvalid_0),
    .axis_slv_rmst_tdata    (rmst_axis_tdata_0),
    .axis_slv_rmst_tready   (rmst_axis_tready_0),

    .axis_mst_wmst_tvalid   (wmst_axis_tvalid_0),
    .axis_mst_wmst_tready   (wmst_axis_tready_0),
    .axis_mst_wmst_tdata    (wmst_axis_tdata_0),

    // .axis_slv_aes_tvalid    (axis_slv0_tvalid),
    // .axis_slv_aes_tdata     (axis_slv0_tdata),
    // .axis_slv_aes_tready    (axis_slv0_tready),

    // .axis_mst_aes_tvalid    (axis_mst0_tvalid),
    // .axis_mst_aes_tready    (axis_mst0_tready),
    // .axis_mst_aes_tdata     (axis_mst0_tdata),

    .wmst_req               (wmst_req_0),
    .wmst_xfer_addr         (wmst_xfer_addr_0),
    .wmst_xfer_size         (wmst_xfer_size_0)  
);

endmodule
