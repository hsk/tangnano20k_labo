`timescale 1 ns / 1 ps
package videoConfig;
  localparam WB=configPackage::VIDEO_X_BITWIDTH-1;
  localparam NB = 7;
  localparam N = 1<<NB;
endpackage
import videoConfig::*;
/* *******************************************************************
 * 位置のピクセルのRGBカラーを生成する。 (pixX,pixY).
 * RGBデータは1クロック・サイクルでレディになり、安定していなければならない (!)
 */
module gen_video(
  input clk, rst, [WB:0] pixX, frameWidth, [9:0] py, frameHeight,
  output reg [23:0] rgb);

  reg [NB-1:0] rspno; wire [7:0] rsx, rsy;
  reg [NB-1:0] wspno; reg  [7:0] wsx, wsy; reg wsp; 
  always@(posedge clk) begin
    if (py==720   && pixX<=N) begin
      rspno <= pixX;
      if(pixX>0) begin
        wspno <= rspno;
        wsx <= rsx + 1;
        wsy <= rsy + 1;
        wsp <= 1;
      end
    end else wsp <= 0;
  end
  
  wire [NB:0] spno; wire [7:0] sx, sy;
  SpriteRam sp_ram(clk,rspno,rsx,rsy,wspno,wsx,wsy,wsp,spno,sx,sy);
  wire [7:0] ptn_addr; wire [63:0] ptn;
  PatternRom pattern_rom(clk, ptn_addr[3:0], ptn);
  wire [3:0] pal; wire [23:0] c;
  PaletteRom pal_rom(pal,c);
  SpriteRender sp_render(clk,rst,pixX,frameWidth,py,frameHeight,pal,
                         spno,sx,sy,
                         ptn_addr,ptn);
  always@(posedge clk) begin
    rgb <= (pixX-256-4>=256*3) ? 0 : pal==0 ? 24'h00aa00 : c;// 非表示時
  end
endmodule

module SpriteRam(input clk,
                 input [NB-1:0] rspno, output [7:0] rsx,rsy,
                 input [NB-1:0] wspno, [7:0] wsx, wsy, input wsp,
                 input [NB-1:0]  spno, output [7:0] sx, sy); 
  initial begin
    integer i,x,y,c;
    x = 0; y = 0; c = 0;
    for (i=0;i<N;i++) begin
      spy[i] = 206-x;
      spx[i] = y;
      x = x + 18;
      if (x >= 18*10) begin
        x = c>>2;
        y = y + 18;
        c += 9;
      end
    end
  end
  reg [7:0] spx[N], spy[N];
  assign sx = spx[spno], sy = spy[spno];
  assign rsx = spx[rspno], rsy = spy[rspno];
  always @(posedge clk)
    if (wsp) begin spx[wspno] <= wsx; spy[wspno] <= wsy; end
endmodule

module PatternRom(input clk, [3:0] ptn_addr, output [63:0] ptn);
  initial begin
    mem['h00] = 64'h0000000330000000;
    mem['h01] = 64'h0000005443000000;
    mem['h02] = 64'h0000005223000000;
    mem['h03] = 64'h0000005213000000;
    mem['h04] = 64'h0000555213230000;
    mem['h05] = 64'h0000775213270000;
    mem['h06] = 64'h0000555363230000;
    mem['h07] = 64'h0005455443132000;
    mem['h08] = 64'h0057455443132300;
    mem['h09] = 64'h0574455443132730;
    mem['h0a] = 64'h5744455443132373;
    mem['h0b] = 64'h5744455663132373;
    mem['h0c] = 64'h5752455443132413;
    mem['h0d] = 64'h5752455443132413;
    mem['h0e] = 64'h5752401221032413;
    mem['h0f] = 64'h0050004433000400;
  end
  reg [0:63] mem[16];
  assign ptn = mem[ptn_addr];
endmodule

module PaletteRom(input [3:0] pal, output [23:0] c);
  initial begin
    mem['h00] = 24'h000000;
    mem['h01] = 24'h242424;
    mem['h02] = 24'h484848;
    mem['h03] = 24'h909090;
    mem['h04] = 24'hb4b4b4;
    mem['h05] = 24'hfcfcfc;
    mem['h06] = 24'hfc0000;
    mem['h07] = 24'h6c6cfc;
    mem['h08] = 24'h000000;
    mem['h09] = 24'h000000;
    mem['h0a] = 24'h000000;
    mem['h0b] = 24'h000000;
    mem['h0c] = 24'h000000;
    mem['h0d] = 24'h000000;
    mem['h0e] = 24'h000000;
    mem['h0f] = 24'h000000;
  end
  reg [23:0] mem[16];
  assign c = mem[pal];
endmodule

module LineRam(input clk,  w1, [3:0] d1, [8:0] p1, output [3:0] o1,input clr2, [8:0] p2, output [3:0] o2);
  reg [3:0] line[512];
  assign o1 = line[p1];
  assign o2 = line[p2];
  always @(posedge clk) begin
    if (w1) line[p1] <= d1;
    if (clr2) line[p2] <= 0;
  end
endmodule

module SpriteRender(
  input clk, rst, [WB:0] pixX, frameWidth, [9:0] py, frameHeight,
  output [3:0] pal,
  output [NB:0] spno, input [7:0] sx,sy,
  output [7:0] ptn_addr, input [63:0] ptn);

  wire w1; wire [3:0] o1, d1; wire [8:0] p1;
  wire clr2; wire [3:0] o2; wire [8:0] p2;
  LineRam line_ram(clk, w1, d1, p1, o1, clr2, p2, o2);

  wire [7:0] x, y; wire [1:0] xc,yc;
  GetXY getxy(clk, pixX, frameWidth, py, frameHeight, x, y, xc, yc);
  LineRender render(clk, pixX,frameWidth,yc,y, spno,sx,sy, ptn_addr,ptn, w1, d1, p1, o1);
  LineView view(clk, pixX, x, y, xc,yc, o2, clr2, p2, pal);
endmodule

module GetXY(input clk,
  input [WB:0] pixX, frameWidth,
  input [9:0] py, frameHeight,
  output reg [7:0] x, y, reg [1:0] xc,yc);
  always @(posedge clk) begin
    // x座標更新
    if (pixX==256-1) begin
      xc <= 0; x <= 0;
    end else if (xc == 2) begin
      xc <= 0; x <= x+1;
    end else xc <= xc + 1;
    // y座標更新
    if (pixX==frameWidth-1) begin
      if (py == frameHeight-2) begin
        yc <= 0; y <= 0;
      end else if (yc == 2) begin
        yc <= 0; y <= y+1;
      end else yc <= yc + 1;
    end
  end
endmodule

module LineRender(input clk, [WB:0] pixX, frameWidth, [1:0] yc, [7:0] y,
  output reg [NB:0] spno, input [7:0] sx,sy,
  output reg [7:0] ptn_addr, input [63:0] ptn,
  output reg w1, reg [3:0] d1, reg [8:0] p1, input [3:0] o1);
  reg [3:0] spbit; reg st;
  always @(posedge clk) begin
    // ラインバッファに書き込み
    if (yc == 2 && pixX==frameWidth-1) begin
      spno<=0; spbit<=0; w1 <= 0; st <= 0;
    end else if (spno[NB]==0) begin
      if (st<1) begin
        w1 = 0;
        ptn_addr = y - sy;
        if (ptn_addr < 16) begin
          st <= 1;
          p1 <= {!y[0], sx};
        end else begin
          spno <= spno + 1;
          spbit <= 0;
        end
      end else begin
        if (spbit == 15) begin
          spno <= spno + 1;
          st <= 0;
        end
        spbit <= spbit + 1;

        p1 <= {!y[0], sx + spbit};
        d1 = ptn>>(6'(4'(~spbit))<<2);
        w1 = (o1==0);
      end
    end
  end
endmodule

module LineView(input clk, [WB:0] pixX, [7:0] x, y, [1:0] xc,yc,
  [3:0] o2, output reg clr2, reg [8:0] p2, reg [3:0] pal);
  always @(posedge clk) begin
    if (pixX>=256) begin   // 表示
      p2 = {y[0],x};
      if (xc==0)        begin clr2 = 0; pal = o2; end
      else if(xc==2 && yc==2) clr2 = 1;
    end
  end
endmodule
