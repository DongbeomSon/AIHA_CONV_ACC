module flatter #(
    parameter WORD_BYTE = 64,
    parameter DATA_WIDTH = 512,
    parameter DATA_WIDTH_BYTE = DATA_WIDTH / 8,
    parameter DATA_NUM = 64,  //eqeaul to burst len
    //    parameter DATA_NUM_BYTE = 63232,
    parameter FIFO_ADDR_WIDTH = 7,
    parameter BURST_LENGTH = 64,
    parameter BURST_LENGTH_BYTE = DATA_WIDTH_BYTE * BURST_LENGTH
    )
    (
    input clk,
    input rst_n,
    input g_stall,

    input op_start,

    input ofm_port0_v,
    input ofm_port1_v,

    input [24:0] ofm_port0,
    input [24:0] ofm_port1,

    input end_conv,

    input [31:0] ofm_size,

    output [511:0] tdata,
    input ready,
    output valid,

    input [63:0] wmst_offset,
    input wmst_done,
    output reg wmst_req,
    output reg [63:0] wmst_addr,
    output reg [63:0] wmst_xfer_size,
    output write_buffer_wait,

    output stall
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
    wire [FIFO_ADDR_WIDTH:0] out_fifo_data_cnt;

    // reg fifo_clear;
    // reg wmst_req;
    reg flag_wmst_req;
    // assign wmst_req = r_wmst_req;

    // address alignment
    wire [63:0] addr_base = {wmst_offset[63:12], 12'b0};
    reg [11:0] addr_waste;
    reg [31:0] addr_cnt;
    reg [31:0] addr_waste_num;
    reg [31:0] addr_waste_cnt;
    reg r_end_conv;


    wire fifo_stall = !r_end_conv & g_stall;

    FifoType0 #(.data_width (512), .addr_bits (FIFO_ADDR_WIDTH)) ofm_fifo (
        .CLK        (clk),
        .nRESET     (rst_n),
        .PUSH_REQ   (!fifo_stall & out_fifo_push_req),
        .POP_REQ    (out_fifo_pop_req),
        .PUSH_DATA  (out_fifo_push_data),
        .CLEAR      (),
  
        .POP_DATA   (out_fifo_pop_data),
        .EMPTY      (out_fifo_empty),
        .FULL       (out_fifo_full),
        .ERROR      (),
        .DATA_CNT   (out_fifo_data_cnt)
    );

    wire algin_fifo_push_req;
    wire align_fifo_pop_req;
    wire [511:0] align_fifo_push_data;
    wire [511:0] align_fifo_pop_data;
    wire align_fifo_empty;
    wire align_fifo_full;
    wire [6:0] align_fifo_data_cnt;

    reg [31:0] align_cnt;
    reg [31:0] align_init_cnt;


    FifoType0 #(.data_width (512), .addr_bits (6)) align_fifo (
        .CLK        (clk),
        .nRESET     (rst_n),
        .PUSH_REQ   (!fifo_stall & align_fifo_push_req),
        .POP_REQ    (align_fifo_pop_req),
        .PUSH_DATA  (align_fifo_push_data),
        .CLEAR      (),
  
        .POP_DATA   (align_fifo_pop_data),
        .EMPTY      (align_fifo_empty),
        .FULL       (align_fifo_full),
        .ERROR      (),
        .DATA_CNT   (align_fifo_data_cnt)
    );

    reg [511:0] ofm_temp0;
    reg [511:0] ofm_temp1;
    reg p_req;
    reg final_write;

    reg [511:0] bypass_input;
    reg bypass_flag;


    reg r_wait_xfer;
    wire align_init = |align_init_cnt;

    assign write_buffer_wait = r_wait_xfer;
    assign tdata = align_init ? align_fifo_pop_data :
                    bypass_flag ? bypass_input : out_fifo_pop_data;
    assign valid = !out_fifo_empty;
    assign out_fifo_pop_req = !align_init & ready & valid;
    assign out_fifo_push_req = p_req; //| (final_write & ready & valid);
    assign out_fifo_push_data = ofm_temp0; // final_write ? out_fifo_pop_data : ofm_temp0;

    assign align_fifo_push_req = !(|align_cnt) & ready & valid;
    assign align_fifo_pop_req = |align_init_cnt & ready & valid;
    assign align_fifo_push_data = tdata;

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

    assign stall = out_fifo_full;

    reg [2:0] flat_done;

    localparam IDLE = 0;
    localparam WORD_READY_1 = 1;
    localparam WORD_READY_2 = 2;
    localparam LAST_WORD = 3;
    localparam PREQ = 4;
    localparam WREQ = 5;

    reg [63:0] r_wmst_xfer_size;
    reg [63:0] addr_last_waste;
    reg [63:0] addr_last_waste_num;
    wire [63:0] non_aligned_addr = ofm_size + wmst_offset;
    always @(*) begin
        addr_waste = wmst_offset[11:0];
        addr_waste_num = addr_waste / DATA_NUM;
        //wmst_addr = addr_base + addr_cnt * BURST_LENGTH_BYTE; // 64 byte = 512bit //addr_base -> addr_waste;
        wmst_addr = {wmst_offset[63:12], 12'b0};
        r_wmst_xfer_size = addr_waste + ofm_size;
        addr_last_waste = {r_wmst_xfer_size[63:12],12'b0};
        addr_last_waste_num = addr_last_waste / DATA_NUM;
        // wmst_xfer_size = WORD_BYTE * 2; //addr_cnt_temp * WORD_BYTE;
    end


    // reg [31:0] r_waste_cnt;
    // always @(posedge clk, negedge rst_n) begin
    //     if(!rst_n) begin
    //         r_waste_cnt <= 0;
    //     end else begin
    //         if(op_start) begin
    //             r_waste_cnt <= addr_waste_num;
    //         end else if (ready & valid & |r_waste_cnt) begin
    //             r_waste_cnt <= r_waste_cnt-1;
    //         end
    //     end
    // end


    // assign wmst_wstrb = {64{|r_waste_cnt}};

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            wmst_xfer_size <= 0;
            align_cnt <= 0;
            align_init_cnt <= 0;
        end else begin
            if(op_start)begin
                wmst_xfer_size <= r_wmst_xfer_size;
                align_init_cnt <= addr_waste_num;
                align_cnt <= addr_last_waste_num;
            end else if (ready & valid) begin
                align_cnt <= |align_cnt ? align_cnt-1 : 0;
                align_init_cnt <= |align_init_cnt ? align_init_cnt-1 : 0;
            end
            // if(!flag_wmst_req & (r_end_conv|end_conv)) begin
            //     if(out_fifo_data_cnt <= (BURST_LENGTH)) begin
            //         wmst_xfer_size <= out_fifo_data_cnt*DATA_NUM;
            //     end else begin
            //         wmst_xfer_size <= BURST_LENGTH_BYTE;
            //     end
            // end else begin
            //     wmst_xfer_size <= BURST_LENGTH_BYTE;
            // end
        end
    end


    // always @(posedge clk, negedge rst_n) begin
    //     if(!rst_n) begin
    //         r_end_conv <= 0;
    //         // fifo_clear <= 0;
    //         // r_wait_xfer <= 0;
    //     end else begin
    //         if(end_conv) begin
    //             r_end_conv <= 1;
    //             // r_wait_xfer <= 1;
    //         end
    //         else if (wmst_done & r_end_conv) begin // & final_write) begin
    //             r_end_conv <= 0;
    //             // r_wait_xfer <= 0;
    //             // if(out_fifo_data_cnt == BURST_LENGTH) begin
    //             //     fifo_clear <= 1;
    //             // end
    //         // end else begin
    //         //     fifo_clear <= 0;
    //         // end
    //         end
    //     end
    // end


    reg [31:0] wcnt;
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            wmst_req <=0;
            flag_wmst_req <= 0;
            addr_cnt <= 0;
            final_write <= 0;
            r_wait_xfer <= 0;
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
            // if(wmst_done) begin
            //     flag_wmst_req <= 0;
            //     final_write <= 0;
            //     if(r_end_conv) begin
            //         addr_cnt <= 0;
            //     end else begin
            //         // addr_cnt <= addr_cnt + 1;
            //     end
            // end else if(!flag_wmst_req) begin
            //     if(r_end_conv | end_conv) begin
            //         if(out_fifo_data_cnt <= (BURST_LENGTH)) begin
            //             flag_wmst_req <= 1;
            //             wmst_req <= 1;
            //             // final_write <= 1;
            //         end else begin
            //             flag_wmst_req <= 1;
            //             wmst_req <= 1;
            //         end
            //     end else if(out_fifo_data_cnt > (BURST_LENGTH-1)) begin
            //         flag_wmst_req <= 1;
            //         wmst_req <= 1;
            //     end
            // end else if (wmst_req) begin
            //     wmst_req <= 0;
            // end
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
            if(!g_stall) begin
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


    reg [31:0] p_ofm0 [0:15];
    reg [31:0] p_ofm1 [0:15];
    integer i;
    always @(*) begin
        for(i = 0; i < 16; i=i+1) begin
            p_ofm0[i] <= ofm0[i*32 +: 32];
            p_ofm1[i] <= ofm1[i*32 +: 32];
        end
    end


// //for debug
//     reg [31:0] wmst_done_counter;

//     always @(posedge clk, negedge rst_n) begin
//         if(!rst_n) begin
//             wmst_done_counter <= 0;
//         end else wmst_done_counter <= wmst_done ? wmst_done_counter + 1 : wmst_done_counter;
//     end

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