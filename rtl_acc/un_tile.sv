module un_tile #(
    parameter OFM_WIDTH = 25,
    parameter OH = 61,
    parameter OW = 61
)(
    input clk,
    input rst_n,

    input port0_v,
    input port1_v,
    input [OFM_WIDTH-1:0] port0,
    input [OFM_WIDTH-1:0] port1,

    input [31:0] ofm_ch,
    input [31:0] ti,
    
    input read,

    output  [OFM_WIDTH-1:0] ofm [0:OW-1][0:OH-1],
    output d_valid
);

    reg [7:0] ow, oh, oc, tw, thcnt;
    reg buffer_flag;
    reg reg_d_valid;

    reg [OFM_WIDTH-1:0] ofm_buffer_0 [0:OW-1][0:OH-1];
    reg [OFM_WIDTH-1:0] ofm_buffer_1 [0:OW-1][0:OH-1];

    assign ofm = buffer_flag ? ofm_buffer_0 : ofm_buffer_1;
    
    assign d_valid = reg_d_valid;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            ofm_buffer_0 <= 0;
            ofm_buffer_1 <= 0;
            buffer_flag <= 0;
            reg_d_valid <= 0;
        end else begin
            reg_d_valid <= read ? 0 : reg_d_valid;
            if (port0_v && port1_v) begin
                ofm_buffer[buffer_flag][oh][ow+tw*ti]   <= port0;
                ofm_buffer[buffer_flag][oh+1][ow+tw*ti] <= port1;
                ow <= ow + 1;
                if (ow == ti) begin
                    ow <= 0;
                    oh <= oh + 2;
                    thcnt <= thcnt + 2;
                end 
            end else if (port0_v) begin
                ofm_buffer[buffer_flag][oh][ow+tw*ti] <= port0;
                ow <= ow + 1;
                if (ow == ti) begin
                    ow <= 0;
                    oh <= oh + 1;
                    thcnt <= thcnt + 1;
                    if (thcnt == 5) begin
                        thcnt <= 0;
                        tw <= tw + 1;
                        oh <= oh - 5;
                        if (tw == 4) begin
                            tw <= 0;
                            oh <= oh + 5;
                        end
                    end
                end 
                if (oh == 65) begin
                    oh <= 0;
                    buffer_flag <= !buffer_flag;
                    reg_d_valid <= 1;
                end
            end
        end
    end

endmodule
