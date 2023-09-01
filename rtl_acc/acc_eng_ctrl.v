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


// AXI write master control signals
    input wmst_done,
    
// kernel control signals
    input               ap_start,
    input               ap_continue,
    output              ap_ready,
    output reg          ap_done,
    output              ap_idle,

// engine control signals
    output reg          op_start,

    input               end_conv,
    input               write_buffer_wait
);
    
    reg         eng_busy;       // operate state

    reg r_end_conv;

    // assign ap_ready = ap_start ? (engine_busy_cnt < 3'd1) && !rmst_busy;
    assign ap_ready = !eng_busy;
    // assign ap_idle = (engine_busy_cnt == 3'd0);
    assign ap_idle = !eng_busy;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            eng_busy <= 1'b0;
            op_start <= 1'b0;
        end else if (op_start)
            op_start <= 1'b0;
        else if (ap_start && ap_ready) begin
            op_start <= 1'b1;
            eng_busy <= 1;
        end else if (r_end_conv && !write_buffer_wait) begin
            eng_busy <= 0;
        end
    end

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            r_end_conv <= 0;    
        end else begin
            if(end_conv) 
                r_end_conv <= 1;
            else if (r_end_conv && !write_buffer_wait)
                r_end_conv <= 0;
        end
    end



// --------------------------------------------------------------------------------------
//   AP_CTRL_CHAIN output sync
// // --------------------------------------------------------------------------------------

    // ap_done generation
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n)
            ap_done <= 1'b0;
        else if (ap_done && ap_continue)    // ap_done clear when ap_continue asserted
            ap_done <= 1'b0;
        else if (r_end_conv && !write_buffer_wait) begin                 // when any CBC engine finish axi master write, assert ap_done
            ap_done <= 1'b1;
        end
    end


endmodule
