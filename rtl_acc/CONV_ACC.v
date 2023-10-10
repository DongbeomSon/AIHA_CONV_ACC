///==------------------------------------------------------------------==///
/// Conv kernel: top level module
///==------------------------------------------------------------------==///

`timescale 1ns/1ps

module CONV_ACC #(
    parameter out_data_width = 32,
    parameter buf_addr_width = 5,
    parameter buf_depth      = 28,
    parameter pe_set         = 128,
	parameter IFM_DATA_WIDTH = 8 * 16,
	parameter WGT_DATA_WIDTH = 8 * 3 * pe_set
) (
    input  clk,
    input  rst_n,
    input  start_conv,
    input  [1:0] cfg_ci,
    input  [1:0] cfg_co,
    input  [511:0] ifm,
    input  [WGT_DATA_WIDTH-1:0] weight,
    output reg [511:0] out_ofm0_port0,
    output reg [511:0] out_ofm0_port1,
    output reg [511:0] out_ofm0_port2,
    output reg [511:0] out_ofm0_port3,
    output reg [511:0] out_ofm0_port4,
    output reg [511:0] out_ofm0_port5,
    output reg [511:0] out_ofm0_port6,
    output reg [511:0] out_ofm0_port7,
    output reg [511:0] out_ofm0_port8,
    output reg [511:0] out_ofm0_port9,
    output reg [511:0] out_ofm0_port10,
    output reg [511:0] out_ofm0_port11,
    output reg [511:0] out_ofm0_port12,
    output reg [511:0] out_ofm0_port13,
    output reg [511:0] out_ofm1_port0,
    output reg [511:0] out_ofm1_port1,
    output reg [511:0] out_ofm1_port2,
    output reg [511:0] out_ofm1_port3,
    output reg [511:0] out_ofm1_port4,
    output reg [511:0] out_ofm1_port5,
    output reg [511:0] out_ofm1_port6,
    output reg [511:0] out_ofm1_port7,
    output reg [511:0] out_ofm1_port8,
    output reg [511:0] out_ofm1_port9,
    output reg [511:0] out_ofm1_port10,
    output reg [511:0] out_ofm1_port11,
    output reg [511:0] out_ofm1_port12,
    output reg [511:0] out_ofm1_port13,
    output reg out_ofm_port_v0,
    output reg out_ofm_port_v1,
    output reg out_ofm_port_v2,
    output reg out_ofm_port_v3,
    output reg out_ofm_port_v4,
    output reg out_ofm_port_v5,
    output reg out_ofm_port_v6,
    output reg out_ofm_port_v7,
    output reg out_ofm_port_v8,
    output reg out_ofm_port_v9,
    output reg out_ofm_port_v10,
    output reg out_ofm_port_v11,
    output reg out_ofm_port_v12,
    output reg out_ofm_port_v13,
    output ifm_read,
    output wgt_read,
    output end_op
);


    /// Assign ifm to each pes
    reg [7:0] rows0 [0:3];
    reg [7:0] rows1 [0:3];
    reg [7:0] rows2 [0:3];
    reg [7:0] rows3 [0:3];
    reg [7:0] rows4 [0:3];
    reg [7:0] rows5 [0:3];
    reg [7:0] rows6 [0:3];
    reg [7:0] rows7 [0:3];
    reg [7:0] rows8 [0:3];
    reg [7:0] rows9 [0:3];
    reg [7:0] rows10 [0:3];
    reg [7:0] rows11 [0:3];
    reg [7:0] rows12 [0:3];
    reg [7:0] rows13 [0:3];
    reg [7:0] rows14 [0:3];
    reg [7:0] rows15 [0:3];

    wire [127:0] ifm0, ifm1, ifm2, ifm3;

    assign ifm0 = ifm[127:0];
    assign ifm1 = ifm[255:128];
    assign ifm2 = ifm[383:256];
    assign ifm3 = ifm[511:384];

    always @(*) begin
        rows0[0] <= ifm0[7:0];
        rows1[0] <= ifm0[15:8];
        rows2[0] <= ifm0[23:16];
        rows3[0] <= ifm0[31:24];
        rows4[0] <= ifm0[39:32];
        rows5[0] <= ifm0[47:40];
        rows6[0] <= ifm0[55:48];
        rows7[0] <= ifm0[63:56];
		rows8[0] <= ifm0[71:64];
        rows9[0] <= ifm0[79:72]; 
		rows10[0] <= ifm0[87:80];
        rows11[0] <= ifm0[95:88];
        rows12[0] <= ifm0[103:96];
        rows13[0] <= ifm0[111:104];
		rows14[0] <= ifm0[119:112];
        rows15[0] <= ifm0[127:120]; 

        rows0[1] <= ifm1[7:0];
        rows1[1] <= ifm1[15:8];
        rows2[1] <= ifm1[23:16];
        rows3[1] <= ifm1[31:24];
        rows4[1] <= ifm1[39:32];
        rows5[1] <= ifm1[47:40];
        rows6[1] <= ifm1[55:48];
        rows7[1] <= ifm1[63:56];
		rows8[1] <= ifm1[71:64];
        rows9[1] <= ifm1[79:72]; 
		rows10[1] <= ifm1[87:80];
        rows11[1] <= ifm1[95:88];
        rows12[1] <= ifm1[103:96];
        rows13[1] <= ifm1[111:104];
		rows14[1] <= ifm1[119:112];
        rows15[1] <= ifm1[127:120]; 

        rows0[2] <= ifm2[7:0];
        rows1[2] <= ifm2[15:8];
        rows2[2] <= ifm2[23:16];
        rows3[2] <= ifm2[31:24];
        rows4[2] <= ifm2[39:32];
        rows5[2] <= ifm2[47:40];
        rows6[2] <= ifm2[55:48];
        rows7[2] <= ifm2[63:56];
		rows8[2] <= ifm2[71:64];
        rows9[2] <= ifm2[79:72]; 
		rows10[2] <= ifm2[87:80];
        rows11[2] <= ifm2[95:88];
        rows12[2] <= ifm2[103:96];
        rows13[2] <= ifm2[111:104];
		rows14[2] <= ifm2[119:112];
        rows15[2] <= ifm2[127:120]; 

        rows0[3] <= ifm3[7:0];
        rows1[3] <= ifm3[15:8];
        rows2[3] <= ifm3[23:16];
        rows3[3] <= ifm3[31:24];
        rows4[3] <= ifm3[39:32];
        rows5[3] <= ifm3[47:40];
        rows6[3] <= ifm3[55:48];
        rows7[3] <= ifm3[63:56];
		rows8[3] <= ifm3[71:64];
        rows9[3] <= ifm3[79:72]; 
		rows10[3] <= ifm3[87:80];
        rows11[3] <= ifm3[95:88];
        rows12[3] <= ifm3[103:96];
        rows13[3] <= ifm3[111:104];
		rows14[3] <= ifm3[119:112];
        rows15[3] <= ifm3[127:120]; 	
    end
    /// Assign weight to each pes
    reg [7:0] wgts0 [0:pe_set-1];
    reg [7:0] wgts1 [0:pe_set-1];
    reg [7:0] wgts2 [0:pe_set-1];

    genvar a;
    generate
        for (a=0 ; a<pe_set ; a++) begin: wgt_gen

            always @(*) begin
                wgts0[a] = weight[24*a+7:24*a+0];
                wgts1[a] = weight[24*a+15:24*a+8];
                wgts2[a] = weight[24*a+23:24*a+16];
            end
        end
    endgenerate

    ///==-------------------------------------------------------------------------------------==
    /// Connect between PE and PE_FSM
    wire ifm_read_en;
    wire wgt_read_en;
    assign ifm_read = ifm_read_en;
    assign wgt_read = wgt_read_en;
    /// Connection between PEs+PE_FSM and WRITEBACK+BUFF
    wire [out_data_width-1:0] pe00_data[0:pe_set-1], pe10_data[0:pe_set-1], pe20_data[0:pe_set-1];
    wire [out_data_width-1:0] pe01_data[0:pe_set-1], pe11_data[0:pe_set-1], pe21_data[0:pe_set-1];
    wire [out_data_width-1:0] pe02_data[0:pe_set-1], pe12_data[0:pe_set-1], pe22_data[0:pe_set-1];
    wire [out_data_width-1:0] pe03_data[0:pe_set-1], pe13_data[0:pe_set-1], pe23_data[0:pe_set-1];
    wire [out_data_width-1:0] pe04_data[0:pe_set-1], pe14_data[0:pe_set-1], pe24_data[0:pe_set-1];
    wire [out_data_width-1:0] pe05_data[0:pe_set-1], pe15_data[0:pe_set-1], pe25_data[0:pe_set-1];
    wire [out_data_width-1:0] pe06_data[0:pe_set-1], pe16_data[0:pe_set-1], pe26_data[0:pe_set-1];
    wire [out_data_width-1:0] pe07_data[0:pe_set-1], pe17_data[0:pe_set-1], pe27_data[0:pe_set-1];
	wire [out_data_width-1:0] pe08_data[0:pe_set-1], pe18_data[0:pe_set-1], pe28_data[0:pe_set-1];
    wire [out_data_width-1:0] pe09_data[0:pe_set-1], pe19_data[0:pe_set-1], pe29_data[0:pe_set-1];
    wire [out_data_width-1:0] pe010_data[0:pe_set-1], pe110_data[0:pe_set-1], pe210_data[0:pe_set-1];
    wire [out_data_width-1:0] pe011_data[0:pe_set-1], pe111_data[0:pe_set-1], pe211_data[0:pe_set-1];
    wire [out_data_width-1:0] pe012_data[0:pe_set-1], pe112_data[0:pe_set-1], pe212_data[0:pe_set-1];
    wire [out_data_width-1:0] pe013_data[0:pe_set-1], pe113_data[0:pe_set-1], pe213_data[0:pe_set-1];


    wire p_filter_end, p_valid_data, start_again[0:7];
    /// PE FSM
    PE_FSM pe_fsm ( .clk(clk), .rst_n(rst_n), .start_conv(start_conv), .start_again(start_again[0]), .cfg_ci(cfg_ci), .cfg_co(cfg_co), 
            .ifm_read(ifm_read_en), .wgt_read(wgt_read_en), .p_valid_output(p_valid_data), 
            .last_chanel_output(p_filter_end), .end_conv(end_conv) );  
    
    /// First row
    wire [7:0] ifm_buf00[0:pe_set-1], ifm_buf01[0:pe_set-1], ifm_buf02[0:pe_set-1];
    wire [7:0] ifm_buf10[0:pe_set-1], ifm_buf11[0:pe_set-1], ifm_buf12[0:pe_set-1];
    wire [7:0] ifm_buf20[0:pe_set-1], ifm_buf21[0:pe_set-1], ifm_buf22[0:pe_set-1];
    wire [7:0] ifm_buf30[0:pe_set-1], ifm_buf31[0:pe_set-1], ifm_buf32[0:pe_set-1];
    wire [7:0] ifm_buf40[0:pe_set-1], ifm_buf41[0:pe_set-1], ifm_buf42[0:pe_set-1];
    wire [7:0] ifm_buf50[0:pe_set-1], ifm_buf51[0:pe_set-1], ifm_buf52[0:pe_set-1];
    wire [7:0] ifm_buf60[0:pe_set-1], ifm_buf61[0:pe_set-1], ifm_buf62[0:pe_set-1];
    wire [7:0] ifm_buf70[0:pe_set-1], ifm_buf71[0:pe_set-1], ifm_buf72[0:pe_set-1];
	wire [7:0] ifm_buf80[0:pe_set-1], ifm_buf81[0:pe_set-1], ifm_buf82[0:pe_set-1];
    wire [7:0] ifm_buf90[0:pe_set-1], ifm_buf91[0:pe_set-1], ifm_buf92[0:pe_set-1];
	wire [7:0] ifm_buf100[0:pe_set-1], ifm_buf101[0:pe_set-1], ifm_buf102[0:pe_set-1];
    wire [7:0] ifm_buf110[0:pe_set-1], ifm_buf111[0:pe_set-1], ifm_buf112[0:pe_set-1];
    wire [7:0] ifm_buf120[0:pe_set-1], ifm_buf121[0:pe_set-1], ifm_buf122[0:pe_set-1];
    wire [7:0] ifm_buf130[0:pe_set-1], ifm_buf131[0:pe_set-1], ifm_buf132[0:pe_set-1];
    wire [7:0] ifm_buf140[0:pe_set-1], ifm_buf141[0:pe_set-1], ifm_buf142[0:pe_set-1];
    wire [7:0] ifm_buf150[0:pe_set-1], ifm_buf151[0:pe_set-1], ifm_buf152[0:pe_set-1];


	wire [7:0] wgt_buf00[0:pe_set-1], wgt_buf01[0:pe_set-1], wgt_buf02[0:pe_set-1];
	wire [7:0] wgt_buf10[0:pe_set-1], wgt_buf11[0:pe_set-1], wgt_buf12[0:pe_set-1];
	wire [7:0] wgt_buf20[0:pe_set-1], wgt_buf21[0:pe_set-1], wgt_buf22[0:pe_set-1];
	

    genvar j;
    generate
        for (j=0 ; j<pe_set ; j++) begin: buf_gen

            IFM_BUF m_ifm_buf0( .clk(clk), .rst_n(rst_n), .ifm_input(rows0[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf00[j]), .ifm_buf1(ifm_buf01[j]), .ifm_buf2(ifm_buf02[j]));
            IFM_BUF m_ifm_buf1( .clk(clk), .rst_n(rst_n), .ifm_input(rows1[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf10[j]), .ifm_buf1(ifm_buf11[j]), .ifm_buf2(ifm_buf12[j]));
            IFM_BUF m_ifm_buf2( .clk(clk), .rst_n(rst_n), .ifm_input(rows2[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf20[j]), .ifm_buf1(ifm_buf21[j]), .ifm_buf2(ifm_buf22[j]));
            IFM_BUF m_ifm_buf3( .clk(clk), .rst_n(rst_n), .ifm_input(rows3[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf30[j]), .ifm_buf1(ifm_buf31[j]), .ifm_buf2(ifm_buf32[j]));
            IFM_BUF m_ifm_buf4( .clk(clk), .rst_n(rst_n), .ifm_input(rows4[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf40[j]), .ifm_buf1(ifm_buf41[j]), .ifm_buf2(ifm_buf42[j]));
            IFM_BUF m_ifm_buf5( .clk(clk), .rst_n(rst_n), .ifm_input(rows5[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf50[j]), .ifm_buf1(ifm_buf51[j]), .ifm_buf2(ifm_buf52[j]));
            IFM_BUF m_ifm_buf6( .clk(clk), .rst_n(rst_n), .ifm_input(rows6[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf60[j]), .ifm_buf1(ifm_buf61[j]), .ifm_buf2(ifm_buf62[j]));
            IFM_BUF m_ifm_buf7( .clk(clk), .rst_n(rst_n), .ifm_input(rows7[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf70[j]), .ifm_buf1(ifm_buf71[j]), .ifm_buf2(ifm_buf72[j]));
            IFM_BUF m_ifm_buf8( .clk(clk), .rst_n(rst_n), .ifm_input(rows8[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf80[j]), .ifm_buf1(ifm_buf81[j]), .ifm_buf2(ifm_buf82[j]));
            IFM_BUF m_ifm_buf9( .clk(clk), .rst_n(rst_n), .ifm_input(rows9[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf90[j]), .ifm_buf1(ifm_buf91[j]), .ifm_buf2(ifm_buf92[j]));	
            IFM_BUF m_ifm_buf10( .clk(clk), .rst_n(rst_n), .ifm_input(rows10[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf100[j]), .ifm_buf1(ifm_buf101[j]), .ifm_buf2(ifm_buf102[j]));
            IFM_BUF m_ifm_buf11( .clk(clk), .rst_n(rst_n), .ifm_input(rows11[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf110[j]), .ifm_buf1(ifm_buf111[j]), .ifm_buf2(ifm_buf112[j]));
            IFM_BUF m_ifm_buf12( .clk(clk), .rst_n(rst_n), .ifm_input(rows12[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf120[j]), .ifm_buf1(ifm_buf121[j]), .ifm_buf2(ifm_buf122[j]));
            IFM_BUF m_ifm_buf13( .clk(clk), .rst_n(rst_n), .ifm_input(rows13[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf130[j]), .ifm_buf1(ifm_buf131[j]), .ifm_buf2(ifm_buf132[j]));
            IFM_BUF m_ifm_buf14( .clk(clk), .rst_n(rst_n), .ifm_input(rows14[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf140[j]), .ifm_buf1(ifm_buf141[j]), .ifm_buf2(ifm_buf142[j]));
            IFM_BUF m_ifm_buf15( .clk(clk), .rst_n(rst_n), .ifm_input(rows15[j/32]), .ifm_read(ifm_read_en), 
            .ifm_buf0(ifm_buf150[j]), .ifm_buf1(ifm_buf151[j]), .ifm_buf2(ifm_buf152[j]));

            WGT_BUF wgt_buf0( .clk(clk), .rst_n(rst_n), .wgt_input(wgts0[j]), .wgt_read(wgt_read_en), 
            .wgt_buf0(wgt_buf00[j]), .wgt_buf1(wgt_buf01[j]), .wgt_buf2(wgt_buf02[j]));
            WGT_BUF wgt_buf1( .clk(clk), .rst_n(rst_n), .wgt_input(wgts1[j]), .wgt_read(wgt_read_en), 
            .wgt_buf0(wgt_buf10[j]), .wgt_buf1(wgt_buf11[j]), .wgt_buf2(wgt_buf12[j]));
            WGT_BUF wgt_buf2( .clk(clk), .rst_n(rst_n), .wgt_input(wgts2[j]), .wgt_read(wgt_read_en), 
            .wgt_buf0(wgt_buf20[j]), .wgt_buf1(wgt_buf21[j]), .wgt_buf2(wgt_buf22[j]));
	
        end
    endgenerate

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	//ofm0 pe array                                                                                             //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    genvar i;
    generate
        for (i=0 ; i<pe_set ; i++) begin: pe_gen


            PE pe00( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf00[i]), .ifm_input1(ifm_buf01[i]), .ifm_input2(ifm_buf02[i]), 
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe00_data[i]) );
            PE pe01( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf10[i]), .ifm_input1(ifm_buf11[i]), .ifm_input2(ifm_buf12[i]), 
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe01_data[i]) );
            PE pe02( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20[i]), .ifm_input1(ifm_buf21[i]), .ifm_input2(ifm_buf22[i]),
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe02_data[i]) );
            PE pe03( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30[i]), .ifm_input1(ifm_buf31[i]), .ifm_input2(ifm_buf32[i]), 
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe03_data[i]) );
            PE pe04( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40[i]), .ifm_input1(ifm_buf41[i]), .ifm_input2(ifm_buf42[i]), 
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe04_data[i]) );
            PE pe05( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50[i]), .ifm_input1(ifm_buf51[i]), .ifm_input2(ifm_buf52[i]), 
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe05_data[i]) );
            PE pe06( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60[i]), .ifm_input1(ifm_buf61[i]), .ifm_input2(ifm_buf62[i]),
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe06_data[i]) );
            PE pe07( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70[i]), .ifm_input1(ifm_buf71[i]), .ifm_input2(ifm_buf72[i]), 
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe07_data[i]) );
            PE pe08( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf80[i]), .ifm_input1(ifm_buf81[i]), .ifm_input2(ifm_buf82[i]), 
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe08_data[i]) );
            PE pe09( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf90[i]), .ifm_input1(ifm_buf91[i]), .ifm_input2(ifm_buf92[i]), 
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe09_data[i]) );
            PE pe010( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf100[i]), .ifm_input1(ifm_buf101[i]), .ifm_input2(ifm_buf102[i]),
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe010_data[i]) );
            PE pe011( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf110[i]), .ifm_input1(ifm_buf111[i]), .ifm_input2(ifm_buf112[i]), 
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe011_data[i]) );
            PE pe012( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf120[i]), .ifm_input1(ifm_buf121[i]), .ifm_input2(ifm_buf122[i]), 
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe012_data[i]) );
            PE pe013( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf130[i]), .ifm_input1(ifm_buf131[i]), .ifm_input2(ifm_buf132[i]), 
            .wgt_input0(wgt_buf00[i]), .wgt_input1(wgt_buf01[i]), .wgt_input2(wgt_buf02[i]), .p_sum(pe013_data[i]) );
            
            
            
            PE pe10( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf10[i]), .ifm_input1(ifm_buf11[i]), .ifm_input2(ifm_buf12[i]), 
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe10_data[i]) );
            PE pe11( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20[i]), .ifm_input1(ifm_buf21[i]), .ifm_input2(ifm_buf22[i]), 
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe11_data[i]) );
            PE pe12( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30[i]), .ifm_input1(ifm_buf31[i]), .ifm_input2(ifm_buf32[i]),
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe12_data[i]) );
            PE pe13( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40[i]), .ifm_input1(ifm_buf41[i]), .ifm_input2(ifm_buf42[i]), 
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe13_data[i]) );
            PE pe14( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50[i]), .ifm_input1(ifm_buf51[i]), .ifm_input2(ifm_buf52[i]), 
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe14_data[i]) );
            PE pe15( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60[i]), .ifm_input1(ifm_buf61[i]), .ifm_input2(ifm_buf62[i]), 
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe15_data[i]) );
            PE pe16( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70[i]), .ifm_input1(ifm_buf71[i]), .ifm_input2(ifm_buf72[i]),
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe16_data[i]) );
            PE pe17( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf80[i]), .ifm_input1(ifm_buf81[i]), .ifm_input2(ifm_buf82[i]), 
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe17_data[i]) );	
            PE pe18( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf90[i]), .ifm_input1(ifm_buf91[i]), .ifm_input2(ifm_buf92[i]), 
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe18_data[i]) );
            PE pe19( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf100[i]), .ifm_input1(ifm_buf101[i]), .ifm_input2(ifm_buf102[i]), 
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe19_data[i]) );
            PE pe110( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf110[i]), .ifm_input1(ifm_buf111[i]), .ifm_input2(ifm_buf112[i]),
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe110_data[i]) );
            PE pe111( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf120[i]), .ifm_input1(ifm_buf121[i]), .ifm_input2(ifm_buf122[i]), 
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe111_data[i]) );
            PE pe112( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf130[i]), .ifm_input1(ifm_buf131[i]), .ifm_input2(ifm_buf132[i]), 
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe112_data[i]) );
            PE pe113( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf140[i]), .ifm_input1(ifm_buf141[i]), .ifm_input2(ifm_buf142[i]), 
            .wgt_input0(wgt_buf10[i]), .wgt_input1(wgt_buf11[i]), .wgt_input2(wgt_buf12[i]), .p_sum(pe113_data[i]) );

            
            PE pe20( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf20[i]), .ifm_input1(ifm_buf21[i]), .ifm_input2(ifm_buf22[i]), 
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe20_data[i]) );
            PE pe21( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf30[i]), .ifm_input1(ifm_buf31[i]), .ifm_input2(ifm_buf32[i]), 
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe21_data[i]) );
            PE pe22( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf40[i]), .ifm_input1(ifm_buf41[i]), .ifm_input2(ifm_buf42[i]),
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe22_data[i]) );
            PE pe23( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf50[i]), .ifm_input1(ifm_buf51[i]), .ifm_input2(ifm_buf52[i]), 
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe23_data[i]) );
            PE pe24( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf60[i]), .ifm_input1(ifm_buf61[i]), .ifm_input2(ifm_buf62[i]), 
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe24_data[i]) );
            PE pe25( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf70[i]), .ifm_input1(ifm_buf71[i]), .ifm_input2(ifm_buf72[i]), 
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe25_data[i]) );
            PE pe26( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf80[i]), .ifm_input1(ifm_buf81[i]), .ifm_input2(ifm_buf82[i]),
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe26_data[i]) );
            PE pe27( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf90[i]), .ifm_input1(ifm_buf91[i]), .ifm_input2(ifm_buf92[i]), 
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe27_data[i]) );	
            PE pe28( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf100[i]), .ifm_input1(ifm_buf101[i]), .ifm_input2(ifm_buf102[i]), 
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe28_data[i]) );
            PE pe29( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf110[i]), .ifm_input1(ifm_buf111[i]), .ifm_input2(ifm_buf112[i]), 
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe29_data[i]) );
            PE pe210( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf120[i]), .ifm_input1(ifm_buf121[i]), .ifm_input2(ifm_buf122[i]),
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe210_data[i]) );
            PE pe211( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf130[i]), .ifm_input1(ifm_buf131[i]), .ifm_input2(ifm_buf132[i]), 
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe211_data[i]) );
            PE pe212( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf140[i]), .ifm_input1(ifm_buf141[i]), .ifm_input2(ifm_buf142[i]), 
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe212_data[i]) );
            PE pe213( .clk(clk), .rst_n(rst_n), .ifm_input0(ifm_buf150[i]), .ifm_input1(ifm_buf151[i]), .ifm_input2(ifm_buf152[i]), 
            .wgt_input0(wgt_buf20[i]), .wgt_input1(wgt_buf21[i]), .wgt_input2(wgt_buf22[i]), .p_sum(pe213_data[i]) );

        end
    endgenerate

    ///==-------------------------------------------------------------------------------------==
    /// Connection between the buffer and write back controllers
    wire [out_data_width-1:0] fifo_out0[0:pe_set-1], fifo_out1[0:pe_set-1], fifo_out2[0:pe_set-1], fifo_out3[0:pe_set-1], fifo_out4[0:pe_set-1], 
                              fifo_out5[0:pe_set-1], fifo_out6[0:pe_set-1], fifo_out7[0:pe_set-1], fifo_out8[0:pe_set-1], fifo_out9[0:pe_set-1], 
                              fifo_out10[0:pe_set-1], fifo_out11[0:pe_set-1], fifo_out12[0:pe_set-1], fifo_out13[0:pe_set-1];
    wire valid_fifo_out0[0:pe_set-1], valid_fifo_out1[0:pe_set-1], valid_fifo_out2[0:pe_set-1], valid_fifo_out3[0:pe_set-1], valid_fifo_out4[0:pe_set-1], 
         valid_fifo_out5[0:pe_set-1], valid_fifo_out6[0:pe_set-1], valid_fifo_out7[0:pe_set-1], valid_fifo_out8[0:pe_set-1], valid_fifo_out9[0:pe_set-1], 
         valid_fifo_out10[0:pe_set-1], valid_fifo_out11[0:pe_set-1], valid_fifo_out12[0:pe_set-1], valid_fifo_out13[0:pe_set-1];
    wire [127:0] ofm_port0[0:7], ofm_port1[0:7], ofm_port2[0:7], ofm_port3[0:7], ofm_port4[0:7], ofm_port5[0:7],
                              ofm_port6[0:7], ofm_port7[0:7], ofm_port8[0:7], ofm_port9[0:7], ofm_port10[0:7], ofm_port11[0:7],
                              ofm_port12[0:7], ofm_port13[0:7];
    wire                      ofm_port_v0[0:7], ofm_port_v1[0:7], ofm_port_v2[0:7], ofm_port_v3[0:7], ofm_port_v4[0:7], ofm_port_v5[0:7],
                              ofm_port_v6[0:7], ofm_port_v7[0:7], ofm_port_v8[0:7], ofm_port_v9[0:7], ofm_port_v10[0:7], ofm_port_v11[0:7],
                              ofm_port_v12[0:7], ofm_port_v13[0:7];
    wire p_write_zero[0:7]; 
    wire p_init[0:7];
    wire odd_cnt[0:7];
    wire end_op_w[0:7];
    assign end_op = end_op_w[0];

    always @(*) begin
		out_ofm0_port0 <= {ofm_port0[3],ofm_port0[2],ofm_port0[1],ofm_port0[0]};
        out_ofm1_port0 <= {ofm_port0[7],ofm_port0[6],ofm_port0[5],ofm_port0[4]};
        out_ofm0_port1 <= {ofm_port1[3],ofm_port1[2],ofm_port1[1],ofm_port1[0]};
        out_ofm1_port1 <= {ofm_port1[7],ofm_port1[6],ofm_port1[5],ofm_port1[4]};
        out_ofm0_port2 <= {ofm_port2[3],ofm_port2[2],ofm_port2[1],ofm_port2[0]};
        out_ofm1_port2 <= {ofm_port2[7],ofm_port2[6],ofm_port2[5],ofm_port2[4]};
        out_ofm0_port3 <= {ofm_port3[3],ofm_port3[2],ofm_port3[1],ofm_port3[0]};
        out_ofm1_port3 <= {ofm_port3[7],ofm_port3[6],ofm_port3[5],ofm_port3[4]};
        out_ofm0_port4 <= {ofm_port4[3],ofm_port4[2],ofm_port4[1],ofm_port4[0]};
        out_ofm1_port4 <= {ofm_port4[7],ofm_port4[6],ofm_port4[5],ofm_port4[4]};
        out_ofm0_port5 <= {ofm_port5[3],ofm_port5[2],ofm_port5[1],ofm_port5[0]};
        out_ofm1_port5 <= {ofm_port5[7],ofm_port5[6],ofm_port5[5],ofm_port5[4]};
        out_ofm0_port6 <= {ofm_port6[3],ofm_port6[2],ofm_port6[1],ofm_port6[0]};
        out_ofm1_port6 <= {ofm_port6[7],ofm_port6[6],ofm_port6[5],ofm_port6[4]};
        out_ofm0_port7 <= {ofm_port7[3],ofm_port7[2],ofm_port7[1],ofm_port7[0]};
        out_ofm1_port7 <= {ofm_port7[7],ofm_port7[6],ofm_port7[5],ofm_port7[4]};
        out_ofm0_port8 <= {ofm_port8[3],ofm_port8[2],ofm_port8[1],ofm_port8[0]};
        out_ofm1_port8 <= {ofm_port8[7],ofm_port8[6],ofm_port8[5],ofm_port8[4]};
        out_ofm0_port9 <= {ofm_port9[3],ofm_port9[2],ofm_port9[1],ofm_port9[0]};
        out_ofm1_port9 <= {ofm_port9[7],ofm_port9[6],ofm_port9[5],ofm_port9[4]};
        out_ofm0_port10 <= {ofm_port10[3],ofm_port10[2],ofm_port10[1],ofm_port10[0]};
        out_ofm1_port10 <= {ofm_port10[7],ofm_port10[6],ofm_port10[5],ofm_port10[4]};
        out_ofm0_port11 <= {ofm_port11[3],ofm_port11[2],ofm_port11[1],ofm_port11[0]};
        out_ofm1_port11 <= {ofm_port11[7],ofm_port11[6],ofm_port11[5],ofm_port11[4]};
        out_ofm0_port12 <= {ofm_port12[3],ofm_port12[2],ofm_port12[1],ofm_port12[0]};
        out_ofm1_port12 <= {ofm_port12[7],ofm_port12[6],ofm_port12[5],ofm_port12[4]};
        out_ofm0_port13 <= {ofm_port13[3],ofm_port13[2],ofm_port13[1],ofm_port13[0]};
        out_ofm1_port13 <= {ofm_port13[7],ofm_port13[6],ofm_port13[5],ofm_port13[4]};

        out_ofm_port_v0 <= {ofm_port_v0[7]&&ofm_port_v0[6]&&ofm_port_v0[5]&&ofm_port_v0[4]&&ofm_port_v0[3]&&ofm_port_v0[2]&&ofm_port_v0[1]&&ofm_port_v0[0]};
        out_ofm_port_v1 <= {ofm_port_v1[7]&&ofm_port_v1[6]&&ofm_port_v1[5]&&ofm_port_v1[4]&&ofm_port_v1[3]&&ofm_port_v1[2]&&ofm_port_v1[1]&&ofm_port_v1[0]};
        out_ofm_port_v2 <= {ofm_port_v2[7]&&ofm_port_v2[6]&&ofm_port_v2[5]&&ofm_port_v2[4]&&ofm_port_v2[3]&&ofm_port_v2[2]&&ofm_port_v2[1]&&ofm_port_v2[0]};
        out_ofm_port_v3 <= {ofm_port_v3[7]&&ofm_port_v3[6]&&ofm_port_v3[5]&&ofm_port_v3[4]&&ofm_port_v3[3]&&ofm_port_v3[2]&&ofm_port_v3[1]&&ofm_port_v3[0]};
        out_ofm_port_v4 <= {ofm_port_v4[7]&&ofm_port_v4[6]&&ofm_port_v4[5]&&ofm_port_v4[4]&&ofm_port_v4[3]&&ofm_port_v4[2]&&ofm_port_v4[1]&&ofm_port_v4[0]};
        out_ofm_port_v5 <= {ofm_port_v5[7]&&ofm_port_v5[6]&&ofm_port_v5[5]&&ofm_port_v5[4]&&ofm_port_v5[3]&&ofm_port_v5[2]&&ofm_port_v5[1]&&ofm_port_v5[0]};
        out_ofm_port_v6 <= {ofm_port_v6[7]&&ofm_port_v6[6]&&ofm_port_v6[5]&&ofm_port_v6[4]&&ofm_port_v6[3]&&ofm_port_v6[2]&&ofm_port_v6[1]&&ofm_port_v6[0]};
        out_ofm_port_v7 <= {ofm_port_v7[7]&&ofm_port_v7[6]&&ofm_port_v7[5]&&ofm_port_v7[4]&&ofm_port_v7[3]&&ofm_port_v7[2]&&ofm_port_v7[1]&&ofm_port_v7[0]};
        out_ofm_port_v8 <= {ofm_port_v8[7]&&ofm_port_v8[6]&&ofm_port_v8[5]&&ofm_port_v8[4]&&ofm_port_v8[3]&&ofm_port_v8[2]&&ofm_port_v8[1]&&ofm_port_v8[0]};
        out_ofm_port_v9 <= {ofm_port_v9[7]&&ofm_port_v9[6]&&ofm_port_v9[5]&&ofm_port_v9[4]&&ofm_port_v9[3]&&ofm_port_v9[2]&&ofm_port_v9[1]&&ofm_port_v9[0]};
        out_ofm_port_v10 <= {ofm_port_v10[7]&&ofm_port_v10[6]&&ofm_port_v10[5]&&ofm_port_v10[4]&&ofm_port_v10[3]&&ofm_port_v10[2]&&ofm_port_v10[1]&&ofm_port_v10[0]};
        out_ofm_port_v11 <= {ofm_port_v11[7]&&ofm_port_v11[6]&&ofm_port_v11[5]&&ofm_port_v11[4]&&ofm_port_v11[3]&&ofm_port_v11[2]&&ofm_port_v11[1]&&ofm_port_v11[0]};
        out_ofm_port_v12 <= {ofm_port_v12[7]&&ofm_port_v12[6]&&ofm_port_v12[5]&&ofm_port_v12[4]&&ofm_port_v12[3]&&ofm_port_v12[2]&&ofm_port_v12[1]&&ofm_port_v12[0]};
        out_ofm_port_v13 <= {ofm_port_v13[7]&&ofm_port_v13[6]&&ofm_port_v13[5]&&ofm_port_v13[4]&&ofm_port_v13[3]&&ofm_port_v13[2]&&ofm_port_v13[1]&&ofm_port_v13[0]};
	end

    genvar l;
    generate
        for (l=0 ; l<8 ; l++) begin: write_back_gen

        /// Write back controller
            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control0 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out0[4*l+0]),
                .row0_valid(valid_fifo_out0[4*l+0]),
                .row1(fifo_out0[4*l+1]),
                .row1_valid(valid_fifo_out0[4*l+1]),
                .row2(fifo_out0[4*l+2]),
                .row2_valid(valid_fifo_out0[4*l+2]),
                .row3(fifo_out0[4*l+3]),
                .row3_valid(valid_fifo_out0[4*l+3]),
                .row4(fifo_out0[4*l+32]),
                .row4_valid(valid_fifo_out0[4*l+32]),
                .row5(fifo_out0[4*l+33]),
                .row5_valid(valid_fifo_out0[4*l+33]),
                .row6(fifo_out0[4*l+34]),
                .row6_valid(valid_fifo_out0[4*l+34]),
                .row7(fifo_out0[4*l+35]),
                .row7_valid(valid_fifo_out0[4*l+35]),
                .row8(fifo_out0[4*l+64]),
                .row8_valid(valid_fifo_out0[4*l+64]),
                .row9(fifo_out0[4*l+65]),
                .row9_valid(valid_fifo_out0[4*l+65]),
                .row10(fifo_out0[4*l+66]),
                .row10_valid(valid_fifo_out0[4*l+66]),
                .row11(fifo_out0[4*l+67]),
                .row11_valid(valid_fifo_out0[4*l+67]),
                .row12(fifo_out0[4*l+96]),
                .row12_valid(valid_fifo_out0[4*l+96]),
                .row13(fifo_out0[4*l+97]),
                .row13_valid(valid_fifo_out0[4*l+97]),
                .row14(fifo_out0[4*l+98]),
                .row14_valid(valid_fifo_out0[4*l+98]),
                .row15(fifo_out0[4*l+99]),
                .row15_valid(valid_fifo_out0[4*l+99]),
                .p_write_zero(p_write_zero[l]),
                .p_init(p_init[l]),
                .out_port(ofm_port0[l]),
                .port_valid(ofm_port_v0[l]),
                .start_conv(start_again[l]),
                .odd_cnt(odd_cnt[l]),

                .end_conv(end_conv),
                .end_op(end_op_w[l])
            );

                WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control1 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out1[4*l+0]),
                .row0_valid(valid_fifo_out1[4*l+0]),
                .row1(fifo_out1[4*l+1]),
                .row1_valid(valid_fifo_out1[4*l+1]),
                .row2(fifo_out1[4*l+2]),
                .row2_valid(valid_fifo_out1[4*l+2]),
                .row3(fifo_out1[4*l+3]),
                .row3_valid(valid_fifo_out1[4*l+3]),
                .row4(fifo_out1[4*l+32]),
                .row4_valid(valid_fifo_out1[4*l+32]),
                .row5(fifo_out1[4*l+33]),
                .row5_valid(valid_fifo_out1[4*l+33]),
                .row6(fifo_out1[4*l+34]),
                .row6_valid(valid_fifo_out1[4*l+34]),
                .row7(fifo_out1[4*l+35]),
                .row7_valid(valid_fifo_out1[4*l+35]),
                .row8(fifo_out1[4*l+64]),
                .row8_valid(valid_fifo_out1[4*l+64]),
                .row9(fifo_out1[4*l+65]),
                .row9_valid(valid_fifo_out1[4*l+65]),
                .row10(fifo_out1[4*l+66]),
                .row10_valid(valid_fifo_out1[4*l+66]),
                .row11(fifo_out1[4*l+67]),
                .row11_valid(valid_fifo_out1[4*l+67]),
                .row12(fifo_out1[4*l+96]),
                .row12_valid(valid_fifo_out1[4*l+96]),
                .row13(fifo_out1[4*l+97]),
                .row13_valid(valid_fifo_out1[4*l+97]),
                .row14(fifo_out1[4*l+98]),
                .row14_valid(valid_fifo_out1[4*l+98]),
                .row15(fifo_out1[4*l+99]),
                .row15_valid(valid_fifo_out1[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port1[l]),
                .port_valid(ofm_port_v1[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );

            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control2 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out2[4*l+0]),
                .row0_valid(valid_fifo_out2[4*l+0]),
                .row1(fifo_out2[4*l+1]),
                .row1_valid(valid_fifo_out2[4*l+1]),
                .row2(fifo_out2[4*l+2]),
                .row2_valid(valid_fifo_out2[4*l+2]),
                .row3(fifo_out2[4*l+3]),
                .row3_valid(valid_fifo_out2[4*l+3]),
                .row4(fifo_out2[4*l+32]),
                .row4_valid(valid_fifo_out2[4*l+32]),
                .row5(fifo_out2[4*l+33]),
                .row5_valid(valid_fifo_out2[4*l+33]),
                .row6(fifo_out2[4*l+34]),
                .row6_valid(valid_fifo_out2[4*l+34]),
                .row7(fifo_out2[4*l+35]),
                .row7_valid(valid_fifo_out2[4*l+35]),
                .row8(fifo_out2[4*l+64]),
                .row8_valid(valid_fifo_out2[4*l+64]),
                .row9(fifo_out2[4*l+65]),
                .row9_valid(valid_fifo_out2[4*l+65]),
                .row10(fifo_out2[4*l+66]),
                .row10_valid(valid_fifo_out2[4*l+66]),
                .row11(fifo_out2[4*l+67]),
                .row11_valid(valid_fifo_out2[4*l+67]),
                .row12(fifo_out2[4*l+96]),
                .row12_valid(valid_fifo_out2[4*l+96]),
                .row13(fifo_out2[4*l+97]),
                .row13_valid(valid_fifo_out2[4*l+97]),
                .row14(fifo_out2[4*l+98]),
                .row14_valid(valid_fifo_out2[4*l+98]),
                .row15(fifo_out2[4*l+99]),
                .row15_valid(valid_fifo_out2[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port2[l]),
                .port_valid(ofm_port_v2[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );


            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control3 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out3[4*l+0]),
                .row0_valid(valid_fifo_out3[4*l+0]),
                .row1(fifo_out3[4*l+1]),
                .row1_valid(valid_fifo_out3[4*l+1]),
                .row2(fifo_out3[4*l+2]),
                .row2_valid(valid_fifo_out3[4*l+2]),
                .row3(fifo_out3[4*l+3]),
                .row3_valid(valid_fifo_out3[4*l+3]),
                .row4(fifo_out3[4*l+32]),
                .row4_valid(valid_fifo_out3[4*l+32]),
                .row5(fifo_out3[4*l+33]),
                .row5_valid(valid_fifo_out3[4*l+33]),
                .row6(fifo_out3[4*l+34]),
                .row6_valid(valid_fifo_out3[4*l+34]),
                .row7(fifo_out3[4*l+35]),
                .row7_valid(valid_fifo_out3[4*l+35]),
                .row8(fifo_out3[4*l+64]),
                .row8_valid(valid_fifo_out3[4*l+64]),
                .row9(fifo_out3[4*l+65]),
                .row9_valid(valid_fifo_out3[4*l+65]),
                .row10(fifo_out3[4*l+66]),
                .row10_valid(valid_fifo_out3[4*l+66]),
                .row11(fifo_out3[4*l+67]),
                .row11_valid(valid_fifo_out3[4*l+67]),
                .row12(fifo_out3[4*l+96]),
                .row12_valid(valid_fifo_out3[4*l+96]),
                .row13(fifo_out3[4*l+97]),
                .row13_valid(valid_fifo_out3[4*l+97]),
                .row14(fifo_out3[4*l+98]),
                .row14_valid(valid_fifo_out3[4*l+98]),
                .row15(fifo_out3[4*l+99]),
                .row15_valid(valid_fifo_out3[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port3[l]),
                .port_valid(ofm_port_v3[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );

            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control4 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out4[4*l+0]),
                .row0_valid(valid_fifo_out4[4*l+0]),
                .row1(fifo_out4[4*l+1]),
                .row1_valid(valid_fifo_out4[4*l+1]),
                .row2(fifo_out4[4*l+2]),
                .row2_valid(valid_fifo_out4[4*l+2]),
                .row3(fifo_out4[4*l+3]),
                .row3_valid(valid_fifo_out4[4*l+3]),
                .row4(fifo_out4[4*l+32]),
                .row4_valid(valid_fifo_out4[4*l+32]),
                .row5(fifo_out4[4*l+33]),
                .row5_valid(valid_fifo_out4[4*l+33]),
                .row6(fifo_out4[4*l+34]),
                .row6_valid(valid_fifo_out4[4*l+34]),
                .row7(fifo_out4[4*l+35]),
                .row7_valid(valid_fifo_out4[4*l+35]),
                .row8(fifo_out4[4*l+64]),
                .row8_valid(valid_fifo_out4[4*l+64]),
                .row9(fifo_out4[4*l+65]),
                .row9_valid(valid_fifo_out4[4*l+65]),
                .row10(fifo_out4[4*l+66]),
                .row10_valid(valid_fifo_out4[4*l+66]),
                .row11(fifo_out4[4*l+67]),
                .row11_valid(valid_fifo_out4[4*l+67]),
                .row12(fifo_out4[4*l+96]),
                .row12_valid(valid_fifo_out4[4*l+96]),
                .row13(fifo_out4[4*l+97]),
                .row13_valid(valid_fifo_out4[4*l+97]),
                .row14(fifo_out4[4*l+98]),
                .row14_valid(valid_fifo_out4[4*l+98]),
                .row15(fifo_out4[4*l+99]),
                .row15_valid(valid_fifo_out4[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port4[l]),
                .port_valid(ofm_port_v4[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );

                WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control5 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out5[4*l+0]),
                .row0_valid(valid_fifo_out5[4*l+0]),
                .row1(fifo_out5[4*l+1]),
                .row1_valid(valid_fifo_out5[4*l+1]),
                .row2(fifo_out5[4*l+2]),
                .row2_valid(valid_fifo_out5[4*l+2]),
                .row3(fifo_out5[4*l+3]),
                .row3_valid(valid_fifo_out5[4*l+3]),
                .row4(fifo_out5[4*l+32]),
                .row4_valid(valid_fifo_out5[4*l+32]),
                .row5(fifo_out5[4*l+33]),
                .row5_valid(valid_fifo_out5[4*l+33]),
                .row6(fifo_out5[4*l+34]),
                .row6_valid(valid_fifo_out5[4*l+34]),
                .row7(fifo_out5[4*l+35]),
                .row7_valid(valid_fifo_out5[4*l+35]),
                .row8(fifo_out5[4*l+64]),
                .row8_valid(valid_fifo_out5[4*l+64]),
                .row9(fifo_out5[4*l+65]),
                .row9_valid(valid_fifo_out5[4*l+65]),
                .row10(fifo_out5[4*l+66]),
                .row10_valid(valid_fifo_out5[4*l+66]),
                .row11(fifo_out5[4*l+67]),
                .row11_valid(valid_fifo_out5[4*l+67]),
                .row12(fifo_out5[4*l+96]),
                .row12_valid(valid_fifo_out5[4*l+96]),
                .row13(fifo_out5[4*l+97]),
                .row13_valid(valid_fifo_out5[4*l+97]),
                .row14(fifo_out5[4*l+98]),
                .row14_valid(valid_fifo_out5[4*l+98]),
                .row15(fifo_out5[4*l+99]),
                .row15_valid(valid_fifo_out5[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port5[l]),
                .port_valid(ofm_port_v5[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );

            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control6 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out6[4*l+0]),
                .row0_valid(valid_fifo_out6[4*l+0]),
                .row1(fifo_out6[4*l+1]),
                .row1_valid(valid_fifo_out6[4*l+1]),
                .row2(fifo_out6[4*l+2]),
                .row2_valid(valid_fifo_out6[4*l+2]),
                .row3(fifo_out6[4*l+3]),
                .row3_valid(valid_fifo_out6[4*l+3]),
                .row4(fifo_out6[4*l+32]),
                .row4_valid(valid_fifo_out6[4*l+32]),
                .row5(fifo_out6[4*l+33]),
                .row5_valid(valid_fifo_out6[4*l+33]),
                .row6(fifo_out6[4*l+34]),
                .row6_valid(valid_fifo_out6[4*l+34]),
                .row7(fifo_out6[4*l+35]),
                .row7_valid(valid_fifo_out6[4*l+35]),
                .row8(fifo_out6[4*l+64]),
                .row8_valid(valid_fifo_out6[4*l+64]),
                .row9(fifo_out6[4*l+65]),
                .row9_valid(valid_fifo_out6[4*l+65]),
                .row10(fifo_out6[4*l+66]),
                .row10_valid(valid_fifo_out6[4*l+66]),
                .row11(fifo_out6[4*l+67]),
                .row11_valid(valid_fifo_out6[4*l+67]),
                .row12(fifo_out6[4*l+96]),
                .row12_valid(valid_fifo_out6[4*l+96]),
                .row13(fifo_out6[4*l+97]),
                .row13_valid(valid_fifo_out6[4*l+97]),
                .row14(fifo_out6[4*l+98]),
                .row14_valid(valid_fifo_out6[4*l+98]),
                .row15(fifo_out6[4*l+99]),
                .row15_valid(valid_fifo_out6[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port6[l]),
                .port_valid(ofm_port_v6[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );

            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control7 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out7[4*l+0]),
                .row0_valid(valid_fifo_out7[4*l+0]),
                .row1(fifo_out7[4*l+1]),
                .row1_valid(valid_fifo_out7[4*l+1]),
                .row2(fifo_out7[4*l+2]),
                .row2_valid(valid_fifo_out7[4*l+2]),
                .row3(fifo_out7[4*l+3]),
                .row3_valid(valid_fifo_out7[4*l+3]),
                .row4(fifo_out7[4*l+32]),
                .row4_valid(valid_fifo_out7[4*l+32]),
                .row5(fifo_out7[4*l+33]),
                .row5_valid(valid_fifo_out7[4*l+33]),
                .row6(fifo_out7[4*l+34]),
                .row6_valid(valid_fifo_out7[4*l+34]),
                .row7(fifo_out7[4*l+35]),
                .row7_valid(valid_fifo_out7[4*l+35]),
                .row8(fifo_out7[4*l+64]),
                .row8_valid(valid_fifo_out7[4*l+64]),
                .row9(fifo_out7[4*l+65]),
                .row9_valid(valid_fifo_out7[4*l+65]),
                .row10(fifo_out7[4*l+66]),
                .row10_valid(valid_fifo_out7[4*l+66]),
                .row11(fifo_out7[4*l+67]),
                .row11_valid(valid_fifo_out7[4*l+67]),
                .row12(fifo_out7[4*l+96]),
                .row12_valid(valid_fifo_out7[4*l+96]),
                .row13(fifo_out7[4*l+97]),
                .row13_valid(valid_fifo_out7[4*l+97]),
                .row14(fifo_out7[4*l+98]),
                .row14_valid(valid_fifo_out7[4*l+98]),
                .row15(fifo_out7[4*l+99]),
                .row15_valid(valid_fifo_out7[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port7[l]),
                .port_valid(ofm_port_v7[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );

            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control8 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out8[4*l+0]),
                .row0_valid(valid_fifo_out8[4*l+0]),
                .row1(fifo_out8[4*l+1]),
                .row1_valid(valid_fifo_out8[4*l+1]),
                .row2(fifo_out8[4*l+2]),
                .row2_valid(valid_fifo_out8[4*l+2]),
                .row3(fifo_out8[4*l+3]),
                .row3_valid(valid_fifo_out8[4*l+3]),
                .row4(fifo_out8[4*l+32]),
                .row4_valid(valid_fifo_out8[4*l+32]),
                .row5(fifo_out8[4*l+33]),
                .row5_valid(valid_fifo_out8[4*l+33]),
                .row6(fifo_out8[4*l+34]),
                .row6_valid(valid_fifo_out8[4*l+34]),
                .row7(fifo_out8[4*l+35]),
                .row7_valid(valid_fifo_out8[4*l+35]),
                .row8(fifo_out8[4*l+64]),
                .row8_valid(valid_fifo_out8[4*l+64]),
                .row9(fifo_out8[4*l+65]),
                .row9_valid(valid_fifo_out8[4*l+65]),
                .row10(fifo_out8[4*l+66]),
                .row10_valid(valid_fifo_out8[4*l+66]),
                .row11(fifo_out8[4*l+67]),
                .row11_valid(valid_fifo_out8[4*l+67]),
                .row12(fifo_out8[4*l+96]),
                .row12_valid(valid_fifo_out8[4*l+96]),
                .row13(fifo_out8[4*l+97]),
                .row13_valid(valid_fifo_out8[4*l+97]),
                .row14(fifo_out8[4*l+98]),
                .row14_valid(valid_fifo_out8[4*l+98]),
                .row15(fifo_out8[4*l+99]),
                .row15_valid(valid_fifo_out8[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port8[l]),
                .port_valid(ofm_port_v8[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );

            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control9 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out9[4*l+0]),
                .row0_valid(valid_fifo_out9[4*l+0]),
                .row1(fifo_out9[4*l+1]),
                .row1_valid(valid_fifo_out9[4*l+1]),
                .row2(fifo_out9[4*l+2]),
                .row2_valid(valid_fifo_out9[4*l+2]),
                .row3(fifo_out9[4*l+3]),
                .row3_valid(valid_fifo_out9[4*l+3]),
                .row4(fifo_out9[4*l+32]),
                .row4_valid(valid_fifo_out9[4*l+32]),
                .row5(fifo_out9[4*l+33]),
                .row5_valid(valid_fifo_out9[4*l+33]),
                .row6(fifo_out9[4*l+34]),
                .row6_valid(valid_fifo_out9[4*l+34]),
                .row7(fifo_out9[4*l+35]),
                .row7_valid(valid_fifo_out9[4*l+35]),
                .row8(fifo_out9[4*l+64]),
                .row8_valid(valid_fifo_out9[4*l+64]),
                .row9(fifo_out9[4*l+65]),
                .row9_valid(valid_fifo_out9[4*l+65]),
                .row10(fifo_out9[4*l+66]),
                .row10_valid(valid_fifo_out9[4*l+66]),
                .row11(fifo_out9[4*l+67]),
                .row11_valid(valid_fifo_out9[4*l+67]),
                .row12(fifo_out9[4*l+96]),
                .row12_valid(valid_fifo_out9[4*l+96]),
                .row13(fifo_out9[4*l+97]),
                .row13_valid(valid_fifo_out9[4*l+97]),
                .row14(fifo_out9[4*l+98]),
                .row14_valid(valid_fifo_out9[4*l+98]),
                .row15(fifo_out9[4*l+99]),
                .row15_valid(valid_fifo_out9[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port9[l]),
                .port_valid(ofm_port_v9[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );

            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control10 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out10[4*l+0]),
                .row0_valid(valid_fifo_out10[4*l+0]),
                .row1(fifo_out10[4*l+1]),
                .row1_valid(valid_fifo_out10[4*l+1]),
                .row2(fifo_out10[4*l+2]),
                .row2_valid(valid_fifo_out10[4*l+2]),
                .row3(fifo_out10[4*l+3]),
                .row3_valid(valid_fifo_out10[4*l+3]),
                .row4(fifo_out10[4*l+32]),
                .row4_valid(valid_fifo_out10[4*l+32]),
                .row5(fifo_out10[4*l+33]),
                .row5_valid(valid_fifo_out10[4*l+33]),
                .row6(fifo_out10[4*l+34]),
                .row6_valid(valid_fifo_out10[4*l+34]),
                .row7(fifo_out10[4*l+35]),
                .row7_valid(valid_fifo_out10[4*l+35]),
                .row8(fifo_out10[4*l+64]),
                .row8_valid(valid_fifo_out10[4*l+64]),
                .row9(fifo_out10[4*l+65]),
                .row9_valid(valid_fifo_out10[4*l+65]),
                .row10(fifo_out10[4*l+66]),
                .row10_valid(valid_fifo_out10[4*l+66]),
                .row11(fifo_out10[4*l+67]),
                .row11_valid(valid_fifo_out10[4*l+67]),
                .row12(fifo_out10[4*l+96]),
                .row12_valid(valid_fifo_out10[4*l+96]),
                .row13(fifo_out10[4*l+97]),
                .row13_valid(valid_fifo_out10[4*l+97]),
                .row14(fifo_out10[4*l+98]),
                .row14_valid(valid_fifo_out10[4*l+98]),
                .row15(fifo_out10[4*l+99]),
                .row15_valid(valid_fifo_out10[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port10[l]),
                .port_valid(ofm_port_v10[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );

            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control11 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out11[4*l+0]),
                .row0_valid(valid_fifo_out11[4*l+0]),
                .row1(fifo_out11[4*l+1]),
                .row1_valid(valid_fifo_out11[4*l+1]),
                .row2(fifo_out11[4*l+2]),
                .row2_valid(valid_fifo_out11[4*l+2]),
                .row3(fifo_out11[4*l+3]),
                .row3_valid(valid_fifo_out11[4*l+3]),
                .row4(fifo_out11[4*l+32]),
                .row4_valid(valid_fifo_out11[4*l+32]),
                .row5(fifo_out11[4*l+33]),
                .row5_valid(valid_fifo_out11[4*l+33]),
                .row6(fifo_out11[4*l+34]),
                .row6_valid(valid_fifo_out11[4*l+34]),
                .row7(fifo_out11[4*l+35]),
                .row7_valid(valid_fifo_out11[4*l+35]),
                .row8(fifo_out11[4*l+64]),
                .row8_valid(valid_fifo_out11[4*l+64]),
                .row9(fifo_out11[4*l+65]),
                .row9_valid(valid_fifo_out11[4*l+65]),
                .row10(fifo_out11[4*l+66]),
                .row10_valid(valid_fifo_out11[4*l+66]),
                .row11(fifo_out11[4*l+67]),
                .row11_valid(valid_fifo_out11[4*l+67]),
                .row12(fifo_out11[4*l+96]),
                .row12_valid(valid_fifo_out11[4*l+96]),
                .row13(fifo_out11[4*l+97]),
                .row13_valid(valid_fifo_out11[4*l+97]),
                .row14(fifo_out11[4*l+98]),
                .row14_valid(valid_fifo_out11[4*l+98]),
                .row15(fifo_out11[4*l+99]),
                .row15_valid(valid_fifo_out11[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port11[l]),
                .port_valid(ofm_port_v11[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );

            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control12 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out12[4*l+0]),
                .row0_valid(valid_fifo_out12[4*l+0]),
                .row1(fifo_out12[4*l+1]),
                .row1_valid(valid_fifo_out12[4*l+1]),
                .row2(fifo_out12[4*l+2]),
                .row2_valid(valid_fifo_out12[4*l+2]),
                .row3(fifo_out12[4*l+3]),
                .row3_valid(valid_fifo_out12[4*l+3]),
                .row4(fifo_out12[4*l+32]),
                .row4_valid(valid_fifo_out12[4*l+32]),
                .row5(fifo_out12[4*l+33]),
                .row5_valid(valid_fifo_out12[4*l+33]),
                .row6(fifo_out12[4*l+34]),
                .row6_valid(valid_fifo_out12[4*l+34]),
                .row7(fifo_out12[4*l+35]),
                .row7_valid(valid_fifo_out12[4*l+35]),
                .row8(fifo_out12[4*l+64]),
                .row8_valid(valid_fifo_out12[4*l+64]),
                .row9(fifo_out12[4*l+65]),
                .row9_valid(valid_fifo_out12[4*l+65]),
                .row10(fifo_out12[4*l+66]),
                .row10_valid(valid_fifo_out12[4*l+66]),
                .row11(fifo_out12[4*l+67]),
                .row11_valid(valid_fifo_out12[4*l+67]),
                .row12(fifo_out12[4*l+96]),
                .row12_valid(valid_fifo_out12[4*l+96]),
                .row13(fifo_out12[4*l+97]),
                .row13_valid(valid_fifo_out12[4*l+97]),
                .row14(fifo_out12[4*l+98]),
                .row14_valid(valid_fifo_out12[4*l+98]),
                .row15(fifo_out12[4*l+99]),
                .row15_valid(valid_fifo_out12[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port12[l]),
                .port_valid(ofm_port_v12[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );

            WRITE_BACK #(
                .data_width(out_data_width),
                .depth(buf_depth)
            ) writeback_control13 (
                .clk(clk),
                .rst_n(rst_n),
                .start_init(start_conv),
                .p_filter_end(p_filter_end),
                .row0(fifo_out13[4*l+0]),
                .row0_valid(valid_fifo_out13[4*l+0]),
                .row1(fifo_out13[4*l+1]),
                .row1_valid(valid_fifo_out13[4*l+1]),
                .row2(fifo_out13[4*l+2]),
                .row2_valid(valid_fifo_out13[4*l+2]),
                .row3(fifo_out13[4*l+3]),
                .row3_valid(valid_fifo_out13[4*l+3]),
                .row4(fifo_out13[4*l+32]),
                .row4_valid(valid_fifo_out13[4*l+32]),
                .row5(fifo_out13[4*l+33]),
                .row5_valid(valid_fifo_out13[4*l+33]),
                .row6(fifo_out13[4*l+34]),
                .row6_valid(valid_fifo_out13[4*l+34]),
                .row7(fifo_out13[4*l+35]),
                .row7_valid(valid_fifo_out13[4*l+35]),
                .row8(fifo_out13[4*l+64]),
                .row8_valid(valid_fifo_out13[4*l+64]),
                .row9(fifo_out13[4*l+65]),
                .row9_valid(valid_fifo_out13[4*l+65]),
                .row10(fifo_out13[4*l+66]),
                .row10_valid(valid_fifo_out13[4*l+66]),
                .row11(fifo_out13[4*l+67]),
                .row11_valid(valid_fifo_out13[4*l+67]),
                .row12(fifo_out13[4*l+96]),
                .row12_valid(valid_fifo_out13[4*l+96]),
                .row13(fifo_out13[4*l+97]),
                .row13_valid(valid_fifo_out13[4*l+97]),
                .row14(fifo_out13[4*l+98]),
                .row14_valid(valid_fifo_out13[4*l+98]),
                .row15(fifo_out13[4*l+99]),
                .row15_valid(valid_fifo_out13[4*l+99]),
                .p_write_zero(),
                .p_init(),
                .out_port(ofm_port13[l]),
                .port_valid(ofm_port_v13[l]),
                .start_conv(),
                .odd_cnt(),

                .end_conv(end_conv),
                .end_op()
            );
        end
    endgenerate
    
    /// Buffer
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	// pe array                                                                                             //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
	

    genvar k;
    generate
        for (k=0 ; k<pe_set ; k++) begin: psum_gen

            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff0 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe00_data[k]),
                .pe1_data(pe10_data[k]),
                .pe2_data(pe20_data[k]),
                .fifo_out(fifo_out0[k]),
                .valid_fifo_out(valid_fifo_out0[k])
            );

            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff1 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe01_data[k]),
                .pe1_data(pe11_data[k]),
                .pe2_data(pe21_data[k]),
                .fifo_out(fifo_out1[k]),
                .valid_fifo_out(valid_fifo_out1[k])
            );

            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff2 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe02_data[k]),
                .pe1_data(pe12_data[k]),
                .pe2_data(pe22_data[k]),
                .fifo_out(fifo_out2[k]),
                .valid_fifo_out(valid_fifo_out2[k])
            );

            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff3 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe03_data[k]),
                .pe1_data(pe13_data[k]),
                .pe2_data(pe23_data[k]),
                .fifo_out(fifo_out3[k]),
                .valid_fifo_out(valid_fifo_out3[k])
            );

            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff4 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe04_data[k]),
                .pe1_data(pe14_data[k]),
                .pe2_data(pe24_data[k]),
                .fifo_out(fifo_out4[k]),
                .valid_fifo_out(valid_fifo_out4[k])
            );
            
            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff5 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe05_data[k]),
                .pe1_data(pe15_data[k]),
                .pe2_data(pe25_data[k]),
                .fifo_out(fifo_out5[k]),
                .valid_fifo_out(valid_fifo_out5[k])
            );

            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff6 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe06_data[k]),
                .pe1_data(pe16_data[k]),
                .pe2_data(pe26_data[k]),
                .fifo_out(fifo_out6[k]),
                .valid_fifo_out(valid_fifo_out6[k])
            );
            
            
            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff7 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe07_data[k]),
                .pe1_data(pe17_data[k]),
                .pe2_data(pe27_data[k]),
                .fifo_out(fifo_out7[k]),
                .valid_fifo_out(valid_fifo_out7[k])
            );

            
            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff8 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe08_data[k]),
                .pe1_data(pe18_data[k]),
                .pe2_data(pe28_data[k]),
                .fifo_out(fifo_out8[k]),
                .valid_fifo_out(valid_fifo_out8[k])
            );

            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff9 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe09_data[k]),
                .pe1_data(pe19_data[k]),
                .pe2_data(pe29_data[k]),
                .fifo_out(fifo_out9[k]),
                .valid_fifo_out(valid_fifo_out9[k])
            );

            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff10 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe010_data[k]),
                .pe1_data(pe110_data[k]),
                .pe2_data(pe210_data[k]),
                .fifo_out(fifo_out10[k]),
                .valid_fifo_out(valid_fifo_out10[k])
            );

            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff11 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe011_data[k]),
                .pe1_data(pe111_data[k]),
                .pe2_data(pe211_data[k]),
                .fifo_out(fifo_out11[k]),
                .valid_fifo_out(valid_fifo_out11[k])
            );

            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff12 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe012_data[k]),
                .pe1_data(pe112_data[k]),
                .pe2_data(pe212_data[k]),
                .fifo_out(fifo_out12[k]),
                .valid_fifo_out(valid_fifo_out12[k])
            );
            
            PSUM_BUFF #(
                .data_width(out_data_width),
                .addr_width(buf_addr_width),
                .depth(buf_depth)
            ) psum_buff13 (
                .clk(clk),
                .rst_n(rst_n),
                .p_valid_data(p_valid_data),
                .p_write_zero(p_write_zero[0]),
                .p_init(p_init[0]),
                .odd_cnt(odd_cnt[0]),
                .pe0_data(pe013_data[k]),
                .pe1_data(pe113_data[k]),
                .pe2_data(pe213_data[k]),
                .fifo_out(fifo_out13[k]),
                .valid_fifo_out(valid_fifo_out13[k])
            );
        end
    endgenerate

endmodule //CONV_ACC