///==------------------------------------------------------------------==///
/// Conv kernel: writeback controller
///==------------------------------------------------------------------==///
`timescale 1ns/1ps

module WRITE_BACK #(
    parameter data_width = 32,
    parameter depth = 61
) (
    input  clk,
    input  stall,
    input  rst_n,
    input  start_init,
    input  p_filter_end,
    input  row_valid,
    input  [data_width-1:0] row0,
    input  [data_width-1:0] row1,
    input  [data_width-1:0] row2,
    input  [data_width-1:0] row3,
    input  [data_width-1:0] row4,
	input  [data_width-1:0] row5,
	input  [data_width-1:0] row6,
	input  [data_width-1:0] row7,
    input  [data_width-1:0] row8,
    input  [data_width-1:0] row9,
    input  [data_width-1:0] row10,
    input  [data_width-1:0] row11,
    input  [data_width-1:0] row12,
	input  [data_width-1:0] row13,
    input  [data_width-1:0] row14,
	input  [data_width-1:0] row15,
    output p_write_zero0,
    output p_write_zero1,
    output p_write_zero2,
    output p_write_zero3,
    output p_write_zero4,
    output p_write_zero5,
    output p_write_zero6,
    output p_write_zero7,
    output p_write_zero8,
    output p_write_zero9,
    output p_write_zero10,
    output p_write_zero11,
    output p_write_zero12,
    output p_write_zero13,
    output p_init,
    output [data_width*16-1:0] out_port,
    output port_valid,
    output start_conv,
    output odd_cnt,


    input end_conv,
    output end_op
);
    /// machine state encode
    localparam IDLE         = 6'd0;
    localparam INIT_BUFF    = 6'd1;
    localparam START_CONV   = 6'd2;
    localparam WAIT_ADD     = 6'd3;
    localparam WAIT_WRITE0    = 6'd4;
    localparam ROW_0      = 6'd5;
    localparam CLEAR_0    = 6'd6;
    localparam ROW_1      = 6'd7;
    localparam CLEAR_1    = 6'd8;
    localparam ROW_2        = 6'd9;
    localparam CLEAR_2    = 6'd10;
    localparam ROW_3      = 6'd11;
    localparam CLEAR_3    = 6'd12;
    localparam ROW_4        = 6'd13;
    localparam CLEAR_4    = 6'd14;
    localparam ROW_5      = 6'd15;
    localparam CLEAR_5    = 6'd16;
    localparam ROW_6        = 6'd17;
    localparam CLEAR_6    = 6'd18;
    localparam ROW_7      = 6'd19;
    localparam CLEAR_7    = 6'd20;
    localparam ROW_8        = 6'd21;
    localparam CLEAR_8    = 6'd22;
    localparam ROW_9      = 6'd23;
    localparam CLEAR_9    = 6'd24;
    localparam ROW_10        = 6'd25;
    localparam CLEAR_10    = 6'd26;
    localparam ROW_11      = 6'd27;
    localparam CLEAR_11    = 6'd28;
    localparam ROW_12        = 6'd29;
    localparam CLEAR_12    = 6'd30;
    localparam ROW_13      = 6'd31;
    localparam CLEAR_13    = 6'd32;
    localparam CLEAR_START_CONV = 6'd33;
    localparam CLEAR_CNT    = 6'd34;
    localparam FINISH       = 6'd35;
    localparam END_CONV       = 6'd36;

    // localparam DONE         = 4'b1001;
    /// machine state

    reg [6:0] st_next;
    reg [6:0] st_cur;
    reg [7:0] cnt;
    reg r_end_conv;
    /// State transfer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            st_cur <= IDLE;
        else 
            st_cur <= !stall ? st_next : st_cur;
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
                st_next = ROW_0;
            ROW_0:
                if (cnt == depth-1)
                    st_next = CLEAR_0;
                else
                    st_next = ROW_0;
            CLEAR_0:
                st_next = ROW_1;
            ROW_1:
                if (cnt == depth-1)
                    st_next = CLEAR_1;
                else
                    st_next = ROW_1;
            CLEAR_1:
                st_next = ROW_2;
            ROW_2:
                if (cnt == depth-1)
                    st_next = CLEAR_2;
                else
                    st_next = ROW_2;
            CLEAR_2:
                st_next = ROW_3;
            ROW_3:
                if (cnt == depth-1)
                    st_next = CLEAR_3;
                else
                    st_next = ROW_3;
            CLEAR_3:
                st_next = ROW_4;
            ROW_4:
                if (cnt == depth-1)
                    st_next = CLEAR_4;
                else
                    st_next = ROW_4;
            CLEAR_4:
                st_next = ROW_5;
            ROW_5:
                if (cnt == depth-1)
                    st_next = CLEAR_5;
                else
                    st_next = ROW_5;
            CLEAR_5:
                st_next = ROW_6;
            ROW_6:
                if (cnt == depth-1)
                    st_next = CLEAR_6;
                else
                    st_next = ROW_6;
            CLEAR_6:
                st_next = ROW_7;
            ROW_7:
                if (cnt == depth-1)
                    st_next = CLEAR_7;
                else
                    st_next = ROW_7;
            CLEAR_7:
                st_next = ROW_8;
            ROW_8:
                if (cnt == depth-1)
                    st_next = CLEAR_8;
                else
                    st_next = ROW_8;
            CLEAR_8:
                st_next = ROW_9;
            ROW_9:
                if (cnt == depth-1)
                    st_next = CLEAR_9;
                else
                    st_next = ROW_9;
            CLEAR_9:
                st_next = ROW_10;
            ROW_10:
                if (cnt == depth-1)
                    st_next = CLEAR_10;
                else
                    st_next = ROW_10;
            CLEAR_10:
                st_next = ROW_11;
            ROW_11:
                if (cnt == depth-1)
                    st_next = CLEAR_11;
                else
                    st_next = ROW_11;
            CLEAR_11:
                st_next = ROW_12;
            ROW_12:
                if (cnt == depth-1)
                    st_next = CLEAR_12;
                else
                    st_next = ROW_12;
            CLEAR_12:
                st_next = ROW_13;
            ROW_13:
                if (cnt == depth-1)
                    st_next = r_end_conv ? FINISH : CLEAR_START_CONV;
                else
                    st_next = ROW_13;
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
    reg p_write_zero0_r;
    reg p_write_zero1_r;
    reg p_write_zero2_r;
    reg p_write_zero3_r;
    reg p_write_zero4_r;
    reg p_write_zero5_r;
    reg p_write_zero6_r;
    reg p_write_zero7_r;
    reg p_write_zero8_r;
    reg p_write_zero9_r;
    reg p_write_zero10_r;
    reg p_write_zero11_r;
    reg p_write_zero12_r;
    reg p_write_zero13_r;
    reg p_init_r;
    reg [data_width*16-1:0] out_port_r;
    reg port_valid_r;
    reg start_conv_r;

    /// Output start conv signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_conv_r <= 0;
        else if(!stall) begin
            if (st_cur == START_CONV || st_cur == CLEAR_CNT)
                start_conv_r <= 1;
            else
                start_conv_r <= 0;
        end
    end
    assign start_conv = start_conv_r;
    /// PingPong buffer controller signal
    reg odd_cnt_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            odd_cnt_r <= 0;
        else if(!stall) begin
            if (st_cur == CLEAR_CNT)
                odd_cnt_r <= ~odd_cnt;
            else
                odd_cnt_r <= odd_cnt;
        end
    end
    assign odd_cnt = odd_cnt_r;
    /// Output zero flag signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_write_zero0_r <= 0;
            p_write_zero1_r <= 0;
            p_write_zero2_r <= 0;
            p_write_zero3_r <= 0;
            p_write_zero4_r <= 0;
            p_write_zero5_r <= 0;
            p_write_zero6_r <= 0;
            p_write_zero7_r <= 0;
            p_write_zero8_r <= 0;
            p_write_zero9_r <= 0;
            p_write_zero10_r <= 0;
            p_write_zero11_r <= 0;
            p_write_zero12_r <= 0;
            p_write_zero13_r <= 0;
        end else if(!stall) begin
            if (st_cur == ROW_0)
                p_write_zero0_r <= 1;  
            else
                p_write_zero0_r <= 0;
            if (st_cur == ROW_1)
                p_write_zero1_r <= 1;  
            else
                p_write_zero1_r <= 0;
            if (st_cur == ROW_2)
                p_write_zero2_r <= 1;  
            else
                p_write_zero2_r <= 0;
            if (st_cur == ROW_3)
                p_write_zero3_r <= 1;  
            else
                p_write_zero3_r <= 0;
            if (st_cur == ROW_4)
                p_write_zero4_r <= 1;  
            else
                p_write_zero4_r <= 0;
            if (st_cur == ROW_5)
                p_write_zero5_r <= 1;  
            else
                p_write_zero5_r <= 0;
            if (st_cur == ROW_6)
                p_write_zero6_r <= 1;  
            else
                p_write_zero6_r <= 0;
            if (st_cur == ROW_7)
                p_write_zero7_r <= 1;  
            else
                p_write_zero7_r <= 0;
            if (st_cur == ROW_8)
                p_write_zero8_r <= 1;  
            else
                p_write_zero8_r <= 0;
            if (st_cur == ROW_9)
                p_write_zero9_r <= 1;  
            else
                p_write_zero9_r <= 0;
            if (st_cur == ROW_10)
                p_write_zero10_r <= 1;  
            else
                p_write_zero10_r <= 0;
            if (st_cur == ROW_11)
                p_write_zero11_r <= 1;  
            else
                p_write_zero11_r <= 0;
            if (st_cur == ROW_12)
                p_write_zero12_r <= 1;  
            else
                p_write_zero12_r <= 0;
            if (st_cur == ROW_13)
                p_write_zero13_r <= 1;  
            else
                p_write_zero13_r <= 0;
            

        end
    end

    assign p_write_zero0 = p_write_zero0_r; 
    assign p_write_zero1 = p_write_zero1_r; 
    assign p_write_zero2 = p_write_zero2_r; 
    assign p_write_zero3 = p_write_zero3_r; 
    assign p_write_zero4 = p_write_zero4_r; 
    assign p_write_zero5 = p_write_zero5_r; 
    assign p_write_zero6 = p_write_zero6_r; 
    assign p_write_zero7 = p_write_zero7_r; 
    assign p_write_zero8 = p_write_zero8_r; 
    assign p_write_zero9 = p_write_zero9_r; 
    assign p_write_zero10 = p_write_zero10_r; 
    assign p_write_zero11 = p_write_zero11_r; 
    assign p_write_zero12 = p_write_zero12_r; 
    assign p_write_zero13 = p_write_zero13_r; 

    /// Init buffer signal, why this signal? since, at the beginning, the buffer is empty, we only need to
    /// push zero to buffer without read from it, this behaviour is difference from p_write_zerox signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            p_init_r <= 0;
        else if(!stall) begin
            if (st_cur == INIT_BUFF)
                p_init_r <= 1;
            else
                p_init_r <= 0;
        end
    end
    assign p_init = p_init_r;
    /// Update the cnt
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 0;
        else if(!stall) begin
            if (st_cur == IDLE ||  st_cur == CLEAR_START_CONV || st_cur == CLEAR_0 || st_cur == CLEAR_1 || st_cur == CLEAR_2 || st_cur == CLEAR_3 || st_cur == CLEAR_4
                || st_cur == CLEAR_5 || st_cur == CLEAR_6 || st_cur == CLEAR_7 || st_cur == CLEAR_8 || st_cur == CLEAR_9 || st_cur == CLEAR_10 || st_cur == CLEAR_11
                || st_cur == CLEAR_12 || st_cur == CLEAR_13 || st_cur == CLEAR_CNT || st_cur == FINISH)
                cnt <= 0;
            else 
                cnt <= cnt + 1;
        end
    end

    // end of convolution assert

    reg r_end_op;
    assign end_op = r_end_op;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            r_end_op <= 0;
        else if(!stall)
            r_end_op <= st_cur == END_CONV ? 1 : 0;
    end

    // end_conv registering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            r_end_conv <= 0;
        else if(!stall) begin
            if (st_cur == FINISH)
                r_end_conv <= 0;
            else r_end_conv <= r_end_conv ? 1 : end_conv;
        end
    end

    /// Final result, a big mux
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_port_r <= 0;
            port_valid_r <= 0;
        end else if(!stall) begin
            out_port_r <= {row0, row1, row2, row3, row4, row5, row6, 
                           row7, row8, row9, row10, row11, row12, row13,
                          row14, row15};
            port_valid_r <= row_valid;  
        end
        else begin
             out_port_r <= 0;
             port_valid_r <= 0;
             end    
    end
    assign out_port = out_port_r;
    assign port_valid = port_valid_r;
endmodule
