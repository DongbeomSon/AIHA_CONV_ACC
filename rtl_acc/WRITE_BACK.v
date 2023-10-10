///==------------------------------------------------------------------==///
/// Conv kernel: writeback controller
///==------------------------------------------------------------------==///
`timescale 1ns/1ps

module WRITE_BACK #(
    parameter data_width = 32,
    parameter depth = 61
) (
    input  clk,
    input  rst_n,
    input  start_init,
    input  p_filter_end,
    input  [data_width-1:0] row0,
    input  row0_valid,
    input  [data_width-1:0] row1,
    input  row1_valid,
    input  [data_width-1:0] row2,
    input  row2_valid,
    input  [data_width-1:0] row3,
    input  row3_valid,
    input  [data_width-1:0] row4,
    input  row4_valid,
	input  [data_width-1:0] row5,
    input  row5_valid,
	input  [data_width-1:0] row6,
    input  row6_valid,
	input  [data_width-1:0] row7,
    input  row7_valid,
    input  [data_width-1:0] row8,
    input  row8_valid,
    input  [data_width-1:0] row9,
    input  row9_valid,
    input  [data_width-1:0] row10,
    input  row10_valid,
    input  [data_width-1:0] row11,
    input  row11_valid,
    input  [data_width-1:0] row12,
    input  row12_valid,
	input  [data_width-1:0] row13,
    input  row13_valid,
    input  [data_width-1:0] row14,
    input  row14_valid,
	input  [data_width-1:0] row15,
    input  row15_valid,
    output p_write_zero,
    output p_init,
    output [127:0] out_port,
    output port_valid,
    output start_conv,
    output odd_cnt,


    input end_conv,
    output end_op
);
    /// machine state encode
    localparam IDLE         = 4'd0;
    localparam INIT_BUFF    = 4'd1;
    localparam START_CONV   = 4'd2;
    localparam WAIT_ADD     = 4'd3;
    localparam WAIT_WRITE0    = 4'd4;
    localparam ROW          = 4'd5;
    localparam CLEAR_START_CONV = 4'd6;
    localparam CLEAR_CNT    = 4'd7;
    localparam FINISH       = 4'd8;
    localparam END_CONV       = 4'd9;

    // localparam DONE         = 4'b1001;
    /// machine state
	
    reg [3:0] st_next;
    reg [3:0] st_cur;
    reg [7:0] cnt;
    reg r_end_conv;
    reg [data_width-1:0] channel_sum1[0:7];
    reg [data_width-1:0] channel_sum2[0:7];


    /// State transfer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            st_cur <= IDLE;
        else 
            st_cur <= st_next;
    end
    /// Next state logic
    always @(*) begin
        st_next = st_cur;
        case(st_cur)
            IDLE:
                if (start_init)
                    st_next = INIT_BUFF;
                else
                    st_next = IDLE;
            INIT_BUFF:
                if (cnt == depth-1)
                    st_next = START_CONV;
                else
                    st_next = INIT_BUFF;
            START_CONV:
                if (cnt >= depth+2)
                    st_next = CLEAR_START_CONV;
                else 
                    st_next = START_CONV;
            CLEAR_START_CONV:
                if (p_filter_end)
                    st_next = WAIT_ADD;
                else
                    st_next = CLEAR_START_CONV;
            WAIT_ADD:
                if (cnt == depth-1)
                    st_next = WAIT_WRITE0;
                else
                    st_next = WAIT_ADD;
            WAIT_WRITE0:
                st_next = CLEAR_CNT;
            CLEAR_CNT:
                st_next = ROW;
            ROW:
                if (cnt == depth-1)
                    st_next = r_end_conv ? FINISH : CLEAR_START_CONV;
                else
                    st_next = ROW;
            FINISH:
                    st_next = !port_valid ? END_CONV : FINISH;
            END_CONV:
                    st_next = IDLE;
            // DONE:
            //     st_next = START_CONV;
            default:
                st_next = IDLE;  
        endcase
    end
    /// Output logic
    reg p_write_zero_r;
    reg p_init_r;
    reg [127:0] out_port_r;
    reg port_valid_r[0:2];
    reg start_conv_r;
    wire row_valid = (row0_valid & row1_valid & row2_valid & row3_valid 
					 & row4_valid & row5_valid & row6_valid & row7_valid
					 & row8_valid & row9_valid & row10_valid & row11_valid 
					 & row12_valid & row13_valid);	
    /// Output start conv signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_conv_r <= 0;
        else if (st_cur == START_CONV || st_cur == CLEAR_CNT)
            start_conv_r <= 1;
        else
            start_conv_r <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            channel_sum1[0] <= 0;
            channel_sum1[1] <= 0;
            channel_sum1[2] <= 0;
            channel_sum1[3] <= 0;
            channel_sum1[4] <= 0;
            channel_sum1[5] <= 0;
            channel_sum1[6] <= 0;
            channel_sum1[7] <= 0;
            channel_sum2[0] <= 0;
            channel_sum2[1] <= 0;
            channel_sum2[2] <= 0;
            channel_sum2[3] <= 0;
            port_valid_r[0] <= 0;
        end
        else if (row_valid) begin
            channel_sum1[0] <= row0 + row4;
            channel_sum1[1] <= row8 + row12;
            channel_sum1[2] <= row1 + row5;
            channel_sum1[3] <= row9 + row13;
            channel_sum1[4] <= row2 + row6;
            channel_sum1[5] <= row10 + row14;
            channel_sum1[6] <= row3 + row7;
            channel_sum1[7] <= row11 + row15;
            port_valid_r[0] <= row_valid;
        end
        else begin
            channel_sum1[0] <= 0;
            channel_sum1[1] <= 0;
            channel_sum1[2] <= 0;
            channel_sum1[3] <= 0;
            channel_sum1[4] <= 0;
            channel_sum1[5] <= 0;
            channel_sum1[6] <= 0;
            channel_sum1[7] <= 0;
            channel_sum2[0] <= 0;
            channel_sum2[1] <= 0;
            channel_sum2[2] <= 0;
            channel_sum2[3] <= 0;
            port_valid_r[0] <= 0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            channel_sum2[0] <= 0;
            channel_sum2[1] <= 0;
            channel_sum2[2] <= 0;
            channel_sum2[3] <= 0;
            port_valid_r[1] <= 0;
        end
        else if (port_valid_r[0]) begin
            channel_sum2[0] <= channel_sum1[0] + channel_sum1[1];
            channel_sum2[1] <= channel_sum1[2] + channel_sum1[3];
            channel_sum2[2] <= channel_sum1[4] + channel_sum1[5];
            channel_sum2[3] <= channel_sum1[6] + channel_sum1[7];
            port_valid_r[1] <= port_valid_r[0];
        end
        else begin
            channel_sum2[0] <= 0;
            channel_sum2[1] <= 0;
            channel_sum2[2] <= 0;
            channel_sum2[3] <= 0;
            port_valid_r[1] <= 0;
        end
    end
    assign start_conv = start_conv_r;
    /// PingPong buffer controller signal
    reg odd_cnt_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            odd_cnt_r <= 0;
        else if (st_cur == CLEAR_CNT)
            odd_cnt_r <= ~odd_cnt;
        else
            odd_cnt_r <= odd_cnt;
    end
    assign odd_cnt = odd_cnt_r;
    /// Output zero flag signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_write_zero_r <= 0;
        end else if (st_cur == ROW) begin
            p_write_zero_r <= 1;  
        end else begin
            p_write_zero_r <= 0;
        end
    end
    
    assign p_write_zero = p_write_zero_r; 
    /// Init buffer signal, why this signal? since, at the beginning, the buffer is empty, we only need to
    /// push zero to buffer without read from it, this behaviour is difference from p_write_zerox signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            p_init_r <= 0;
        else if (st_cur == INIT_BUFF)
            p_init_r <= 1;
        else
            p_init_r <= 0;
    end
    assign p_init = p_init_r;
    /// Update the cnt
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 0;
        else if (st_cur == IDLE ||  st_cur == CLEAR_START_CONV
            || st_cur == CLEAR_CNT || st_cur == FINISH)
            cnt <= 0;
        else 
            cnt <= cnt + 1;
    end


    // end of convolution assert

    reg r_end_op;
    assign end_op = r_end_op;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            r_end_op <= 0;
        else r_end_op <= st_cur == END_CONV ? 1 : 0;
    end

    // end_conv registering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            r_end_conv <= 0;
        else if (st_cur == FINISH)
            r_end_conv <= 0;
        else r_end_conv <= r_end_conv ? 1 : end_conv;
    end


		

    /// Final result, a big mux
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_port_r <= 0;
			port_valid_r[2] <= 0;
        end else begin
            if(port_valid_r[1])
                begin
                    out_port_r[31:0] <= channel_sum2[0][data_width-1] ? 0 : channel_sum2[0];
					out_port_r[63:32] <= channel_sum2[1][data_width-1] ? 0 : channel_sum2[1];
					out_port_r[95:64] <= channel_sum2[2][data_width-1] ? 0 : channel_sum2[2];
					out_port_r[127:96] <= channel_sum2[3][data_width-1] ? 0 : channel_sum2[3];
					port_valid_r[2] <= port_valid_r[1];
				end
			else
				begin
					out_port_r <= 0;
					port_valid_r[2] <= 0;
				end
		end
    end
    assign out_port = out_port_r;
    assign port_valid = port_valid_r[2];
endmodule
