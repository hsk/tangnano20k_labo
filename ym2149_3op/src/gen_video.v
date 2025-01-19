module gen_video(
  input wire I_clk_pixel,
  input wire I_reset_n,
  input [VIDEO_X_BITWIDTH-1:0] pixX,
  input [VIDEO_Y_BITWIDTH-1:0] pixY,
  input [VIDEO_X_BITWIDTH-1:0] screenWidth,
  input [VIDEO_Y_BITWIDTH-1:0] screenHeight,
  input [15:0] sample,
  output reg [23:0] rgb
);
  always@(posedge I_clk_pixel)
    if (!I_reset_n)
      rgb <= 24'd0;
    else
//      rgb <= {pixX[7:0],pixY[7:0],pixY[7:0]};
      rgb <= {8'd0,sample};
endmodule
