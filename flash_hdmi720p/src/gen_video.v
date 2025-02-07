module gen_video(
  input wire clk,
  input wire rst,
  input [VIDEO_X_BITWIDTH-1:0] x1,
  input [VIDEO_Y_BITWIDTH-1:0] y1,
  output [23:0] rgb,
  output mspi_cs, mspi_clk, inout mspi_di, mspi_do
);
  wire [7:0] b_w_wd; wire [15:0] b_w_ad; wire b_w_en;
  LoadFromFlash loader(clk,rst,
    b_w_wd, b_w_ad, b_w_en,
    mspi_cs, mspi_clk, mspi_di, mspi_do);
  // フレームバッファ
  wire [7:0] b_r_rd; wire [15:0] b_r_ad;
  FrameBuffer buffer(
    .clk(clk),
    .b_w_wd(b_w_wd), .b_w_ad(b_w_ad), .b_w_en(b_w_en),
    .b_r_rd(b_r_rd), .b_r_ad(b_r_ad));
  // 色を取得
  VideoRenderer renderer(
    clk, rst, x1, TOTALWIDTH, y1, TOTALHEIGHT,
    b_r_ad, b_r_rd, rgb);
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
  wire [7:0] x, y; wire [1:0] yc;
  GetXY getxy(clk, x1, frameWidth, y1, frameHeight, x, y, yc);
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
  output reg [7:0] x, reg [7:0] y, reg [1:0] yc);
  reg [1:0] xc;
  always @(posedge clk) begin
    // x座標更新
    if (x1==256-1) begin
      xc <= 0; x <= 0;
    end else if (xc < 2) xc <= xc + 2'd1;
    else begin
      xc <= 0; x <= x + 8'd1;
    end
    // y座標更新
    if (x1==frameWidth-1) begin
      if (y1 == 72-3-1) begin
        yc <= 0; y <= 0;
      end else if (yc < 2)
        yc <= yc + 2'd1;
      else begin
        yc <= 0; y <= y + 8'd1;
      end
    end
  end
endmodule

// ラインバッファに描画する
module LineRenderer(input clk, [VIDEO_X_BITWIDTH-1:0] x1, [7:0] y, [1:0] yc,
  output reg [15:0] b_r_ad, input [7:0] b_r_rd,
  output reg lb_w_en, reg [8:0] lb_w_ad, reg [7:0] lb_w_wd);
  always @(posedge clk) begin
    if (yc == 0 && x1 < 256 && y < 192)
      b_r_ad <= {y,x1[7:0]}; // バッファアドレスを指定し
    // ラインバッファに書き込み
    if (yc == 0 && 1 <= x1 && x1 < 256+1 && y < 192) begin
      lb_w_en <= 1; // 書き込み ON
      lb_w_wd <= b_r_rd; // バッファから読み込んだデータをラインバッファに書き込む
      lb_w_ad <= {!y[0], x1[7:0]-8'd1}; // ラインバッファのアドレス
    end else lb_w_en <= 0;
  end
endmodule

// 表示エリアないならラインバッファから読み出して表示する。
module LineView(input clk, [VIDEO_X_BITWIDTH-1:0] x1, [VIDEO_Y_BITWIDTH-1:0] y1, [7:0] x, y,
  output [8:0] lb_r_ad, input [7:0] lb_r_rd,
  output [7:0] col);
  wire view;
  assign view = 256 <= x1 && x1 < 256*4 && 72 <= y1 && y1 < 72+192*3; // 表示エリアなら
  assign lb_r_ad = {y[0],x}; // ラインバッファの読み込みのアドレス
  assign col = view ? lb_r_rd : 7; // ラインバッファの色を読み込む
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
