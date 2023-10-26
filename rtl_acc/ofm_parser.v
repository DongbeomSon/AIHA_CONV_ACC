module ofm_parser #(
    parameter FIFO_ADDR_WIDTH = 10,

    parameter R = 14,
    parameter S = 16,

    parameter INPUT_WIDTH = 32*S,
    parameter OUTPUT_WIDTH = 512,
    parameter MAX_CNT = INPUT_WIDTH/OUTPUT_WIDTH
    )
    (
    input clk,
    input rst_n,
    input g_stall,

    input op_start,

    input ofm_port_v,

    input [INPUT_WIDTH-1:0] ofm_port,

    input [31:0] ofm_size,

    input end_conv,

    output [OUTPUT_WIDTH-1:0] tdata,
    input ready,
    output valid,

    input [63:0] wmst_offset,
    input wmst_done,
    output reg wmst_req,
    output [63:0] wmst_addr,
    output [63:0] wmst_xfer_size,
    output write_buffer_wait,

    output stall
);

    reg [31:0] cnt;

    reg [OUTPUT_WIDTH-1:0] ofm;


    wire out_fifo_push_req;
    wire out_fifo_pop_req;
    wire [OUTPUT_WIDTH-1:0] out_fifo_push_data;
    wire [OUTPUT_WIDTH-1:0] out_fifo_pop_data;
    wire [OUTPUT_WIDTH-1:0] out_fifo_bypass_data;
    wire out_fifo_empty;
    wire out_fifo_full;
    wire [FIFO_ADDR_WIDTH:0] out_fifo_data_cnt;

    wire in_fifo_push_req;
    wire in_fifo_pop_req;
    wire [INPUT_WIDTH-1:0] in_fifo_push_data;
    wire [INPUT_WIDTH-1:0] in_fifo_pop_data;
    wire in_fifo_empty;
    wire in_fifo_full;
    wire [FIFO_ADDR_WIDTH:0] in_fifo_data_cnt;

    

    reg flag_wmst_req;

    // address alignment
    reg r_end_conv;

    reg [31:0] in_cnt;
    reg in_flag;

    wire out_fifo_stall = !r_end_conv & out_fifo_full;
    wire in_fifo_stall = !r_end_conv & g_stall;
    wire parser_stall = !r_end_conv & (in_fifo_empty | out_fifo_full);

    FifoType0 #(.data_width (OUTPUT_WIDTH), .addr_bits (FIFO_ADDR_WIDTH)) ofm_fifo (
        .CLK        (clk),
        .nRESET     (rst_n),
        .PUSH_REQ   (!parser_stall & out_fifo_push_req),
        .POP_REQ    (out_fifo_pop_req),
        .PUSH_DATA  (out_fifo_push_data),
        .CLEAR      (),
  
        .POP_DATA   (out_fifo_pop_data),
        .EMPTY      (out_fifo_empty),
        .FULL       (out_fifo_full),
        .ERROR      (),
        .DATA_CNT   (out_fifo_data_cnt)
    );

    FifoType0 #(.data_width (INPUT_WIDTH), .addr_bits (FIFO_ADDR_WIDTH)) in_fifo (
        .CLK        (clk),
        .nRESET     (rst_n),
        .PUSH_REQ   (!in_fifo_stall & in_fifo_push_req),
        .POP_REQ    (!parser_stall & in_fifo_pop_req),
        .PUSH_DATA  (in_fifo_push_data),
        .CLEAR      (),
  
        .POP_DATA   (in_fifo_pop_data),
        .EMPTY      (in_fifo_empty),
        .FULL       (in_fifo_full),
        .ERROR      (),
        .DATA_CNT   (in_fifo_data_cnt)
    );

    wire in_pop_req;
    assign in_fifo_pop_req = in_pop_req & !in_fifo_empty;
    assign in_fifo_push_req = ofm_port_v; //| (final_write & ready & valid);
    assign in_fifo_push_data = ofm_port; // final_write ? in_fifo_pop_data : ofm_temp0;
    
    

    reg in_bypass_flag;
    reg [INPUT_WIDTH-1:0] in_bypass_input;

    wire [INPUT_WIDTH-1:0] in_parse_data;

    assign in_parse_data = in_bypass_flag ? in_bypass_input : in_fifo_pop_data;


    reg [OUTPUT_WIDTH-1:0] ofm_temp;
    //reg p_req;

    reg [OUTPUT_WIDTH-1:0] bypass_input;
    reg bypass_flag;

    reg r_wait_xfer;

    assign write_buffer_wait = r_wait_xfer;
    assign tdata = bypass_flag ? bypass_input : out_fifo_pop_data;
    assign valid = !out_fifo_empty;
    assign out_fifo_pop_req = ready & valid;
    assign out_fifo_push_req = in_flag; //| (final_write & ready & valid);
    // assign out_fifo_push_data = ofm_temp; // final_write ? out_fifo_pop_data : ofm_temp0;


    parser #(.INPUT_WIDTH(INPUT_WIDTH), .OUTPUT_WIDTH(OUTPUT_WIDTH)) ofm_int_parser (
        .clk(clk),
        .rst_n(rst_n),

        .fm(in_parse_data),
        .ifm_read(in_flag),

        .parse_out(out_fifo_push_data),
        .input_req(in_pop_req),

        .stall((!in_flag)|parser_stall)
    );


    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            in_bypass_flag  <= 0;
            in_bypass_input <= 0;
        end else begin
            if (in_fifo_push_req) begin
                if(in_fifo_empty | (in_fifo_data_cnt == 1 & in_fifo_pop_req & in_fifo_push_req)) begin
                    in_bypass_flag  <= 1;
                    in_bypass_input <= in_fifo_push_data;
                end else begin
                    in_bypass_flag <= 0;
                end
            end else begin
                in_bypass_flag <= 0;
            end
        end
    end


    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            in_cnt <= 0;
            in_flag <= 0;
        end else begin
            if(in_fifo_push_req | !in_fifo_empty) begin
                in_flag <= 1;
                in_cnt <= |in_cnt ? in_cnt-1 : MAX_CNT-1;
            end else begin
                if(|in_cnt) begin
                    in_cnt <= in_cnt-1;
                    in_flag <= 1;
                end else begin
                    in_cnt <= 0;
                    in_flag <= 0;
                end
            end
        end
    end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            bypass_flag  <= 0;
            bypass_input <= 0;
        end else begin
            if (out_fifo_push_req) begin
                if(out_fifo_empty | (out_fifo_data_cnt == 1 & out_fifo_pop_req & out_fifo_push_req)) begin
                    bypass_flag  <= 1;
                    bypass_input <= out_fifo_push_data;
                end else begin
                    bypass_flag <= 0;
                end
            end else begin
                bypass_flag <= 0;
            end
        end
    end

    assign stall = in_fifo_full;

    reg [2:0] flat_done;

    // localparam IDLE = 0;
    // localparam WORD_READY_1 = 1;
    // localparam WORD_READY_2 = 2;
    // localparam LAST_WORD = 3;
    // localparam PREQ = 4;
    // localparam WREQ = 5;

    assign wmst_addr = wmst_offset;
    assign wmst_xfer_size = {{32{1'b0}}, ofm_size};
    // always @(posedge clk, negedge rst_n) begin
    //     if(!rst_n) begin
    //         wmst_xfer_size <= 0;
    //     end else begin
    //         if(op_start)begin
    //             wmst_xfer_size <= {{32{1'b0}}, ofm_size};
    //             wmst_addr <= wmst_offset;
    //         end
    //     end
    // end


    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            wmst_req <=0;
            flag_wmst_req <= 0;
            r_wait_xfer <= 0;
            r_end_conv <= 0;
        end else begin
            if(op_start) begin
                wmst_req <= 1;
                r_wait_xfer <= 1;
            end else begin
                wmst_req <= 0;
            end

            if((end_conv | r_end_conv)& wmst_done) begin
                r_wait_xfer <= 0;
                r_end_conv <= 0;
            end else if(end_conv) begin
                r_end_conv <= 1;
            end
        end
    end

    // reg r_port_v;
    // always @(posedge clk, negedge rst_n) begin
    //     if (!rst_n) begin
    //         cnt <= 0;
    //         ofm0 <= 0;
    //         ofm1 <= 0;
    //         ofm_temp0 <= 0;
    //         ofm_temp1 <= 0;
    //         p_req <= 0;
    //         flat_done <= 0;
    //         wcnt <= 0;
    //         r_port_v <= 0;
    //     end else begin
    //         if(!g_stall) begin
    //             if (flat_done == WORD_READY_1) begin
    //                 ofm_temp0 <= ofm_temp1;
    //                 flat_done <= PREQ;
    //                 p_req <= 1;
    //             end else if (flat_done == PREQ) begin
    //                 p_req <= 0;
    //                 flat_done <= IDLE;
    //             end
    //             if (cnt == 16) begin
    //                     cnt <= 0;
    //                     flat_done <= (r_port_v) ? PREQ : WORD_READY_1;
    //                     ofm_temp0 <= ofm0;
    //                     ofm_temp1 <= ofm1;
    //                     p_req <= 1;
    //                 end else begin
    //                     if (ofm_port0_v) ofm0[cnt * 32 +: 32] <= {7'b000_0000,ofm_port0};
    //                     if (ofm_port1_v) ofm1[cnt * 32 +: 32] <= {7'b000_0000, ofm_port1};
    //                     cnt <= (ofm_port0_v | ofm_port1_v) ? cnt + 1 : cnt;
    //                     r_port_v <= ofm_port0_v ^ ofm_port1_v;
    //             end
    //         end
    //     end
    // end


    // reg [31:0] p_ofm0 [0:15];
    // reg [31:0] p_ofm1 [0:15];
    // integer i;
    // always @(*) begin
    //     for(i = 0; i < 16; i=i+1) begin
    //         p_ofm0[i] <= ofm0[i*32 +: 32];
    //         p_ofm1[i] <= ofm1[i*32 +: 32];
    //     end
    // end


// //for debug
    reg [31:0] wmst_done_counter;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            wmst_done_counter <= 0;
        end else wmst_done_counter <= ready & valid ? wmst_done_counter + 1 : wmst_done_counter;
    end

	// // ILA monitoring combinatorial adder
	// ila_0 i_ila_0 (
	// 	.clk(clk),              // input wire        clk
	// 	.probe0(op_start),           // input wire [0:0]  probe0  
	// 	.probe1(wmst_offset), // input wire [63:0]  probe1 
	// 	.probe2(wmst_addr),   // input wire [63:0]  probe2 
	// 	.probe3(wmst_xfer_size),    // input wire [63:0] probe3 
    //     .probe4(ready),      // input wire [0:0] probe4
    //     .probe5(valid),       // input wire [0:0] probe5
    //     .probe6(wmst_req),       // input wire [0:0] probe6
    //     .probe7(wmst_done),    // input wire [0:0] probe7
    //     .probe8(out_fifo_data_cnt),    // input wire [7:0] probe8
    //     .probe9(align_fifo_data_cnt),    // input wire [6:0] probe9
    //     .probe10(end_conv),   // input wire [0:0] probe10
    //     .probe11(g_stall),   // input wire [0:0] probe11
    //     .probe12(tdata),      // input wire [511:0] probe12
    //     .probe13(ofm_size)     // input wire [31:0] probe13
	// );
endmodule