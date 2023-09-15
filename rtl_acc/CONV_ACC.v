///==------------------------------------------------------------------==///
/// Conv kernel: top level module
///==------------------------------------------------------------------==///

`timescale 1ns/1ps

module CONV_ACC #(
    parameter out_data_width = 32,
    parameter buf_addr_width = 5,
    parameter buf_depth      = 16
) (
    input  clk,
    input  rst_n,
    input  start_conv,
    input  [1:0] cfg_ci,
    input  [1:0] cfg_co,
    input  [79:0] ifm,
    input  [47:0] weight,
    output [255:0] ofm0_port,
    output [255:0] ofm1_port,
    output ofm0_port_v,
    output ofm1_port_v,
    output ifm_read,
    output wgt_read,
    output end_op
);


    /// Assign ifm to each pes
    reg [7:0] rows [0:9];
    always @(*) begin
        rows[0] = ifm[7:0];
        rows[1] = ifm[15:8];
        rows[2] = ifm[23:16];
        rows[3] = ifm[31:24];
        rows[4] = ifm[39:32];
        rows[5] = ifm[47:40];
        rows[6] = ifm[55:48];
        rows[7] = ifm[63:56];
		rows[8] = ifm[71:64]; // total 10 rows of ifm
        rows[9] = ifm[79:72]; //
		
		
        // {rows[0], rows[1], rows[2], rows[3], rows[4], rows[5], rows[6], rows[7]} = 
        //     {ifm[7:0], ifm[15:8], ifm[23:16], ifm[31:24], ifm[39:32], ifm[47:40], ifm[55:48], ifm[63:56]};
    end
    /// Assign weight to each pes
    reg [7:0] ofm0_wgts [0:2];
	reg [7:0] ofm1_wgts [0:2];
    always @(*) begin
        ofm0_wgts[0] = weight[7:0];
        ofm0_wgts[1] = weight[15:8];
        ofm0_wgts[2] = weight[23:16];
        ofm1_wgts[0] = weight[31:24];
		ofm1_wgts[1] = weight[39:32];
        ofm1_wgts[2] = weight[47:40]; // total 6 wgt

        // {wgts[0], wgts[1], wgts[2], wgts[3]} = {weight[7:0], weight[15:8], weight[23:16], weight[31:24]};
    end

    ///==-------------------------------------------------------------------------------------==
    /// Connect between PE and PE_FSM
    wire ifm_read_en;
    wire wgt_read_en;
    assign ifm_read = ifm_read_en;
    assign wgt_read = wgt_read_en;
    /// Connection between PEs+PE_FSM and WRITEBACK+BUFF
    wire [out_data_width-1:0] ofm0_pe00_data, ofm0_pe10_data, ofm0_pe20_data;
    wire [out_data_width-1:0] ofm0_pe01_data, ofm0_pe11_data, ofm0_pe21_data;
    wire [out_data_width-1:0] ofm0_pe02_data, ofm0_pe12_data, ofm0_pe22_data;
    wire [out_data_width-1:0] ofm0_pe03_data, ofm0_pe13_data, ofm0_pe23_data;
    wire [out_data_width-1:0] ofm0_pe04_data, ofm0_pe14_data, ofm0_pe24_data;
    wire [out_data_width-1:0] ofm0_pe05_data, ofm0_pe15_data, ofm0_pe25_data;
    wire [out_data_width-1:0] ofm0_pe06_data, ofm0_pe16_data, ofm0_pe26_data;
    wire [out_data_width-1:0] ofm0_pe07_data, ofm0_pe17_data, ofm0_pe27_data;
	
	wire [out_data_width-1:0] ofm1_pe00_data, ofm1_pe10_data, ofm1_pe20_data;
    wire [out_data_width-1:0] ofm1_pe01_data, ofm1_pe11_data, ofm1_pe21_data;
    wire [out_data_width-1:0] ofm1_pe02_data, ofm1_pe12_data, ofm1_pe22_data;
    wire [out_data_width-1:0] ofm1_pe03_data, ofm1_pe13_data, ofm1_pe23_data;
    wire [out_data_width-1:0] ofm1_pe04_data, ofm1_pe14_data, ofm1_pe24_data;
    wire [out_data_width-1:0] ofm1_pe05_data, ofm1_pe15_data, ofm1_pe25_data;
    wire [out_data_width-1:0] ofm1_pe06_data, ofm1_pe16_data, ofm1_pe26_data;
    wire [out_data_width-1:0] ofm1_pe07_data, ofm1_pe17_data, ofm1_pe27_data;

    wire p_filter_end, p_valid_data, start_again;
    /// PE FSM
    PE_FSM pe_fsm ( .clk(clk), .rst_n(rst_n), .start_conv(start_conv), .start_again(start_again), .cfg_ci(cfg_ci), .cfg_co(cfg_co), 
            .ifm_read(ifm_read_en), .wgt_read(wgt_read_en), .p_valid_output(p_valid_data), 
            .last_chanel_output(p_filter_end), .end_conv(end_conv) );  
    
    /// First row
    wire [7:0] ifm_buf00, ifm_buf01, ifm_buf02;
    wire [7:0] ifm_buf10, ifm_buf11, ifm_buf12;
    wire [7:0] ifm_buf20, ifm_buf21, ifm_buf22;
    wire [7:0] ifm_buf30, ifm_buf31, ifm_buf32;
    wire [7:0] ifm_buf40, ifm_buf41, ifm_buf42;
    wire [7:0] ifm_buf50, ifm_buf51, ifm_buf52;
    wire [7:0] ifm_buf60, ifm_buf61, ifm_buf62;
    wire [7:0] ifm_buf70, ifm_buf71, ifm_buf72;
	wire [7:0] ifm_buf80, ifm_buf81, ifm_buf82;
    wire [7:0] ifm_buf90, ifm_buf91, ifm_buf92;

	wire [7:0] ofm0_wgt_buf00, ofm0_wgt_buf01, ofm0_wgt_buf02;
	wire [7:0] ofm0_wgt_buf10, ofm0_wgt_buf11, ofm0_wgt_buf12;
	wire [7:0] ofm0_wgt_buf20, ofm0_wgt_buf21, ofm0_wgt_buf22;
	
	wire [7:0] ofm1_wgt_buf00, ofm1_wgt_buf01, ofm1_wgt_buf02;
	wire [7:0] ofm1_wgt_buf10, ofm1_wgt_buf11, ofm1_wgt_buf12;
	wire [7:0] ofm1_wgt_buf20, ofm1_wgt_buf21, ofm1_wgt_buf22;



	IFM_BUF ifm_buf0( .clk(clk), .rst_n(rst_n), .ifm_input(rows[0]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf00), .ifm_buf1(ifm_buf01), .ifm_buf2(ifm_buf02));
	IFM_BUF ifm_buf1( .clk(clk), .rst_n(rst_n), .ifm_input(rows[1]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf10), .ifm_buf1(ifm_buf11), .ifm_buf2(ifm_buf12));
	IFM_BUF ifm_buf2( .clk(clk), .rst_n(rst_n), .ifm_input(rows[2]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf20), .ifm_buf1(ifm_buf21), .ifm_buf2(ifm_buf22));
	IFM_BUF ifm_buf3( .clk(clk), .rst_n(rst_n), .ifm_input(rows[3]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf30), .ifm_buf1(ifm_buf31), .ifm_buf2(ifm_buf32));
	IFM_BUF ifm_buf4( .clk(clk), .rst_n(rst_n), .ifm_input(rows[4]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf40), .ifm_buf1(ifm_buf41), .ifm_buf2(ifm_buf42));
	IFM_BUF ifm_buf5( .clk(clk), .rst_n(rst_n), .ifm_input(rows[5]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf50), .ifm_buf1(ifm_buf51), .ifm_buf2(ifm_buf52));
	IFM_BUF ifm_buf6( .clk(clk), .rst_n(rst_n), .ifm_input(rows[6]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf60), .ifm_buf1(ifm_buf61), .ifm_buf2(ifm_buf62));
	IFM_BUF ifm_buf7( .clk(clk), .rst_n(rst_n), .ifm_input(rows[7]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf70), .ifm_buf1(ifm_buf71), .ifm_buf2(ifm_buf72));
	IFM_BUF ifm_buf8( .clk(clk), .rst_n(rst_n), .ifm_input(rows[8]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf80), .ifm_buf1(ifm_buf81), .ifm_buf2(ifm_buf82));
	IFM_BUF ifm_buf9( .clk(clk), .rst_n(rst_n), .ifm_input(rows[9]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf90), .ifm_buf1(ifm_buf91), .ifm_buf2(ifm_buf92));	

	WGT_BUF ofm0_wgt_buf0( .clk(clk), .rst_n(rst_n), .wgt_input(ofm0_wgts[0]), .wgt_read(wgt_read_en), 
	.wgt_buf0(ofm0_wgt_buf00), .wgt_buf1(ofm0_wgt_buf01), .wgt_buf2(ofm0_wgt_buf02));
	WGT_BUF ofm0_wgt_buf1( .clk(clk), .rst_n(rst_n), .wgt_input(ofm0_wgts[1]), .wgt_read(wgt_read_en), 
	.wgt_buf0(ofm0_wgt_buf10), .wgt_buf1(ofm0_wgt_buf11), .wgt_buf2(ofm0_wgt_buf12));
	WGT_BUF ofm0_wgt_buf2( .clk(clk), .rst_n(rst_n), .wgt_input(ofm0_wgts[2]), .wgt_read(wgt_read_en), 
	.wgt_buf0(ofm0_wgt_buf20), .wgt_buf1(ofm0_wgt_buf21), .wgt_buf2(ofm0_wgt_buf22));
	
	WGT_BUF ofm1_wgt_buf0( .clk(clk), .rst_n(rst_n), .wgt_input(ofm1_wgts[0]), .wgt_read(wgt_read_en), 
	.wgt_buf0(ofm1_wgt_buf00), .wgt_buf1(ofm1_wgt_buf01), .wgt_buf2(ofm1_wgt_buf02));
	WGT_BUF ofm1_wgt_buf1( .clk(clk), .rst_n(rst_n), .wgt_input(ofm1_wgts[1]), .wgt_read(wgt_read_en), 
	.wgt_buf0(ofm1_wgt_buf10), .wgt_buf1(ofm1_wgt_buf11), .wgt_buf2(ofm1_wgt_buf12));
	WGT_BUF ofm1_wgt_buf2( .clk(clk), .rst_n(rst_n), .wgt_input(ofm1_wgts[2]), .wgt_read(wgt_read_en), 
	.wgt_buf0(ofm1_wgt_buf20), .wgt_buf1(ofm1_wgt_buf21), .wgt_buf2(ofm1_wgt_buf22));

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	//ofm0 pe array                                                                                             //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
	PE ofm0_pe00( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf00), .ifm_input1(ifm_buf01), .ifm_input2(ifm_buf02), 
	.wgt_input0(ofm0_wgt_buf00), .wgt_input1(ofm0_wgt_buf01), .wgt_input2(ofm0_wgt_buf02), .p_sum(ofm0_pe00_data) );
	PE ofm0_pe01( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf10), .ifm_input1(ifm_buf11), .ifm_input2(ifm_buf12), 
	.wgt_input0(ofm0_wgt_buf00), .wgt_input1(ofm0_wgt_buf01), .wgt_input2(ofm0_wgt_buf02), .p_sum(ofm0_pe01_data) );
	PE ofm0_pe02( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20), .ifm_input1(ifm_buf21), .ifm_input2(ifm_buf22),
	.wgt_input0(ofm0_wgt_buf00), .wgt_input1(ofm0_wgt_buf01), .wgt_input2(ofm0_wgt_buf02), .p_sum(ofm0_pe02_data) );
	PE ofm0_pe03( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30), .ifm_input1(ifm_buf31), .ifm_input2(ifm_buf32), 
	.wgt_input0(ofm0_wgt_buf00), .wgt_input1(ofm0_wgt_buf01), .wgt_input2(ofm0_wgt_buf02), .p_sum(ofm0_pe03_data) );
	PE ofm0_ofm0_pe04( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40), .ifm_input1(ifm_buf41), .ifm_input2(ifm_buf42), 
	.wgt_input0(ofm0_wgt_buf00), .wgt_input1(ofm0_wgt_buf01), .wgt_input2(ofm0_wgt_buf02), .p_sum(ofm0_pe04_data) );
	PE ofm0_ofm0_pe05( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50), .ifm_input1(ifm_buf51), .ifm_input2(ifm_buf52), 
	.wgt_input0(ofm0_wgt_buf00), .wgt_input1(ofm0_wgt_buf01), .wgt_input2(ofm0_wgt_buf02), .p_sum(ofm0_pe05_data) );
	PE ofm0_ofm0_pe06( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60), .ifm_input1(ifm_buf61), .ifm_input2(ifm_buf62),
	.wgt_input0(ofm0_wgt_buf00), .wgt_input1(ofm0_wgt_buf01), .wgt_input2(ofm0_wgt_buf02), .p_sum(ofm0_pe06_data) );
	PE ofm0_ofm0_pe07( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70), .ifm_input1(ifm_buf71), .ifm_input2(ifm_buf72), 
	.wgt_input0(ofm0_wgt_buf00), .wgt_input1(ofm0_wgt_buf01), .wgt_input2(ofm0_wgt_buf02), .p_sum(ofm0_pe07_data) );
	
	
	
	PE ofm0_pe10( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf10), .ifm_input1(ifm_buf11), .ifm_input2(ifm_buf12), 
	.wgt_input0(ofm0_wgt_buf10), .wgt_input1(ofm0_wgt_buf11), .wgt_input2(ofm0_wgt_buf12), .p_sum(ofm0_pe10_data) );
	PE ofm0_pe11( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20), .ifm_input1(ifm_buf21), .ifm_input2(ifm_buf22), 
	.wgt_input0(ofm0_wgt_buf10), .wgt_input1(ofm0_wgt_buf11), .wgt_input2(ofm0_wgt_buf12), .p_sum(ofm0_pe11_data) );
	PE ofm0_pe12( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30), .ifm_input1(ifm_buf31), .ifm_input2(ifm_buf32),
	.wgt_input0(ofm0_wgt_buf10), .wgt_input1(ofm0_wgt_buf11), .wgt_input2(ofm0_wgt_buf12), .p_sum(ofm0_pe12_data) );
	PE ofm0_pe13( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40), .ifm_input1(ifm_buf41), .ifm_input2(ifm_buf42), 
	.wgt_input0(ofm0_wgt_buf10), .wgt_input1(ofm0_wgt_buf11), .wgt_input2(ofm0_wgt_buf12), .p_sum(ofm0_pe13_data) );
	PE ofm0_pe14( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50), .ifm_input1(ifm_buf51), .ifm_input2(ifm_buf52), 
	.wgt_input0(ofm0_wgt_buf10), .wgt_input1(ofm0_wgt_buf11), .wgt_input2(ofm0_wgt_buf12), .p_sum(ofm0_pe14_data) );
	PE ofm0_pe15( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60), .ifm_input1(ifm_buf61), .ifm_input2(ifm_buf62), 
	.wgt_input0(ofm0_wgt_buf10), .wgt_input1(ofm0_wgt_buf11), .wgt_input2(ofm0_wgt_buf12), .p_sum(ofm0_pe15_data) );
	PE ofm0_pe16( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70), .ifm_input1(ifm_buf71), .ifm_input2(ifm_buf72),
	.wgt_input0(ofm0_wgt_buf10), .wgt_input1(ofm0_wgt_buf11), .wgt_input2(ofm0_wgt_buf12), .p_sum(ofm0_pe16_data) );
	PE ofm0_pe17( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf80), .ifm_input1(ifm_buf81), .ifm_input2(ifm_buf82), 
	.wgt_input0(ofm0_wgt_buf10), .wgt_input1(ofm0_wgt_buf11), .wgt_input2(ofm0_wgt_buf12), .p_sum(ofm0_pe17_data) );	
	
	
	PE ofm0_pe20( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20), .ifm_input1(ifm_buf21), .ifm_input2(ifm_buf22), 
	.wgt_input0(ofm0_wgt_buf20), .wgt_input1(ofm0_wgt_buf21), .wgt_input2(ofm0_wgt_buf22), .p_sum(ofm0_pe20_data) );
	PE ofm0_pe21( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30), .ifm_input1(ifm_buf31), .ifm_input2(ifm_buf32), 
	.wgt_input0(ofm0_wgt_buf20), .wgt_input1(ofm0_wgt_buf21), .wgt_input2(ofm0_wgt_buf22), .p_sum(ofm0_pe21_data) );
	PE ofm0_pe22( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40), .ifm_input1(ifm_buf41), .ifm_input2(ifm_buf42),
	.wgt_input0(ofm0_wgt_buf20), .wgt_input1(ofm0_wgt_buf21), .wgt_input2(ofm0_wgt_buf22), .p_sum(ofm0_pe22_data) );
	PE ofm0_pe23( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50), .ifm_input1(ifm_buf51), .ifm_input2(ifm_buf52), 
	.wgt_input0(ofm0_wgt_buf20), .wgt_input1(ofm0_wgt_buf21), .wgt_input2(ofm0_wgt_buf22), .p_sum(ofm0_pe23_data) );
	PE ofm0_pe24( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60), .ifm_input1(ifm_buf61), .ifm_input2(ifm_buf62), 
	.wgt_input0(ofm0_wgt_buf20), .wgt_input1(ofm0_wgt_buf21), .wgt_input2(ofm0_wgt_buf22), .p_sum(ofm0_pe24_data) );
	PE ofm0_pe25( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70), .ifm_input1(ifm_buf71), .ifm_input2(ifm_buf72), 
	.wgt_input0(ofm0_wgt_buf20), .wgt_input1(ofm0_wgt_buf21), .wgt_input2(ofm0_wgt_buf22), .p_sum(ofm0_pe25_data) );
	PE ofm0_pe26( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf80), .ifm_input1(ifm_buf81), .ifm_input2(ifm_buf82),
	.wgt_input0(ofm0_wgt_buf20), .wgt_input1(ofm0_wgt_buf21), .wgt_input2(ofm0_wgt_buf22), .p_sum(ofm0_pe26_data) );
	PE ofm0_pe27( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf90), .ifm_input1(ifm_buf91), .ifm_input2(ifm_buf92), 
	.wgt_input0(ofm0_wgt_buf20), .wgt_input1(ofm0_wgt_buf21), .wgt_input2(ofm0_wgt_buf22), .p_sum(ofm0_pe27_data) );	


	//////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	//ofm1 pe array                                                                                             //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
	PE ofm1_pe00( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf00), .ifm_input1(ifm_buf01), .ifm_input2(ifm_buf02), 
	.wgt_input0(ofm1_wgt_buf00), .wgt_input1(ofm1_wgt_buf01), .wgt_input2(ofm1_wgt_buf02), .p_sum(ofm1_pe00_data) );
	PE ofm1_pe01( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf10), .ifm_input1(ifm_buf11), .ifm_input2(ifm_buf12), 
	.wgt_input0(ofm1_wgt_buf00), .wgt_input1(ofm1_wgt_buf01), .wgt_input2(ofm1_wgt_buf02), .p_sum(ofm1_pe01_data) );
	PE ofm1_pe02( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20), .ifm_input1(ifm_buf21), .ifm_input2(ifm_buf22),
	.wgt_input0(ofm1_wgt_buf00), .wgt_input1(ofm1_wgt_buf01), .wgt_input2(ofm1_wgt_buf02), .p_sum(ofm1_pe02_data) );
	PE ofm1_pe03( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30), .ifm_input1(ifm_buf31), .ifm_input2(ifm_buf32), 
	.wgt_input0(ofm1_wgt_buf00), .wgt_input1(ofm1_wgt_buf01), .wgt_input2(ofm1_wgt_buf02), .p_sum(ofm1_pe03_data) );
	PE ofm1_ofm1_pe04( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40), .ifm_input1(ifm_buf41), .ifm_input2(ifm_buf42), 
	.wgt_input0(ofm1_wgt_buf00), .wgt_input1(ofm1_wgt_buf01), .wgt_input2(ofm1_wgt_buf02), .p_sum(ofm1_pe04_data) );
	PE ofm1_ofm1_pe05( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50), .ifm_input1(ifm_buf51), .ifm_input2(ifm_buf52), 
	.wgt_input0(ofm1_wgt_buf00), .wgt_input1(ofm1_wgt_buf01), .wgt_input2(ofm1_wgt_buf02), .p_sum(ofm1_pe05_data) );
	PE ofm1_ofm1_pe06( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60), .ifm_input1(ifm_buf61), .ifm_input2(ifm_buf62),
	.wgt_input0(ofm1_wgt_buf00), .wgt_input1(ofm1_wgt_buf01), .wgt_input2(ofm1_wgt_buf02), .p_sum(ofm1_pe06_data) );
	PE ofm1_ofm1_pe07( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70), .ifm_input1(ifm_buf71), .ifm_input2(ifm_buf72), 
	.wgt_input0(ofm1_wgt_buf00), .wgt_input1(ofm1_wgt_buf01), .wgt_input2(ofm1_wgt_buf02), .p_sum(ofm1_pe07_data) );
	
	
	
	PE ofm1_pe10( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf10), .ifm_input1(ifm_buf11), .ifm_input2(ifm_buf12), 
	.wgt_input0(ofm1_wgt_buf10), .wgt_input1(ofm1_wgt_buf11), .wgt_input2(ofm1_wgt_buf12), .p_sum(ofm1_pe10_data) );
	PE ofm1_pe11( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20), .ifm_input1(ifm_buf21), .ifm_input2(ifm_buf22), 
	.wgt_input0(ofm1_wgt_buf10), .wgt_input1(ofm1_wgt_buf11), .wgt_input2(ofm1_wgt_buf12), .p_sum(ofm1_pe11_data) );
	PE ofm1_pe12( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30), .ifm_input1(ifm_buf31), .ifm_input2(ifm_buf32),
	.wgt_input0(ofm1_wgt_buf10), .wgt_input1(ofm1_wgt_buf11), .wgt_input2(ofm1_wgt_buf12), .p_sum(ofm1_pe12_data) );
	PE ofm1_pe13( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40), .ifm_input1(ifm_buf41), .ifm_input2(ifm_buf42), 
	.wgt_input0(ofm1_wgt_buf10), .wgt_input1(ofm1_wgt_buf11), .wgt_input2(ofm1_wgt_buf12), .p_sum(ofm1_pe13_data) );
	PE ofm1_pe14( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50), .ifm_input1(ifm_buf51), .ifm_input2(ifm_buf52), 
	.wgt_input0(ofm1_wgt_buf10), .wgt_input1(ofm1_wgt_buf11), .wgt_input2(ofm1_wgt_buf12), .p_sum(ofm1_pe14_data) );
	PE ofm1_pe15( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60), .ifm_input1(ifm_buf61), .ifm_input2(ifm_buf62), 
	.wgt_input0(ofm1_wgt_buf10), .wgt_input1(ofm1_wgt_buf11), .wgt_input2(ofm1_wgt_buf12), .p_sum(ofm1_pe15_data) );
	PE ofm1_pe16( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70), .ifm_input1(ifm_buf71), .ifm_input2(ifm_buf72),
	.wgt_input0(ofm1_wgt_buf10), .wgt_input1(ofm1_wgt_buf11), .wgt_input2(ofm1_wgt_buf12), .p_sum(ofm1_pe16_data) );
	PE ofm1_pe17( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf80), .ifm_input1(ifm_buf81), .ifm_input2(ifm_buf82), 
	.wgt_input0(ofm1_wgt_buf10), .wgt_input1(ofm1_wgt_buf11), .wgt_input2(ofm1_wgt_buf12), .p_sum(ofm1_pe17_data) );	
	
	
	PE ofm1_pe20( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20), .ifm_input1(ifm_buf21), .ifm_input2(ifm_buf22), 
	.wgt_input0(ofm1_wgt_buf20), .wgt_input1(ofm1_wgt_buf21), .wgt_input2(ofm1_wgt_buf22), .p_sum(ofm1_pe20_data) );
	PE ofm1_pe21( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30), .ifm_input1(ifm_buf31), .ifm_input2(ifm_buf32), 
	.wgt_input0(ofm1_wgt_buf20), .wgt_input1(ofm1_wgt_buf21), .wgt_input2(ofm1_wgt_buf22), .p_sum(ofm1_pe21_data) );
	PE ofm1_pe22( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40), .ifm_input1(ifm_buf41), .ifm_input2(ifm_buf42),
	.wgt_input0(ofm1_wgt_buf20), .wgt_input1(ofm1_wgt_buf21), .wgt_input2(ofm1_wgt_buf22), .p_sum(ofm1_pe22_data) );
	PE ofm1_pe23( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50), .ifm_input1(ifm_buf51), .ifm_input2(ifm_buf52), 
	.wgt_input0(ofm1_wgt_buf20), .wgt_input1(ofm1_wgt_buf21), .wgt_input2(ofm1_wgt_buf22), .p_sum(ofm1_pe23_data) );
	PE ofm1_pe24( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60), .ifm_input1(ifm_buf61), .ifm_input2(ifm_buf62), 
	.wgt_input0(ofm1_wgt_buf20), .wgt_input1(ofm1_wgt_buf21), .wgt_input2(ofm1_wgt_buf22), .p_sum(ofm1_pe24_data) );
	PE ofm1_pe25( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70), .ifm_input1(ifm_buf71), .ifm_input2(ifm_buf72), 
	.wgt_input0(ofm1_wgt_buf20), .wgt_input1(ofm1_wgt_buf21), .wgt_input2(ofm1_wgt_buf22), .p_sum(ofm1_pe25_data) );
	PE ofm1_pe26( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf80), .ifm_input1(ifm_buf81), .ifm_input2(ifm_buf82),
	.wgt_input0(ofm1_wgt_buf20), .wgt_input1(ofm1_wgt_buf21), .wgt_input2(ofm1_wgt_buf22), .p_sum(ofm1_pe26_data) );
	PE ofm1_pe27( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf90), .ifm_input1(ifm_buf91), .ifm_input2(ifm_buf92), 
	.wgt_input0(ofm1_wgt_buf20), .wgt_input1(ofm1_wgt_buf21), .wgt_input2(ofm1_wgt_buf22), .p_sum(ofm1_pe27_data) );
	
	
		

    ///==-------------------------------------------------------------------------------------==
    /// Connection between the buffer and write back controllers
    wire [out_data_width-1:0] ofm0_fifo_out[0:7];
	wire [out_data_width-1:0] ofm1_fifo_out[0:7];
    wire ofm0_valid_fifo_out[0:7];
	wire ofm1_valid_fifo_out[0:7];
    wire p_write_zero;
    wire p_init;
    wire odd_cnt;

    /// Write back controller
    WRITE_BACK #(
        .data_width(out_data_width),
        .depth(buf_depth)
    ) writeback_control (
        .clk(clk),
        .rst_n(rst_n),
        .start_init(start_conv),
        .p_filter_end(p_filter_end),
        .ofm0_row0(ofm0_fifo_out[0]),
        .ofm0_row0_valid(ofm0_valid_fifo_out[0]),
        .ofm0_row1(ofm0_fifo_out[1]),
        .ofm0_row1_valid(ofm0_valid_fifo_out[1]),
        .ofm0_row2(ofm0_fifo_out[2]),
        .ofm0_row2_valid(ofm0_valid_fifo_out[2]),
        .ofm0_row3(ofm0_fifo_out[3]),
        .ofm0_row3_valid(ofm0_valid_fifo_out[3]),
        .ofm0_row4(ofm0_fifo_out[4]),
        .ofm0_row4_valid(ofm0_valid_fifo_out[4]),
		.ofm0_row5(ofm0_fifo_out[5]),
        .ofm0_row5_valid(ofm0_valid_fifo_out[5]),
        .ofm0_row6(ofm0_fifo_out[6]),
        .ofm0_row6_valid(ofm0_valid_fifo_out[6]),
        .ofm0_row7(ofm0_fifo_out[7]),
        .ofm0_row7_valid(ofm0_valid_fifo_out[7]),
        .ofm1_row0(ofm1_fifo_out[0]),
        .ofm1_row0_valid(ofm1_valid_fifo_out[0]),
        .ofm1_row1(ofm1_fifo_out[1]),
        .ofm1_row1_valid(ofm1_valid_fifo_out[1]),
        .ofm1_row2(ofm1_fifo_out[2]),
        .ofm1_row2_valid(ofm1_valid_fifo_out[2]),
        .ofm1_row3(ofm1_fifo_out[3]),
        .ofm1_row3_valid(ofm1_valid_fifo_out[3]),
        .ofm1_row4(ofm1_fifo_out[4]),
        .ofm1_row4_valid(ofm1_valid_fifo_out[4]),
		.ofm1_row5(ofm1_fifo_out[5]),
        .ofm1_row5_valid(ofm1_valid_fifo_out[5]),
        .ofm1_row6(ofm1_fifo_out[6]),
        .ofm1_row6_valid(ofm1_valid_fifo_out[6]),
        .ofm1_row7(ofm1_fifo_out[7]),
        .ofm1_row7_valid(ofm1_valid_fifo_out[7]),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .ofm0_out_port(ofm0_port),
        .ofm0_port_valid(ofm0_port_v),
		.ofm1_out_port(ofm1_port),
        .ofm1_port_valid(ofm1_port_v),
        .start_conv(start_again),
        .odd_cnt(odd_cnt),

        .end_conv(end_conv),
        .end_op(end_op)
    );

    
    /// Buffer
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	//ofm0 pe array                                                                                             //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm0_psum_buff0 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm0_pe00_data),
        .pe1_data(ofm0_pe10_data),
        .pe2_data(ofm0_pe20_data),
        .fifo_out(ofm0_fifo_out[0]),
        .valid_fifo_out(ofm0_valid_fifo_out[0])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm0_psum_buff1 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm0_pe01_data),
        .pe1_data(ofm0_pe11_data),
        .pe2_data(ofm0_pe21_data),
        .fifo_out(ofm0_fifo_out[1]),
        .valid_fifo_out(ofm0_valid_fifo_out[1])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm0_psum_buff2 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm0_pe02_data),
        .pe1_data(ofm0_pe12_data),
        .pe2_data(ofm0_pe22_data),
        .fifo_out(ofm0_fifo_out[2]),
        .valid_fifo_out(ofm0_valid_fifo_out[2])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm0_psum_buff3 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm0_pe03_data),
        .pe1_data(ofm0_pe13_data),
        .pe2_data(ofm0_pe23_data),
        .fifo_out(ofm0_fifo_out[3]),
        .valid_fifo_out(ofm0_valid_fifo_out[3])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm0_psum_buff4 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm0_pe04_data),
        .pe1_data(ofm0_pe14_data),
        .pe2_data(ofm0_pe24_data),
        .fifo_out(ofm0_fifo_out[4]),
        .valid_fifo_out(ofm0_valid_fifo_out[4])
    );
	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm0_psum_buff5 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm0_pe05_data),
        .pe1_data(ofm0_pe15_data),
        .pe2_data(ofm0_pe25_data),
        .fifo_out(ofm0_fifo_out[5]),
        .valid_fifo_out(ofm0_valid_fifo_out[5])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm0_psum_buff6 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm0_pe06_data),
        .pe1_data(ofm0_pe16_data),
        .pe2_data(ofm0_pe26_data),
        .fifo_out(ofm0_fifo_out[6]),
        .valid_fifo_out(ofm0_valid_fifo_out[6])
    );
	
	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm0_psum_buff7 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm0_pe07_data),
        .pe1_data(ofm0_pe17_data),
        .pe2_data(ofm0_pe27_data),
        .fifo_out(ofm0_fifo_out[7]),
        .valid_fifo_out(ofm0_valid_fifo_out[7])
    );



	//////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	//ofm1 pe array                                                                                             //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm1_psum_buff0 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm1_pe00_data),
        .pe1_data(ofm1_pe10_data),
        .pe2_data(ofm1_pe20_data),
        .fifo_out(ofm1_fifo_out[0]),
        .valid_fifo_out(ofm1_valid_fifo_out[0])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm1_psum_buff1 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm1_pe01_data),
        .pe1_data(ofm1_pe11_data),
        .pe2_data(ofm1_pe21_data),
        .fifo_out(ofm1_fifo_out[1]),
        .valid_fifo_out(ofm1_valid_fifo_out[1])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm1_psum_buff2 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm1_pe02_data),
        .pe1_data(ofm1_pe12_data),
        .pe2_data(ofm1_pe22_data),
        .fifo_out(ofm1_fifo_out[2]),
        .valid_fifo_out(ofm1_valid_fifo_out[2])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm1_psum_buff3 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm1_pe03_data),
        .pe1_data(ofm1_pe13_data),
        .pe2_data(ofm1_pe23_data),
        .fifo_out(ofm1_fifo_out[3]),
        .valid_fifo_out(ofm1_valid_fifo_out[3])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm1_psum_buff4 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm1_pe04_data),
        .pe1_data(ofm1_pe14_data),
        .pe2_data(ofm1_pe24_data),
        .fifo_out(ofm1_fifo_out[4]),
        .valid_fifo_out(ofm1_valid_fifo_out[4])
    );
	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm1_psum_buff5 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm1_pe05_data),
        .pe1_data(ofm1_pe15_data),
        .pe2_data(ofm1_pe25_data),
        .fifo_out(ofm1_fifo_out[5]),
        .valid_fifo_out(ofm1_valid_fifo_out[5])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm1_psum_buff6 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm1_pe06_data),
        .pe1_data(ofm1_pe16_data),
        .pe2_data(ofm1_pe26_data),
        .fifo_out(ofm1_fifo_out[6]),
        .valid_fifo_out(ofm1_valid_fifo_out[6])
    );
	
	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) ofm1_psum_buff7 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(ofm1_pe07_data),
        .pe1_data(ofm1_pe17_data),
        .pe2_data(ofm1_pe27_data),
        .fifo_out(ofm1_fifo_out[7]),
        .valid_fifo_out(ofm1_valid_fifo_out[7])
    );

endmodule //CONV_ACC