//*****************************************************************************
//	File Name			: jpeg_dec_core.v
//-----------------------------------------------------------------------------
//	Description			: JPEG Decoder core
//-----------------------------------------------------------------------------
//	Date				: 2024.05.24
//	Designed by			: Junhee Jung, Donghak Oh
//-----------------------------------------------------------------------------
//	Revision History	:
//		1. 2024.05.24	: Created by Junhee Jung
//*****************************************************************************

module	jpeg_dec_core (
			HCLK,
			HRESETn,

			// Controller interface
			INIT,
			C_BLK_TOT,
			C_BLK_ECS,
			C_BLK_ECS_Y,
			C_BLK_ECS_CB,
			C_BLK_ECS_CR,
			C_IMG_FMT,

			// Huffman table
			C_CTBL_SEL,
			// TODO

			// Q table
			C_QTBL_SEL,
			DQT_UP_EN,
			DQT_UP_DAT,
			DQT_UP_ID,

			// Bitstream - Pre interface
			VLD_START,
			VLD_FIN,
			VLD_ECS_FIN,
			PI_EMPTY,
			PI_REQ,
			PI,
			PI_RST_MRK,
			PI_EOI_MRK,

			// Post interface
			REORD_AFULL_Y,
			REORD_AFULL_CB,
			REORD_AFULL_CR,
			PO_EN_Y,
			PO_EN_CB,
			PO_EN_CR,
			PO_Y,
			PO_CB,
			PO_CR,

			// Error info
			ERR_INFO
		);

	parameter		PI_W	=	7'd32;

	input				HCLK;
	input				HRESETn;

	// Controller interface
	input				INIT;
	input	[31:0]		C_BLK_TOT;		// Total number of blocks
	input	[15:0]		C_BLK_ECS;		// Number of blocks per ECS for all component
	input	[15:0]		C_BLK_ECS_Y;	// Number of blocks per ECS for Y
	input	[15:0]		C_BLK_ECS_CB;	// Number of blocks per ECS for CB
	input	[15:0]		C_BLK_ECS_CR;	// Number of blocks per ECS for CR
	input	[1:0]		C_IMG_FMT;		// 0: YC444(Y,CB,CR), 1: YC422(Y,Y,CB,CR), 2: YC420(Y,Y,Y,Y,CB,CR), 3: Y-only(Y,Y,...)

	// Huffman table
	input	[2:0]		C_CTBL_SEL;		// [N]: Entropy coding table select for component N
	// TODO : Huffman table update code

	// Q table
	input	[5:0]		C_QTBL_SEL;		// [(N*2+1):(N*2)]: Q table select for component N
	input				DQT_UP_EN;		// DQT table enable
	input	[7:0]		DQT_UP_DAT;		// DQT table data
	input	[1:0]		DQT_UP_ID;		// 0: Y, 1: CB, 2:CR

	// Bitstream - Pre interface
	input				VLD_START;
	output				VLD_FIN;
	output				VLD_ECS_FIN;
	input				PI_EMPTY;
	output				PI_REQ;
	input	[PI_W-1:0]	PI;
	input				PI_RST_MRK;
	input				PI_EOI_MRK;

	// Post interface
	input				REORD_AFULL_Y;
	input				REORD_AFULL_CB;
	input				REORD_AFULL_CR;
	output				PO_EN_Y;
	output				PO_EN_CB;
	output				PO_EN_CR;
	output	[7:0]		PO_Y;
	output	[7:0]		PO_CB;
	output	[7:0]		PO_CR;

	// Error info
	output	[2:0]		ERR_INFO;

//=============================================================================
//	Signal declaration
//=============================================================================
	
	// VLD(Variable Length Decoder)
	wire				vld_po_en;
	wire	[11:0]		vld_po;
	wire				vld_po_dc;
	wire				vld_po_lst;
	wire	[3:0]		vld_po_zr;
	wire	[1:0]		vld_po_id;

	// Q-table
	wire				deqt_en_y;
	wire				deqt_en_cb;
	wire				deqt_en_cr;
	wire	[5:0]		deqt_adr_y;
	wire	[5:0]		deqt_adr_cb;
	wire	[5:0]		deqt_adr_cr;
	wire	[7:0]		deqt_out_y;
	wire	[7:0]		deqt_out_cb;
	wire	[7:0]		deqt_out_cr;

	// Sub-processing (Burst FIFO -> Expand -> Dequantization -> Inverse Zigzag -> Inverse DCT)
	wire				brst_afull_y;
	wire				brst_afull_cb;
	wire				brst_afull_cr;
	wire				pi_en_y		=	vld_po_en & (vld_po_id==2'd0);
	wire				pi_en_cb	=	vld_po_en & (vld_po_id==2'd1);
	wire				pi_en_cr	=	vld_po_en & (vld_po_id==2'd2);

//=============================================================================
//	Sub modules
//=============================================================================

	// VLD(Variable Length Decoder)
	jpeg_dec_vld #(
		.PI_W			(PI_W			))
	JPEG_DEC_VLD(
		.HCLK			(HCLK			),
		.HRESETn		(HRESETn		),
		.INIT			(INIT			),
		.C_BLK_TOT		(C_BLK_TOT		),
		.C_BLK_ECS		(C_BLK_ECS		),
		.C_IMG_FMT		(C_IMG_FMT		),
		.C_CTBL_SEL		(C_CTBL_SEL		),
		.VLD_START		(VLD_START		),
		.VLD_FIN		(VLD_FIN		),
		.VLD_ECS_FIN	(VLD_ECS_FIN	),

		.PI_EMPTY		(PI_EMPTY		),
		.PI_REQ			(PI_REQ			),
		.PI				(PI				),
		.PI_RST_MRK		(PI_RST_MRK		),
		.PI_EOI_MRK		(PI_EOI_MRK		),

		.BRST_AFULL_Y	(brst_afull_y	),
		.BRST_AFULL_CB	(brst_afull_cb	),
		.BRST_AFULL_CR	(brst_afull_cr	),
		.PO_EN			(vld_po_en		),
		.PO				(vld_po			),
		.PO_DC			(vld_po_dc		),
		.PO_LST			(vld_po_lst		),
		.PO_ZR			(vld_po_zr		),
		.PO_ID			(vld_po_id		),

		.ERR_INFO		(ERR_INFO		)
	);

	// Q-table
	jpeg_dec_dequant_table	JPEG_DEC_DEQT_TABLE(
		.HCLK			(HCLK			),
		.HRESETn		(HRESETn		),
		.INIT			(INIT			),
		.C_QTBL_SEL		(C_QTBL_SEL		),
		.DQT_UP_EN		(DQT_UP_EN		),
		.DQT_UP_DAT		(DQT_UP_DAT		),
		.DQT_UP_ID		(DQT_UP_ID		),

		.DEQT_EN_Y		(deqt_en_y		),
		.DEQT_EN_CB		(deqt_en_cb		),
		.DEQT_EN_CR		(deqt_en_cr		),
		.DEQT_ADR_Y		(deqt_adr_y		),
		.DEQT_ADR_CB	(deqt_adr_cb	),
		.DEQT_ADR_CR	(deqt_adr_cr	),
		.DEQT_OUT_Y		(deqt_out_y		),
		.DEQT_OUT_CB	(deqt_out_cb	),
		.DEQT_OUT_CR	(deqt_out_cr	)
	);

//-------------------------------------------------------------------------
//	Sub-processing (Burst FIFO -> Expand -> Dequantization -> Inverse Zigzag -> Inverse DCT)
//-------------------------------------------------------------------------

	// Y
	jpeg_dec_core_sub JPEG_DEC_CORE_Y(
		.HCLK			(HCLK			),
		.HRESETn		(HRESETn		),
		.INIT			(INIT			),
		.C_BLK_ECS		(C_BLK_ECS_Y	),
		.BRST_AFULL		(brst_afull_y	),
		.PI_EN			(pi_en_y		),
		.PI				(vld_po			),
		.PI_DC			(vld_po_dc		),
		.PI_LST			(vld_po_lst		),
		.PI_ZR			(vld_po_zr		),
		.DEQT_EN		(deqt_en_y		),
		.DEQT_ADR		(deqt_adr_y		),
		.DEQT_DAT		(deqt_out_y		),
		.REORD_AFULL	(REORD_AFULL_Y	),
		.PO_EN			(PO_EN_Y		),
		.PO				(PO_Y			)
	);

	// CB
	jpeg_dec_core_sub JPEG_DEC_CORE_CB(
		.HCLK			(HCLK			),
		.HRESETn		(HRESETn		),
		.INIT			(INIT			),
		.C_BLK_ECS		(C_BLK_ECS_CB	),
		.BRST_AFULL		(brst_afull_cb	),
		.PI_EN			(pi_en_cb		),
		.PI				(vld_po			),
		.PI_DC			(vld_po_dc		),
		.PI_LST			(vld_po_lst		),
		.PI_ZR			(vld_po_zr		),
		.DEQT_EN		(deqt_en_cb		),
		.DEQT_ADR		(deqt_adr_cb	),
		.DEQT_DAT		(deqt_out_cb	),
		.REORD_AFULL	(REORD_AFULL_CB	),
		.PO_EN			(PO_EN_CB		),
		.PO				(PO_CB			)
	);

	// CR
	jpeg_dec_core_sub JPEG_DEC_CORE_CR(
		.HCLK			(HCLK			),
		.HRESETn		(HRESETn		),
		.INIT			(INIT			),
		.C_BLK_ECS		(C_BLK_ECS_CR	),
		.BRST_AFULL		(brst_afull_cr	),
		.PI_EN			(pi_en_cr		),
		.PI				(vld_po			),
		.PI_DC			(vld_po_dc		),
		.PI_LST			(vld_po_lst		),
		.PI_ZR			(vld_po_zr		),
		.DEQT_EN		(deqt_en_cr		),
		.DEQT_ADR		(deqt_adr_cr	),
		.DEQT_DAT		(deqt_out_cr	),
		.REORD_AFULL	(REORD_AFULL_CR	),
		.PO_EN			(PO_EN_CR		),
		.PO				(PO_CR			)
	);

endmodule
