// 下のテストベンチは27MHzのiClkをシミュレーションするものです．
// ファイル名をsim.vとします．
	
`timescale 1ns / 1ps
module sim_top;
  reg clk_27MHz;
  wire clk_48kHz;
  wire [15:0] sample;
  main uut(clk_27MHz, clk_48kHz, sample);
  initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0, uut);
    clk_27MHz = 0;
    forever
      #18.518518 clk_27MHz = ~clk_27MHz;
  end
  initial #30000000 $finish;

endmodule

module main (input clk_27MHz, output clk_48kHz, output [15:0] sample);
  clock_div clock_div(clk_27MHz,0,clk_48kHz);
  gen_audio audio(clk_27MHz,clk_48kHz, 1, sample);

endmodule

module clock_div(input clk_27MHz, reset, output reg clk_48kHz = 0);
  reg [9:0] counter = 0;
  always @(posedge clk_27MHz)
    if (reset) begin clk_48kHz <= 0; counter <= 0; end else
    if (counter == 281) begin counter <= 0; clk_48kHz <= !clk_48kHz; end else
    counter <= counter + 1;
endmodule
