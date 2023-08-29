//
//
//# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
//# SPDX-License-Identifier: X11
//
//

`timescale 1ns/1ps

module acc_eng_ctrl #(
  parameter integer DATA_WIDTH  = 512,
  parameter integer WORD_BYTE = DATA_WIDTH/8
)(
    input               clk,
    input               rst_n,

// AXI read master control signals
    // output  reg         ifm_req_out,
    // input               ifm_done,

    // output  reg         wgt_req_out,
    // input               wgt_done,

// AXI write master control signals
    // output  reg         wmst_req_out,
    // output  reg [63:0]  wmst_xfer_addr_out,
    // output  reg [63:0]  wmst_xfer_size_out,
    // input               wmst_done,

    // input               wmst_req_in_0,
    // input       [63:0]  wmst_xfer_addr_in_0,
    // input       [63:0]  wmst_xfer_size_in_0,

    // input wmst_req_in,
    // input rmst_req_in,
    input wmst_done,
    // input rmst_done,
    
// kernel control signals
    input               ap_start,
    input               ap_continue,
    output              ap_ready,
    output reg          ap_done,
    output              ap_idle,

// engine control signals
    output reg          op_start,

    input               end_conv
);
    
    // reg         rmst_busy;      // when set to 1, read master is in busy status
    // reg         wmst_busy;      // when set to 1, write master is in busy status
    reg         eng_busy;       // operate state


    // rmst axis signal mux
    // always @ (*) begin
    //     axis_slv_rmst_tready_out = 1'b0;


    //     axis_slv_rmst_tready_out = axis_slv_rmst_tready_in_0; 
    // end


    // assign axis_slv_rmst_tvalid_out_0 = axis_slv_rmst_tvalid_in;


    // assign axis_slv_rmst_tdata_out_0 = axis_slv_rmst_tdata_in;

    // // read master status update
    // always @ (posedge aclk or negedge areset_n) begin
    //     if (!areset_n) begin
    //         rmst_busy <= 1'b0;
    //     end else begin
    //         // if (ap_start && ap_ready) 
    //         if (rmst_req_in)
    //             rmst_busy <= 1'b1;
    //         else if (rmst_done)
    //             rmst_busy <= 1'b0;
    //     end
    // end

    reg r_end_conv;
    // engine status update
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            eng_busy <= 1'b0;
            r_end_conv <= 1'b0;
        end else begin
            // if (ap_start && ap_ready) 
            if (op_start)
                eng_busy <= 1'b1;

            r_end_conv <= end_conv ? 1 : 
                        wmst_done ? 0 : r_end_conv;

            if (r_end_conv & wmst_done) begin
                eng_busy <= 1'b0;
            end
        end
    end

    // // read master request generation
    // always @ (posedge aclk or negedge areset_n) begin
    //     if (!areset_n) begin
    //         rmst_req_out <= 1'b0;
    //     end else begin
    //         if (ap_start && ap_ready) 
    //             rmst_req_out <= 1'b1;
    //         else if (rmst_req_out)
    //             rmst_req_out <= 1'b0;
    //     end
    // end




    // assign ap_ready = ap_start ? (engine_busy_cnt < 3'd1) && !rmst_busy;
    assign ap_ready = !eng_busy;
    // assign ap_idle = (engine_busy_cnt == 3'd0);
    assign ap_idle = !eng_busy;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n)
            op_start <= 1'b0;
        else if (op_start)
            op_start <= 1'b0;
        else if (ap_start && ap_ready)
            op_start <= 1'b1;
    end



// --------------------------------------------------------------------------------------
//   AP_CTRL_CHAIN output sync
// // --------------------------------------------------------------------------------------
//     // write master status update
//     always @ (posedge aclk or negedge areset_n) begin
//         if (!areset_n) begin
//             wmst_busy <= 1'b0;
//         end else begin
//             if (wmst_req_in) 
//                 wmst_busy <= 1'b1;
//             else if (wmst_done)
//                 wmst_busy <= 1'b0;
//         end
//     end

    // ap_done generation
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n)
            ap_done <= 1'b0;
        else if (ap_done && ap_continue)    // ap_done clear when ap_continue asserted
            ap_done <= 1'b0;
        else if (end_conv)                 // when any CBC engine finish axi master write, assert ap_done
            ap_done <= 1'b1;
    end


endmodule
