//*************************************************************************************************
//	File Name     : jpeg_dec_quant_test_model.v
//	Date          : 2024.05.23
//	Designed by   : DongHak Oh (Ref. code : Junhee Jung's jpeg_dec_expand_test_model.v)
//*************************************************************************************************

`timescale 1ns / 1ps

module	jpeg_dec_quant_test_model	(
			iCLK,
			iRSTN,
			oINIT,
			oPO_EN,
			oPO,
			oPO_DC,
			oPO_ID,
			iPI_EN,
			iPI
		);

	parameter		DUT_INPUT_FILE = "./_In/dut_input.txt";
	parameter		DUT_OUTPUT_FILE = "./_In/dut_output.txt";

	input			iCLK;
	input			iRSTN;
	output			oINIT;
	output			oPO_EN;
	output	[11:0]	oPO;
	output			oPO_DC;
	output	[1:0]	oPO_ID;
	input			iPI_EN;
	input	[11:0]	iPI;

//=================================================================================================
// Test parameters
//=================================================================================================
	reg		[1:0]	TEST_DATA_TYPE;
	reg		[31:0]	TEST_BLOCK_CYC;
	reg		[31:0]	TEST_DONE_CYC;
	reg		[1:0]	TEST_BLANK_MOD;		// 0: short range random, 1: long range random, 2: very long range random, 3: fixed
	reg		[31:0]	TEST_BLANK_VAL;
	reg		[1:0]	TEST_BURST_MOD;		// 0: short range random, 1: long range random, 2: very long range random, 3: fixed
	reg		[31:0]	TEST_BURST_VAL;
	reg				TEST_COMP_CHECK;


//=================================================================================================
// Signal description
//=================================================================================================

	reg					r1_PoState;		// 0: blank, 1: burst(multiple of 64cycle)
	wire				w1_PoEnTUp;

//=================================================================================================
// FSM
//=================================================================================================
	localparam			TW	=	32;

	reg			[1:0]	test_st;
	localparam	[1:0]	ST_IDLE			=	2'd0,
						ST_TEST_BUSY	=	2'd1,
						ST_TEST_DONE	=	2'd2,
						ST_FIN			=	2'd3;
	wire				test_st_chk		= (test_st==ST_TEST_BUSY);

	reg				test_go = 1'd0;
	reg				test_done;
	reg		[31:0]	test_cnt;
	reg				oINIT;
	always @(posedge iCLK or negedge iRSTN) begin
		if(!iRSTN) begin
			test_st		<=	ST_IDLE;
			test_cnt	<=	{TW{1'd0}};
			test_done	<=	1'd0;
			oINIT		<=	1'd0;
		end
		else begin
			case(test_st)
			ST_IDLE: begin
				test_done	<=	1'd0;
				if(test_go) begin
					test_st		<=	ST_TEST_BUSY;
					test_cnt	<=	{TW{1'd0}};
					oINIT		<=	1'd1;
				end
			end
			ST_TEST_BUSY: begin
				oINIT	<=	1'd0;
				if(r1_PoState & w1_PoEnTUp) begin
					if(test_cnt==TEST_BLOCK_CYC-1'd1) begin
						test_st		<=	ST_TEST_DONE;
						test_cnt	<=	{TW{1'd0}};
					end
					else begin
						test_cnt	<=	test_cnt + 1'd1;
					end
				end
			end
			ST_TEST_DONE: begin
				if(test_cnt==TEST_DONE_CYC) begin
					test_st		<=	ST_FIN;
					test_cnt	<=	{TW{1'd0}};
				end
				else begin
					test_cnt	<=	test_cnt + 1'd1;
				end
			end
			ST_FIN: begin
				test_done	<=	1'd1;
				if(~test_go) begin
					test_st	<=	ST_IDLE;
				end
			end
			endcase
		end
	end

//=================================================================================================
// DUT input
//=================================================================================================
	localparam		IAW		=	22;
	localparam		DLEN	=	2**IAW;

	// load DUT input
	reg		[11:0]	po		[0:(DLEN-1)];

	// load DUT input
	initial begin
		$readmemh(DUT_INPUT_FILE, po);
	end

	reg					r1_PoEnT;
	reg		[31:0]		r32_CycCnt;
	assign				w1_PoEnTUp	=	(~|r32_CycCnt[5:0]);
	reg		[IAW-1:0]	r_DutInAddr;
	always @(posedge iCLK or negedge iRSTN) begin
		if(!iRSTN) begin
			r1_PoState	<=	1'd0;
			r1_PoEnT	<=	1'd0;
			r32_CycCnt	<=	16'd0;
			r_DutInAddr	<=	{IAW{1'd0}};

		end
		else begin
			if((!test_st_chk)|oINIT) begin
				r1_PoState	<=	1'd0;
				r1_PoEnT	<=	1'd0;
				r32_CycCnt	<=	$urandom_range(0,256);
				r_DutInAddr	<=	{IAW{1'd0}};
			end
			else begin
				if(~|r32_CycCnt) begin
					r1_PoEnT	<=	1'd0;
					r1_PoState	<=	~r1_PoState;
					if(r1_PoState) begin	// burst => blank
						if(TEST_BLANK_MOD==2'd0)		r32_CycCnt	<=	$urandom_range(0,8);					// short blank
						else if(TEST_BLANK_MOD==2'd1)	r32_CycCnt	<=	$urandom_range(128,256);				// long blank
						else if(TEST_BLANK_MOD==2'd2)	r32_CycCnt	<=	$urandom_range(1024,2048);				// very long blank
						else 							r32_CycCnt	<=	TEST_BLANK_VAL;							// fixed
					end
					else begin				// blank => burst
						r1_PoEnT	<=	1'd1;
						if(TEST_BURST_MOD==2'd0)		r32_CycCnt	<=	($urandom_range(1,4)<<6) - 32'd1;		// short burst
						else if(TEST_BURST_MOD==2'd1)	r32_CycCnt	<=	($urandom_range(33,64)<<6) - 32'd1;		// long burst
						else if(TEST_BURST_MOD==2'd2)	r32_CycCnt	<=	($urandom_range(129,256)<<6) - 32'd1;	// very long burst
						else 							r32_CycCnt	<=	(TEST_BURST_VAL<<6) - 32'd1;			// fixed				
					end
				end
				else begin
					r32_CycCnt	<=	r32_CycCnt - 1'd1;

					if(w1_PoEnTUp)		r1_PoEnT	<=	1'd1;
				end

				if(oPO_EN)	r_DutInAddr	<=	r_DutInAddr + 1'd1;
			end
		end
	end

	reg		[1:0]		component_id;
	reg		[2:0]		state;
	always @(posedge iCLK or negedge iRSTN) begin
		if(!iRSTN) begin
			state			<= 3'd0;
			component_id 	<= 2'd0;
		end
		else begin
			if(w1_PoEnTUp&r1_PoState) begin
				case(TEST_DATA_TYPE)
				2'd0: begin
					if(component_id < 3'd2) 		component_id <= component_id + 1'd1;
					else							component_id <= 3'd0;
				end
				2'd1: begin
					if(state==3'd3)					state <= 3'd0;
					else 							state <= state + 1'd1;

					if(state < 3'd1)				component_id <= 2'd0;
					else if(component_id==2'd2)		component_id <= 2'd0;
					else							component_id <= component_id + 1'd1;
				end
				2'd2: begin 
					if(state==3'd5)					state <= 3'd0;
					else 							state <= state + 1'd1;

					if(state < 3'd3)				component_id <= 2'd0;
					else if(component_id==2'd2)		component_id <= 2'd0;
					else							component_id <= component_id + 1'd1;
				end
				default: begin
					state			<= 3'd0;
					component_id <= 2'd0;
				end
				endcase
			end
		end
	end

	assign			oPO_EN	=	r1_PoState & r1_PoEnT;
	assign			oPO		=	po[r_DutInAddr];
	assign			oPO_DC	=	~(|r_DutInAddr[5:0]) & oPO_EN;
	assign			oPO_ID	=	component_id;

//=================================================================================================
// Compare DUT output
//=================================================================================================

	localparam		OAW	=	24;

	// load DUT output
	reg		[11:0]	DutOutput[0:((2**OAW)-1)];
	initial begin
		$readmemh(DUT_OUTPUT_FILE, DutOutput);
	end

	reg		[OAW-1:0]	r_DutOutAddr;
	always @(posedge iCLK or negedge iRSTN) begin
		if(!iRSTN) begin
			r_DutOutAddr	<=	{OAW{1'd0}};
		end
		else begin
			if(oINIT)		r_DutOutAddr	<=	{OAW{1'd0}};
			else if(iPI_EN)	r_DutOutAddr	<=	r_DutOutAddr + 1'd1;
		end
	end

	wire	[11:0]		w12_PiCompare = DutOutput[r_DutOutAddr];
	wire				w1_PiNotMatch = (!oINIT) & iPI_EN & (w12_PiCompare!==iPI);
	always @(posedge iCLK) begin
		if(TEST_COMP_CHECK) begin
			if(test_st_chk & w1_PiNotMatch) begin $display("%m, @%0t: Data compare error!", $time); #(1000); $finish; end
		end
	end


//=================================================================================================
// Test Task
//=================================================================================================
	task test_case_go(
		input	[31:0]	BLOCK_CYC,
		input	[31:0]	DONE_CYC,
		input	[1:0]	BLANK_MOD,
		input	[31:0]	BLANK_VAL,
		input	[1:0]	BURST_MOD,
		input	[31:0]	BURST_VAL,
		input	[1:0]	DATA_TYPE,
		input			COMP_CHECK
	);
	begin
		TEST_BLOCK_CYC	=	BLOCK_CYC;
		TEST_DONE_CYC	=	DONE_CYC;
		TEST_BLANK_MOD	=	BLANK_MOD;
		TEST_BLANK_VAL	=	BLANK_VAL;
		TEST_BURST_MOD	=	BURST_MOD;
		TEST_BURST_VAL	=	BURST_VAL;
		TEST_DATA_TYPE	=	DATA_TYPE;
		TEST_COMP_CHECK	= 	COMP_CHECK;

		test_go = 1'd1;
		wait(test_done);
		@(posedge iCLK);
		test_go = 1'd0;
		@(posedge iCLK);
		wait(!test_done);
		@(posedge iCLK);

	end
	endtask

endmodule

module	jpeg_dec_dqt_gen #(
	parameter	DUT_INPUT_FILE = "./_In/dut_input.txt"
	)
	(
	input			iCLK,
	input			iRSTN,
	output	reg		oINIT,
	output			oDEQT_EN,
	output	[7:0]	oDEQT_DAT,
	output	[1:0]	oDEQT_ID
);

	localparam		DUT_LEN = 192;

	reg		[7:0]	DUT_OUT[0:DUT_LEN-1];
	initial begin
		$readmemh(DUT_INPUT_FILE, DUT_OUT);
	end
	localparam		DQT_IDLE	= 3'd0,
					DQT_INIT	= 3'd1,
					DQT_OP 		= 3'd2,
					DQT_DONE	= 3'd3;

	reg				test_go = 1'd0;
	reg				test_done;
	reg		[2:0]	dqt_state;
	reg		[31:0]	cycle_cnt;
	reg		[7:0]	dut_adr;
	always @(posedge iCLK or negedge iRSTN) begin
		if(!iRSTN) begin
			dqt_state <= DQT_IDLE;
			dut_adr <= 8'd0;
			test_done <= 1'd0;
			cycle_cnt <= 32'd0;
			oINIT <= 1'd0;
		end
		else begin
			case(dqt_state)
			DQT_IDLE: begin
				dut_adr <= 8'd0;
				test_done <= 1'd0;
				if(test_go)	begin
					dqt_state <= DQT_INIT;
					oINIT <= 1'd1;
					cycle_cnt <= ($urandom_range(1,64));
				end
				else begin
					dqt_state <= DQT_IDLE;
					oINIT <= 1'd0;
					cycle_cnt <= 32'd0;
				end
			end
			DQT_INIT: begin
				oINIT <= 1'd0;
				cycle_cnt <= cycle_cnt - 1'd1;
				if(~(|cycle_cnt))	dqt_state <= DQT_OP;
				else				dqt_state <= DQT_INIT;
			end
			DQT_OP: begin
				if(dut_adr==(DUT_LEN-1'd1)) begin
					dqt_state <= DQT_DONE;
					dut_adr <= 8'd0;
				end else begin
					dqt_state <= DQT_OP;
					dut_adr <= dut_adr + 1'd1;
				end
			end
			DQT_DONE: begin
				dqt_state <= DQT_IDLE;
				test_done <= 1'd1;
			end
			endcase
		end
	end

	assign		oDEQT_EN	= (dqt_state==DQT_OP);
	assign		oDEQT_DAT	= DUT_OUT[dut_adr];
	assign		oDEQT_ID	=	(dut_adr < 8'd64)							? 2'd0 :
								((dut_adr > 8'd63)  && (dut_adr < 8'd128))	? 2'd1 :
								((dut_adr > 8'd127) && (dut_adr < 8'd192))	? 2'd2 : 2'd0;

	task test_case_go;
	begin
		@(posedge iCLK);
		test_go = 1'd1;
		wait(test_done);
		@(posedge iCLK);
		test_go = 1'd0;
		@(posedge iCLK);
		wait(!test_done);
		@(posedge iCLK);
	end
	endtask


endmodule