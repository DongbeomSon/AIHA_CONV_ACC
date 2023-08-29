//
//# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
//# SPDX-License-Identifier: X11
//
//

`timescale 1ns/1ps


module Conv_acc_wrapper #(parameter CONV_ENG_NUM = 1) #(
    parameter IFM_WIDTH = 64,
    parameter WGT_WIDTH = 32,
    parameter OFM_WDITH = $ceil(25/8) * 8

)
(
    input                       CLK,        // AXI bus clock
    input                       RESETn,

    // axi control slave connection
    input                       mode,       // AES cipher mode, 0 - decrypt, 1 - encrypt
    input   [1:0]               key_length, // AES key length, 00 - 128bit, 01 - 192bit, 10 - 256bit
    input   [255:0]             key,        // AES KEY. When shorted than 256bit, aligned to MSB
    output  [CONV_ENG_NUM-1:0] status,     // some bit is 1 mean the related AES engine are busy
    input                       keyexp_start,   // multi-cycle keyexp_start signal from axi slave
    output                      keyexp_done,    // one-cycle keyexp_done signal to axi slave

    // axi stream ports
    axis_if.SLAVE               axis_if_ifm[CONV_ENG_NUM],
    axis_if.SLAVE               axis_if_wgt[CONV_ENG_NUM],
    axis_if.MASTER              axis_if_ofm[CONV_ENG_NUM],
//    axis_if.MASTER              axis_if_ofm_1[CONV_ENG_NUM]
);

    // logic   [CONV_ENG_NUM-1:0]     int_keyexp_done;
    
    // assign keyexp_done = &int_keyexp_done;      // actually all int_keyexp_done[] signals are fully synchronized in this case
    

        //s_tdata_0 : ifm
        //s_tdata_1 : wgt
        //m_tdata_0 : ofm_0
        //m_tdata_1 : ofm_1

    generate
        genvar i;
        for (i = 0; i < CONV_ENG_NUM; i = i + 1) begin : conv_inst
            logic [IFM_WIDTH-1:0] ifm;
            logic ifm_fifo_push_req;
            logic ifm_fifo_pop_req;
            logic ifm_fifo_push_data;
            logic ifm_fifo_pop_data;
            logic ifm_fifo_empty;
            logic ifm_fifo_full;
            logic ifm_first_req;

            FifoType0 #(.data_width (512), .addr_bits (5)) ifm_fifo (
                .CLK        (CLK),
                .nRESET     (RESETn),
                .PUSH_REQ   (ifm_fifo_push_req),
                .POP_REQ    (ifm_fifo_pop_req),
                .PUSH_DATA  (ifm_fifo_push_data),
                .CLEAR      (),
        
                .POP_DATA   (ifm_fifo_pop_data),
                .EMPTY      (ifm_fifo_empty),
                .FULL       (ifm_fifo_full),
                .ERROR      (),
                .DATA_CNT   ()
            );

            Parser #(INPUT_WIDTH = 512) ifm_parser (
                .clk       (CLK),
                .rst_n      (RESETn),
                .fm         (ifm_fifo_pop_data),
                .ifm_read   (ifm_read),
                .first_word (ifm_first_req),
                .parse_out  (ifm),
                .input_req  (ifm_fifo_pop_req)
            );


            // internel AXIS signals
            logic [IFM_WIDTH-1:0]   int_s_tdata_0;
            logic           int_s_tvalid_0;
            logic           int_s_tready_0;

            logic [WGT_WIDTH-1:0]   int_s_tdata_1;
            logic           int_s_tvalid_1;
            logic           int_s_tready_1;
            
            logic [2 * OFM_WDITH-1:0]   int_m_tdata_0;
            logic           int_m_tvalid_0;
            logic           int_m_tready_0;

            // logic [OFM_WIDTH-1:0]   int_m_tdata_1;
            // logic           int_m_tvalid_1;
            // logic           int_m_tready_1;          

            // // internal misc signals
            logic   int_status;
            // logic   keyexp_start_reg;

            // internel aes module control signals
            logic start_cipher;
            // logic start_exp;
            logic op_finish;
            // logic exp_finish;
            
            // logic exp_finish_reg;   // registered exp_finish
            // logic exp_finish_rising; // indicating rising edge of exp_finish
            
            logic op_finish_reg;    // registered op_finish
            logic op_finish_rising; // indicating rising edge of op_finish        
            
            logic [IFM_WIDTH-1:0]   int_s_tdata_0_reg;
            logic [WGT_WIDTH-1:0]   int_s_tdata_1_reg;
            
            
            // port signal assignment
            assign int_s_tdata_0 = axis_if_ifm[i].tdata;
            assign int_s_tvalid_0 = axis_if_ifm[i].tvalid;
            assign axis_if_ifm[i].tready = int_s_tready_0;

            assign int_s_tdata_1 = axis_if_wgt[i].tdata;
            assign int_s_tvalid_1 = axis_if_wgt[i].tvalid;
            assign axis_if_wgt[i].tready = int_s_tready_1;
            
            assign axis_if_ofm_0[i].tdata = int_m_tdata_0;
            assign axis_if_ofm_0[i].tvalid = int_m_tvalid_0;
            assign int_m_tready_0 = axis_if_ofm_0[i].tready;
            
            assign axis_if_ofm_1[i].tdata = int_m_tdata_1;
            assign axis_if_ofm_1[i].tvalid = int_m_tvalid_1;
            assign int_m_tready_1 = axis_if_ofm_1[i].tready;

            
            assign status[i] = int_status;

            // assign int_keyexp_done[i] = exp_finish_rising;  // use rising edge of exp_finish as keyexp_done
            
            always @(posedge CLK)
                int_status <= !op_finish;
    
            // exp_finish rising edge detection
            // always @ (posedge CLK or negedge RESETn) begin
            //     if (!RESETn)
            //         exp_finish_reg <= 1'b1;
            //     else
            //         exp_finish_reg <= exp_finish;
            // end
            
            // always @ (posedge CLK or negedge RESETn) begin
            //     if (!RESETn)
            //         exp_finish_rising <= 1'b0;
            //     else if (!exp_finish_reg && exp_finish)
            //         exp_finish_rising <= 1'b1;
            //     else
            //         exp_finish_rising <= 1'b0;
            // end

            // op_finish rising edge detection, as keyexp_done output
            always @ (posedge CLK or negedge RESETn) begin
                if (!RESETn)
                    op_finish_reg <= 1'b1;
                else
                    op_finish_reg <= op_finish;
            end
            
            assign op_finish_rising = !op_finish_reg && op_finish;

            // generate axis master tvalid
            always @ (posedge CLK or negedge RESETn) begin
                if (!RESETn)
                    int_m_tvalid <= 1'b0;
                else if (int_m_tvalid && int_m_tready)
                    int_m_tvalid <= 1'b0;
                else if (op_finish_rising)
                    int_m_tvalid <= 1'b1;
            end

            // generate axis slave tready
            always @ (posedge CLK or negedge RESETn) begin
                if (!RESETn)
                    int_s_tready <= 1'b1;
                else if (int_s_tvalid && int_s_tready)
                    int_s_tready <= 1'b0;
                else if (int_m_tvalid && int_m_tready)
                    int_s_tready <= 1'b1;
            end
                        
            // generate 1-cycle start_cipher from AXIS tvalid and tready signal            
            always @ (posedge CLK or negedge RESETn) begin
                if (!RESETn) begin
                    start_cipher <= 1'b0;
                    int_s_tdata_reg <= 128'b0;
                end
                else if (int_s_tvalid && int_s_tready) begin
                    start_cipher <= 1'b1;
                    int_s_tdata_reg <= int_s_tdata;
                end
                else begin
                    start_cipher <= 1'b0;
                end
            end                    
            
            // use keyexp_start to generate 1-cycle start_exp pulse
            always @ (posedge CLK or negedge RESETn) begin
                if (!RESETn) begin
                    keyexp_start_reg <= 1'b0;
                    start_exp    <= 1'b0;
                end else begin
                    keyexp_start_reg <= keyexp_start;
                    if (start_exp) 
                        start_exp <= 1'b0;
                    else if (!keyexp_start_reg && keyexp_start)
                        start_exp <= 1'b1;
                end
            end
                    
            // instantiation of Aes module
            Aes uAes (
                .CLK            (CLK),
                .RESETn         (RESETn),
                .DATA_INPUT     (int_s_tdata_reg),
                .KEY            (key),
                .DATA_OUTPUT    (int_m_tdata),
                .OP_MODE        (mode),
                .NK             (key_length),
                .NR             (4'b0),
                .START_CIPHER   (start_cipher),
                .START_KEYEXP   (start_exp),
                .OP_FINISH      (op_finish),
                .EXP_FINISH     (exp_finish)
            );

        end // aes_inst
    endgenerate

endmodule
