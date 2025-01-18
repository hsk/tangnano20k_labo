// 下のテストベンチは27MHzのiClkをシミュレーションするものです．
// ファイル名をsim.vとします．
	
`timescale 1ns / 1ps
module sim_top;
  reg clk_27MHz;
  wire led;
  top top(clk_27MHz, led);
  initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0, top.led);
    clk_27MHz = 0;
    forever
      #18.518518 clk_27MHz = ~clk_27MHz;
  end
  initial #2000000000 $finish;

endmodule
