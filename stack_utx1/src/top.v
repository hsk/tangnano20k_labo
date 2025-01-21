module top(input clk, s1, output reg [5:0] led, output uart_txp);
  `define INCLUDE
  `include "UartTx.v"
  `undef INCLUDE
  assign print_clk = clk;
  `define ln {8'd13,"\n"}
  `define p(a,s) begin `print(a,STR);led[0]<=0; if(print_state==PRINT_IDLE_STATE) begin st<=PWAIT; pwait_st<=s; end end
  localparam FREQ=27_000_000;

  reg [3:0] st,pwait_st;
  initial begin st = INI; rst1 = 1; end
  localparam INI = 0, WAIT = 1, RUN = 2, OUT = 3, FIN = 4, IDLE=5,PWAIT=6;
  wire flg; wire [7:0] result; reg rst1; reg [32:0] cnt;
  StackMachine vm(clk,rst1,flg,result);
  always @(posedge clk) begin
    led[0] = ~s1;
    if (s1) begin st <= INI; led[3:1]<= ~0; end else
    case (st)
    INI: begin st <= WAIT; cnt <= 0; led[3:2]<= ~0; led[1] <= 0; `p({"initialize",`ln},WAIT) end
    WAIT:if (cnt >= FREQ/2) begin st <= RUN; rst1 <= 1; end
         else cnt <= cnt+1;
    RUN: begin rst1 <= 0; if (flg) st <= OUT; end
    OUT: begin led[2] <= 0; `p({"out[",hexf(result),"]",`ln},FIN) end
    FIN: begin led[3] <= 0; `p({"ok",`ln},IDLE) end
    PWAIT: st<=pwait_st;
    endcase
  end
endmodule

module StackMachine(input clk, rst, output reg flg, reg [7:0] out);
  initial begin flg = 0; st = IDLE; end
  localparam IDLE = 0, INI = 1, RUN = 2, FIN = 3;
  reg [7:0] st, sp, s[7], pc, c[13] = '{0,1,0,2,0,3,0,4,1,1,1,2,0};
  always @(posedge clk)
    if (rst) st <= INI; else
    case(st)
    INI: begin pc <= 0; sp <= 0; flg <= 0; st <= RUN; end
    RUN: case (c[pc])
         0: begin s[sp] <= c[pc+1]; sp <= sp+1; pc <= pc+2; end
         1: begin sp = sp-1; s[sp-1] <= s[sp]+s[sp-1]; pc <= pc+1; end
         2: begin out = s[sp-1]; flg = 1; st <= FIN; end
         endcase
    FIN: begin flg = 0; st <= IDLE; end
    endcase
endmodule
