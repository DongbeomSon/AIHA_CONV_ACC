module flatter #(
    parameter WORD_BYTE = 64
    )
    (
    input clk,
    input rst_n,

    
    input [511:0] out_ofm0_port0,
    input [511:0] out_ofm0_port1,
    input [511:0] out_ofm0_port2,
    input [511:0] out_ofm0_port3,
    input [511:0] out_ofm0_port4,
    input [511:0] out_ofm0_port5,
    input [511:0] out_ofm0_port6,
    input [511:0] out_ofm0_port7,
    input [511:0] out_ofm0_port8,
    input [511:0] out_ofm0_port9,
    input [511:0] out_ofm0_port10,
    input [511:0] out_ofm0_port11,
    input [511:0] out_ofm0_port12,
    input [511:0] out_ofm0_port13,
    input [511:0] out_ofm1_port0,
    input [511:0] out_ofm1_port1,
    input [511:0] out_ofm1_port2,
    input [511:0] out_ofm1_port3,
    input [511:0] out_ofm1_port4,
    input [511:0] out_ofm1_port5,
    input [511:0] out_ofm1_port6,
    input [511:0] out_ofm1_port7,
    input [511:0] out_ofm1_port8,
    input [511:0] out_ofm1_port9,
    input [511:0] out_ofm1_port10,
    input [511:0] out_ofm1_port11,
    input [511:0] out_ofm1_port12,
    input [511:0] out_ofm1_port13,
    input out_ofm_port_v0,
    input out_ofm_port_v1,
    input out_ofm_port_v2,
    input out_ofm_port_v3,
    input out_ofm_port_v4,
    input out_ofm_port_v5,
    input out_ofm_port_v6,
    input out_ofm_port_v7,
    input out_ofm_port_v8,
    input out_ofm_port_v9,
    input out_ofm_port_v10,
    input out_ofm_port_v11,
    input out_ofm_port_v12,
    input out_ofm_port_v13,

    input end_conv,

    output [511:0] tdata,
    input ready,
    output valid,

    input [63:0] wmst_offset,
    input wmst_done,
    output wmst_req,
    output reg [63:0] wmst_addr,
    output reg [63:0] wmst_xfer_size,
    output write_buffer_wait
);

    reg [4:0]  fifo_cnt;

    wire out_fifo_push_req[0:27];
    wire out_fifo_pop_req[0:27];
    wire [511:0] out_fifo_push_data[0:27];
    wire [511:0] out_fifo_pop_data[0:27];
    wire out_fifo_empty[0:27];
    wire out_fifo_full[0:27];
    wire [10:0] out_fifo_data_cnt[0:27];

    genvar i;
    generate
        for (i=0 ; i<28 ; i++) begin: pe_gen

        FifoType0 #(.data_width (512), .addr_bits (10)) ofm_fifo (
            .CLK        (clk),
            .nRESET     (rst_n),
            .PUSH_REQ   (out_fifo_push_req[i]),
            .POP_REQ    (out_fifo_pop_req[i]),
            .PUSH_DATA  (out_fifo_push_data[i]),
            .CLEAR      (),
    
            .POP_DATA   (out_fifo_pop_data[i]),
            .EMPTY      (out_fifo_empty[i]),
            .FULL       (out_fifo_full[i]),
            .ERROR      (),
            .DATA_CNT   (out_fifo_data_cnt[i])
        );

        assign out_fifo_pop_req[i] = ready & valid ? (fifo_cnt==i) : 0;

        end  
    endgenerate  
    
    assign pop_req =           (out_fifo_pop_req[0] || out_fifo_pop_req[1] || out_fifo_pop_req[2] || out_fifo_pop_req[3] || out_fifo_pop_req[4] || out_fifo_pop_req[5] || out_fifo_pop_req[6] ||
                                out_fifo_pop_req[7] || out_fifo_pop_req[8] || out_fifo_pop_req[9] || out_fifo_pop_req[10] || out_fifo_pop_req[11] || out_fifo_pop_req[12] || out_fifo_pop_req[13] ||
                                out_fifo_pop_req[14] || out_fifo_pop_req[15] || out_fifo_pop_req[16] || out_fifo_pop_req[17] || out_fifo_pop_req[18] || out_fifo_pop_req[19] || out_fifo_pop_req[20] ||
                                out_fifo_pop_req[21] || out_fifo_pop_req[22] || out_fifo_pop_req[23] || out_fifo_pop_req[24] || out_fifo_pop_req[25] || out_fifo_pop_req[26] || out_fifo_pop_req[27]);
    assign fifo_empty =        (out_fifo_empty[0] && out_fifo_empty[1] && out_fifo_empty[2] && out_fifo_empty[3] && out_fifo_empty[4] && out_fifo_empty[5] && out_fifo_empty[6] &&
                                out_fifo_empty[7] && out_fifo_empty[8] && out_fifo_empty[9] && out_fifo_empty[10] && out_fifo_empty[11] && out_fifo_empty[12] && out_fifo_empty[13] &&
                                out_fifo_empty[14] && out_fifo_empty[15] && out_fifo_empty[16] && out_fifo_empty[17] && out_fifo_empty[18] && out_fifo_empty[19] && out_fifo_empty[20] &&
                                out_fifo_empty[21] && out_fifo_empty[22] && out_fifo_empty[23] && out_fifo_empty[24] && out_fifo_empty[25] && out_fifo_empty[26] && out_fifo_empty[27]);
    assign write_buffer_wait = !(out_fifo_data_cnt[27]<1); // !out_fifo_empty[27];
    assign tdata = (fifo_cnt == 0) ? out_fifo_pop_data[0] : (fifo_cnt == 1) ? out_fifo_pop_data[1] :
                   (fifo_cnt == 2) ? out_fifo_pop_data[2] : (fifo_cnt == 3) ? out_fifo_pop_data[3] :
                   (fifo_cnt == 4) ? out_fifo_pop_data[4] : (fifo_cnt == 5) ? out_fifo_pop_data[5] :
                   (fifo_cnt == 6) ? out_fifo_pop_data[6] : (fifo_cnt == 7) ? out_fifo_pop_data[7] :
                   (fifo_cnt == 8) ? out_fifo_pop_data[8] : (fifo_cnt == 9) ? out_fifo_pop_data[9] :
                   (fifo_cnt == 10) ? out_fifo_pop_data[10] : (fifo_cnt == 11) ? out_fifo_pop_data[11] :
                   (fifo_cnt == 12) ? out_fifo_pop_data[12] : (fifo_cnt == 13) ? out_fifo_pop_data[13] :
                   (fifo_cnt == 14) ? out_fifo_pop_data[14] : (fifo_cnt == 15) ? out_fifo_pop_data[15] :
                   (fifo_cnt == 16) ? out_fifo_pop_data[16] : (fifo_cnt == 17) ? out_fifo_pop_data[17] :
                   (fifo_cnt == 18) ? out_fifo_pop_data[18] : (fifo_cnt == 19) ? out_fifo_pop_data[19] :
                   (fifo_cnt == 20) ? out_fifo_pop_data[20] : (fifo_cnt == 21) ? out_fifo_pop_data[21] :
                   (fifo_cnt == 22) ? out_fifo_pop_data[22] : (fifo_cnt == 23) ? out_fifo_pop_data[23] :
                   (fifo_cnt == 24) ? out_fifo_pop_data[24] : (fifo_cnt == 25) ? out_fifo_pop_data[25] :
                   (fifo_cnt == 26) ? out_fifo_pop_data[26] : (fifo_cnt == 27) ? out_fifo_pop_data[27] : 0;
    assign valid = write_buffer_wait;

    assign out_fifo_push_req[0] = out_ofm_port_v0;
    assign out_fifo_push_req[1] = out_ofm_port_v0;
    assign out_fifo_push_req[2] = out_ofm_port_v1;
    assign out_fifo_push_req[3] = out_ofm_port_v1;
    assign out_fifo_push_req[4] = out_ofm_port_v2;
    assign out_fifo_push_req[5] = out_ofm_port_v2;
    assign out_fifo_push_req[6] = out_ofm_port_v3;
    assign out_fifo_push_req[7] = out_ofm_port_v3;
    assign out_fifo_push_req[8] = out_ofm_port_v4;
    assign out_fifo_push_req[9] = out_ofm_port_v4;
    assign out_fifo_push_req[10] = out_ofm_port_v5;
    assign out_fifo_push_req[11] = out_ofm_port_v5;
    assign out_fifo_push_req[12] = out_ofm_port_v6;
    assign out_fifo_push_req[13] = out_ofm_port_v6;
    assign out_fifo_push_req[14] = out_ofm_port_v7;
    assign out_fifo_push_req[15] = out_ofm_port_v7;
    assign out_fifo_push_req[16] = out_ofm_port_v8;
    assign out_fifo_push_req[17] = out_ofm_port_v8;
    assign out_fifo_push_req[18] = out_ofm_port_v9;
    assign out_fifo_push_req[19] = out_ofm_port_v9;
    assign out_fifo_push_req[20] = out_ofm_port_v10;
    assign out_fifo_push_req[21] = out_ofm_port_v10;
    assign out_fifo_push_req[22] = out_ofm_port_v11;
    assign out_fifo_push_req[23] = out_ofm_port_v11;
    assign out_fifo_push_req[24] = out_ofm_port_v12;
    assign out_fifo_push_req[25] = out_ofm_port_v12;
    assign out_fifo_push_req[26] = out_ofm_port_v13;
    assign out_fifo_push_req[27] = out_ofm_port_v13;

    assign out_fifo_push_data[0] = out_ofm0_port0;
    assign out_fifo_push_data[1] = out_ofm1_port0;
    assign out_fifo_push_data[2] = out_ofm0_port1;
    assign out_fifo_push_data[3] = out_ofm1_port1;
    assign out_fifo_push_data[4] = out_ofm0_port2;
    assign out_fifo_push_data[5] = out_ofm1_port2;
    assign out_fifo_push_data[6] = out_ofm0_port3;
    assign out_fifo_push_data[7] = out_ofm1_port3;
    assign out_fifo_push_data[8] = out_ofm0_port4;
    assign out_fifo_push_data[9] = out_ofm1_port4;
    assign out_fifo_push_data[10] = out_ofm0_port5;
    assign out_fifo_push_data[11] = out_ofm1_port5;
    assign out_fifo_push_data[12] = out_ofm0_port6;
    assign out_fifo_push_data[13] = out_ofm1_port6;
    assign out_fifo_push_data[14] = out_ofm0_port7;
    assign out_fifo_push_data[15] = out_ofm1_port7;
    assign out_fifo_push_data[16] = out_ofm0_port8;
    assign out_fifo_push_data[17] = out_ofm1_port8;
    assign out_fifo_push_data[18] = out_ofm0_port9;
    assign out_fifo_push_data[19] = out_ofm1_port9;
    assign out_fifo_push_data[20] = out_ofm0_port10;
    assign out_fifo_push_data[21] = out_ofm1_port10;
    assign out_fifo_push_data[22] = out_ofm0_port11;
    assign out_fifo_push_data[23] = out_ofm1_port11;
    assign out_fifo_push_data[24] = out_ofm0_port12;
    assign out_fifo_push_data[25] = out_ofm1_port12;
    assign out_fifo_push_data[26] = out_ofm0_port13;
    assign out_fifo_push_data[27] = out_ofm1_port13;

	reg r_end_conv;
    reg r_wmst_req;
    reg flag_wmst_req;
    assign wmst_req = r_wmst_req;


    reg [31:0] addr_cnt;


	always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            fifo_cnt <= 0;
        end else begin
             if(pop_req&&(!fifo_empty)) begin
                if(fifo_cnt==27)
                fifo_cnt <= 0;
                else
                fifo_cnt <= fifo_cnt + 1;
            end
            else 
                fifo_cnt <= fifo_cnt;
        end
    end

    always @(*) begin
        wmst_addr = wmst_offset + addr_cnt * WORD_BYTE; // 64 byte = 512bit
        wmst_xfer_size = WORD_BYTE * 2; //addr_cnt_temp * WORD_BYTE;
    end
	
	always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            r_wmst_req <=0;
            flag_wmst_req <= 0;
            addr_cnt <= 0;
        end else begin
            if(wmst_done) begin
                flag_wmst_req <= 0;
                if(r_end_conv & fifo_empty) begin
                    addr_cnt <= 0;
                end else begin
                    addr_cnt <= addr_cnt + 2;
                end
            end else if(out_fifo_data_cnt[27] > 0 & !flag_wmst_req) begin
                flag_wmst_req <= 1;
                r_wmst_req <= 1;
            end else if (r_wmst_req) begin
                r_wmst_req <= 0;
            end
        end
    end
	
	
	
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            r_end_conv <= 0;
        end else begin
            if(end_conv) r_end_conv <= 1;
            else if (wmst_done & r_end_conv & fifo_empty) begin
                r_end_conv <= 0;
            end
        end
    end
	
endmodule