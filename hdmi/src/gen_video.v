/* *******************************************************************
 * Generate RGB color for pixel at position (x,y).
 * RGB data must be ready and stable in 1 clock cycle (!)
*/
module gen_video(
  input wire clk,
  input wire rst,
  input [VIDEO_X_BITWIDTH-1:0] x1,
  input [VIDEO_Y_BITWIDTH-1:0] y1,
  output reg [23:0] rgb
);
  wire [VIDEO_X_BITWIDTH-1:0] x = x1-10'd104;
  wire [VIDEO_Y_BITWIDTH-1:0] y = y1-10'd16;
  wire de = x < 512 && y < 448;

  // Video generation
  always@(posedge clk) begin
    if (!rst)
      rgb <= 12'd0;
    else if (de) begin
      rgb <= {x[7:0],8'h00,y[7:0]};
    end else rgb <= 0;
  end

endmodule
