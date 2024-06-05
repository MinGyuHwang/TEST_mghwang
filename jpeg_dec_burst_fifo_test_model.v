//*************************************************************************************************
//  File Name     : jpeg_dec_burst_fifo_test_model.v
//  Date          : 2024.05.23
//  Designed by   : DongHak Oh (Ref. code : Junhee Jung's jpeg_dec_expand_test_model.v)
//*************************************************************************************************

`timescale 1ns / 1ps

module  jpeg_dec_burst_fifo_test_model  (
            iCLK,
            iRSTN,
            oINIT,
            iBRST_AFULL,
            oPO_EN,
            oPO,
            oPO_DC,
            oPO_LST,
            oPO_ZR,
            oREORD_AFULL,
            iPI_EN,
            iPI,
            iPI_DC,
            iPI_LST,
            iPI_ZR
        );

    parameter       DUT_INPUT_FILE = "./_In/dut_input.txt";

    input           iCLK;
    input           iRSTN;
    output          oINIT;
    input           iBRST_AFULL;
    output          oPO_EN;
    output  [11:0]  oPO;
    output          oPO_DC;
    output          oPO_LST;
    output  [3:0]   oPO_ZR;
    output          oREORD_AFULL;
    output          iPI_EN;
    output  [11:0]  iPI;
    output          iPI_DC;
    output          iPI_LST;
    output  [3:0]   iPI_ZR;

//=================================================================================================
// Test parameters
//=================================================================================================
    reg     [31:0]  TEST_BUSY_CYC;
    reg     [31:0]  TEST_DONE_CYC;
    reg     [1:0]   TEST_OUT_MOD;
    reg     [1:0]   TEST_BUSY_MOD;

//=================================================================================================
// FSM
//=================================================================================================
    localparam          TW  =   32;

    reg         [1:0]   test_st;
    localparam  [1:0]   ST_IDLE         =   2'd0,
                        ST_TEST_BUSY    =   2'd1,
                        ST_TEST_DONE    =   2'd2,
                        ST_FIN          =   2'd3;
    wire                test_st_chk     = (test_st==ST_TEST_BUSY);

    reg             test_go = 1'd0;
    reg             test_done;
    reg     [31:0]  test_cnt;
    reg             oINIT;
    always @(posedge iCLK or negedge iRSTN) begin
        if(!iRSTN) begin
            test_st     <=  ST_IDLE;
            test_cnt    <=  {TW{1'd0}};
            test_done   <=  1'd0;
            oINIT       <=  1'd0;
        end
        else begin
            case(test_st)
            ST_IDLE: begin
                test_done   <=  1'd0;
                if(test_go) begin
                    test_st     <=  ST_TEST_BUSY;
                    test_cnt    <=  {TW{1'd0}};
                    oINIT       <=  1'd1;
                end
            end
            ST_TEST_BUSY: begin
                oINIT   <=  1'd0;
                if(test_cnt==TEST_BUSY_CYC) begin
                    test_st     <=  ST_TEST_DONE;
                    test_cnt    <=  {TW{1'd0}};
                end
                else begin
                    test_cnt    <=  test_cnt + 1'd1;
                end
            end
            ST_TEST_DONE: begin
                if(test_cnt==TEST_DONE_CYC) begin
                    test_st     <=  ST_FIN;
                    test_cnt    <=  {TW{1'd0}};
                end
                else begin
                    test_cnt    <=  test_cnt + 1'd1;
                end
            end
            ST_FIN: begin
                test_done   <=  1'd1;
                if(~test_go) begin
                    test_st <=  ST_IDLE;
                end
            end
            endcase
        end
    end

//=================================================================================================
// DUT input
//=================================================================================================
    localparam      IAW     =   22;
    localparam      DLEN    =   2**IAW;

    // load DUT input
    reg     [11:0]  po      [0:(DLEN-1)];
    reg             po_dc   [0:(DLEN-1)];
    reg             po_lst  [0:(DLEN-1)];
    reg     [3:0]   po_zr   [0:(DLEN-1)];

    integer fp_dut_input;
    integer i, ret;
    initial begin
        fp_dut_input = $fopen(DUT_INPUT_FILE, "r");

        for (i=0;i<DLEN;i=i+1) begin
            ret = $fscanf(fp_dut_input, "%03x %d %d %x\n", po[i], po_dc[i], po_lst[i], po_zr[i]);
        end

        $fclose(fp_dut_input);
    end

    reg     [2:0]   rand_out;
    always @(posedge iCLK or negedge iRSTN) begin
        if(!iRSTN)      rand_out <= 3'd0;
        else            rand_out <= $urandom;
    end

    wire            w1_PoEnT =  (TEST_OUT_MOD==2'd0)        ?   1'd1                        :   // Continuous
                                (TEST_OUT_MOD==2'd1)        ?   (rand_out[2:0]==3'd0)       :   // 1/8 possibility
                                (TEST_OUT_MOD==2'd2)        ?   rand_out[0]                 :   // 4/8 possibility
                                                                (rand_out[2:0]!=3'd0)       ;   // 7/8 possibility
    reg                 r1_PoEnT;
    reg     [IAW-1:0]   r_DutInAddr;
    always @(posedge iCLK or negedge iRSTN) begin
        if(!iRSTN) begin
            r1_PoEnT    <=  1'd0;
            r_DutInAddr <=  {IAW{1'd0}};
        end
        else begin
            if((!test_st_chk)|oINIT) begin
                r1_PoEnT    <=  1'd0;
                r_DutInAddr <=  {IAW{1'd0}};
            end
            else begin
                if(iBRST_AFULL) r1_PoEnT    <= 1'd0;
                else            r1_PoEnT    <= w1_PoEnT;

                if(oPO_EN)  r_DutInAddr <=  r_DutInAddr + 1'd1;
            end
        end
    end

    wire            oPO_EN  =   r1_PoEnT;
    wire    [11:0]  oPO     =   po[r_DutInAddr];
    wire            oPO_DC  =   po_dc[r_DutInAddr];
    wire            oPO_LST =   po_lst[r_DutInAddr];
    wire    [3:0]   oPO_ZR  =   po_zr[r_DutInAddr];

//=================================================================================================
// Compare DUT output
//=================================================================================================
    wire    [17:0]  chk_buf_rd_do;
    wire            chk_buf_afull;

    sfifo_ff #(
        .DW         (18             ),
        .AW         (8              ),
        .FOFF       (64             ))
    CHK_FIFO(
        .CLK        (iCLK           ),
        .RSTN       (iRSTN          ),
        .INIT       (oINIT          ),
        .WR_REQ     (oPO_EN         ),
        .WR_DI      ({oPO,oPO_DC,oPO_LST,oPO_ZR}),
        .RD_REQ     (iPI_EN         ),
        .RD_DO      (chk_buf_rd_do  ),
        .DEPTH      (               ),
        .EMPTY      (               ),
        .FULL       (               ),
        .AFULL      (chk_buf_afull  )
    );

    reg     [2:0]   rand_busy;
    always @(posedge iCLK or negedge iRSTN) begin
        if(!iRSTN)      rand_busy <= 3'd0;
        else            rand_busy <= $urandom;
    end

    wire            tog_busy =  (TEST_BUSY_MOD==2'd0)       ?   1'd0                        :   // no busy
                                (TEST_BUSY_MOD==2'd1)       ?   (rand_busy[2:0]==3'd0)      :   // 1/8 possibility
                                (TEST_BUSY_MOD==2'd2)       ?   rand_busy[0]                :   // 4/8 possibility
                                                                (rand_busy[2:0]!=3'd0)      ;   // 7/8 possibility

    reg             oREORD_AFULL_T;
    always @(posedge iCLK or negedge iRSTN) begin
        if(!iRSTN)                      oREORD_AFULL_T <= 3'd0;
        else if((!test_st_chk)|oINIT)   oREORD_AFULL_T <= 3'd0;
        else if(tog_busy)               oREORD_AFULL_T <= ~oREORD_AFULL_T;
    end
    wire            oREORD_AFULL  =   oREORD_AFULL_T | chk_buf_afull;

	wire	[11:0]		w12_PiCompare 	=	chk_buf_rd_do[17:6];
	wire				w1_DcCompare	=	chk_buf_rd_do[5];
	wire				w1_LstCompare	=	chk_buf_rd_do[4];
	wire	[3:0]		w1_ZrCompare	=	chk_buf_rd_do[3:0];
	wire				w1_PiNotMatch	=	(!oINIT) & iPI_EN & ((w12_PiCompare!==iPI) | (w1_DcCompare!==iPI_DC) | (w1_LstCompare!==iPI_LST) | (w1_ZrCompare!==iPI_ZR)) ;
	always @(posedge iCLK) begin
		if(test_st_chk & w1_PiNotMatch) begin $display("%m, @%0t: Data compare error!", $time); #(5000); $finish; end
	end

//=================================================================================================
// Test Task
//=================================================================================================
    task test_case_go(
        input   [31:0]  BUSY_CYC,
        input   [31:0]  DONE_CYC,
        input   [1:0]   OUT_MOD,
        input   [1:0]   BUSY_MOD
    );
    begin
        TEST_BUSY_CYC   =   BUSY_CYC;
        TEST_DONE_CYC   =   DONE_CYC;
        TEST_OUT_MOD    =   OUT_MOD;
        TEST_BUSY_MOD   =   BUSY_MOD;

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
