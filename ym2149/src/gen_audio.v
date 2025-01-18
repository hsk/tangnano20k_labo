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
  reg [3:0] state = 4'd0, nstate; // ステートマシン状態
  // 周波数テーブル（C4, D4, E4）
  reg [15:0] freq_table[2:0];
  initial begin
    freq_table[0] = 16'h1ac;
    freq_table[1] = 16'h17d; // 約293.66 Hz (D4)
    freq_table[2] = 16'h153; // 約329.63 Hz (E4)

    BDIR <= 0;
    BC <= 0;
    DI <= 0;
    note <= 0;
    note_duration <= 0;
    state <= 0;
    sample <= 0;
  end
  /*
  // 48kHzのオーディオクロックを想定した1kHzの正弦波
  wire [15:0] samples[47:0] = {
    16'd0, 16'd280, 16'd1116, 16'd2494, 16'd4390, 16'd6771, 16'd9597, 16'd12820,
    16'd16384, 16'd20228, 16'd24287, 16'd28490, 16'd32768, 16'd37045, 16'd41248, 16'd45307,
    16'd49152, 16'd52715, 16'd55938, 16'd58764, 16'd61145, 16'd63041, 16'd64419, 16'd65255,
    16'd65535, 16'd65255, 16'd64419, 16'd63041, 16'd61145, 16'd58764, 16'd55938, 16'd52715,
    16'd49152, 16'd45307, 16'd41248, 16'd37045, 16'd32768, 16'd28490, 16'd24287, 16'd20228,
    16'd16384, 16'd12820, 16'd9597, 16'd6771, 16'd4390, 16'd2494, 16'd1116, 16'd280
  };
  reg [5:0] sample_idx = 6'd0;
  always@(posedge I_clk_audio)
    if (!I_reset_n) begin
      sample_idx <= 6'd0;
      sample <= 16'd0;
    end else begin
      sample <= samples[sample_idx];
      sample_idx <= (sample_idx == 'd47) ? 6'd0 : sample_idx + 1'b1;
    end
  */
  always @(posedge I_clk_audio) begin
    sample <= ym2149_audio;
  end
  localparam INI = 0, ENABLE1=9,ENABLE2=10,FREQ11=1,FREQ12=2,FREQ21=3,FREQ22=4,VOL1=5,VOL2=6,FIN=7,WAIT=8;
  always @(posedge clk_3_58MHz) begin
    if (!I_reset_n) begin
      BDIR <= 0;
      BC <= 0;
      DI <= 0;
      note <= 0;
      note_duration <= 0;
      state <= 0;
      ym2149_audio <= 0;
    end else begin
      case (state)
      INI: begin psg_rst <= 1; nstate <= ENABLE1;state<=WAIT; end
      ENABLE1: // レジスタアドレス設定（ENABLE） 
      begin psg_rst <= 0; BDIR <= 1; BC <= 1; DI <= 4'h07; nstate <= ENABLE2;state<=WAIT; end
      ENABLE2:
      begin BDIR <= 1; BC <= 0; DI <= 8'b11111110; nstate <= FREQ11;state<=WAIT; end
      FREQ11: // レジスタアドレス設定（周波数下位バイト）
      begin BDIR <= 1; BC <= 1; DI <= 4'h00; nstate <= FREQ12;state<=WAIT; end
      FREQ12: // データ書き込み（周波数下位バイト） wrtpsg( 0, 0xac )
      begin BDIR <= 1; BC <= 0; DI <= freq_table[note][7:0]; nstate <= FREQ21;state<=WAIT; end
      FREQ21: // レジスタアドレス設定（周波数上位バイト）
      begin BDIR <= 1; BC <= 1; DI <= 8'h01; nstate <= FREQ22;state<=WAIT; end
      FREQ22: // データ書き込み（周波数上位バイト）wrtpsg( 0, 1 )
      begin BDIR <= 1; BC <= 0; DI <= freq_table[note][15:8]; nstate <= VOL1;state<=WAIT; end
      VOL1: // 音量設定     wrtpsg( 8, 0);
      begin BDIR <= 1; BC <= 1; DI <= 8'h08; nstate <= VOL2;state<=WAIT; end
      VOL2: // データ書き込み（音量は最大で固定）
      begin BDIR <= 1; BC <= 0; DI <= 8'h0f; nstate <= FIN;state<=WAIT; end
      FIN: begin // 書き込み完了
        BDIR <= 0; BC <= 0;
        // 音符の持続時間を管理
        if (note_duration == 3000000) begin // 約1秒 (3.58MHzのクロックで)
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
      ym2149_audio <= {1'b0,CHANNEL_A,CHANNEL_A[7:1]};
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
