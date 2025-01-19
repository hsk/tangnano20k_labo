module gen_audio(
  input wire clk_27MHz,
  input wire I_clk_audio,
  input wire I_reset_n,
  output reg [15:0] sample
);
  wire clk_3_58MHz;
  clock_divider clock_divider(clk_27MHz, clk_3_58MHz);

  reg BDIR, BC, SEL=0, MODE=1;
  reg [7:0] DI, IOA_in=0, IOB_in=0;
  wire [7:0] DO,CHANNEL_A,CHANNEL_B,CHANNEL_C;
  wire [5:0] ACTIVE;
  wire [7:0] IOA_out,IOB_out;
  reg [15:0] ym2149_audio;
  reg psg_rst;
  YM2149 psg(clk_3_58MHz,1,psg_rst,BDIR,BC,DI,DO,
  CHANNEL_A,CHANNEL_B,CHANNEL_C,
  SEL,MODE,ACTIVE,IOA_in,IOA_out,IOB_in,IOB_out);

  // 演奏の管理
  reg [1:0] note = 2'd0; // 0:ド, 1:レ, 2:ミ
  reg [23:0] note_duration = 24'd0; // 各音符の持続時間を管理
  reg [7:0] state = 4'd0, nstate; // ステートマシン状態
  // 周波数テーブル（C4, D4, E4）
  reg [15:0] freq_table_a[2:0],freq_table_b[2:0],freq_table_c[2:0];
  initial begin
    // http://ngs.no.coocan.jp/doc/wiki.cgi/datapack?page=1%BE%CF+PSG%A4%C8%B2%BB%C0%BC%BD%D0%CE%CF
    // （C4-E4-G4）、（G4-B4-D5）、（A4-C5-E5）
    freq_table_a[0] = 16'h1ac; // C4
    freq_table_b[0] = 16'h153; // E4
    freq_table_c[0] = 16'h11d; // G4

    freq_table_a[1] = 16'h11d; // G4
    freq_table_b[1] = 16'h0e3; // B4
    freq_table_c[1] = 16'h0be; // D5

    freq_table_a[2] = 16'h0fe; // A4
    freq_table_b[2] = 16'h0d6; // C5
    freq_table_c[2] = 16'h0aa; // E5

    BDIR <= 0;
    BC <= 0;
    DI <= 0;
    note <= 0;
    note_duration <= 0;
    state <= 0;
    sample <= 0;
  end
  `define USE_PSG
  `ifdef USE_PSG
    always @(posedge I_clk_audio) begin
      sample <= ym2149_audio;
    end
  `else
    // 48kHzのオーディオクロックを想定した1kHzの正弦波
    //`define USE_SIN

    `ifdef USE_SIN
      wire [15:0] samples[47:0] = {
        16'd0, 16'd280, 16'd1116, 16'd2494, 16'd4390, 16'd6771, 16'd9597, 16'd12820,
        16'd16384, 16'd20228, 16'd24287, 16'd28490, 16'd32768, 16'd37045, 16'd41248, 16'd45307,
        16'd49152, 16'd52715, 16'd55938, 16'd58764, 16'd61145, 16'd63041, 16'd64419, 16'd65255,
        16'd65535, 16'd65255, 16'd64419, 16'd63041, 16'd61145, 16'd58764, 16'd55938, 16'd52715,
        16'd49152, 16'd45307, 16'd41248, 16'd37045, 16'd32768, 16'd28490, 16'd24287, 16'd20228,
        16'd16384, 16'd12820, 16'd9597, 16'd6771, 16'd4390, 16'd2494, 16'd1116, 16'd280
      };
    `else
      wire [15:0] samples[47:0] = {
        16'd0, 16'd0, 16'd0, 16'd0,   16'd0, 16'd0, 16'd0, 16'd0,
        16'd0, 16'd0, 16'd0, 16'd0,   16'd0, 16'd0, 16'd0, 16'd0,
        16'd0, 16'd0, 16'd0, 16'd0,   16'd0, 16'd0, 16'd0, 16'd0,
        16'h7fff,16'h7fff,16'h7fff,16'h7fff, 16'h7fff,16'h7fff,16'h7fff,16'h7fff,
        16'h7fff,16'h7fff,16'h7fff,16'h7fff, 16'h7fff,16'h7fff,16'h7fff,16'h7fff,
        16'h7fff,16'h7fff,16'h7fff,16'h7fff, 16'h7fff,16'h7fff,16'h7fff,16'h7fff
      };
    `endif
    reg [5:0] sample_idx = 6'd0;
    always@(posedge I_clk_audio)
      if (!I_reset_n) begin
        sample_idx <= 6'd0;
        sample <= 16'd0;
      end else begin
        sample <= samples[sample_idx];
        sample_idx <= (sample_idx == 'd47) ? 6'd0 : sample_idx + 1'b1;
      end
  `endif
  localparam INI=0, ENABLE1=1,ENABLE2=2;
  localparam FREQ11=3,FREQ12=4,FREQ13=5,FREQ14=6,VOL11=7,VOL12=8;
  localparam FREQ21=9,FREQ22=10,FREQ23=11,FREQ24=12,VOL21=13,VOL22=14;
  localparam FREQ31=15,FREQ32=16,FREQ33=17,FREQ34=18,VOL31=19,VOL32=20;
  localparam FIN=21,WAIT=22;
  always @(posedge clk_3_58MHz) begin
    if (!I_reset_n) begin
      BDIR <= 0;
      BC <= 0;
      DI <= 0;
      note <= 0;
      note_duration <= 0;
      state <= INI;
      ym2149_audio <= 0;
    end else begin
      case (state)
      INI: begin psg_rst <= 1; state <= state+1; end
      ENABLE1: // レジスタアドレス設定（ENABLE） 
      begin psg_rst <= 0; BDIR <= 1; BC <= 1; DI <= 4'h07; state <= state+1; end
      ENABLE2:
      begin BDIR <= 1; BC <= 0; DI <= 8'b11111000; state <= state+1; end
      FREQ11: // レジスタアドレス設定（周波数下位バイト）
      begin BDIR <= 1; BC <= 1; DI <= 4'h00; state <= state+1; end
      FREQ12: // データ書き込み（周波数下位バイト） wrtpsg( 0, 0xac )
      begin BDIR <= 1; BC <= 0; DI <= freq_table_a[note][7:0]; state <= state+1; end
      FREQ13: // レジスタアドレス設定（周波数上位バイト）
      begin BDIR <= 1; BC <= 1; DI <= 8'h01; state <= state+1; end
      FREQ14: // データ書き込み（周波数上位バイト）wrtpsg( 0, 1 )
      begin BDIR <= 1; BC <= 0; DI <= freq_table_a[note][15:8]; state <= state+1; end
      VOL11: // 音量設定     wrtpsg( 8, 0);
      begin BDIR <= 1; BC <= 1; DI <= 8'h08; state <= state+1; end
      VOL12: // データ書き込み（音量は最大で固定）
      begin BDIR <= 1; BC <= 0; DI <= 8'h0f; state <= state+1; end


      FREQ21: // レジスタアドレス設定（周波数下位バイト）
      begin BDIR <= 1; BC <= 1; DI <= 4'h02; state <= state+1; end
      FREQ22: // データ書き込み（周波数下位バイト） wrtpsg( 0, 0xac )
      begin BDIR <= 1; BC <= 0; DI <= freq_table_b[note][7:0]; state <= state+1; end
      FREQ23: // レジスタアドレス設定（周波数上位バイト）
      begin BDIR <= 1; BC <= 1; DI <= 8'h03; state <= state+1; end
      FREQ24: // データ書き込み（周波数上位バイト）wrtpsg( 0, 1 )
      begin BDIR <= 1; BC <= 0; DI <= freq_table_b[note][15:8]; state <= state+1; end
      VOL21: // 音量設定     wrtpsg( 9, 0);
      begin BDIR <= 1; BC <= 1; DI <= 8'h09; state <= state+1; end
      VOL22: // データ書き込み（音量は最大で固定）
      begin BDIR <= 1; BC <= 0; DI <= 8'h0f; state <= state+1; end

      FREQ31: // レジスタアドレス設定（周波数下位バイト）
      begin BDIR <= 1; BC <= 1; DI <= 4'h04; state <= state+1; end
      FREQ32: // データ書き込み（周波数下位バイト） wrtpsg( 0, 0xac )
      begin BDIR <= 1; BC <= 0; DI <= freq_table_c[note][7:0]; state <= state+1; end
      FREQ33: // レジスタアドレス設定（周波数上位バイト）
      begin BDIR <= 1; BC <= 1; DI <= 8'h05; state <= state+1; end
      FREQ34: // データ書き込み（周波数上位バイト）wrtpsg( 0, 1 )
      begin BDIR <= 1; BC <= 0; DI <= freq_table_c[note][15:8]; state <= state+1; end
      VOL31: // 音量設定     wrtpsg( 10, 0);
      begin BDIR <= 1; BC <= 1; DI <= 8'h0a; state <= state+1; end
      VOL32: // データ書き込み（音量は最大で固定）
      begin BDIR <= 1; BC <= 0; DI <= 8'h0f; state <= state+1; end

      FIN: begin // 書き込み完了
        BDIR <= 0; BC <= 0;
        // 音符の持続時間を管理
        if (note_duration == 9000000) begin // 約1秒 (3.58MHzのクロックで)
          note_duration <= 0;
          note <= note == 2 ? 0 : note + 1; // 3つの音符をループ
          state <= FREQ11;
        end else
          note_duration <= note_duration + 1;
      end
      WAIT: begin
        if (note_duration == 100) begin // 約1秒 (3.58MHzのクロックで)
          note_duration <= 0;
          state <= nstate;
        end else
          note_duration <= note_duration + 1;
      end
      endcase
      ym2149_audio <= {3'd0,CHANNEL_A,CHANNEL_A[7:3]}
                    + {3'd0,CHANNEL_B,CHANNEL_B[7:3]}
                    + {3'd0,CHANNEL_C,CHANNEL_C[7:3]};
    end
  end


endmodule
 
// クロック分周モジュール
module clock_divider (input wire clk27MHz, output reg clk3_375MHz = 0);
  reg [1:0] counter = 0;
  always @(posedge clk27MHz) begin
    if (counter == 5'd3) clk3_375MHz <= ~clk3_375MHz; // 27MHz / 8 = 3.375MHz (3.58MHzに近づける)
    counter <= counter + 1;
  end
endmodule
