//-------------------------------------------------------------------
//                                                          
// PLAYSTATION CONTROLLER(DUALSHOCK TYPE) INTERFACE TOP          
//                                                          
// Version : 2.00                                           
//                                                          
// Copyright(c) 2003 - 2004 Katsumi Degawa , All rights reserved  
//                                                          
// Important !                                              
//                                                          
// This program is freeware for non-commercial use.         
// An author does no guarantee about this program.          
// You can use this under your own risk.                    
// 
// 2003.10.30  It is optimized . by K Degawa 
//                                                        
//-------------------------------------------------------------------
`timescale 100ps/10ps		

//--------- SIMULATION ---------------------------------------------- 
//`define	SIMULATION_1	

// Poll controller status every 2^Timer clock cycles
// 250Khz / 2^12 = 61Hz
//
// "The DS4 stock polling rate is 250Hz 3-4 ms compared to the SN30 which is 67-75Hz 13-18 ms"
// https://www.reddit.com/r/8bitdo/comments/u8z3ag/has_anyone_managed_to_get_their_controllers/
`ifdef SIMULATION_1
   `define Timer_siz 18
`else
   `define Timer_siz 12
`endif
//-------------------------------------------------------------------
`define Dualshock
module dualshock_controller(
   input  I_CLK250K,       //  MAIN CLK 250KHz
   input  I_RSTn,          //  MAIN RESET
   // to JoyStick
   output O_psCLK,         //  psCLK CLK OUT           コントローラと繋がるクロック
   output O_psSEL,         //  psSEL OUT               コントローラと繋がる出力
   output O_psTXD,         //  psTXD OUT               コントローラと繋がる出力
   input  I_psRXD,         //  psRXD IN                コントローラと繋がる入力
   // ボタンの状態
   output [7:0]O_RXD_1,    //  RX DATA 1 (8bit) これと
   output [7:0]O_RXD_2,    //  RX DATA 2 (8bit) これしか見てない
   output [7:0]O_RXD_3,    //  RX DATA 3 (8bit) // 見てないが見て見たい この辺にx、yが入ってそう。
   output [7:0]O_RXD_4,    //  RX DATA 4 (8bit) // 見てないが見て見たい
   output [7:0]O_RXD_5,    //  RX DATA 5 (8bit) // 見てないが見て見たい
   output [7:0]O_RXD_6,    //  RX DATA 6 (8bit) // 見てないが見て見たい
   // 設定
   input I_CONF_SW,       //  Dualshook Config  ACTIVE-HI
   input I_MODE_SW,       //  Dualshook Mode Set DEGITAL PAD 0: ANALOG PAD 1:
   input I_MODE_EN,       //  Dualshook Mode Control  OFF 0: ON 1:
   input [1:0] I_VIB_SW,  //  Vibration SW  VIB_SW[0] Small Moter OFF 0:ON  1:
                          //                VIB_SW[1] Bic Moter   OFF 0:ON  1(Dualshook Only)
   input [7:0] I_VIB_DAT  //  Vibration(Bic Moter)Data   8'H00-8'HFF (Dualshook Only)
);
   wire   W_scan_seq_pls, W_type;
   wire   [3:0]W_byte_cnt;
   wire   W_RXWT, W_TXWT, W_TXSET, W_TXEN;
   wire   [7:0]W_TXD_DAT, W_RXD_DAT;
   wire   W_conf_ent;
   ps_pls_gan pls(
      .I_CLK(I_CLK250K), .I_RSTn(I_RSTn), .I_TYPE(W_type), // DEGITAL PAD 0: ANALOG PAD 1:
      .O_SCAN_SEQ_PLS(W_scan_seq_pls),
      .O_RXWT(W_RXWT), .O_TXWT(W_TXWT), .O_TXSET(W_TXSET), .O_TXEN(W_TXEN),
      .O_psCLK(O_psCLK), .O_psSEL(O_psSEL), .O_byte_cnt(W_byte_cnt), .Timer() //.Timer(O_Timer)
   );
   `ifdef Dualshock
      ps_txd_commnd cmd(
         .I_CLK(W_TXSET), .I_RSTn(I_RSTn), .I_BYTE_CNT(W_byte_cnt),
         .I_MODE({I_CONF_SW,~I_MODE_EN,I_MODE_SW}),
         .I_VIB_SW(I_VIB_SW), .I_VIB_DAT(I_VIB_DAT), .I_RXD_DAT(W_RXD_DAT),
         .O_TXD_DAT(W_TXD_DAT), .O_TYPE(W_type), .O_CONF_ENT(W_conf_ent));
   `else
      txd_commnd_EZ cmd(
         .I_CLK(W_TXSET), .I_RSTn(I_RSTn), .I_BYTE_CNT(W_byte_cnt),
         .I_MODE(), .I_VIB_SW(I_VIB_SW), .I_VIB_DAT(), .I_RXD_DAT(),
         .O_TXD_DAT(W_TXD_DAT), .O_TYPE(W_type), .O_CONF_ENT(W_conf_ent));
   `endif
   ps_txd txd(
      .I_CLK(I_CLK250K), .I_RSTn(I_RSTn),
      .I_WT(W_TXWT), .I_EN(W_TXEN), .I_TXD_DAT(W_TXD_DAT), .O_psTXD(O_psTXD));
   ps_rxd rxd(.I_CLK(O_psCLK), .I_RSTn(I_RSTn),
      .I_WT(W_RXWT), .I_psRXD(I_psRXD), .O_RXD_DAT(W_RXD_DAT));
   //----------   RXD DATA DEC  ----------------------------------------
   reg [7:0] O_RXD_1, O_RXD_2, O_RXD_3, O_RXD_4, O_RXD_5, O_RXD_6;
   reg W_rxd_mask;
   always@(posedge W_scan_seq_pls)  W_rxd_mask <= ~W_conf_ent;
   always@(negedge W_RXWT) if (W_rxd_mask) case(W_byte_cnt)
      3: O_RXD_1 <= W_RXD_DAT;
      4: O_RXD_2 <= W_RXD_DAT;
      5: O_RXD_3 <= W_RXD_DAT;
      6: O_RXD_4 <= W_RXD_DAT;
      7: O_RXD_5 <= W_RXD_DAT;
      8: O_RXD_6 <= W_RXD_DAT;
   endcase
endmodule

`ifndef Dualshock
   module txd_commnd_EZ(
      input  I_CLK,I_RSTn,
      input  [3:0]I_BYTE_CNT,
      input  [2:0]I_MODE,
      input  [1:0]I_VIB_SW,
      input  [7:0]I_VIB_DAT,
      input  [7:0]I_RXD_DAT,
      output reg [7:0]O_TXD_DAT,
      output O_TYPE, O_CONF_ENT
   );
      assign O_TYPE = 1'b1;
      assign O_CONF_ENT = 1'b0;
      always@(posedge I_CLK or negedge I_RSTn)
         if (!I_RSTn)       O_TXD_DAT <= 8'h00;
         else case(I_BYTE_CNT)
            0:              O_TXD_DAT <= 8'h01;
            1:              O_TXD_DAT <= 8'h42;
            3: if(I_VIB_SW) O_TXD_DAT <= 8'h40;
               else         O_TXD_DAT <= 8'h00;
            4: if(I_VIB_SW) O_TXD_DAT <= 8'h01;
               else         O_TXD_DAT <= 8'h00;
            default: O_TXD_DAT <= 8'h00;
         endcase
   endmodule
`endif

module ps_txd_commnd(
   input  I_CLK,I_RSTn,
   input  [3:0]I_BYTE_CNT,
   input  [2:0]I_MODE,
   input  [1:0]I_VIB_SW,
   input  [7:0]I_VIB_DAT,
   input  [7:0]I_RXD_DAT,
   output reg [7:0]O_TXD_DAT,
   output O_TYPE, O_CONF_ENT
);
   wire   [1:0]pad_mode = I_MODE[1:0];
   wire   ds_sw  = I_MODE[2];
   reg    [2:0]conf_state;
   reg    conf_entry;
   reg    conf_ent_reg;
   reg    conf_done;
   reg    pad_status;
   reg    pad_id;
   assign O_TYPE = pad_id;
   assign O_CONF_ENT = conf_entry;
   always@(posedge I_CLK or negedge I_RSTn)
      if (!I_RSTn) pad_id <= 1'b0; 
      else if (I_BYTE_CNT==2) case(I_RXD_DAT) //------  GET TYPE(Byte_SEQ)
         8'h23:    pad_id <= 1'b1;
         8'h41:    pad_id <= 1'b0;
         8'h53:    pad_id <= 1'b1;
         8'h73:    pad_id <= 1'b1;
         8'hE3:    pad_id <= 1'b1;
         8'hF3:    pad_id <= 1'b1;
         default:  pad_id <= 1'b0;
      endcase
   always@(posedge I_CLK or negedge I_RSTn)
      if (!I_RSTn) begin
         O_TXD_DAT    <= 8'h00;
         conf_entry   <= 1'b0;
         conf_ent_reg <= 1'b0;
         conf_done    <= 1'b1;
         conf_state   <= 0;
         pad_status   <= 0;
      end else if (~conf_entry) case(I_BYTE_CNT)
         //---------- nomal mode --------------------------------------------------------
         //----------------- read_data_and_vibrate_ex    01,42,00,WW,PP(,00,00,00,00)
         //                                              --,ID,SS,XX,XX(,XX,XX,XX,XX)
         0: O_TXD_DAT <= 8'h01;
         1: O_TXD_DAT <= 8'h42;
         3: begin
            if (I_RXD_DAT == 8'h00) conf_ent_reg <= 1'b1;
            if (pad_status) begin
               if (I_VIB_SW[0]) O_TXD_DAT <= 8'h01;
               else             O_TXD_DAT <= 8'h00;
            end else begin
               if (I_VIB_SW[0] | I_VIB_SW[1]) O_TXD_DAT <= 8'h40;
               else                           O_TXD_DAT <= 8'h00;			        
            end
         end
         4: begin
            if (pad_status) begin
               if (I_VIB_SW[1]) O_TXD_DAT <= I_VIB_DAT;
               else             O_TXD_DAT <= 8'h00;
            end else begin
               if(I_VIB_SW[0] | I_VIB_SW[1]) O_TXD_DAT <= 8'h01;
               else                          O_TXD_DAT <= 8'h00;			        
            end
            if (pad_id == 0) begin
               if (conf_state == 0 && ds_sw)
                  conf_entry <= 1'b1;
               if (conf_state == 7 && (pad_status & conf_ent_reg)) begin
                  conf_state <= 0;
                  conf_entry <= 1'b1;
               end
            end
         end
         8: begin
            O_TXD_DAT <= 8'h00;
            if (pad_id == 1) begin
               if (conf_state == 0 && ds_sw)
                  conf_entry <= 1'b1;
               if (conf_state == 7 && (pad_status & conf_ent_reg)) begin
                  conf_state <= 0;
                  conf_entry <= 1'b1;
               end
            end
         end      
         default: O_TXD_DAT <= 8'h00;
      endcase else case(conf_state)
         //---------- confg mode --------------------------------------------------------
         //-------- config_mode_enter (43):     01,43,00,01,00(,00 x 4 or XX x 16)
         //                                     --,ID,SS,XX,XX(,XX x 4 or XX x 16)  
         0: case(I_BYTE_CNT)
               0:begin
                  O_TXD_DAT <= 8'h01;
                  conf_done <= 1'b0;
               end
               1:O_TXD_DAT <= 8'h43;
               3:O_TXD_DAT <= 8'h01;
               4:begin
                  O_TXD_DAT <= 8'h00;
                  if(pad_id==0)begin
                     if(pad_status) conf_state <= 3;
                     else           conf_state <= 1;    
                  end
               end
               8:begin
                  O_TXD_DAT <= 8'h00;
                  if(pad_id==1)begin
                     if(pad_status) conf_state <= 3;
                     else           conf_state <= 1;    
                  end
               end															         
               default:O_TXD_DAT <= 8'h00;
            endcase
         //-------- query_model_and_mode (45):  01,45,00,5A,5A,5A,5A,5A,5A
         //                                     FF,F3,5A,TT,02,MM,VV,01,00
         1: case(I_BYTE_CNT)
               0:O_TXD_DAT <= 8'h01;
               1:O_TXD_DAT <= 8'h45;
               2:begin
                     O_TXD_DAT <= 8'h00;
                     conf_done <= (I_RXD_DAT == 8'hF3)? 1'b0:1'b1;
                  end
               4:begin
                     O_TXD_DAT <= 8'h00;
                     if(I_RXD_DAT==8'h01 || I_RXD_DAT==8'h03) pad_status <= 1;
                     if(pad_id==0 && conf_done==1'b1)begin
                        conf_state <= 7;
                        conf_entry <= 1'b0;
                     end
                  end
               8:begin
                     O_TXD_DAT <= 8'h00;
                     conf_state <= 2;
                     if(pad_id==1 && conf_done==1'b1)begin
                        conf_state <= 7;
                        conf_entry <= 1'b0;
                     end                                
                  end 												         
               default:O_TXD_DAT <= 8'h00;
            endcase
         //-------- set_mode_and_lock (44):     01,44,00,XX,YY,00,00,00,00
         //                                     --,F3,5A,00,00,00,00,00,00
         2: case(I_BYTE_CNT)
               0:O_TXD_DAT <= 8'h01;
               1:O_TXD_DAT <= 8'h44;
               3:O_TXD_DAT <= pad_mode[0] ? 8'h01:8'h00;
               4:O_TXD_DAT <= pad_mode[1] ? 8'h03:8'h00;
               8:begin
                  O_TXD_DAT <= 8'h00;
                  conf_state<= 3;
               end
               default:O_TXD_DAT <= 8'h00;
            endcase
         //-------- vibration_enable (4D):      01,4D,00,00,01,FF,FF,FF,FF
         //                                     --,F3,5A,XX,YY,FF,FF,FF,FF
         3: case(I_BYTE_CNT)
               0:O_TXD_DAT <= 8'h01;
               1:O_TXD_DAT <= 8'h4D;
               2,3:O_TXD_DAT <= 8'h00;
               4:O_TXD_DAT <= 8'h01;
               8:begin
                  O_TXD_DAT <= 8'hFF; 
                  conf_state<= 6;
               end
               default:O_TXD_DAT <= 8'hFF;
            endcase
         //-------- config_mode_exit (43):      01,43,00,00,5A,5A,5A,5A,5A
         //                                     --,F3,5A,00,00,00,00,00,00
         6: case(I_BYTE_CNT)
               0: O_TXD_DAT <= 8'h01;
               1: O_TXD_DAT <= 8'h43;
               2,3:O_TXD_DAT <= 8'h00;
               8:begin
                  O_TXD_DAT <= 8'h5A;
                  conf_state<= 7;
                  conf_entry<= 1'b0;
                  conf_done <= 1'b1;
                  conf_ent_reg<= 1'b0; 						 
               end
               default:O_TXD_DAT <= 8'h5A;
            endcase
      endcase
endmodule

module ps_pls_gan(
   input  I_CLK,I_RSTn,I_TYPE,
   output reg O_SCAN_SEQ_PLS,
   output O_RXWT, O_TXWT, O_TXSET, O_TXEN, O_psCLK, O_psSEL,
   output reg [3:0]O_byte_cnt,
   output reg [Timer_size-1:0]Timer
);
   parameter Timer_size = `Timer_siz;
   reg    RXWT;
   reg    TXWT;
   reg    TXSET;
   reg    psCLK_gate;
   reg    psSEL;
   always@(posedge I_CLK or negedge I_RSTn)
      if(! I_RSTn) Timer <= 0;
      else         Timer <= Timer+1;
   always@(posedge I_CLK or negedge I_RSTn)
      if(! I_RSTn)        O_SCAN_SEQ_PLS <= 0;
      else if(Timer == 0) O_SCAN_SEQ_PLS <= 1; 
      else                O_SCAN_SEQ_PLS <= 0;            
   always@(posedge I_CLK or negedge I_RSTn)
      if(! I_RSTn) begin
         psCLK_gate <= 1;
         RXWT     <= 0;
         TXWT     <= 0;
         TXSET    <= 0;
      end else case(Timer[4:0])
         6: TXSET <= 1;
         8: TXSET <= 0;
         9: TXWT <= 1;
         11: TXWT <= 0;
         12: psCLK_gate <= 0;
         20: psCLK_gate <= 1;
         21: RXWT <= 1;
         23: RXWT <= 0;
      endcase
   always@(posedge I_CLK or negedge I_RSTn)
      if(! I_RSTn)
         psSEL <= 1;
      else if(O_SCAN_SEQ_PLS == 1)
         psSEL <= 0;
      else if((I_TYPE == 0)&&(Timer == 158))
         psSEL <= 1;
      else if((I_TYPE == 1)&&(Timer == 286))
         psSEL <= 1;
   always@(posedge I_CLK or negedge I_RSTn)
      if (!I_RSTn)
         O_byte_cnt <= 0;
      else if (O_SCAN_SEQ_PLS == 1)
         O_byte_cnt <= 0;
      else if (Timer[4:0] == 5'b11111) begin
         if(I_TYPE == 0 && O_byte_cnt == 5)
            O_byte_cnt <= O_byte_cnt;
         else if(I_TYPE == 1 && O_byte_cnt == 9)
            O_byte_cnt <= O_byte_cnt;
         else
            O_byte_cnt <= O_byte_cnt+1;
      end    
   assign O_psCLK = psCLK_gate | I_CLK | psSEL;
   assign O_psSEL = psSEL;
   assign O_RXWT  = ~psSEL&RXWT;
   assign O_TXSET = ~psSEL&TXSET;
   assign O_TXWT  = ~psSEL&TXWT;
   assign O_TXEN  = ~psSEL&(~psCLK_gate);
endmodule

module ps_rxd(
    input	I_CLK,I_RSTn,I_WT,
    input	I_psRXD,
    output	reg [7:0]O_RXD_DAT
);
    reg     [7:0]sp;
    always@(posedge I_CLK or negedge I_RSTn)
        if(! I_RSTn) sp <= 1;
        else         sp <= { I_psRXD, sp[7:1]};
    always@(posedge I_WT or negedge I_RSTn)
        if(! I_RSTn) O_RXD_DAT <= 1;
        else         O_RXD_DAT <= sp;
endmodule

module ps_txd(
    input	I_CLK,I_RSTn,
    input	I_WT,I_EN,
    input	[7:0]I_TXD_DAT,
    output	reg O_psTXD
);
    reg     [7:0]ps;
    always@(negedge I_CLK or negedge I_RSTn)
        if(! I_RSTn) begin 
            O_psTXD <= 1;
            ps      <= 0;
        end else if(I_WT) begin
            ps  <= I_TXD_DAT;
        end else if(I_EN) begin
            O_psTXD <= ps[0];
            ps      <= {1'b1, ps[7:1]};
        end else begin
            O_psTXD <= 1'd1;
            ps  <= ps;
        end
endmodule
