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

    //=================================================================================================
    //  Sub module test
    //=================================================================================================

    //-------------------------------------------------------------------------------------------------
    // jpeg_dec busrt fifo
    //-------------------------------------------------------------------------------------------------
    wire            jpeg_dec_bf_init;
    wire            jpeg_dec_bf_afull;
    wire            jpeg_dec_bf_pi_en;
    wire    [11:0]  jpeg_dec_bf_pi;
    wire            jpeg_dec_bf_pi_dc;
    wire            jpeg_dec_bf_pi_lst;
    wire    [3:0]   jpeg_dec_bf_pi_zr;
    wire            jpeg_dec_reord_afull;
    wire            jpeg_dec_bf_po_en;
    wire    [11:0]  jpeg_dec_bf_po;
    wire            jpeg_dec_bf_po_dc;
    wire            jpeg_dec_bf_po_lst;
    wire    [3:0]   jpeg_dec_bf_po_zr;

    jpeg_dec_burst_fifo_test_model #(
`ifdef	TEST_IMG0	.DUT_INPUT_FILE("../golden_data/ivl0_ydc1_cdc1_QP0_1_QP1_3_high_quality/D1_core0_jpdec_expand_input.txt")
`elsif	TEST_IMG1	.DUT_INPUT_FILE("../golden_data/ivl0_ydc16_cdc17_QP0_16_QP1_1_low_quality/D1_core0_jpdec_expand_input.txt")
`elsif	TEST_IMG2	.DUT_INPUT_FILE("../golden_data/ivl1_ydc1_cdc1_QP0_1_QP1_7_high_quality/D1_core0_jpdec_expand_input.txt")
`elsif	TEST_IMG3	.DUT_INPUT_FILE("../golden_data/ivl1_ydc16_cdc17_QP0_16_QP1_1_low_quality/D1_core0_jpdec_expand_input.txt")
`elsif	TEST_IMG4	.DUT_INPUT_FILE("../golden_data/ivl4_ydc1_cdc1_QP0_1_QP1_7_high_quality/D1_core0_jpdec_expand_input.txt")
`elsif	TEST_IMG5	.DUT_INPUT_FILE("../golden_data/ivl4_ydc16_cdc17_QP0_16_QP1_1_low_quality/D1_core0_jpdec_expand_input.txt")
`else				.DUT_INPUT_FILE("../golden_data/ivl0_ydc1_cdc1_QP0_1_QP1_3_high_quality/D1_core0_jpdec_expand_input.txt")
    `endif
    )
	JPEG_DEC_BURST_FIFO_TEST_MODEL(
		.iCLK				(CLK_CORE				),
		.iRSTN				(RSTN					),
		.oINIT				(jpeg_dec_bf_init		),
        .iBRST_AFULL        (jpeg_dec_bf_afull      ),
		.oPO_EN				(jpeg_dec_bf_pi_en 	    ),
		.oPO				(jpeg_dec_bf_pi	        ),
		.oPO_DC				(jpeg_dec_bf_pi_dc	    ),
		.oPO_LST			(jpeg_dec_bf_pi_lst     ),
		.oPO_ZR				(jpeg_dec_bf_pi_zr      ),
        .oREORD_AFULL       (jpeg_dec_reord_afull   ),
        .iPI_EN             (jpeg_dec_bf_po_en      ),
        .iPI                (jpeg_dec_bf_po         ),
        .iPI_DC             (jpeg_dec_bf_po_dc      ),
        .iPI_LST            (jpeg_dec_bf_po_lst     ),
        .iPI_ZR             (jpeg_dec_bf_po_zr      )
	);

    jpeg_dec_burst_fifo     JPEG_DEC_BURST_FIFO (
        .HCLK               (CLK_CORE               ),
        .HRESETn            (RSTN                   ),
        .INIT               (jpeg_dec_bf_init       ),
        .BRST_AFULL         (jpeg_dec_bf_afull      ),
        .PI_EN              (jpeg_dec_bf_pi_en      ),
        .PI                 (jpeg_dec_bf_pi         ),
        .PI_DC              (jpeg_dec_bf_pi_dc      ),
        .PI_LST             (jpeg_dec_bf_pi_lst     ),
        .PI_ZR              (jpeg_dec_bf_pi_zr      ),
        .REORD_AFULL        (jpeg_dec_reord_afull   ),
        .PO_EN              (jpeg_dec_bf_po_en      ),
        .PO                 (jpeg_dec_bf_po         ),
        .PO_DC              (jpeg_dec_bf_po_dc      ),
        .PO_LST             (jpeg_dec_bf_po_lst     ),
        .PO_ZR              (jpeg_dec_bf_po_zr      )
    );

    //=================================================================================================
    //	Stimulus
    //=================================================================================================

    initial begin
        wait(RSTN);
        @(posedge CLK_CORE);
        //                                          |BLOCK_CYC|DONE_CYC|OUT_MOD|BUSY_MOD|
        JPEG_DEC_BURST_FIFO_TEST_MODEL.test_case_go(     2**20,   2**10,   2'd0,    2'd0);  // OUT_MOD: countinuous,     BUSY_MOD: no busy
        JPEG_DEC_BURST_FIFO_TEST_MODEL.test_case_go(     2**20,   2**10,   2'd1,    2'd0);  // OUT_MOD: 1/8 possibility, BUSY_MOD: no busy
        JPEG_DEC_BURST_FIFO_TEST_MODEL.test_case_go(     2**20,   2**10,   2'd3,    2'd0);  // OUT_MOD: 7/8 possibility, BUSY_MOD: no busy

        JPEG_DEC_BURST_FIFO_TEST_MODEL.test_case_go(     2**20,   2**10,   2'd1,    2'd1);  // OUT_MOD: 1/8 possibility, BUSY_MOD: 1/8 possibility
        JPEG_DEC_BURST_FIFO_TEST_MODEL.test_case_go(     2**20,   2**10,   2'd1,    2'd2);  // OUT_MOD: 1/8 possibility, BUSY_MOD: 4/8 possibility
        JPEG_DEC_BURST_FIFO_TEST_MODEL.test_case_go(     2**20,   2**10,   2'd1,    2'd3);  // OUT_MOD: 1/8 possibility, BUSY_MOD: 7/8 possibility

        JPEG_DEC_BURST_FIFO_TEST_MODEL.test_case_go(     2**20,   2**10,   2'd3,    2'd1);  // OUT_MOD: 7/8 possibility, BUSY_MOD: 1/8 possibility
        JPEG_DEC_BURST_FIFO_TEST_MODEL.test_case_go(     2**20,   2**10,   2'd3,    2'd2);  // OUT_MOD: 7/8 possibility, BUSY_MOD: 4/8 possibility
        JPEG_DEC_BURST_FIFO_TEST_MODEL.test_case_go(     2**20,   2**10,   2'd3,    2'd3);  // OUT_MOD: 7/8 possibility, BUSY_MOD: 7/8 possibility

        #(1000);
        $display("JPEG burst FIFO test finished!");
        $finish;
    end

    endmodule
