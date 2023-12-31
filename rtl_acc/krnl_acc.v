//`default_nettype none
`timescale 1ns/1ps

module krnl_acc #(
  parameter integer C_M_AXI_ADDR_WIDTH       = 64 ,
  parameter integer C_M_AXI_DATA_WIDTH       = 512,
  parameter integer C_XFER_SIZE_WIDTH        = 32,
  parameter integer C_ADDER_BIT_WIDTH        = 32,
  parameter integer DATA_WIDTH = 512,
parameter integer WORD_BYTE = DATA_WIDTH/8,

    parameter IFM_BUFF_WORD_NUM = 4,
    parameter IFM_BUFF_ADDR_WIDTH  = $clog2(IFM_BUFF_WORD_NUM) + 1,
    parameter WGT_BUFF_WORD_NUM = 4,
    parameter WGT_BUFF_ADDR_WIDTH  = $clog2(WGT_BUFF_WORD_NUM) + 1
)
(
  // System Signals
  input wire                                    ap_clk               ,
  input wire                                    ap_rst_n             ,


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


  // AXI4 master interface
  //ofm ch
  output wire                                   m_ofm_awvalid      ,
  input wire                                    m_ofm_awready      ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          m_ofm_awaddr       ,
  output wire [8-1:0]                           m_ofm_awlen        ,
  output wire                                   m_ofm_wvalid       ,
  input wire                                    m_ofm_wready       ,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          m_ofm_wdata        ,
  output wire [C_M_AXI_DATA_WIDTH/8-1:0]        m_ofm_wstrb        ,
  output wire                                   m_ofm_wlast        ,
  input wire                                    m_ofm_bvalid       ,
  output wire                                   m_ofm_bready       ,

  //ifm ch
  output wire                                   m_ifm_arvalid      ,
  input wire                                    m_ifm_arready      ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          m_ifm_araddr       ,
  output wire [8-1:0]                           m_ifm_arlen        ,
  input wire                                    m_ifm_rvalid       ,
  output wire                                   m_ifm_rready       ,
  input wire [C_M_AXI_DATA_WIDTH-1:0]           m_ifm_rdata        ,
  input wire                                    m_ifm_rlast        ,

  //wgt ch
  output wire                                   m_wgt_arvalid      ,
  input wire                                    m_wgt_arready      ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          m_wgt_araddr       ,
  output wire [8-1:0]                           m_wgt_arlen        ,
  input wire                                    m_wgt_rvalid       ,
  output wire                                   m_wgt_rready       ,
  input wire [C_M_AXI_DATA_WIDTH-1:0]           m_wgt_rdata        ,
  input wire                                    m_wgt_rlast        ,


  //not used channel
  output wire                                   m_ofm_arvalid      ,
  input wire                                    m_ofm_arready      ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          m_ofm_araddr       ,
  output wire [8-1:0]                           m_ofm_arlen        ,
  input wire                                    m_ofm_rvalid       ,
  output wire                                   m_ofm_rready       ,
  input wire [C_M_AXI_DATA_WIDTH-1:0]           m_ofm_rdata        ,
  input wire                                    m_ofm_rlast        ,

  output wire                                   m_ifm_awvalid      ,
  input wire                                    m_ifm_awready      ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          m_ifm_awaddr       ,
  output wire [8-1:0]                           m_ifm_awlen        ,
  output wire                                   m_ifm_wvalid       ,
  input wire                                    m_ifm_wready       ,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          m_ifm_wdata        ,
  output wire [C_M_AXI_DATA_WIDTH/8-1:0]        m_ifm_wstrb        ,
  output wire                                   m_ifm_wlast        ,
  input wire                                    m_ifm_bvalid       ,
  output wire                                   m_ifm_bready       ,

  output wire                                   m_wgt_awvalid      ,
  input wire                                    m_wgt_awready      ,
  output wire [C_M_AXI_ADDR_WIDTH-1:0]          m_wgt_awaddr       ,
  output wire [8-1:0]                           m_wgt_awlen        ,
  output wire                                   m_wgt_wvalid       ,
  input wire                                    m_wgt_wready       ,
  output wire [C_M_AXI_DATA_WIDTH-1:0]          m_wgt_wdata        ,
  output wire [C_M_AXI_DATA_WIDTH/8-1:0]        m_wgt_wstrb        ,
  output wire                                   m_wgt_wlast        ,
  input wire                                    m_wgt_bvalid       ,
  output wire                                   m_wgt_bready       


);

  // tie-off not used channel interface
  assign m_ofm_arvalid = 1'b0;
  assign m_ofm_araddr  = 64'b0;
  assign m_ofm_arlen   = 8'b0;
  assign m_ofm_rready  = 1'b1;

  assign m_ifm_awvalid = 1'b0;
  assign m_ifm_awaddr  = 64'b0;
  assign m_ifm_awlen   = 8'b0;
  assign m_ifm_wvalid  = 1'b0;
  assign m_ifm_wdata   = 512'b0;
  assign m_ifm_wstrb   = 16'b0;
  assign m_ifm_wlast   = 1'b0;
  assign m_ifm_bready  = 1'b1; 

  assign m_wgt_awvalid = 1'b0;
  assign m_wgt_awaddr  = 64'b0;
  assign m_wgt_awlen   = 8'b0;
  assign m_wgt_wvalid  = 1'b0;
  assign m_wgt_wdata   = 512'b0;
  assign m_wgt_wstrb   = 16'b0;
  assign m_wgt_wlast   = 1'b0;
  assign m_wgt_bready  = 1'b1; 


  // internal control singnal

  wire [C_M_AXI_ADDR_WIDTH-1:0]           ifm_addr_base;
  wire [C_M_AXI_ADDR_WIDTH-1:0]           wgt_addr_base;
  wire [C_M_AXI_ADDR_WIDTH-1:0]           ofm_addr_base;
  wire [31:0]                             cfg_ci;
  wire [31:0]                             cfg_co;
  // wire [31:0]                             input_width;
  wire [31:0]                             ifm_size;
  wire [31:0]                             wgt_size;
  wire [31:0]                             ofm_size;

  wire  ap_start;
  wire  ap_done;
  wire  ap_idle;
  wire  ap_ready;
  wire  ap_continue;

  // reg [C_M_AXI_ADDR_WIDTH-1:0]           r_ifm_addr_base;
  // reg [C_M_AXI_ADDR_WIDTH-1:0]           r_wgt_addr_base;
  // reg [C_M_AXI_ADDR_WIDTH-1:0]           r_ofm_addr_base;
  // reg [31:0]                            r_cfg_ci;
  // reg [31:0]                            r_cfg_co;
  // // reg [31:0]                            r_input_width;
  // reg [31:0]                             r_ifm_size;
  // reg [31:0]                             r_wgt_size;

  wire [C_M_AXI_ADDR_WIDTH-1:0]           t_ifm_addr_base;
  wire [C_M_AXI_ADDR_WIDTH-1:0]           t_wgt_addr_base;
  wire [C_M_AXI_ADDR_WIDTH-1:0]           t_ofm_addr_base;
  wire [31:0]                             t_cfg_ci;
  wire [31:0]                             t_cfg_co;
  // wire [31:0]                             t_input_width;
  wire [31:0]                             t_ifm_size;
  wire [31:0]                             t_wgt_size;
  wire [31:0]                             t_ofm_size;

  // assign ifm_addr_base = r_ifm_addr_base;
  // assign wgt_addr_base = r_wgt_addr_base;
  // assign ofm_addr_base = r_ofm_addr_base;
  // assign cfg_ci = r_cfg_ci;
  // assign cfg_co = r_cfg_co;
  // // assign input_width = r_input_width;
  // assign ifm_size = r_ifm_size;
  // assign wgt_size = r_wgt_size;

  wire op_start;
  wire write_buffer_wait;

  // always @(posedge ap_clk, negedge ap_rst_n) begin
  //   if(!ap_rst_n) begin
  //     r_ifm_addr_base <= 0;
  //     r_wgt_addr_base <= 0;
  //     r_ofm_addr_base <= 0;
  //   end else begin
  //    if(ap_start & ap_ready) begin
  //     // if(op_start) begin
  //       r_ifm_addr_base <= t_ifm_addr_base;
  //       r_wgt_addr_base <= t_wgt_addr_base;
  //       r_ofm_addr_base <= t_ofm_addr_base;
  //       r_cfg_ci <= t_cfg_ci;
  //       r_cfg_co <= t_cfg_co;
  //       // r_input_width <= t_input_width;
  //       r_ifm_size <= t_ifm_size;
  //       r_wgt_size <= t_wgt_size;
  //     end
  //   end
  // end

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

    .cfg_ci           (t_cfg_ci),
    .cfg_co       (t_cfg_co),
    // .input_width (t_input_width),
    .ifm_size     (t_ifm_size),
    .wgt_size     (t_wgt_size),
    .ofm_size     (t_ofm_size),
    .ifm_addr_base      (t_ifm_addr_base),
    .wgt_addr_base      (t_wgt_addr_base),
    .ofm_addr_base      (t_ofm_addr_base)
);


// control slave


  wire wmst_done;
  wire wmst_req;

    //ifm axis interface
    wire            ifm_start;
    wire            ifm_done;
    wire    [63:0]  ifm_addr_offset;
    wire    [63:0]  ifm_xfer_size_in_bytes;
    wire            ifm_axis_tvalid;
    wire            ifm_axis_tready;
    wire            ifm_axis_tlast;
    wire    [DATA_WIDTH-1:0] ifm_axis_tdata;
    // wire    [DATA_WIDTH-1:0] ifm_axis_tdata_little_endian;

    //wgt axis interface
    wire            wgt_start;
    wire            wgt_done;
    wire    [63:0]  wgt_addr_offset;
    wire    [63:0]  wgt_xfer_size_in_bytes;
    wire            wgt_axis_tvalid;
    wire            wgt_axis_tready;
    wire            wgt_axis_tlast;
    wire    [DATA_WIDTH-1:0] wgt_axis_tdata;
    // wire    [DATA_WIDTH-1:0] wgt_axis_tdata_little_endian;
    
    //ofm axis interface
    wire            ofm_start;
    wire            ofm_done;
    wire    [63:0]  ofm_addr_offset;
    wire    [63:0]  ofm_xfer_size_in_bytes;
    wire            ofm_axis_tvalid;
    wire            ofm_axis_tready;
    wire    [DATA_WIDTH-1:0] ofm_axis_tdata;
    // wire    [DATA_WIDTH-1:0] ofm_axis_tdata_little_endian;  // in global memory, data are stored in little-endian
    //                                                 // so need to be reordered for AES definition

                                        
 

//    assign ifm_addr_offset = ifm_addr_base;
//    assign ifm_xfer_size_in_bytes = IFM_BUFF_WORD_NUM * 64;
    wire [63:0] ifm_xfer_size;
    assign ifm_xfer_size_in_bytes = ifm_xfer_size;

//    assign wgt_addr_offset = wgt_addr_base;
 //   assign wgt_xfer_size_in_bytes = 4 * 4 * cfg_ci * cfg_co;
//    assign wgt_xfer_size_in_bytes = WGT_BUFF_WORD_NUM * 64;
    wire [63:0] wgt_xfer_size;
    assign wgt_xfer_size_in_bytes = wgt_xfer_size;

    wire    [63:0]  wmst_xfer_addr;
    wire    [63:0]  wmst_xfer_size;

// instantiation of axi read master
  axi_read_master  #(
    .C_M_AXI_ADDR_WIDTH     (64),
    .C_M_AXI_DATA_WIDTH     (DATA_WIDTH),
    .C_XFER_SIZE_WIDTH      (WORD_BYTE),
    .C_MAX_BURST_LENGTH     (64),           // This affect ctrl_addr_offset alignment requirement. Set to 16 means 256-bytes alignment
    .C_INCLUDE_DATA_FIFO    (0)             // disable axi master fifo
  )
        u_ifm_read_master (
    .aclk                       (ap_clk),
    .areset                     (!ap_rst_n),

    .ctrl_start                 (ifm_start),
    .ctrl_done                  (ifm_done),
    .ctrl_addr_offset           (ifm_addr_offset),
    .ctrl_xfer_size_in_bytes    (ifm_xfer_size_in_bytes),

    .m_axi_arvalid              (m_ifm_arvalid),
    .m_axi_arready              (m_ifm_arready),
    .m_axi_araddr               (m_ifm_araddr),
    .m_axi_arlen                (m_ifm_arlen),
    .m_axi_rvalid               (m_ifm_rvalid),
    .m_axi_rready               (m_ifm_rready),
    .m_axi_rdata                (m_ifm_rdata),
    .m_axi_rlast                (m_ifm_rlast),

    .m_axis_tvalid              (ifm_axis_tvalid),
    .m_axis_tready              (ifm_axis_tready),
    .m_axis_tlast               (ifm_axis_tlast),
    .m_axis_tdata               (ifm_axis_tdata)
);

// instantiation of axi read master
  axi_read_master  #(
    .C_M_AXI_ADDR_WIDTH     (64),
    .C_M_AXI_DATA_WIDTH     (DATA_WIDTH),
    .C_XFER_SIZE_WIDTH      (WORD_BYTE),
    .C_MAX_BURST_LENGTH     (64),           // This affect ctrl_addr_offset alignment requirement. Set to 16 means 256-bytes alignment
    .C_INCLUDE_DATA_FIFO    (0)             // disable axi master fifo
  )
        u_wgt_read_master (
    .aclk                       (ap_clk),
    .areset                     (!ap_rst_n),

    .ctrl_start                 (wgt_start),
    .ctrl_done                  (wgt_done),
    .ctrl_addr_offset           (wgt_addr_offset),
    .ctrl_xfer_size_in_bytes    (wgt_xfer_size_in_bytes),

    .m_axi_arvalid              (m_wgt_arvalid),
    .m_axi_arready              (m_wgt_arready),
    .m_axi_araddr               (m_wgt_araddr),
    .m_axi_arlen                (m_wgt_arlen),
    .m_axi_rvalid               (m_wgt_rvalid),
    .m_axi_rready               (m_wgt_rready),
    .m_axi_rdata                (m_wgt_rdata),
    .m_axi_rlast                (m_wgt_rlast),

    .m_axis_tvalid              (wgt_axis_tvalid),
    .m_axis_tready              (wgt_axis_tready),
    .m_axis_tlast               (wgt_axis_tlast),
    .m_axis_tdata               (wgt_axis_tdata)
);
    
    // // data endian conversion
    // generate
    //     genvar i;
    //     for (i = 0; i < WORD_BYTE; i = i + 1) begin : ifm_endian_convert
    //         assign ifm_axis_tdata[i*8+7 : i*8] = ifm_axis_tdata_little_endian[(WORD_BYTE-1-i)*8+7 : (WORD_BYTE-1-i)*8];
    //     end
    // endgenerate

    // generate
    //     for (i = 0; i < WORD_BYTE; i = i + 1) begin : wgt_endian_convert
    //         assign wgt_axis_tdata[i*8+7 : i*8] = wgt_axis_tdata_little_endian[(WORD_BYTE-1-i)*8+7 : (WORD_BYTE-1-i)*8];
    //     end
    // endgenerate

  wire [63:0] ofm_xfer_size;
  assign ofm_xfer_size_in_bytes = ofm_xfer_size;
// instantiation of axi write master
  axi_write_master #(
    .C_M_AXI_ADDR_WIDTH     (64),
    .C_M_AXI_DATA_WIDTH     (DATA_WIDTH),
    .C_XFER_SIZE_WIDTH      (WORD_BYTE),
    .C_MAX_BURST_LENGTH     (64),           // This affect ctrl_addr_offset alignment requirement. Set to 16 means 256-bytes alignment
    .C_INCLUDE_DATA_FIFO    (0)             // disable axi master fifo
  )
        u_ofm_write_master (
    .aclk                       (ap_clk),
    .areset                     (!ap_rst_n),

    .ctrl_start                 (ofm_start),              
    .ctrl_done                  (ofm_done),               
    .ctrl_addr_offset           (ofm_addr_offset),        
    .ctrl_xfer_size_in_bytes    (ofm_xfer_size_in_bytes), 

    .m_axi_awvalid              (m_ofm_awvalid),
    .m_axi_awready              (m_ofm_awready),
    .m_axi_awaddr               (m_ofm_awaddr),
    .m_axi_awlen                (m_ofm_awlen),
    .m_axi_wvalid               (m_ofm_wvalid),
    .m_axi_wready               (m_ofm_wready),
    .m_axi_wdata                (m_ofm_wdata),
    .m_axi_wstrb                (m_ofm_wstrb),
    .m_axi_wlast                (m_ofm_wlast),
    .m_axi_bvalid               (m_ofm_bvalid),
    .m_axi_bready               (m_ofm_bready),
                
    .s_axis_tvalid              (ofm_axis_tvalid),
    .s_axis_tready              (ofm_axis_tready),
    .s_axis_tdata               (ofm_axis_tdata) //should be little endian
);

    //     // data endian conversion
    // generate
    //     genvar j;

    //     for (i = 0; i < WORD_BYTE/4; i = i+1) begin : output_endian_convert_0
    //       for (j = 0; j < 4; j = j + 1) begin : output_endian_convert_1  //output 32bit
    //           assign ofm_axis_tdata_little_endian[i*32 + j*8+7 : i*32 + j*8] = ofm_axis_tdata[(i+1)*32-(j+1)*8+7 : (i+1)*32-(j+1)*8];
    //       end
    //     end
    // endgenerate


// instantiation of engine control
  acc_eng_ctrl u_engine_control (
    .clk                       (ap_clk),
    .rst_n                   (ap_rst_n),


    .ap_start                   (ap_start),
    .ap_continue                (ap_continue),
    .ap_ready                   (ap_ready),
    .ap_done                    (ap_done),
    .ap_idle                    (ap_idle),

    .op_start                 (op_start),

    .end_conv                 (end_conv),
    .wmst_done                (ofm_done),
    .write_buffer_wait        (write_buffer_wait) 

);

// instantiation of cbc_engine_0
    conv_engine conv_eng (
    .clk                   (ap_clk),
    .rst_n               (ap_rst_n),
             
    .op_start               (op_start),
    
    .write_addr               (ofm_addr_base),


    .cfg_ci                   (t_cfg_ci),
    .cfg_co                   (t_cfg_co),

    // .input_width              (input_width),
    .ifm_size                 (t_ifm_size),
    .wgt_size                 (t_wgt_size),
    .ofm_size                 (t_ofm_size),


    .axis_slv_ifm_tvalid    (ifm_axis_tvalid),
    .axis_slv_ifm_tdata    (ifm_axis_tdata),  // is little endian?
    .axis_slv_ifm_tready    (ifm_axis_tready),

    .axis_slv_wgt_tvalid    (wgt_axis_tvalid),
    .axis_slv_wgt_tdata    (wgt_axis_tdata), // is little endian?
    .axis_slv_wgt_tready    (wgt_axis_tready),

    .axis_mst_ofm_tvalid    (ofm_axis_tvalid),
    .axis_mst_ofm_tdata    (ofm_axis_tdata),
    .axis_mst_ofm_tready    (ofm_axis_tready),

    .ofm_req (ofm_start),
    .ofm_addr_base(t_ofm_addr_base),
    .ofm_done (ofm_done),
    .ofm_offset(ofm_addr_offset),
    .ofm_xfer_size(ofm_xfer_size),

    .ifm_req (ifm_start),
    .ifm_addr_base(t_ifm_addr_base),
    .ifm_done (ifm_done),
    .ifm_offset(ifm_addr_offset),
    .ifm_xfer_size(ifm_xfer_size),

    .wgt_req (wgt_start),
    .wgt_addr_base(t_wgt_addr_base),
    .wgt_done (wgt_done),
    .wgt_offset(wgt_addr_offset),
    .wgt_xfer_size(wgt_xfer_size),

    .end_conv (end_conv),
    .write_buffer_wait(write_buffer_wait)
);


// //cycle counter

//   reg [31:0] cycle_counter;
//   reg [31:0] read_cycle;
//   reg [31:0] wgt_cycle;
//   reg [31:0] write_cycle;
//   reg [31:0] engine_counter;
//   reg r_read;
//   reg r_wgt;
//   reg r_write;
//   reg r_engine;

//   always @(negedge ap_rst_n, posedge ap_clk) begin
//       if(!ap_rst_n) begin
//           r_read <= 0;
//           r_wgt <= 0;
//           r_write <= 0;
//           r_engine <= 0;
//       end else begin
//           r_read <= ifm_start ? 1 :
//                     ifm_done ? 0 : r_read;
//           r_write <= ofm_start ? 1 :
//                     ofm_done ? 0 : r_write;
//           r_wgt <= wgt_start ? 1 :
//                     wgt_done ? 0 : r_wgt;
//           r_engine <= op_start ? 1 :
//                     end_conv ? 0 : r_engine;

//       end
//   end

//   always @(negedge ap_rst_n, posedge ap_clk) begin
//       if(!ap_rst_n) begin
//           cycle_counter <= 0;
//           read_cycle <= 0;
//           wgt_cycle <= 0;
//           write_cycle <= 0;
//           engine_counter <= 0;
//       end else begin
//           if(!ap_ready) cycle_counter <= cycle_counter +1;
//           if(r_read) read_cycle <= read_cycle + 1;
//           if(r_wgt) wgt_cycle <= wgt_cycle + 1;
//           if(r_write) write_cycle <= write_cycle + 1;
//           if(r_engine) engine_counter <= engine_counter + 1;
//       end
//   end

	// // ILA monitoring combinatorial adder
	// ila_0 i_ila_0 (
	// 	.clk(ap_clk),              // input wire        clk
	// 	.probe0(op_start),           // input wire [0:0]  probe0  
	// 	.probe1(ap_start), // input wire [0:0]  probe1 
	// 	.probe2(ap_ready),   // input wire [0:0]  probe2 
	// 	.probe3(ifm_addr_base),    // input wire [63:0] probe3 
	// 	.probe4(wgt_addr_base),    // input wire [63:0] probe3 
  //   .probe5(t_ifm_addr_base)      // input wire [63:0] probe4
	// );
endmodule