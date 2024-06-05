`timescale	1ns / 1ps

module tb_main;

//=================================================================================================
// System
//=================================================================================================
// Reset
	reg     		RSTN;
	initial begin
		RSTN = 1'd0;
		#(50.0);
		RSTN = 1'd1;
	end

// Clock
	reg				CLK_CORE = 1'd0;
	always begin
		#(`CLK_CORE_PERIOD/2.0)	CLK_CORE = ~CLK_CORE;
	end

	localparam		GOLDEN_TEST	= 1'd0;

//=================================================================================================
//  Sub module test
//=================================================================================================

//-------------------------------------------------------------------------------------------------
// jpeg_dec dequant
//-------------------------------------------------------------------------------------------------

	reg		[15:0]	C_BLK_ECS_Y 	= 16'd0;
	reg		[15:0]	C_BLK_ECS_CB 	= 16'd0;
	reg		[15:0]	C_BLK_ECS_CR 	= 16'd0;

	// test model
	wire			jpeg_dec_init;
	wire			jpeg_dec_dqt_up_en;
	wire	[7:0]	jpeg_dec_dqt_up_dat;
	wire	[1:0]	jpeg_dec_dqt_up_id;
	wire			jpeg_dec_deqt_pi_en;
	wire			jpeg_dec_deqt_pi_en_y;
	wire			jpeg_dec_deqt_pi_en_cb;
	wire			jpeg_dec_deqt_pi_en_cr;
	wire			jpeg_dec_deqt_pi_dc;
	wire			jpeg_dec_deqt_pi_dc_y;
	wire			jpeg_dec_deqt_pi_dc_cb;
	wire			jpeg_dec_deqt_pi_dc_cr;
	wire	[11:0]	jpeg_dec_deqt_pi;
	wire	[11:0]	jpeg_dec_deqt_pi_y;
	wire	[11:0]	jpeg_dec_deqt_pi_cb;
	wire	[11:0]	jpeg_dec_deqt_pi_cr;
	wire	[1:0]	jpeg_dec_deqt_pi_id;
	reg		[1:0]	jpeg_dec_deqt_pi_id_d1;
	reg		[1:0]	jpeg_dec_deqt_pi_id_d2;

	// jpeg_dec_dequant
	wire			jpeg_dec_deqt_en_y;
	wire			jpeg_dec_deqt_en_cb;
	wire			jpeg_dec_deqt_en_cr;
	wire	[7:0]	jpeg_dec_deqt_out_y;
	wire	[7:0]	jpeg_dec_deqt_out_cb;
	wire	[7:0]	jpeg_dec_deqt_out_cr;
	wire	[7:0]	jpeg_dec_deqt_out;
	wire	[5:0]	jpeg_dec_deqt_adr_y;
	wire	[5:0]	jpeg_dec_deqt_adr_cb;
	wire	[5:0]	jpeg_dec_deqt_adr_cr;
	wire			jpeg_dec_deqt_po_en;
	wire			jpeg_dec_deqt_po_en_y;
	wire			jpeg_dec_deqt_po_en_cb;
	wire			jpeg_dec_deqt_po_en_cr;
	wire	[11:0]	jpeg_dec_deqt_po;
	wire	[11:0]	jpeg_dec_deqt_po_y;
	wire	[11:0]	jpeg_dec_deqt_po_cb;
	wire	[11:0]	jpeg_dec_deqt_po_cr;

	wire			jpeg_dec_deqt_init;

	always @(posedge CLK_CORE or negedge RSTN) begin
		if(!RSTN) begin
			jpeg_dec_deqt_pi_id_d1 <= 2'd0;
			jpeg_dec_deqt_pi_id_d2 <= 2'd0;
		end else begin
			jpeg_dec_deqt_pi_id_d1 <= jpeg_dec_deqt_pi_id;
			jpeg_dec_deqt_pi_id_d2 <= jpeg_dec_deqt_pi_id_d1;
		end
	end

	assign			jpeg_dec_deqt_out = 	(jpeg_dec_deqt_pi_id_d2==2'd0) ? jpeg_dec_deqt_out_y  :
											(jpeg_dec_deqt_pi_id_d2==2'd1) ? jpeg_dec_deqt_out_cb :
											(jpeg_dec_deqt_pi_id_d2==2'd2) ? jpeg_dec_deqt_out_cr : 8'd0;
	// test model => dequant
	assign			jpeg_dec_deqt_pi_en_y	= (jpeg_dec_deqt_pi_id==2'd0)? jpeg_dec_deqt_pi_en : 1'd0;
	assign			jpeg_dec_deqt_pi_en_cb	= (jpeg_dec_deqt_pi_id==2'd1)? jpeg_dec_deqt_pi_en : 1'd0;
	assign			jpeg_dec_deqt_pi_en_cr	= (jpeg_dec_deqt_pi_id==2'd2)? jpeg_dec_deqt_pi_en : 1'd0;
	assign			jpeg_dec_deqt_pi_y		= (jpeg_dec_deqt_pi_id==2'd0)? jpeg_dec_deqt_pi : 12'd0;
	assign			jpeg_dec_deqt_pi_cb		= (jpeg_dec_deqt_pi_id==2'd1)? jpeg_dec_deqt_pi : 12'd0;
	assign			jpeg_dec_deqt_pi_cr		= (jpeg_dec_deqt_pi_id==2'd2)? jpeg_dec_deqt_pi : 12'd0;
	assign			jpeg_dec_deqt_pi_dc_y	= (jpeg_dec_deqt_pi_id==2'd0)? jpeg_dec_deqt_pi_dc : 1'd0;
	assign			jpeg_dec_deqt_pi_dc_cb	= (jpeg_dec_deqt_pi_id==2'd1)? jpeg_dec_deqt_pi_dc : 1'd0;
	assign			jpeg_dec_deqt_pi_dc_cr	= (jpeg_dec_deqt_pi_id==2'd2)? jpeg_dec_deqt_pi_dc : 1'd0;


	// dequant => test model
	assign			jpeg_dec_deqt_po_en 	= jpeg_dec_deqt_po_en_y | jpeg_dec_deqt_po_en_cb | jpeg_dec_deqt_po_en_cr;
	assign			jpeg_dec_deqt_po 		= 	(jpeg_dec_deqt_po_en_y)  ? jpeg_dec_deqt_po_y  :
												(jpeg_dec_deqt_po_en_cb) ? jpeg_dec_deqt_po_cb :
												(jpeg_dec_deqt_po_en_cr) ? jpeg_dec_deqt_po_cr : 12'd0;

	// modify
	jpeg_dec_quant_test_model #(
`ifdef	TEST_IMG0	.DUT_INPUT_FILE("../golden_data/ivl0_ydc1_cdc1_QP0_1_QP1_3_high_quality/D2_core0_jpdec_dequant_input.txt"),		.DUT_OUTPUT_FILE("../golden_data/ivl0_ydc1_cdc1_QP0_1_QP1_3_high_quality/D2_core0_jpdec_dequant_output.txt")
`elsif	TEST_IMG1	.DUT_INPUT_FILE("../golden_data/ivl0_ydc16_cdc17_QP0_16_QP1_1_low_quality/D2_core0_jpdec_dequant_input.txt"),	.DUT_OUTPUT_FILE("../golden_data/ivl0_ydc16_cdc17_QP0_16_QP1_1_low_quality/D2_core0_jpdec_dequant_output.txt")
`elsif	TEST_IMG2	.DUT_INPUT_FILE("../golden_data/ivl1_ydc1_cdc1_QP0_1_QP1_7_high_quality/D2_core0_jpdec_dequant_input.txt"),		.DUT_OUTPUT_FILE("../golden_data/ivl1_ydc1_cdc1_QP0_1_QP1_7_high_quality/D2_core0_jpdec_dequant_output.txt")
`elsif	TEST_IMG3	.DUT_INPUT_FILE("../golden_data/ivl1_ydc16_cdc17_QP0_16_QP1_1_low_quality/D2_core0_jpdec_dequant_input.txt"),	.DUT_OUTPUT_FILE("../golden_data/ivl1_ydc16_cdc17_QP0_16_QP1_1_low_quality/D2_core0_jpdec_dequant_output.txt")
`elsif	TEST_IMG4	.DUT_INPUT_FILE("../golden_data/ivl4_ydc1_cdc1_QP0_1_QP1_7_high_quality/D2_core0_jpdec_dequant_input.txt"),		.DUT_OUTPUT_FILE("../golden_data/ivl4_ydc1_cdc1_QP0_1_QP1_7_high_quality/D2_core0_jpdec_dequant_output.txt")
`elsif	TEST_IMG5	.DUT_INPUT_FILE("../golden_data/ivl4_ydc16_cdc17_QP0_16_QP1_1_low_quality/D2_core0_jpdec_dequant_input.txt"),	.DUT_OUTPUT_FILE("../golden_data/ivl4_ydc16_cdc17_QP0_16_QP1_1_low_quality/D2_core0_jpdec_dequant_output.txt")
`else				.DUT_INPUT_FILE("../golden_data/ivl0_ydc1_cdc1_QP0_1_QP1_3_high_quality/D2_core0_jpdec_dequant_input.txt"),		.DUT_OUTPUT_FILE("../golden_data/ivl0_ydc1_cdc1_QP0_1_QP1_3_high_quality/D2_core0_jpdec_dequant_output.txt")
`endif
	)
	JPEG_DEC_QUANT_TEST_MODEL(
		.iCLK				(CLK_CORE				),
		.iRSTN				(RSTN					),
		.oINIT				(jpeg_dec_init			),
		.oPO_EN				(jpeg_dec_deqt_pi_en	),
		.oPO				(jpeg_dec_deqt_pi		),
		.oPO_DC				(jpeg_dec_deqt_pi_dc	),
		.oPO_ID				(jpeg_dec_deqt_pi_id	),
		.iPI_EN				(jpeg_dec_deqt_po_en	),
		.iPI				(jpeg_dec_deqt_po		)
	);

	jpeg_dec_dequant	JPEG_DEC_DEQUANT_Y(
		.HCLK				(CLK_CORE				),
		.HRESETn			(RSTN					),
		.INIT				(jpeg_dec_deqt_init		),
		.C_BLK_ECS			(C_BLK_ECS_Y			),
		.DEQT_EN			(jpeg_dec_deqt_en_y		),
		.DEQT_DAT			(jpeg_dec_deqt_out_y	),
		.DEQT_ADR			(jpeg_dec_deqt_adr_y	),
		.PI_EN				(jpeg_dec_deqt_pi_en_y	),
		.PI					(jpeg_dec_deqt_pi_y		),
		.PI_DC				(jpeg_dec_deqt_pi_dc_y	),
		.PO_EN				(jpeg_dec_deqt_po_en_y	),
		.PO					(jpeg_dec_deqt_po_y		)
	);

	jpeg_dec_dequant	JPEG_DEC_DEQUANT_CB(
		.HCLK				(CLK_CORE				),
		.HRESETn			(RSTN					),
		.INIT				(jpeg_dec_deqt_init		),
		.C_BLK_ECS			(C_BLK_ECS_CB			),
		.DEQT_EN			(jpeg_dec_deqt_en_cb	),
		.DEQT_DAT			(jpeg_dec_deqt_out_cb	),
		.DEQT_ADR			(jpeg_dec_deqt_adr_cb	),
		.PI_EN				(jpeg_dec_deqt_pi_en_cb	),
		.PI					(jpeg_dec_deqt_pi_cb	),
		.PI_DC				(jpeg_dec_deqt_pi_dc_cb	),
		.PO_EN				(jpeg_dec_deqt_po_en_cb	),
		.PO					(jpeg_dec_deqt_po_cb	)
	);

	jpeg_dec_dequant	JPEG_DEC_DEQUANT_CR(
		.HCLK				(CLK_CORE				),
		.HRESETn			(RSTN					),
		.INIT				(jpeg_dec_deqt_init		),
		.C_BLK_ECS			(C_BLK_ECS_CR			),
		.DEQT_EN			(jpeg_dec_deqt_en_cr	),
		.DEQT_DAT			(jpeg_dec_deqt_out_cr	),
		.DEQT_ADR			(jpeg_dec_deqt_adr_cr	),
		.PI_EN				(jpeg_dec_deqt_pi_en_cr	),
		.PI					(jpeg_dec_deqt_pi_cr	),
		.PI_DC				(jpeg_dec_deqt_pi_dc_cr	),
		.PO_EN				(jpeg_dec_deqt_po_en_cr	),
		.PO					(jpeg_dec_deqt_po_cr	)
	);

	jpeg_dec_dequant_table	JPEG_DEC_DEQUANT_TABLE(
		.HCLK				(CLK_CORE				),
		.HRESETn			(RSTN					),
		.INIT				(jpeg_dec_deqt_init		),
		.C_QTBL_SEL			({2'd2,2'd1,2'd0}		),
		.DQT_UP_EN			(jpeg_dec_dqt_up_en		),
		.DQT_UP_DAT			(jpeg_dec_dqt_up_dat	),
		.DQT_UP_ID			(jpeg_dec_dqt_up_id		),
		.DEQT_EN_Y			(jpeg_dec_deqt_en_y		),
		.DEQT_EN_CB			(jpeg_dec_deqt_en_cb	),
		.DEQT_EN_CR			(jpeg_dec_deqt_en_cr	),
		.DEQT_ADR_Y			(jpeg_dec_deqt_adr_y	),
		.DEQT_ADR_CB		(jpeg_dec_deqt_adr_cb	),
		.DEQT_ADR_CR		(jpeg_dec_deqt_adr_cr	),
		.DEQT_OUT_Y			(jpeg_dec_deqt_out_y	),
		.DEQT_OUT_CB		(jpeg_dec_deqt_out_cb	),
		.DEQT_OUT_CR		(jpeg_dec_deqt_out_cr	)
	);

	jpeg_dec_dqt_gen #(
`ifdef	TEST_IMG0	.DUT_INPUT_FILE("../golden_data/ivl0_ydc1_cdc1_QP0_1_QP1_3_high_quality/jpdec_core_qtable.txt")
`elsif	TEST_IMG1	.DUT_INPUT_FILE("../golden_data/ivl0_ydc16_cdc17_QP0_16_QP1_1_low_quality/jpdec_core_qtable.txt")
`elsif	TEST_IMG2	.DUT_INPUT_FILE("../golden_data/ivl1_ydc1_cdc1_QP0_1_QP1_7_high_quality/jpdec_core_qtable.txt")
`elsif	TEST_IMG3	.DUT_INPUT_FILE("../golden_data/ivl1_ydc16_cdc17_QP0_16_QP1_1_low_quality/jpdec_core_qtable.txt")
`elsif	TEST_IMG4	.DUT_INPUT_FILE("../golden_data/ivl4_ydc1_cdc1_QP0_1_QP1_7_high_quality/jpdec_core_qtable.txt")
`elsif	TEST_IMG5	.DUT_INPUT_FILE("../golden_data/ivl4_ydc16_cdc17_QP0_16_QP1_1_low_quality/jpdec_core_qtable.txt")
`else				.DUT_INPUT_FILE("../golden_data/ivl0_ydc1_cdc1_QP0_1_QP1_3_high_quality/jpdec_core_qtable.txt")
`endif
	)
	JPEG_DEC_DQT_GEN(
		.iCLK				(CLK_CORE				),
		.iRSTN				(RSTN					),
		.oINIT				(jpeg_dec_deqt_init		),
		.oDEQT_EN			(jpeg_dec_dqt_up_en		),
		.oDEQT_DAT			(jpeg_dec_dqt_up_dat	),
		.oDEQT_ID			(jpeg_dec_dqt_up_id		)
	);


//=================================================================================================
//	Stimulus
//=================================================================================================
	reg		[1:0]	test_done = 2'd0;
	initial begin
		wait(RSTN);
		@(posedge CLK_CORE);
`ifdef TEST_CASE1
		// Restart interval test
		C_BLK_ECS_Y  = 16'd10; C_BLK_ECS_CB = 16'd10; C_BLK_ECS_CR = 16'd10;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(      200,   2**10,     2'd0,        0,     2'd0,      256,     2'd0,      1'd0);
		C_BLK_ECS_Y  = 16'd20; C_BLK_ECS_CB = 16'd10; C_BLK_ECS_CR = 16'd10;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(      200,   2**10,     2'd0,        0,     2'd0,      256,     2'd1,      1'd0);
		C_BLK_ECS_Y  = 16'd24; C_BLK_ECS_CB = 16'd6; C_BLK_ECS_CR = 16'd6;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(      200,   2**10,     2'd0,        0,     2'd0,      256,     2'd2,      1'd0);
		C_BLK_ECS_Y  = 16'd8; C_BLK_ECS_CB = 16'd8; C_BLK_ECS_CR = 16'd8;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(       16,   2**10,     2'd0,        0,     2'd0,      256,     2'd0,      1'd0);
		C_BLK_ECS_Y  = 16'd10; C_BLK_ECS_CB = 16'd5; C_BLK_ECS_CR = 16'd5;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(       20,   2**10,     2'd0,        0,     2'd0,      256,     2'd1,      1'd0);
		C_BLK_ECS_Y  = 16'd0; C_BLK_ECS_CB = 16'd0; C_BLK_ECS_CR = 16'd0;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(       30,   2**10,     2'd0,        0,     2'd0,      256,     2'd2,      1'd0);
`else
`ifdef	TEST_IMG2
		C_BLK_ECS_Y = 16'd2; C_BLK_ECS_CB = 16'd1; C_BLK_ECS_CR = 16'd1;
`elsif	TEST_IMG3
		C_BLK_ECS_Y = 16'd2; C_BLK_ECS_CB = 16'd1; C_BLK_ECS_CR = 16'd1;
`elsif	TEST_IMG4
		C_BLK_ECS_Y = 16'd8; C_BLK_ECS_CB = 16'd4; C_BLK_ECS_CR = 16'd4;
`elsif	TEST_IMG5
		C_BLK_ECS_Y = 16'd8; C_BLK_ECS_CB = 16'd4; C_BLK_ECS_CR = 16'd4;
`else
		C_BLK_ECS_Y = 16'd2; C_BLK_ECS_CB = 16'd1; C_BLK_ECS_CR = 16'd1;
`endif
		//                                    BLOCK_CYC|DONE_CYC|BLANK_MOD|BLANK_VAL|BURST_MOD|BURST_VAL|DATA_TYPE|COMP_CHECK|
		JPEG_DEC_DQT_GEN.test_case_go;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(   10000,   2**10,     2'd0,        0,     2'd0,      256,     2'd1,      1'd1);
		JPEG_DEC_DQT_GEN.test_case_go;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(   10000,   2**10,     2'd0,        0,     2'd0,      256,     2'd1,      1'd1);
		JPEG_DEC_DQT_GEN.test_case_go;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(   10000,   2**10,     2'd0,        0,     2'd1,      256,     2'd1,      1'd1);
		JPEG_DEC_DQT_GEN.test_case_go;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(   10000,   2**10,     2'd0,        0,     2'd2,      256,     2'd1,      1'd1);
		JPEG_DEC_DQT_GEN.test_case_go;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(   10000,   2**10,     2'd0,        0,     2'd0,      256,     2'd1,      1'd1);
		JPEG_DEC_DQT_GEN.test_case_go;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(   10000,   2**10,     2'd1,        0,     2'd0,      256,     2'd1,      1'd1);
		JPEG_DEC_DQT_GEN.test_case_go;
		JPEG_DEC_QUANT_TEST_MODEL.test_case_go(   10000,   2**10,     2'd2,        0,     2'd0,      256,     2'd1,      1'd1);
`endif
		$display("JPEG QUANT test finished!");
		$finish;
	end

endmodule
