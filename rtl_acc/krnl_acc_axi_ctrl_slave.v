//
//
//# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
//# SPDX-License-Identifier: X11
//
//


`timescale 1ns / 1ps
module krnl_acc_axi_ctrl_slave (
    input         ACLK,
    input         ARESETn,
    // AXI signals
    input  [11:0] AWADDR,
    input         AWVALID,
    output        AWREADY,
    input  [31:0] WDATA,
    input  [ 3:0] WSTRB,
    input         WVALID,
    output        WREADY,
    output [ 1:0] BRESP,
    output        BVALID,
    input         BREADY,
    input  [11:0] ARADDR,
    input         ARVALID,
    output        ARREADY,
    output [31:0] RDATA,
    output [ 1:0] RRESP,
    output        RVALID,
    input         RREADY,
    // ap_ctrl_chain signals
    output        ap_start,
    input         ap_done,
    input         ap_idle,
    input         ap_ready,
    output        ap_continue,
    // control register signals

    output [31:0] cfg_ci,
    output [31:0] cfg_co,
    // output [31:0] input_width,
    output [31:0] ifm_size,
    output [31:0] wgt_size,
    output [31:0] ofm_size,
    output [31:0] tile_num,
    output [63:0] ifm_addr_base,
    output [63:0] wgt_addr_base,
    output [63:0] ofm_addr_base
);

    //------------------------Register Address Map-------------------
    // 0x000 : CTRL
    // 0x010 : CFG_CI
    // 0x018 : CFG_CO
    // 0x020 : IFM_ADDR_BASE_0[31:0]
    // 0x024 : IFM_ADDR_BASE_1[63:32]
    // 0x028 : WGT_ADDR_BASE_0[31:0]
    // 0x02C : WGT_ADDR_BASE_1[63:32]
    // 0x030 : OFM_ADDR_BASE_0[31:0]
    // 0x034 : OFM_ADDR_BASE_1[63:32]

    //------------------------Parameter----------------------
    localparam
    // register address map
    ADDR_CTRL       = 12'h000, 
    ADDR_CFG_CI     = 12'h010, 
    ADDR_CFG_CO     = 12'h014,
    ADDR_IFM_SIZE   = 12'h018,
    ADDR_WGT_SIZE   = 12'h01C,
    ADDR_OFM_SIZE   = 12'h020,
    ADDR_TILE_NUM = 12'h24,
    // ADDR_INPUT_WIDTH = 12'h01C,
    ADDR_IFM_ADDR_BASE_0 = 12'h040,
    ADDR_IFM_ADDR_BASE_1 = 12'h044,
    ADDR_WGT_ADDR_BASE_0 = 12'h048,
    ADDR_WGT_ADDR_BASE_1 = 12'h04C,
    ADDR_OFM_ADDR_BASE_0 = 12'h050,
    ADDR_OFM_ADDR_BASE_1 = 12'h054,


    // registers write state machine
    WRIDLE = 2'd0, WRDATA = 2'd1, WRRESP = 2'd2, WRRESET = 2'd3,

    // registers read state machine
    RDIDLE = 2'd0, RDDATA = 2'd1, RDRESET = 2'd2;

    //------------------------Signal Declaration----------------------
    // axi operation
    reg  [ 1:0] wstate;
    reg  [ 1:0] wnext;
    reg  [11:0] waddr;
    wire [31:0] wmask;
    wire        aw_hs;
    wire        w_hs;
    reg  [ 1:0] rstate;
    reg  [ 1:0] rnext;
    reg  [31:0] rdata;
    wire        ar_hs;
    wire [11:0] raddr;

    // control register bit
    reg         reg_ctrl_ap_idle;
    wire        reg_ctrl_ap_done;
    reg         reg_ctrl_ap_ready;
    reg         reg_ctrl_ap_start;
    reg         reg_ctrl_ap_continue;

    reg  [31:0] reg_cfg_ci;  // bit[0] used
    reg  [31:0] reg_cfg_co;
    // reg  [31:0]     reg_input_width;
    reg  [31:0] reg_ifm_size;
    reg  [31:0] reg_wgt_size;
    reg  [31:0] reg_ofm_size;
    reg  [31:0] reg_tile_num;
    reg  [63:0] reg_ifm_addr_base;
    reg  [63:0] reg_wgt_addr_base;
    reg  [63:0] reg_ofm_addr_base;


    //------------------------AXI protocol control------------------

    //------------------------AXI write fsm------------------
    assign AWREADY = (wstate == WRIDLE);
    assign WREADY = (wstate == WRDATA);
    assign BRESP = 2'b00;  // OKAY
    assign BVALID = (wstate == WRRESP);
    assign wmask = {{8{WSTRB[3]}}, {8{WSTRB[2]}}, {8{WSTRB[1]}}, {8{WSTRB[0]}}};
    assign aw_hs = AWVALID & AWREADY;
    assign w_hs = WVALID & WREADY;

    // wstate
    always @(posedge ACLK) begin
        if (!ARESETn) wstate <= WRRESET;
        else wstate <= wnext;
    end

    // wnext
    always @(*) begin
        case (wstate)
            WRIDLE:  if (AWVALID) wnext = WRDATA;
 else wnext = WRIDLE;
            WRDATA:  if (WVALID) wnext = WRRESP;
 else wnext = WRDATA;
            WRRESP:  if (BREADY) wnext = WRIDLE;
 else wnext = WRRESP;
            default: wnext = WRIDLE;
        endcase
    end

    // waddr
    always @(posedge ACLK) begin
        if (aw_hs) waddr <= AWADDR;
    end

    //------------------------AXI read fsm-------------------
    assign ARREADY = (rstate == RDIDLE);
    assign RDATA   = rdata;
    assign RRESP   = 2'b00;  // OKAY
    assign RVALID  = (rstate == RDDATA);
    assign ar_hs   = ARVALID & ARREADY;
    assign raddr   = ARADDR;

    // rstate
    always @(posedge ACLK) begin
        if (!ARESETn) rstate <= RDRESET;
        else rstate <= rnext;
    end

    // rnext
    always @(*) begin
        case (rstate)
            RDIDLE:  if (ARVALID) rnext = RDDATA;
 else rnext = RDIDLE;
            RDDATA:  if (RREADY & RVALID) rnext = RDIDLE;
 else rnext = RDDATA;
            default: rnext = RDIDLE;
        endcase
    end

    // rdata
    always @(posedge ACLK) begin
        if (ar_hs) begin
            case (raddr)
                ADDR_CTRL: begin
                    rdata[0] <= reg_ctrl_ap_start;
                    rdata[1] <= reg_ctrl_ap_done;
                    rdata[2] <= reg_ctrl_ap_idle;
                    rdata[3] <= reg_ctrl_ap_ready;
                    rdata[4] <= reg_ctrl_ap_continue;
                    rdata[31:5] <= 'h0;
                end
                // --------------------------------------
                ADDR_CFG_CI: begin
                    rdata <= reg_cfg_ci;
                end
                // --------------------------------------
                ADDR_CFG_CO: begin
                    rdata <= reg_cfg_co;
                end
                // ADDR_INPUT_WIDTH: begin
                //     rdata <= reg_input_width;
                // end
                ADDR_IFM_SIZE: begin
                    rdata <= reg_ifm_size;
                end
                ADDR_WGT_SIZE: begin
                    rdata <= reg_wgt_size;
                end
                ADDR_OFM_SIZE: begin
                    rdata <= reg_ofm_size;
                end
                ADDR_TILE_NUM: begin
                    rdata <= reg_tile_num;
                end
                // --------------------------------------
                ADDR_IFM_ADDR_BASE_0: begin
                    rdata <= reg_ifm_addr_base[31:0];
                end
                // --------------------------------------
                ADDR_IFM_ADDR_BASE_1: begin
                    rdata <= reg_ifm_addr_base[63:32];
                end
                // --------------------------------------
                ADDR_WGT_ADDR_BASE_0: begin
                    rdata <= reg_wgt_addr_base[31:0];
                end
                // --------------------------------------
                ADDR_WGT_ADDR_BASE_1: begin
                    rdata <= reg_wgt_addr_base[63:32];
                end
                // --------------------------------------
                ADDR_OFM_ADDR_BASE_0: begin
                    rdata <= reg_ofm_addr_base[31:0];
                end
                // --------------------------------------
                ADDR_OFM_ADDR_BASE_1: begin
                    rdata <= reg_ofm_addr_base[63:32];
                end
            endcase
        end
    end


    // Control register update operation

    // reg_ctrl_ap_start
    always @(posedge ACLK) begin
        if (!ARESETn) reg_ctrl_ap_start <= 1'b0;
        else if (w_hs && waddr == ADDR_CTRL && WSTRB[0] && WDATA[0])
            reg_ctrl_ap_start <= 1'b1;
        else if (ap_ready)
            reg_ctrl_ap_start <= 1'b0;  // clear when ap_ready asserted
    end

    // reg_ctrl_ap_done
    assign reg_ctrl_ap_done = ap_done;  // ap_done clear is controlled by CU


    // reg_ctrl_ap_idle
    always @(posedge ACLK) begin
        reg_ctrl_ap_idle <= ap_idle;
    end

    // reg_ctrl_ap_ready
    always @(posedge ACLK) begin
        reg_ctrl_ap_ready <= ap_ready;
    end

    // reg_ctrl_ap_continue
    always @(posedge ACLK) begin
        if (!ARESETn) reg_ctrl_ap_continue <= 1'b0;
        else if (w_hs && waddr == ADDR_CTRL && WSTRB[0] && WDATA[4])
            reg_ctrl_ap_continue <= 1'b1;
        else reg_ctrl_ap_continue <= 1'b0;  // self clear
    end

    // reg_cfg_ci
    always @(posedge ACLK) begin
        if (!ARESETn) reg_cfg_ci <= 'h0;
        else if (w_hs && waddr == ADDR_CFG_CI)
            reg_cfg_ci <= (WDATA & wmask) | (reg_cfg_ci & ~wmask);
    end

    // reg_cfg_co
    always @(posedge ACLK) begin
        if (!ARESETn) reg_cfg_co <= 'h0;
        else if (w_hs && waddr == ADDR_CFG_CO)
            reg_cfg_co <= (WDATA & wmask) | (reg_cfg_co & ~wmask);
    end

    // // reg_input_width
    // always @(posedge ACLK) begin
    //     if (!ARESETn)
    //         reg_input_width <= 'h0;
    //     else
    //         if (w_hs && waddr == ADDR_INPUT_WIDTH)
    //             reg_input_width <= (WDATA & wmask) | (reg_input_width & ~wmask);
    // end

    // reg_ifm_size
    always @(posedge ACLK) begin
        if (!ARESETn) reg_ifm_size <= 'h0;
        else if (w_hs && waddr == ADDR_IFM_SIZE)
            reg_ifm_size <= (WDATA & wmask) | (reg_ifm_size & ~wmask);
    end

    // reg_wgt_size
    always @(posedge ACLK) begin
        if (!ARESETn) reg_wgt_size <= 'h0;
        else if (w_hs && waddr == ADDR_WGT_SIZE)
            reg_wgt_size <= (WDATA & wmask) | (reg_wgt_size & ~wmask);
    end

    // reg_ofm_size
    always @(posedge ACLK) begin
        if (!ARESETn) reg_ofm_size <= 'h0;
        else if (w_hs && waddr == ADDR_OFM_SIZE)
            reg_ofm_size <= (WDATA & wmask) | (reg_ofm_size & ~wmask);
    end


    // reg_tile_num
    always @(posedge ACLK) begin
        if (!ARESETn) reg_tile_num <= 'h0;
        else if (w_hs && waddr == ADDR_TILE_NUM)
            reg_tile_num <= (WDATA & wmask) | (reg_tile_num & ~wmask);
    end

    // reg_ifm_addr_base [31:0]
    always @(posedge ACLK) begin
        if (!ARESETn) reg_ifm_addr_base[31:0] <= 'h0;
        else if (w_hs && waddr == ADDR_IFM_ADDR_BASE_0)
            reg_ifm_addr_base[31:0] <= (WDATA & wmask) | (reg_ifm_addr_base[31:0] & ~wmask);
    end

    // reg_ifm_addr_base [63:32]
    always @(posedge ACLK) begin
        if (!ARESETn) reg_ifm_addr_base[63:32] <= 'h0;
        else if (w_hs && waddr == ADDR_IFM_ADDR_BASE_1)
            reg_ifm_addr_base[63:32] <= (WDATA & wmask) | (reg_ifm_addr_base[63:32] & ~wmask);
    end

    // reg_wgt_addr_base [31:0]
    always @(posedge ACLK) begin
        if (!ARESETn) reg_wgt_addr_base[31:0] <= 'h0;
        else if (w_hs && waddr == ADDR_WGT_ADDR_BASE_0)
            reg_wgt_addr_base[31:0] <= (WDATA & wmask) | (reg_wgt_addr_base[31:0] & ~wmask);
    end

    // reg_wgt_addr_base [63:32]
    always @(posedge ACLK) begin
        if (!ARESETn) reg_wgt_addr_base[63:32] <= 'h0;
        else if (w_hs && waddr == ADDR_WGT_ADDR_BASE_1)
            reg_wgt_addr_base[63:32] <= (WDATA & wmask) | (reg_wgt_addr_base[63:32] & ~wmask);
    end

    // reg_ofm_addr_base [31:0]
    always @(posedge ACLK) begin
        if (!ARESETn) reg_ofm_addr_base[31:0] <= 'h0;
        else if (w_hs && waddr == ADDR_OFM_ADDR_BASE_0)
            reg_ofm_addr_base[31:0] <= (WDATA & wmask) | (reg_ofm_addr_base[31:0] & ~wmask);
    end

    // reg_ofm_addr_base [63:32]
    always @(posedge ACLK) begin
        if (!ARESETn) reg_ofm_addr_base[63:32] <= 'h0;
        else if (w_hs && waddr == ADDR_OFM_ADDR_BASE_1)
            reg_ofm_addr_base[63:32] <= (WDATA & wmask) | (reg_ofm_addr_base[63:32] & ~wmask);
    end

    //------------------------Control registers output-----------------
    assign ap_start      = reg_ctrl_ap_start;
    assign ap_continue   = reg_ctrl_ap_continue;
    assign cfg_ci        = reg_cfg_ci;
    assign cfg_co        = reg_cfg_co;
    // assign input_width  = reg_input_width;
    assign ifm_size      = reg_ifm_size;
    assign wgt_size      = reg_wgt_size;
    assign ofm_size      = reg_ofm_size;
    assign tile_num      = reg_tile_num;
    assign ifm_addr_base = reg_ifm_addr_base;
    assign wgt_addr_base = reg_wgt_addr_base;
    assign ofm_addr_base = reg_ofm_addr_base;

endmodule
