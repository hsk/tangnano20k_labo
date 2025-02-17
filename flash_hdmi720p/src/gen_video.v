module gen_video(
  input wire clk,
  input wire rst,
  input [VIDEO_X_BITWIDTH-1:0] x1,
  input [VIDEO_Y_BITWIDTH-1:0] y1,
  output [23:0] rgb,
  output mspio[2], inout mspid[2]
);
  wire [7:0] bw; wire [15:0] bw_a; wire bw_e;
  LoadFromFlash loader(clk, bw, bw_a, bw_e, mspio, mspid);
  wire [7:0] b; wire [15:0] b_a;
  FrameBuffer buffer(clk, bw_e, bw_a, bw, b_a, b);
  VideoRenderer renderer(clk, x1, y1, b_a, b, rgb);
endmodule

module FrameBuffer(
  input clk, bw_e, [15:0] bw_a, [7:0] bw, [15:0] b_a, output [7:0] b);
  reg [7:0] mem [0:65535];
  always @(posedge clk) if (bw_e) mem[bw_a] = bw;
  assign b = mem[b_a];
endmodule

module VideoRenderer(
  input clk, [VIDEO_X_BITWIDTH-1:0] x1, [9:0] y1,
  output [15:0] b_a, input [7:0] b, output [23:0] rgb);
  wire lw_e; wire [7:0] lw; wire [8:0] lw_a;
  wire [7:0] l; wire [8:0] l_a;
  LineBuffer buffer(clk, lw_e, lw_a, lw, l_a, l);
  wire [7:0] x, y; wire [1:0] yc;
  GetXY getxy(clk, x1, y1, x, y, yc);
  LineRenderer render(clk, x1,y,yc, b_a, b, lw_e, lw_a, lw);
  wire [7:0] col;
  LineView view(clk, x1, y1, x, y, l_a, l, col);
  assign rgb = {col[7:5],col[7:5],col[7:6],
                col[4:2],col[4:2],col[4:3],
                col[1:0],col[1:0],col[1:0],col[1:0]};
endmodule

module GetXY(input clk,
  input [VIDEO_X_BITWIDTH-1:0] x1,
  input [VIDEO_Y_BITWIDTH-1:0] y1,
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
    if (x1==TOTALWIDTH-1) begin
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
  output reg [15:0] b_a, input [7:0] b,
  output reg lw_e, reg [8:0] lw_a, reg [7:0] lw);
  always @(posedge clk) begin
    if (yc == 0 && x1 < 256 && y < 192)
      b_a <= {y,x1[7:0]}; // バッファアドレスを指定
    // ラインバッファに書き込み
    if (yc == 0 && 1 <= x1 && x1 < 256+1 && y < 192) begin
      lw_e <= 1; // 書き込み ON
      lw <= b; // バッファから読み込んだデータをラインバッファに書き込む
      lw_a <= {!y[0], x1[7:0]-8'd1}; // ラインバッファのアドレス
    end else lw_e <= 0;
  end
endmodule

// 表示エリアないならラインバッファから読み出して表示する。
module LineView(input clk, [VIDEO_X_BITWIDTH-1:0] x1, [VIDEO_Y_BITWIDTH-1:0] y1, [7:0] x, y,
  output [8:0] l_a, input [7:0] l, output [7:0] col);
  wire view;
  assign view = 256 <= x1 && x1 < 256*4 && 72 <= y1 && y1 < 72+192*3; // 表示エリアなら
  assign l_a = {y[0],x}; // ラインバッファの読み込みのアドレス
  assign col = view ? l : 7; // ラインバッファの色を読み込む
endmodule

module LineBuffer(input clk, lw_e, [8:0] lw_a, [7:0] lw, [8:0] l_a, output [7:0] l);
  reg [7:0] mem[512]; // ラインバッファ 256ドット*2ライン
  assign l = mem[l_a]; // 読み込み
  always @(posedge clk) if (lw_e) mem[lw_a] <= lw; // 書き込み
endmodule
