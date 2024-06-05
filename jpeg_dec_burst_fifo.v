//*****************************************************************************
//  File Name           : jpeg_dec_burst_fifo.v
//-----------------------------------------------------------------------------
//  Description         : JPEG Decoder Block Burst FIFO
//-----------------------------------------------------------------------------
//  Date                : 2024.05.27
//  Designed by         : Donghak Oh, mghwang, Junhee Jung
//-----------------------------------------------------------------------------
//  Revision History    :
//      1. 2024.05.27   : Created by Donghak Oh
//*****************************************************************************

module jpeg_dec_burst_fifo(
    input               HCLK,
    input               HRESETn,
    input               INIT,

    output              BRST_AFULL,     // Burst FIFO almost full
    input               PI_EN,
    input   [11:0]      PI,
    input               PI_DC,
    input               PI_LST,
    input   [3:0]       PI_ZR,

    input               REORD_AFULL,    // Reorder buffer almost full
    output  reg         PO_EN,
    output  reg [11:0]  PO,
    output  reg         PO_DC,
    output  reg         PO_LST,
    output  reg [3:0]   PO_ZR
    );

    // Burst FIFO control
    wire                bf_wr_en;
    wire    [17:0]      bf_wdata        = {PI,PI_ZR,PI_LST,PI_DC};
    wire                bf_rd_en;
    wire    [17:0]      bf_rdata;
    wire    [11:0]      bf_rdata_po     = bf_rdata[17:6];
    wire    [3:0]       bf_rdata_zr     = bf_rdata[5:2];
    wire                bf_rdata_lst    = bf_rdata[1];
    wire                bf_rdata_dc     = bf_rdata[0];
    wire    [7:0]       bf_depth;
    wire                bf_empty;
    wire                bf_full;

    // Block couting
    reg     [5:0]       bf_blk_rem;
    wire                bf_blk_wr;
    wire                bf_blk_rd;

    // FSM
    localparam          RD_RDY      = 2'd0,
                        RD_OP       = 2'd1,
                        RD_HOLD     = 2'd2;

    reg     [1:0]       rd_state;
    reg     [5:0]       hold_cnt;
    wire                rd_rdy;

//-----------------------------------------------------------------------------
//  Burst FIFO control
//-----------------------------------------------------------------------------
    assign      bf_wr_en    = PI_EN & !bf_full;
    assign      bf_rd_en    = (!INIT) & (rd_state==RD_OP);

    sfifo_dp_128x18 BURST_FIFO(
        .CLK        (HCLK               ),
        .RSTN       (HRESETn            ),
        .INIT       (INIT               ),
        .WR_REQ     (bf_wr_en           ),
        .WR_DI      (bf_wdata           ),
        .RD_REQ     (bf_rd_en           ),
        .RD_DO      (bf_rdata           ),
        .DEPTH      (bf_depth           ),
        .EMPTY      (bf_empty           ),
        .FULL       (bf_full            ),
        .AFULL      (BRST_AFULL         )
    );

//-----------------------------------------------------------------------------
//  Block couting
//-----------------------------------------------------------------------------
    assign  bf_blk_wr  =   PI_EN & PI_LST;
    assign  bf_blk_rd  =   bf_rd_en & bf_rdata_lst;
    always @(posedge HCLK) begin
        if(INIT)    bf_blk_rem  <= 6'd0;
        else begin
            case({bf_blk_wr,bf_blk_rd})
            2'b10: bf_blk_rem  <= bf_blk_rem + 1'd1;
            2'b01: bf_blk_rem  <= bf_blk_rem - 1'd1;
            endcase
        end
    end

//-----------------------------------------------------------------------------
//  Busrt FSM
//-----------------------------------------------------------------------------
    assign  rd_rdy  = (~REORD_AFULL); // Consider bf_blk_wr -> !bf_empty delay

    always @(posedge HCLK) begin
        if(INIT) begin
            rd_state    <= 2'd0;
            hold_cnt    <= 6'd0;
        end
        else begin
            case(rd_state)
            RD_RDY: begin
                hold_cnt      <= 6'd0;
                if(rd_rdy)
                    rd_state <= RD_OP;
                else begin
                    rd_state <= RD_RDY;
                end
            end
            RD_OP: begin
                if(~&hold_cnt) begin
                    hold_cnt <= hold_cnt + 1'd1;
                end

                if(bf_rdata_lst)
                    rd_state <= RD_HOLD;
                else
                    rd_state <= RD_OP;
            end
            RD_HOLD: begin
                if(&hold_cnt) begin
                    if(rd_rdy) begin
                        rd_state    <= RD_OP;
                        hold_cnt    <= 6'd0;
                    end 
                    else
                        rd_state    <= RD_RDY;
                end
                else begin
                    rd_state    <= RD_HOLD;
                    hold_cnt    <= hold_cnt + 1'd1;
                end
            end
            endcase
        end
    end

//-----------------------------------------------------------------------------
//  Output
//-----------------------------------------------------------------------------
    always @(posedge HCLK) begin
        if(INIT) begin
            PO_EN   <= 1'd0;
            PO      <= 12'd0;
            PO_DC   <= 1'd0;
            PO_LST  <= 1'd0;
            PO_ZR   <= 4'd0;
        end
        else begin
            PO_EN   <= bf_rd_en;
            if(bf_rd_en) begin
                PO      <= bf_rdata_po;
                PO_DC   <= bf_rdata_dc;
                PO_LST  <= bf_rdata_lst;
                PO_ZR   <= bf_rdata_zr;
            end
        end
    end

//=================================================================================================
// Monitor
//=================================================================================================
// synopsys translate_off
/* verilator lint_off STMTDLY */

    // check DC to LST burst
    reg             po_en_d1;
    reg             po_lst_d1;
    reg             po_en_chk;
    wire            po_en_err = (!INIT) & (po_en_d1!=po_en_chk);
    always @(posedge HCLK) begin
        if(INIT) begin
            po_en_d1    <=  1'd0;
            po_lst_d1   <=  1'd0;
            po_en_chk   <=  1'd0;
        end
        else begin
            po_en_d1    <=  PO_EN;
            po_lst_d1   <=  PO_LST;
            if(PO_DC)           po_en_chk   <=  1'd1;
            else if(po_lst_d1)  po_en_chk   <=  1'd0;
        end
    end

    // check DC to DC cycle count
    reg     [5:0]   po_en_cnt_chk;
    wire            po_en_cnt_err = (!INIT) & (~&po_en_cnt_chk & PO_DC);
    always @(posedge HCLK) begin
        if(INIT)                        po_en_cnt_chk   <=  6'd63;
        else begin
            if(PO_DC)                   po_en_cnt_chk   <=  6'd0;
            else if(~&po_en_cnt_chk)    po_en_cnt_chk   <=  po_en_cnt_chk + 1'd1;
        end
    end

    always @(posedge HCLK) begin
        if(bf_empty&bf_rd_en)   begin $display("%m, @%0t: FIFO error!", $time); #(1000); $finish; end
        if(bf_full)             begin $display("%m, @%0t: FIFO error!", $time); #(1000); $finish; end
        if(po_en_err)           begin $display("%m, @%0t: PO_EN burst error!", $time); #(1000); $finish; end
        if(po_en_cnt_err)       begin $display("%m, @%0t: DC to DC cycle error!", $time); #(1000); $finish; end
    end

/* verilator lint_on STMTDLY */
// synopsys translate_on

endmodule
