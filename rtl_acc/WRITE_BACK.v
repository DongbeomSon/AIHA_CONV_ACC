///==------------------------------------------------------------------==///
/// Conv kernel: writeback controller
///==------------------------------------------------------------------==///
`timescale 1ns / 1ps

module WRITE_BACK #(
    parameter data_width = 32,
    parameter depth = 61,
    parameter S = 64,
    parameter R = 14
) (
    input clk,
    input stall,
    input rst_n,
    input start_init,
    input p_filter_end,
    input [R-1:0] row_valid,
    input [data_width*R-1:0] row,
    output [R-1:0] p_write_zero,
    output p_init,
    output [data_width-1:0] out_port,
    output port_valid,
    output start_conv,
    output odd_cnt,

    input  end_conv,
    output end_op
);
    /// machine state encode
    localparam IDLE = 4'd0;
    localparam INIT_BUFF = 4'd1;
    localparam START_CONV = 4'd2;
    localparam WAIT_ADD = 4'd3;
    localparam WAIT_WRITE0 = 4'd4;
    localparam ROW_0 = 6'd5;
    localparam CLEAR_0 = 6'd6;
    localparam CLEAR_START_CONV = 6'd7;
    localparam CLEAR_CNT = 6'd8;
    localparam FINISH = 6'd9;
    localparam END_CONV = 6'd10;

    // localparam DONE         = 4'b1001;
    /// machine state

    reg [6:0] st_next;
    reg [6:0] st_cur;
    reg [7:0] cnt;
    reg [R-1:0] row_cnt;
    reg [6:0] row_cnt_int;
    reg r_end_conv;
    /// State transfer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) st_cur <= IDLE;
        else st_cur <= !stall ? st_next : st_cur;
    end
    /// Next state logic
    always @(*) begin
        st_next = st_cur;
        case (st_cur)
            IDLE:
            if (start_init) st_next = INIT_BUFF;
            else st_next = IDLE;
            INIT_BUFF:
            if (cnt == depth - 1) st_next = START_CONV;
            else st_next = INIT_BUFF;
            START_CONV:
            if (cnt >= depth + 2) st_next = CLEAR_START_CONV;
            else st_next = START_CONV;
            CLEAR_START_CONV:
            if (p_filter_end) st_next = WAIT_ADD;
            else st_next = CLEAR_START_CONV;
            WAIT_ADD:
            if (cnt == depth - 1) st_next = WAIT_WRITE0;
            else st_next = WAIT_ADD;
            WAIT_WRITE0: st_next = CLEAR_CNT;
            CLEAR_CNT: st_next = ROW_0;
            ROW_0:
            if (cnt == depth - 1)
                if (row_cnt[R-1]) begin
                    st_next = r_end_conv ? FINISH : CLEAR_START_CONV;
                end else begin
                    st_next = CLEAR_0;
                end
            else st_next = ROW_0;
            CLEAR_0: st_next = ROW_0;
            FINISH: st_next = !port_valid ? END_CONV : FINISH;
            END_CONV: st_next = IDLE;
            // DONE:
            //     st_next = START_CONV;
            default: st_next = IDLE;
        endcase
    end
    /// Output logic
    reg [R-1:0]p_write_zero_r;
    reg p_init_r;
    reg [data_width-1:0] out_port_r;
    reg port_valid_r;
    reg start_conv_r;

    /// Output start conv signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) start_conv_r <= 0;
        else if (!stall) begin
            if (st_cur == START_CONV || st_cur == CLEAR_CNT) start_conv_r <= 1;
            else start_conv_r <= 0;
        end
    end
    assign start_conv = start_conv_r;
    /// PingPong buffer controller signal
    reg odd_cnt_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) odd_cnt_r <= 0;
        else if (!stall) begin
            if (st_cur == CLEAR_CNT) odd_cnt_r <= ~odd_cnt;
            else odd_cnt_r <= odd_cnt;
        end
    end
    assign odd_cnt = odd_cnt_r;
    /// Output zero flag signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_write_zero_r <= 0;
        end else if (!stall) begin
            if (st_cur == ROW_0) p_write_zero_r <= row_cnt;
            else p_write_zero_r <= 0;
        end
    end

    assign p_write_zero = p_write_zero_r;
    /// Init buffer signal, why this signal? since, at the beginning, the buffer is empty, we only need to
    /// push zero to buffer without read from it, this behaviour is difference from p_write_zerox signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) p_init_r <= 0;
        else if (!stall) begin
            if (st_cur == INIT_BUFF) p_init_r <= 1;
            else p_init_r <= 0;
        end
    end
    assign p_init = p_init_r;
    /// Update the cnt
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            row_cnt <= 1;
            row_cnt_int <= 0;
        end else if (!stall) begin
            if (st_cur == IDLE ||  st_cur == CLEAR_START_CONV || st_cur == CLEAR_0 || st_cur == CLEAR_CNT || st_cur == FINISH) begin
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
            end

            if (st_cur == ROW_0 || st_cur == CLEAR_0) begin
                if (st_cur == CLEAR_0) begin
                    row_cnt <= row_cnt << 1;
                    row_cnt_int <= row_cnt_int + 1;
                end else begin
                    row_cnt <= row_cnt;
                    row_cnt_int <= row_cnt_int;
                end
            end else begin
                row_cnt <= 1;
                row_cnt_int <= 0;
            end
        end
    end


    // end of convolution assert

    reg r_end_op;
    assign end_op = r_end_op;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) r_end_op <= 0;
        else if (!stall) r_end_op <= st_cur == END_CONV ? 1 : 0;
    end

    // end_conv registering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) r_end_conv <= 0;
        else if (!stall) begin
            if (st_cur == FINISH) r_end_conv <= 0;
            else r_end_conv <= r_end_conv ? 1 : end_conv;
        end
    end



    reg [data_width-1:0] r_parse [R-1:0];
    reg [data_width-1:0] r_parse_out;

    integer i;
    always @(*) begin
        for(i = 0; i < R; i=i+1) begin
            r_parse[i] <= row[i*data_width +: data_width];
        end
    end


    always @(*) begin
        for(i = 0; i < R; i=i+1) begin
            if (row_valid == (1 << i))
                r_parse_out = r_parse[i];
        end
    end


    /// Final result, a big mux
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_port_r   <= 0;
            port_valid_r <= 0;
        end else if (!stall) begin
            // out_port_r   <= r_parse[row_cnt_int];
            out_port_r <= r_parse_out;
            port_valid_r <= |row_valid;
            //port_valid_r <= row_valid[row_cnt_int];
        end else begin
            out_port_r   <= 0;
            port_valid_r <= 0;
        end
    end
    assign out_port   = out_port_r;
    assign port_valid = port_valid_r;
endmodule
