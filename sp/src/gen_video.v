/* *******************************************************************
 * 位置のピクセルのRGBカラーを生成する。 (pixX,pixY).
 * RGBデータは1クロック・サイクルでレディになり、安定していなければならない (!)
 */
import configPackage::*;

module gen_video(
  input wire I_clk_pixel,
  input wire I_reset_n,
  input [VIDEO_X_BITWIDTH-1:0] pixX,
  input [VIDEO_Y_BITWIDTH-1:0] pixY,
  input [VIDEO_X_BITWIDTH-1:0] screenWidth,
  input [VIDEO_Y_BITWIDTH-1:0] screenHeight,
  input [VIDEO_X_BITWIDTH-1:0] frameWidth,
  input [VIDEO_Y_BITWIDTH-1:0] frameHeight,
  output wire [23:0] rgb
);

  wire [8:0] vpos = pixY[9:1];
  wire [8:0] hpos = pixX[VIDEO_X_BITWIDTH-1:VIDEO_X_BITWIDTH-1-8];

  always @(posedge I_clk_pixel) if (pixX==0 && pixY == 0) begin
    player_x += 1;
    player_y += 1;
  end

  // start Y counter when we hit the top border (player_y)
  reg [3:0] sprite_y;
  reg [8:0] player_y = 128;
  always @(posedge I_clk_pixel) if (pixX==0 && pixY[0] == 0) begin
    if (vpos == player_y)   sprite_y <= 15;
    else if (sprite_y != 0) sprite_y <= sprite_y - 1;
  end
  
  // restart X counter when we hit the left border (player_x)
  reg [3:0] sprite_x;
  reg [8:0] player_x = 128;
  always @(posedge I_clk_pixel) if (pixX[0]==0) begin
    if (hpos == player_x)   sprite_x <= 15;
    else if (sprite_x != 0) sprite_x <= sprite_x - 1;
  end
  // mirror sprite in X direction
  wire [3:0] bitx = sprite_x>=8 ? 15-sprite_x: sprite_x;
  wire [7:0] sprite_bits;
  car_bitmap car(.yofs(sprite_y), .bits(sprite_bits));
  wire l = sprite_bits[bitx[2:0]];
  reg [23:0] rgb_r;
  // Video generation
  always@(posedge I_clk_pixel, negedge I_reset_n) begin
    if (!I_reset_n)       rgb_r <= 24'd0;
    else if (l)           rgb_r <= 24'hffffff;
    else if (sprite_y!=0) rgb_r <= 24'hff00ff;
    else if (sprite_x!=0) rgb_r <= 24'h0000ff;
    else                  rgb_r <= {pixX[7:0],pixY[7:0],8'd0};
  end
  assign rgb = rgb_r;
endmodule

module car_bitmap(input [3:0] yofs, output [7:0] bits);
  reg [7:0] bitarray[0:15];
  assign bits = bitarray[yofs];
  // 車体の半分 上が前方
  initial begin/*{w:8,h:16}*/
    bitarray[0]  = 8'b00000000;
    bitarray[1]  = 8'b00001100;
    bitarray[2]  = 8'b11001100;
    bitarray[3]  = 8'b11111100;
    bitarray[4]  = 8'b11101100;
    bitarray[5]  = 8'b11100000;
    bitarray[6]  = 8'b01100000;
    bitarray[7]  = 8'b01110000;
    bitarray[8]  = 8'b00110000;
    bitarray[9]  = 8'b00110000;
    bitarray[10] = 8'b00110000;
    bitarray[11] = 8'b01101110;
    bitarray[12] = 8'b11101110;
    bitarray[13] = 8'b11111110;
    bitarray[14] = 8'b11101110;
    bitarray[15] = 8'b00101110;
  end
endmodule
