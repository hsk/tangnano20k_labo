module gen_video(
  input wire clk,
  input wire rst,
  input [VIDEO_X_BITWIDTH-1:0] x1,
  input [VIDEO_Y_BITWIDTH-1:0] y1,
  input [VIDEO_X_BITWIDTH-1:0] frameWidth,
  input [VIDEO_Y_BITWIDTH-1:0] frameHeight,
  input wire rxd,
  output [23:0] rgb
);
  // 通信で書き込みアドレスとデータを取得する
  wire [7:0] b_w_wd; wire [15:0] b_w_ad; wire b_w_en;
  UART uart(clk, rst, rxd, b_w_wd, b_w_ad, b_w_en);
  // フレームバッファ
  wire [7:0] b_r_rd; wire [15:0] b_r_ad;
  FrameBuffer buffer(
    .clk(clk),
    .b_w_wd(b_w_wd), .b_w_ad(b_w_ad), .b_w_en(b_w_en),
    .b_r_rd(b_r_rd), .b_r_ad(b_r_ad));
  // 色を取得
  VideoRenderer renderer(
    clk, rst, x1, frameWidth, y1, frameHeight,
    b_r_ad, b_r_rd, rgb);
endmodule

module UART(
  input clk, rst, rxd,
  output reg [7:0]  b_w_wd,
  output reg [15:0] b_w_ad,
  output reg        b_w_en
);
  wire [7:0] DATA; // データ（ASCIIコードの文字）
  wire FLAG;
  // Serial受信
  Serial_rx r0(.CLK(clk),.RST(rst), .RXD(rxd), .FLAG(FLAG), .receivedChar(DATA));
  wire [7:0] o_data; // データ（ASCIIコードの文字）
  wire flag;
  reg busy = 0;
  localparam ST_MODE = 0, ST_DATA = 1, ST_ADDR1 = 2, ST_ADDR2 = 3;
  reg [2:0] state = ST_MODE;
  COBS_decoder dec(.clk(clk), .rst(rst), .rxd(rxd), .flag(FLAG), .busy(busy), .data(DATA),
               .o_flag(flag), .o_data(o_data));
  always @(posedge clk) begin
    if (DATA==0) begin
      state = ST_MODE;
    end
    if (flag && b_w_en==0) begin
      if (state == ST_MODE) begin // モード入力状態
        state <= 3'(o_data); // モードを設定
      end else if (state == ST_DATA) begin // データ入力モード
        busy <= 1;
        b_w_en <= 1;
        b_w_wd <= o_data;
      end else if (state == ST_ADDR1) begin// アドレス入力モード1 (下位バイト)
        b_w_ad[7:0] <= o_data;
        state <= ST_ADDR2;
      end else if (state == ST_ADDR2) begin// アドレス入力モード2 (上位バイト)
        b_w_ad[15:7] <= o_data;
        state <= ST_ADDR1;
      end
    end else if (flag==0 && b_w_en) begin
      busy <= 0;
      if (state == ST_DATA) begin
        b_w_en <= 0;
        b_w_ad <= b_w_ad + 16'd1;
      end
    end
  end
endmodule

module FrameBuffer(
  input clk,
  input b_w_en, [15:0] b_w_ad, [7:0] b_w_wd,
  input [15:0] b_r_ad, output [7:0] b_r_rd
);
  reg [7:0] mem [0:65535];
  always @(posedge clk) if (b_w_en) mem[b_w_ad] = b_w_wd;
  assign b_r_rd = mem[b_r_ad];
endmodule

/*
module VideoRenderer0(
  input clk, rst, [VIDEO_X_BITWIDTH-1:0] x1, frameWidth, [9:0] y1, frameHeight,
  output [15:0] b_r_ad, input [7:0] b_r_rd,
  output [23:0] rgb);
  assign b_r_ad = {y1[9:2],x1[9:2]};
  assign col = b_r_rd;
  // 24bit色を取得
  assign rgb = {col[7:5],col[7:5],col[7:6],
                col[4:2],col[4:2],col[4:3],
                col[1:0],col[1:0],col[1:0],col[1:0]};
endmodule
*/

module VideoRenderer(
  input clk, rst, [VIDEO_X_BITWIDTH-1:0] x1, frameWidth, [9:0] y1, frameHeight,
  output [15:0] b_r_ad, input [7:0] b_r_rd,
  output [23:0] rgb);
  // x,y座標を求める
  wire [7:0] x, y; wire [1:0] xc,yc;
  GetXY getxy(clk, x1, frameWidth, y1, frameHeight, x, y, xc, yc);
  // ラインの描画
  wire lb_w_en; wire [7:0] lb_w_wd; wire [8:0] lb_w_ad;
  LineRenderer render(
    clk, x1,y,yc,
    b_r_ad, b_r_rd,
    lb_w_en, lb_w_ad, lb_w_wd);
  // ラインバッファ
  wire [7:0] lb_r_rd; wire [8:0] lb_r_ad;
  LineBuffer buffer(clk, lb_w_en, lb_w_ad, lb_w_wd, lb_r_ad, lb_r_rd);
  // ラインの描画 8bit色を取得
  wire [7:0] col;
  LineView view(clk, x1, y1, x, y, lb_r_ad, lb_r_rd, col);
  // 24bit色を取得
  assign rgb = {col[7:5],col[7:5],col[7:6],
                col[4:2],col[4:2],col[4:3],
                col[1:0],col[1:0],col[1:0],col[1:0]};
endmodule

module GetXY(input clk,
  input [VIDEO_X_BITWIDTH-1:0] x1, [VIDEO_X_BITWIDTH-1:0] frameWidth,
  input [VIDEO_Y_BITWIDTH-1:0] y1, [VIDEO_Y_BITWIDTH-1:0] frameHeight,
  output reg [7:0] x, reg [7:0] y, reg [1:0] xc, reg [1:0] yc);
  always @(posedge clk) begin
    // x座標更新
    if (x1==256-1) begin
      xc <= 0; x <= 0;
    end else if (xc == 2) begin
      xc <= 0; x <= x + 8'd1;
    end else xc <= xc + 2'd1;
    // y座標更新
    if (x1==frameWidth-1) begin
      if (y1 == 72-1) begin
        yc <= 0; y <= 0;
      end else if (yc == 2) begin
        yc <= 0; y <= y + 8'd1;
      end else yc <= yc + 2'd1;
    end
  end
endmodule

// ラインバッファに描画する
module LineRenderer(input clk, [VIDEO_X_BITWIDTH-1:0] x1, [7:0] y, [1:0] yc,
  output reg [15:0] b_r_ad, input [7:0] b_r_rd,
  output reg lb_w_en, reg [8:0] lb_w_ad, reg [7:0] lb_w_wd);
  always @(posedge clk) begin
    if (yc == 0 && x1 < 256) begin
      // ラインバッファに書き込み
      b_r_ad = {y,x1[7:0]}; // バッファアドレスを指定し
      lb_w_wd <= b_r_rd; // バッファから読み込んだデータをラインバッファに書き込む
      lb_w_ad <= {!y[0], x1[7:0]}; // ラインバッファのアドレス
      lb_w_en <= 1; // 書き込み ON
    end else lb_w_en <= 0;
  end
endmodule

// 表示エリアないならラインバッファから読み出して表示する。
module LineView(input clk, [VIDEO_X_BITWIDTH-1:0] x1, [VIDEO_Y_BITWIDTH-1:0] y1, [7:0] x, y,
  output reg [8:0] lb_r_ad, input [7:0] lb_r_rd,
  output reg [7:0] col);
  always @(posedge clk) begin
    if (256 <= x1 && x1 < 256*4 && 72 <= y1 && y1 < 72+192*3) begin   // 表示エリアなら
      lb_r_ad = {y[0],x}; // ラインバッファの読み込みのアドレス
      col = lb_r_rd; // ラインバッファの色を読み込む
    end else col = 0;
  end
endmodule

module LineBuffer(
  input        clk,
  input        lb_w_en, // 書き込みフラグ
         [8:0] lb_w_ad, // 書き込みアドレス
         [7:0] lb_w_wd, // 書き込みデータ
  input  [8:0] lb_r_ad, // 読み込みアドレス
  output [7:0] lb_r_rd  // 読み込みデータ
);
  reg [7:0] line[512]; // ラインバッファ 256ドット*2ライン
  assign lb_r_rd = line[lb_r_ad]; // 読み込み
  always @(posedge clk) if (lb_w_en) line[lb_w_ad] <= lb_w_wd; // 書き込み
endmodule

