///==------------------------------------------------------------------==///
/// Conv kernel: top level module
///==------------------------------------------------------------------==///

`timescale 1ns/1ps

module CONV_ACC #(
    parameter out_data_width = 32,
    parameter buf_addr_width = 5,
    parameter buf_depth      = 16,
	parameter IFM_DATA_WIDTH = 8 * 18,
	parameter WGT_DATA_WIDTH = 8 * 3
) (
    input  clk,
    input  rst_n,
    input  start_conv,
    input  [1:0] cfg_ci,
    input  [1:0] cfg_co,
    input  [IFM_DATA_WIDTH-1:0] ifm,
    input  [WGT_DATA_WIDTH-1:0] weight,
    output [511:0] ofm_port,
    output ofm_port_v,
    output ifm_read,
    output wgt_read,
    output end_op
);


    /// Assign ifm to each pes
    reg [7:0] rows [0:17];
    always @(*) begin
        rows[0] = ifm[7:0];
        rows[1] = ifm[15:8];
        rows[2] = ifm[23:16];
        rows[3] = ifm[31:24];
        rows[4] = ifm[39:32];
        rows[5] = ifm[47:40];
        rows[6] = ifm[55:48];
        rows[7] = ifm[63:56];
		rows[8] = ifm[71:64];
        rows[9] = ifm[79:72]; 
		rows[10] = ifm[87:80];
        rows[11] = ifm[95:88];
        rows[12] = ifm[103:96];
        rows[13] = ifm[111:104];
		rows[14] = ifm[119:112];
        rows[15] = ifm[127:120]; 
		rows[16] = ifm[135:128];
        rows[17] = ifm[143:136]; 
		
		
    end
    /// Assign weight to each pes
    reg [7:0] wgts [0:2];
    always @(*) begin
        wgts[0] = weight[7:0];
        wgts[1] = weight[15:8];
        wgts[2] = weight[23:16];

    end

    ///==-------------------------------------------------------------------------------------==
    /// Connect between PE and PE_FSM
    wire ifm_read_en;
    wire wgt_read_en;
    assign ifm_read = ifm_read_en;
    assign wgt_read = wgt_read_en;
    /// Connection between PEs+PE_FSM and WRITEBACK+BUFF
    wire [out_data_width-1:0] pe00_data, pe10_data, pe20_data;
    wire [out_data_width-1:0] pe01_data, pe11_data, pe21_data;
    wire [out_data_width-1:0] pe02_data, pe12_data, pe22_data;
    wire [out_data_width-1:0] pe03_data, pe13_data, pe23_data;
    wire [out_data_width-1:0] pe04_data, pe14_data, pe24_data;
    wire [out_data_width-1:0] pe05_data, pe15_data, pe25_data;
    wire [out_data_width-1:0] pe06_data, pe16_data, pe26_data;
    wire [out_data_width-1:0] pe07_data, pe17_data, pe27_data;
	wire [out_data_width-1:0] pe08_data, pe18_data, pe28_data;
    wire [out_data_width-1:0] pe09_data, pe19_data, pe29_data;
    wire [out_data_width-1:0] pe010_data, pe110_data, pe210_data;
    wire [out_data_width-1:0] pe011_data, pe111_data, pe211_data;
    wire [out_data_width-1:0] pe012_data, pe112_data, pe212_data;
    wire [out_data_width-1:0] pe013_data, pe113_data, pe213_data;
    wire [out_data_width-1:0] pe014_data, pe114_data, pe214_data;
    wire [out_data_width-1:0] pe015_data, pe115_data, pe215_data;

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
	wire [7:0] ifm_buf100, ifm_buf101, ifm_buf102;
    wire [7:0] ifm_buf110, ifm_buf111, ifm_buf112;
    wire [7:0] ifm_buf120, ifm_buf121, ifm_buf122;
    wire [7:0] ifm_buf130, ifm_buf131, ifm_buf132;
    wire [7:0] ifm_buf140, ifm_buf141, ifm_buf142;
    wire [7:0] ifm_buf150, ifm_buf151, ifm_buf152;
	wire [7:0] ifm_buf160, ifm_buf161, ifm_buf162;
    wire [7:0] ifm_buf170, ifm_buf171, ifm_buf172;

	wire [7:0] wgt_buf00, wgt_buf01, wgt_buf02;
	wire [7:0] wgt_buf10, wgt_buf11, wgt_buf12;
	wire [7:0] wgt_buf20, wgt_buf21, wgt_buf22;
	



	IFM_BUF m_ifm_buf0( .clk(clk), .rst_n(rst_n), .ifm_input(rows[0]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf00), .ifm_buf1(ifm_buf01), .ifm_buf2(ifm_buf02));
	IFM_BUF m_ifm_buf1( .clk(clk), .rst_n(rst_n), .ifm_input(rows[1]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf10), .ifm_buf1(ifm_buf11), .ifm_buf2(ifm_buf12));
	IFM_BUF m_ifm_buf2( .clk(clk), .rst_n(rst_n), .ifm_input(rows[2]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf20), .ifm_buf1(ifm_buf21), .ifm_buf2(ifm_buf22));
	IFM_BUF m_ifm_buf3( .clk(clk), .rst_n(rst_n), .ifm_input(rows[3]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf30), .ifm_buf1(ifm_buf31), .ifm_buf2(ifm_buf32));
	IFM_BUF m_ifm_buf4( .clk(clk), .rst_n(rst_n), .ifm_input(rows[4]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf40), .ifm_buf1(ifm_buf41), .ifm_buf2(ifm_buf42));
	IFM_BUF m_ifm_buf5( .clk(clk), .rst_n(rst_n), .ifm_input(rows[5]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf50), .ifm_buf1(ifm_buf51), .ifm_buf2(ifm_buf52));
	IFM_BUF m_ifm_buf6( .clk(clk), .rst_n(rst_n), .ifm_input(rows[6]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf60), .ifm_buf1(ifm_buf61), .ifm_buf2(ifm_buf62));
	IFM_BUF m_ifm_buf7( .clk(clk), .rst_n(rst_n), .ifm_input(rows[7]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf70), .ifm_buf1(ifm_buf71), .ifm_buf2(ifm_buf72));
	IFM_BUF m_ifm_buf8( .clk(clk), .rst_n(rst_n), .ifm_input(rows[8]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf80), .ifm_buf1(ifm_buf81), .ifm_buf2(ifm_buf82));
	IFM_BUF m_ifm_buf9( .clk(clk), .rst_n(rst_n), .ifm_input(rows[9]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf90), .ifm_buf1(ifm_buf91), .ifm_buf2(ifm_buf92));	
	IFM_BUF m_ifm_buf10( .clk(clk), .rst_n(rst_n), .ifm_input(rows[10]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf100), .ifm_buf1(ifm_buf101), .ifm_buf2(ifm_buf102));
	IFM_BUF m_ifm_buf11( .clk(clk), .rst_n(rst_n), .ifm_input(rows[11]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf110), .ifm_buf1(ifm_buf111), .ifm_buf2(ifm_buf112));
	IFM_BUF m_ifm_buf12( .clk(clk), .rst_n(rst_n), .ifm_input(rows[12]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf120), .ifm_buf1(ifm_buf121), .ifm_buf2(ifm_buf122));
	IFM_BUF m_ifm_buf13( .clk(clk), .rst_n(rst_n), .ifm_input(rows[13]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf130), .ifm_buf1(ifm_buf131), .ifm_buf2(ifm_buf132));
	IFM_BUF m_ifm_buf14( .clk(clk), .rst_n(rst_n), .ifm_input(rows[14]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf140), .ifm_buf1(ifm_buf141), .ifm_buf2(ifm_buf142));
	IFM_BUF m_ifm_buf15( .clk(clk), .rst_n(rst_n), .ifm_input(rows[15]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf150), .ifm_buf1(ifm_buf151), .ifm_buf2(ifm_buf152));
	IFM_BUF m_ifm_buf16( .clk(clk), .rst_n(rst_n), .ifm_input(rows[16]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf160), .ifm_buf1(ifm_buf161), .ifm_buf2(ifm_buf162));
	IFM_BUF m_ifm_buf17( .clk(clk), .rst_n(rst_n), .ifm_input(rows[17]), .ifm_read(ifm_read_en), 
	.ifm_buf0(ifm_buf170), .ifm_buf1(ifm_buf171), .ifm_buf2(ifm_buf172));

	WGT_BUF wgt_buf0( .clk(clk), .rst_n(rst_n), .wgt_input(wgts[0]), .wgt_read(wgt_read_en), 
	.wgt_buf0(wgt_buf00), .wgt_buf1(wgt_buf01), .wgt_buf2(wgt_buf02));
	WGT_BUF wgt_buf1( .clk(clk), .rst_n(rst_n), .wgt_input(wgts[1]), .wgt_read(wgt_read_en), 
	.wgt_buf0(wgt_buf10), .wgt_buf1(wgt_buf11), .wgt_buf2(wgt_buf12));
	WGT_BUF wgt_buf2( .clk(clk), .rst_n(rst_n), .wgt_input(wgts[2]), .wgt_read(wgt_read_en), 
	.wgt_buf0(wgt_buf20), .wgt_buf1(wgt_buf21), .wgt_buf2(wgt_buf22));
	

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	//ofm0 pe array                                                                                             //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
	PE pe00( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf00), .ifm_input1(ifm_buf01), .ifm_input2(ifm_buf02), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe00_data) );
	PE pe01( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf10), .ifm_input1(ifm_buf11), .ifm_input2(ifm_buf12), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe01_data) );
	PE pe02( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20), .ifm_input1(ifm_buf21), .ifm_input2(ifm_buf22),
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe02_data) );
	PE pe03( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30), .ifm_input1(ifm_buf31), .ifm_input2(ifm_buf32), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe03_data) );
	PE pe04( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40), .ifm_input1(ifm_buf41), .ifm_input2(ifm_buf42), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe04_data) );
	PE pe05( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50), .ifm_input1(ifm_buf51), .ifm_input2(ifm_buf52), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe05_data) );
	PE pe06( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60), .ifm_input1(ifm_buf61), .ifm_input2(ifm_buf62),
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe06_data) );
	PE pe07( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70), .ifm_input1(ifm_buf71), .ifm_input2(ifm_buf72), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe07_data) );
	PE pe08( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf80), .ifm_input1(ifm_buf81), .ifm_input2(ifm_buf82), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe08_data) );
	PE pe09( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf90), .ifm_input1(ifm_buf91), .ifm_input2(ifm_buf92), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe09_data) );
	PE pe010( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf100), .ifm_input1(ifm_buf101), .ifm_input2(ifm_buf102),
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe010_data) );
	PE pe011( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf110), .ifm_input1(ifm_buf111), .ifm_input2(ifm_buf112), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe011_data) );
	PE pe012( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf120), .ifm_input1(ifm_buf121), .ifm_input2(ifm_buf122), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe012_data) );
	PE pe013( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf130), .ifm_input1(ifm_buf131), .ifm_input2(ifm_buf132), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe013_data) );
	PE pe014( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf140), .ifm_input1(ifm_buf141), .ifm_input2(ifm_buf142),
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe014_data) );
	PE pe015( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf150), .ifm_input1(ifm_buf151), .ifm_input2(ifm_buf152), 
	.wgt_input0(wgt_buf00), .wgt_input1(wgt_buf01), .wgt_input2(wgt_buf02), .p_sum(pe015_data) );
	
	
	
	PE pe10( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf10), .ifm_input1(ifm_buf11), .ifm_input2(ifm_buf12), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe10_data) );
	PE pe11( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20), .ifm_input1(ifm_buf21), .ifm_input2(ifm_buf22), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe11_data) );
	PE pe12( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30), .ifm_input1(ifm_buf31), .ifm_input2(ifm_buf32),
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe12_data) );
	PE pe13( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40), .ifm_input1(ifm_buf41), .ifm_input2(ifm_buf42), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe13_data) );
	PE pe14( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50), .ifm_input1(ifm_buf51), .ifm_input2(ifm_buf52), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe14_data) );
	PE pe15( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60), .ifm_input1(ifm_buf61), .ifm_input2(ifm_buf62), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe15_data) );
	PE pe16( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70), .ifm_input1(ifm_buf71), .ifm_input2(ifm_buf72),
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe16_data) );
	PE pe17( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf80), .ifm_input1(ifm_buf81), .ifm_input2(ifm_buf82), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe17_data) );	
	PE pe18( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf90), .ifm_input1(ifm_buf91), .ifm_input2(ifm_buf92), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe18_data) );
	PE pe19( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf100), .ifm_input1(ifm_buf101), .ifm_input2(ifm_buf102), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe19_data) );
	PE pe110( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf110), .ifm_input1(ifm_buf111), .ifm_input2(ifm_buf112),
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe110_data) );
	PE pe111( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf120), .ifm_input1(ifm_buf121), .ifm_input2(ifm_buf122), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe111_data) );
	PE pe112( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf130), .ifm_input1(ifm_buf131), .ifm_input2(ifm_buf132), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe112_data) );
	PE pe113( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf140), .ifm_input1(ifm_buf141), .ifm_input2(ifm_buf142), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe113_data) );
	PE pe114( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf150), .ifm_input1(ifm_buf151), .ifm_input2(ifm_buf152),
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe114_data) );
	PE pe115( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf160), .ifm_input1(ifm_buf161), .ifm_input2(ifm_buf162), 
	.wgt_input0(wgt_buf10), .wgt_input1(wgt_buf11), .wgt_input2(wgt_buf12), .p_sum(pe115_data) );	
	
	PE pe20( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20), .ifm_input1(ifm_buf21), .ifm_input2(ifm_buf22), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe20_data) );
	PE pe21( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30), .ifm_input1(ifm_buf31), .ifm_input2(ifm_buf32), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe21_data) );
	PE pe22( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40), .ifm_input1(ifm_buf41), .ifm_input2(ifm_buf42),
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe22_data) );
	PE pe23( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50), .ifm_input1(ifm_buf51), .ifm_input2(ifm_buf52), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe23_data) );
	PE pe24( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60), .ifm_input1(ifm_buf61), .ifm_input2(ifm_buf62), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe24_data) );
	PE pe25( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70), .ifm_input1(ifm_buf71), .ifm_input2(ifm_buf72), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe25_data) );
	PE pe26( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf80), .ifm_input1(ifm_buf81), .ifm_input2(ifm_buf82),
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe26_data) );
	PE pe27( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf90), .ifm_input1(ifm_buf91), .ifm_input2(ifm_buf92), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe27_data) );	
	PE pe28( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf100), .ifm_input1(ifm_buf101), .ifm_input2(ifm_buf102), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe28_data) );
	PE pe29( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf110), .ifm_input1(ifm_buf111), .ifm_input2(ifm_buf112), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe29_data) );
	PE pe210( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf120), .ifm_input1(ifm_buf121), .ifm_input2(ifm_buf122),
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe210_data) );
	PE pe211( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf130), .ifm_input1(ifm_buf131), .ifm_input2(ifm_buf132), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe211_data) );
	PE pe212( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf140), .ifm_input1(ifm_buf141), .ifm_input2(ifm_buf142), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe212_data) );
	PE pe213( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf150), .ifm_input1(ifm_buf151), .ifm_input2(ifm_buf152), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe213_data) );
	PE pe214( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf160), .ifm_input1(ifm_buf161), .ifm_input2(ifm_buf162),
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe214_data) );
	PE pe215( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf170), .ifm_input1(ifm_buf171), .ifm_input2(ifm_buf172), 
	.wgt_input0(wgt_buf20), .wgt_input1(wgt_buf21), .wgt_input2(wgt_buf22), .p_sum(pe215_data) );	

	

    ///==-------------------------------------------------------------------------------------==
    /// Connection between the buffer and write back controllers
    wire [out_data_width-1:0] fifo_out[0:15];
    wire valid_fifo_out[0:15];
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
        .row0(fifo_out[0]),
        .row0_valid(valid_fifo_out[0]),
        .row1(fifo_out[1]),
        .row1_valid(valid_fifo_out[1]),
        .row2(fifo_out[2]),
        .row2_valid(valid_fifo_out[2]),
        .row3(fifo_out[3]),
        .row3_valid(valid_fifo_out[3]),
        .row4(fifo_out[4]),
        .row4_valid(valid_fifo_out[4]),
		.row5(fifo_out[5]),
        .row5_valid(valid_fifo_out[5]),
        .row6(fifo_out[6]),
        .row6_valid(valid_fifo_out[6]),
        .row7(fifo_out[7]),
        .row7_valid(valid_fifo_out[7]),
        .row8(fifo_out[8]),
        .row8_valid(valid_fifo_out[8]),
        .row9(fifo_out[9]),
        .row9_valid(valid_fifo_out[9]),
        .row10(fifo_out[10]),
        .row10_valid(valid_fifo_out[10]),
        .row11(fifo_out[11]),
        .row11_valid(valid_fifo_out[11]),
        .row12(fifo_out[12]),
        .row12_valid(valid_fifo_out[12]),
		.row13(fifo_out[13]),
        .row13_valid(valid_fifo_out[13]),
        .row14(fifo_out[14]),
        .row14_valid(valid_fifo_out[14]),
        .row15(fifo_out[15]),
        .row15_valid(valid_fifo_out[15]),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .out_port(ofm_port),
        .port_valid(ofm_port_v),
        .start_conv(start_again),
        .odd_cnt(odd_cnt),

        .end_conv(end_conv),
        .end_op(end_op)
    );

    
    /// Buffer
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	// pe array                                                                                             //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff0 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe00_data),
        .pe1_data(pe10_data),
        .pe2_data(pe20_data),
        .fifo_out(fifo_out[0]),
        .valid_fifo_out(valid_fifo_out[0])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff1 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe01_data),
        .pe1_data(pe11_data),
        .pe2_data(pe21_data),
        .fifo_out(fifo_out[1]),
        .valid_fifo_out(valid_fifo_out[1])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff2 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe02_data),
        .pe1_data(pe12_data),
        .pe2_data(pe22_data),
        .fifo_out(fifo_out[2]),
        .valid_fifo_out(valid_fifo_out[2])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff3 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe03_data),
        .pe1_data(pe13_data),
        .pe2_data(pe23_data),
        .fifo_out(fifo_out[3]),
        .valid_fifo_out(valid_fifo_out[3])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff4 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe04_data),
        .pe1_data(pe14_data),
        .pe2_data(pe24_data),
        .fifo_out(fifo_out[4]),
        .valid_fifo_out(valid_fifo_out[4])
    );
	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff5 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe05_data),
        .pe1_data(pe15_data),
        .pe2_data(pe25_data),
        .fifo_out(fifo_out[5]),
        .valid_fifo_out(valid_fifo_out[5])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff6 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe06_data),
        .pe1_data(pe16_data),
        .pe2_data(pe26_data),
        .fifo_out(fifo_out[6]),
        .valid_fifo_out(valid_fifo_out[6])
    );
	
	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff7 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe07_data),
        .pe1_data(pe17_data),
        .pe2_data(pe27_data),
        .fifo_out(fifo_out[7]),
        .valid_fifo_out(valid_fifo_out[7])
    );

	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff8 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe08_data),
        .pe1_data(pe18_data),
        .pe2_data(pe28_data),
        .fifo_out(fifo_out[8]),
        .valid_fifo_out(valid_fifo_out[8])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff9 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe09_data),
        .pe1_data(pe19_data),
        .pe2_data(pe29_data),
        .fifo_out(fifo_out[9]),
        .valid_fifo_out(valid_fifo_out[9])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff10 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe010_data),
        .pe1_data(pe110_data),
        .pe2_data(pe210_data),
        .fifo_out(fifo_out[10]),
        .valid_fifo_out(valid_fifo_out[10])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff11 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe011_data),
        .pe1_data(pe111_data),
        .pe2_data(pe211_data),
        .fifo_out(fifo_out[11]),
        .valid_fifo_out(valid_fifo_out[11])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff12 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe012_data),
        .pe1_data(pe112_data),
        .pe2_data(pe212_data),
        .fifo_out(fifo_out[12]),
        .valid_fifo_out(valid_fifo_out[12])
    );
	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff13 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe013_data),
        .pe1_data(pe113_data),
        .pe2_data(pe213_data),
        .fifo_out(fifo_out[13]),
        .valid_fifo_out(valid_fifo_out[13])
    );

    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff14 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe014_data),
        .pe1_data(pe114_data),
        .pe2_data(pe214_data),
        .fifo_out(fifo_out[14]),
        .valid_fifo_out(valid_fifo_out[14])
    );
	
	
    PSUM_BUFF #(
        .data_width(out_data_width),
        .addr_width(buf_addr_width),
        .depth(buf_depth)
    ) psum_buff15 (
        .clk(clk),
        .rst_n(rst_n),
        .p_valid_data(p_valid_data),
        .p_write_zero(p_write_zero),
        .p_init(p_init),
        .odd_cnt(odd_cnt),
        .pe0_data(pe015_data),
        .pe1_data(pe115_data),
        .pe2_data(pe215_data),
        .fifo_out(fifo_out[15]),
        .valid_fifo_out(valid_fifo_out[15])
    );

endmodule //CONV_ACC