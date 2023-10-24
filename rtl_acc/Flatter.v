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

    input [511:0] out_ofm_port0,
    input [511:0] out_ofm_port1,
    input [511:0] out_ofm_port2,
    input [511:0] out_ofm_port3,

    input out_ofm_port_v0,
    input out_ofm_port_v1,
    input out_ofm_port_v2,
    input out_ofm_port_v3,

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

    reg [4:0]  fifo_cnt;
    reg r_wait_xfer;
    wire out_fifo_push_req[0:3];
    wire out_fifo_pop_req[0:3];
    wire [511:0] out_fifo_push_data[0:3];
    wire [511:0] out_fifo_pop_data[0:3];
    wire out_fifo_empty[0:3];
    wire out_fifo_full[0:3];
    wire [FIFO_ADDR_WIDTH:0] out_fifo_data_cnt[0:3];

    // reg fifo_clear;
    // reg wmst_req;
    reg flag_wmst_req;
    // assign wmst_req = r_wmst_req;

    // address alignment
    reg r_wmst_req;
    reg r_valid;
    reg r_end_conv;


    wire fifo_stall = !r_end_conv & g_stall;
    genvar i;
    generate
        for (i=0 ; i<4 ; i++) begin: pe_gen

        FifoType0 #(.data_width (512), .addr_bits (FIFO_ADDR_WIDTH)) ofm_fifo (
            .CLK        (clk),
            .nRESET     (rst_n),
            .PUSH_REQ   (!fifo_stall & out_fifo_push_req[i]),
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

    assign stall = out_fifo_full[0] || out_fifo_full[1] || out_fifo_full[2] || out_fifo_full[3];
    
    assign pop_req =           (out_fifo_pop_req[0] || out_fifo_pop_req[1] || out_fifo_pop_req[2] || out_fifo_pop_req[3]);
    assign fifo_empty =        (out_fifo_empty[0] && out_fifo_empty[1] && out_fifo_empty[2] && out_fifo_empty[3]);
    //assign write_buffer_wait = !(out_fifo_data_cnt[27]<1); // !out_fifo_empty[27];
    assign write_buffer_wait = r_wait_xfer;
    assign tdata = (fifo_cnt == 0) ? out_fifo_pop_data[0] : (fifo_cnt == 1) ? out_fifo_pop_data[1] :
                   (fifo_cnt == 2) ? out_fifo_pop_data[2] : (fifo_cnt == 3) ? out_fifo_pop_data[3] : 0;
    assign valid = r_valid;

    assign out_fifo_push_req[0] = out_ofm_port_v0;
    assign out_fifo_push_req[1] = out_ofm_port_v1;
    assign out_fifo_push_req[2] = out_ofm_port_v2;
    assign out_fifo_push_req[3] = out_ofm_port_v3;


    assign out_fifo_push_data[0] = out_ofm_port0;
    assign out_fifo_push_data[1] = out_ofm_port1;
    assign out_fifo_push_data[2] = out_ofm_port2;
    assign out_fifo_push_data[3] = out_ofm_port3;

	always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            r_valid <= 0;
        else if(!out_fifo_empty[3])
            r_valid <= 1;
        else r_valid <= 0;
    end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            fifo_cnt <= 0;
        end
        else if(pop_req&&(!fifo_empty)) begin
                if(fifo_cnt==3)
                fifo_cnt <= 0;
                else
                fifo_cnt <= fifo_cnt + 1;
            end
            else 
                fifo_cnt <= fifo_cnt;

    end

    reg [11:0] addr_waste;
    reg [31:0] addr_waste_num;
    reg [63:0] r_wmst_xfer_size;
    reg [63:0] addr_last_waste;
    reg [63:0] addr_last_waste_num;
    //wire [63:0] non_aligned_addr = ofm_size + wmst_offset;
    always @(*) begin
        addr_waste = wmst_offset[11:0];
        addr_waste_num = addr_waste / DATA_NUM;
        wmst_addr = {wmst_offset[63:12], 12'b0};
        r_wmst_xfer_size = addr_waste + ofm_size;
        addr_last_waste = {r_wmst_xfer_size[63:12],12'b0};
        addr_last_waste_num = addr_last_waste / DATA_NUM;
    end

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            wmst_xfer_size <= 0;
        end else begin
            if(op_start)begin
                wmst_xfer_size <= r_wmst_xfer_size;
            end
        end
    end

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
endmodule