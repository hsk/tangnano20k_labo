module gen_video(
  input wire clk,
  input wire rst,
  input [VIDEO_X_BITWIDTH-1:0] sx,
  input [VIDEO_Y_BITWIDTH-1:0] sy,
  output [23:0] rgb,
  output mspio[2], inout mspid[2]
);
  wire fl_e; wire [22:0] fl_a; wire [15:0] fl; wire busy;
  reg rstn=0;
  always@(posedge clk) rstn<=1;
  flash flash(
      .clk(clk), .rstn(rstn),
      .fl_a(fl_a), .fl_e(fl_e), .fl(fl),
      .mspio(mspio), .mspid(mspid), .busy(busy));
  wire lw_e; wire [7:0] lw; wire [8:0] lw_a;
  wire [7:0] l; wire [8:0] l_a;
  LineBuffer buffer(clk, lw_e, lw_a, lw, l_a, l);
  wire [7:0] x, y; wire [1:0] yc;
  GetXY getxy(clk, sx, sy, x, y, yc);
  LineRenderer render(clk, sx,y,yc, fl_e, fl_a, fl, lw_e, lw_a, lw,busy|~rstn);
  wire [7:0] col;
  LineView view(clk, sx, sy, x, y, l_a, l, col);
  assign rgb = {col[7:5],col[7:5],col[7:6],
                col[4:2],col[4:2],col[4:3],
                col[1:0],col[1:0],col[1:0],col[1:0]};
endmodule

module GetXY(input clk,
  input [VIDEO_X_BITWIDTH-1:0] sx,
  input [VIDEO_Y_BITWIDTH-1:0] sy,
  output reg [7:0] x, reg [7:0] y, reg [1:0] yc);
  reg [1:0] xc;
  always @(posedge clk) begin
    // x座標更新
    if (sx==256-1) begin
      xc <= 0; x <= 0;
    end else if (xc < 2) xc <= xc + 2'd1;
    else begin
      xc <= 0; x <= x + 8'd1;
    end
    // y座標更新
    if (sx==TOTALWIDTH-1) begin
      if (sy == 72-3-1) begin
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
module LineRenderer(input clk, [VIDEO_X_BITWIDTH-1:0] sx, [7:0] y, [1:0] yc,
  output reg fl_e, output reg [22:0] fl_a, input [15:0] fl,
  output reg lw_e, reg [8:0] lw_a, reg [7:0] lw, input busy);
  reg [12:0] x;
  always @(posedge clk) begin
    if (yc == 2 && sx == TOTALWIDTH-1) x <= 0;
    else x <= x+12'd1;
    if (x[12]==0) begin
      if (x[4:0]==0) begin
        if(!busy)fl_e <= 1;
        fl_a <= {y,x[11:5],1'd0}+23'h100000; // バッファアドレスを指定
      end else fl_e <= 0;
      // ラインバッファに書き込み
      if (x[4:0]==31) begin
        lw_e <= 1; // 書き込み ON
        lw <= fl[15:8]; // バッファから読み込んだデータをラインバッファに書き込む
        lw_a <= {!y[0], x[11:5],1'd0}; // ラインバッファのアドレス
      end else if (x[4:0]==0) begin
        lw <= fl[7:0]; // バッファから読み込んだデータをラインバッファに書き込む
        lw_a <= lw_a+1; // ラインバッファのアドレス
      end else lw_e <= 0;
    end
  end
endmodule

// 表示エリアないならラインバッファから読み出して表示する。
module LineView(input clk, [VIDEO_X_BITWIDTH-1:0] sx, [VIDEO_Y_BITWIDTH-1:0] sy, [7:0] x, y,
  output [8:0] l_a, input [7:0] l, output [7:0] col);
  wire view;
  assign view = 256 <= sx && sx < 256*4 && 72 <= sy && sy < 72+192*3; // 表示エリアなら
  assign l_a = {y[0],x}; // ラインバッファの読み込みのアドレス
  assign col = view ? l : 7; // ラインバッファの色を読み込む
endmodule

module LineBuffer(input clk, lw_e, [8:0] lw_a, [7:0] lw, [8:0] l_a, output [7:0] l);
  reg [7:0] mem[512]; // ラインバッファ 256ドット*2ライン
  assign l = mem[l_a];
  always @(posedge clk) if (lw_e) mem[lw_a] = lw;
endmodule
