module flatter #(
    parameter WORD_BYTE = 64
    )
    (
    input clk,
    input rst_n,
    input stall,

    input ofm_port0_v,
    input ofm_port1_v,

    input [24:0] ofm_port0,
    input [24:0] ofm_port1,

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

    reg [4:0] cnt;
    reg [511:0] ofm0;
    reg [511:0] ofm1;


    wire out_fifo_push_req;
    wire out_fifo_pop_req;
    wire [511:0] out_fifo_push_data;
    wire [511:0] out_fifo_pop_data;
    wire out_fifo_empty;
    wire out_fifo_full;
    wire [12:0] out_fifo_data_cnt;

    FifoType0 #(.data_width (512), .addr_bits (12)) ofm_fifo (
        .CLK        (clk),
        .nRESET     (rst_n),
        .PUSH_REQ   (!stall & out_fifo_push_req),
        .POP_REQ    (out_fifo_pop_req),
        .PUSH_DATA  (out_fifo_push_data),
        .CLEAR      (),
  
        .POP_DATA   (out_fifo_pop_data),
        .EMPTY      (out_fifo_empty),
        .FULL       (out_fifo_full),
        .ERROR      (),
        .DATA_CNT   (out_fifo_data_cnt)
    );

    reg [511:0] ofm_temp0;
    reg [511:0] ofm_temp1;
    reg p_req;

    assign write_buffer_wait = !out_fifo_empty;
    assign tdata = out_fifo_pop_data;
    assign valid = !out_fifo_empty;
    assign out_fifo_pop_req = ready & valid;
    assign out_fifo_push_req = p_req;
    assign out_fifo_push_data = ofm_temp0;

    reg [2:0] flat_done;

    localparam IDLE = 0;
    localparam WORD_READY_1 = 1;
    localparam WORD_READY_2 = 2;
    localparam LAST_WORD = 3;
    localparam PREQ = 4;
    localparam WREQ = 5;

    

    reg r_wmst_req;
    reg flag_wmst_req;
    assign wmst_req = r_wmst_req;


    reg [31:0] addr_cnt;

    always @(*) begin
        wmst_addr = wmst_offset + addr_cnt * WORD_BYTE; // 64 byte = 512bit
        wmst_xfer_size = WORD_BYTE * 2; //addr_cnt_temp * WORD_BYTE;
    end


    // always @(posedge clk, negedge rst_n) begin
    //     if(!rst_n) begin
    //         addr_cnt <= 0;
    //     end else begin
    //         addr_cnt <= start_conv ? 0 : out_fifo_pop_req ? addr_cnt + 1 : addr_cnt;
    //     end
    // end
    reg r_end_conv;
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            r_end_conv <= 0;
        end else begin
            if(end_conv) r_end_conv <= 1;
            else if (wmst_done & r_end_conv & out_fifo_empty) begin
                r_end_conv <= 0;
            end
        end
    end

    reg [31:0] wcnt;
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            r_wmst_req <=0;
            flag_wmst_req <= 0;
            addr_cnt <= 0;
        end else begin
            if(wmst_done) begin
                flag_wmst_req <= 0;
                if(r_end_conv & out_fifo_empty) begin
                    addr_cnt <= 0;
                end else begin
                    addr_cnt <= addr_cnt + 2;
                end
            end else if(out_fifo_data_cnt > 1 & !flag_wmst_req) begin
                flag_wmst_req <= 1;
                r_wmst_req <= 1;
            end else if (r_wmst_req) begin
                r_wmst_req <= 0;
            end
        end
    end

    reg r_port_v;
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
            ofm0 <= 0;
            ofm1 <= 0;
            ofm_temp0 <= 0;
            ofm_temp1 <= 0;
            p_req <= 0;
            flat_done <= 0;
            wcnt <= 0;
            r_port_v <= 0;
        end else begin
            if(!stall) begin
                if (flat_done == WORD_READY_1) begin
                    ofm_temp0 <= ofm_temp1;
                    flat_done <= PREQ;
                    p_req <= 1;
                end else if (flat_done == PREQ) begin
                    p_req <= 0;
                    flat_done <= IDLE;
                end
                if (cnt == 16) begin
                        cnt <= 0;
                        flat_done <= (r_port_v) ? PREQ : WORD_READY_1;
                        ofm_temp0 <= ofm0;
                        ofm_temp1 <= ofm1;
                        p_req <= 1;
                    end else begin
                        if (ofm_port0_v) ofm0[cnt * 32 +: 32] <= {7'b000_0000,ofm_port0};
                        if (ofm_port1_v) ofm1[cnt * 32 +: 32] <= {7'b000_0000, ofm_port1};
                        cnt <= (ofm_port0_v | ofm_port1_v) ? cnt + 1 : cnt;
                        r_port_v <= ofm_port0_v ^ ofm_port1_v;
                end
            end
        end
    end


//for debug

    reg [31:0] p_ofm0 [0:15];
    reg [31:0] p_ofm1 [0:15];
    integer i;
    always @(*) begin
        for(i = 0; i < 16; i=i+1) begin
            p_ofm0[i] <= ofm0[i*32 +: 32];
            p_ofm1[i] <= ofm1[i*32 +: 32];
        end
    end

    reg [31:0] wmst_done_counter;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            wmst_done_counter <= 0;
        end else wmst_done_counter <= wmst_done ? wmst_done_counter + 1 : wmst_done_counter;
    end
endmodule