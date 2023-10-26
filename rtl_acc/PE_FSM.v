`timescale 1ns / 1ps

module PE_FSM #(
    parameter K = 3,
    parameter T = 14,
    parameter S = 64,
    parameter P = 1
) (
    input clk,
    input stall,
    input rst_n,
    input start_conv,
    input start_again,
    input [31:0] cfg_ci,
    input [31:0] cfg_co,
    input [31:0] tile_num,  //# of tiles ex) 64x64 for T=16 R=5 --> 4*13*co = 52*co


    output reg ifm_read,
    output reg wgt_read,
    output reg p_valid_output,
    output reg last_chanel_output,
    output reg end_conv
);




    // reg [5:0] ci;
    // reg [5:0] co;

    // reg [5:0] cnt1;
    // reg [8:0] cnt2;
    // reg [8:0] cnt3;

    reg [31:0] ci;
    reg [31:0] co;

    reg [4:0] cnt1;
    reg [9:0] cnt2;
    reg [31:0] cnt3;



    reg [2:0] current_state;
    reg [2:0] next_state;

    // reg ifm_read;
    // reg wgt_read;
    reg p_valid;
    reg last_chanel;
    // reg end_conv;

    parameter [2:0] IDLE = 3'b000, S1 = 3'b001, S2 = 3'b010, FINISH = 3'b100;

    parameter [6:0] tile_length = 14;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) current_state <= IDLE;
        else current_state <= stall ? current_state : next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ci <= 0;
            co <= 0;
        end else if (start_conv) begin
            // ci <= ((cfg_ci + 6'b000001) << 3);
            // co <= ((cfg_co + 6'b000001) << 3);
            ci <= (((cfg_ci + 1) << 3));
            co <= (((cfg_co + 1) << 3));
        end
    end

    always @(current_state or start_conv or start_again or cnt1 or cnt2) begin
        next_state = 3'bx;
        case (current_state)
            IDLE:
            if (start_again && cnt1 == 0 && cnt2 == 0 && cnt3 == tile_num/S)
                next_state = FINISH;
            else if (start_again) next_state = S1;
            else next_state = IDLE;
            S1: next_state = (cnt1 == K) ? S2 : S1;
            S2:
            if (cnt2 == 0 && cnt1 == 0) next_state = IDLE;
            else if (cnt1 == 0) next_state = S1;
            // else if(cnt1 == 0)
            //     next_state = S1;
            else
                next_state = S2;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            {ifm_read, wgt_read, p_valid, last_chanel, end_conv} <= 5'b00000;
        else begin
            if (!stall) begin
                {ifm_read, wgt_read, p_valid, last_chanel, end_conv} <= 5'b00000;
                case (next_state)
                    IDLE:
                    {ifm_read, wgt_read, p_valid, last_chanel, end_conv} <= 5'b00000;
                    S1: begin
                        {ifm_read, wgt_read, end_conv} <= 3'b110;
                        p_valid <= (cnt1 < K - 1) ? 0 : 1;
                        last_chanel <= (cnt1 == K - 1 && cnt2 == 0) ? 1 : 0;
                    end
                    S2: begin
                        {ifm_read, wgt_read, p_valid, end_conv} <= 4'b1010;
                        last_chanel <= (cnt2 == 0) ? 1 : 0;
                    end
                    FINISH:
                    {ifm_read, wgt_read, p_valid, last_chanel, end_conv} <= 5'b00001;
                    default:
                    {ifm_read, wgt_read, p_valid, last_chanel, end_conv} <= 5'b00000;
                endcase
            end
        end



    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            cnt1 <= 0;
            cnt2 <= 0;
            cnt3 <= 0;
        end else begin
            if (!stall) begin
                if (next_state == FINISH) begin
                    cnt3 <= 0;
                    cnt2 <= 0;
                    cnt1 <= 0;
                end else if (next_state == IDLE) cnt1 <= 0;
                else begin
                    if (cnt1 == tile_length + (K-1)-1) cnt1 <= 0;
                    else cnt1 <= cnt1 + 1;

                    if (cnt1 == 0) begin
                        if (cnt2 == ci - 1) cnt2 <= 0;
                        else cnt2 <= cnt2 + 1;

                        if (cnt2 == 0)
                            if (cnt3 == tile_num/S) cnt3 <= 0;
                            else cnt3 <= cnt3 + 1;
                        else cnt3 <= cnt3;
                    end else cnt2 <= cnt2;
                end
            end

        end

    reg [2:0] p_valid_i;
    reg [2:0] last_chanel_i;
    // reg p_valid_output;
    // reg last_chanel_output;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            p_valid_output     <= 0;
            p_valid_i[2]       <= 0;
            p_valid_i[1]       <= 0;
            p_valid_i[0]       <= 0;
            last_chanel_output <= 0;
            last_chanel_i[2]   <= 0;
            last_chanel_i[1]   <= 0;
            last_chanel_i[0]   <= 0;
        end else begin
            if (!stall) begin
                p_valid_output     <= p_valid_i[2];
                p_valid_i[2]       <= p_valid_i[1];
                p_valid_i[1]       <= p_valid_i[0];
                p_valid_i[0]       <= p_valid;
                last_chanel_output <= last_chanel_i[2];
                last_chanel_i[2]   <= last_chanel_i[1];
                last_chanel_i[1]   <= last_chanel_i[0];
                last_chanel_i[0]   <= last_chanel;
            end
        end


endmodule  //PE
