module top(input clk, rst, output [3:0] tmdsp, tmdsn);
    wire [9:0] sx, sy; wire [23:0] rgb;
    video video(clk, sx, sy, rgb);
    wire clk5x, hsync, vsync, de;
    hdmi_vga vga(clk,rst,rgb,clk5x, hsync, vsync, de, sx, sy, tmdsp, tmdsn);
endmodule

module video(input clk, [9:0] x, y, output reg [23:0] rgb);
  wire [7:0] vram_rd;
  VRAM vram(clk,11'd40*y[9:4]+x[9:4],vram_rd);
  wire [10:0] chr_ad; wire [7:0] chr_rd;
  assign chr_ad = {vram_rd,y[3:1]};
  CharROM rom(chr_ad, chr_rd);
  always@(posedge clk)
      rgb <= chr_rd[~x[3:1]] ? 24'hffffff : 24'h0000ff;
endmodule

module CharROM(input [10:0] chr_ad, output [7:0] chr_rd);
  reg [7:0] mem[256*8];
  assign chr_rd = mem[chr_ad];
  initial $readmemb("font.txt", mem);
endmodule

module VRAM(input clk, [10:0] vram_ad, output [7:0] vram_rd);
  reg [7:0] mem[1240];
  assign vram_rd = mem[vram_ad];
  initial begin
    integer i,j;
    for (i=0,j=0;i<40*30;i++) begin
      mem[i] = j+'h2f;
      j = j == 9 ? 0 : j+1;
    end
  end
endmodule
