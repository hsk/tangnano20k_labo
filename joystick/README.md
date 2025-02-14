# joystick

Sipeed Tang nano 20Kでデュアルショックのジョイスティック入力の情報をHDMIに出力します。


https://github.com/user-attachments/assets/a4b409d2-46c2-40ec-9a4e-7d124fbb7a13


cst ファイルに以下のように定義し

```verilog
IO_LOC "joy[0]" 17; IO_PORT "joy[0]" PULL_MODE=NONE IO_TYPE=LVCMOS33;
IO_LOC "joy[1]" 18; IO_PORT "joy[1]" PULL_MODE=NONE IO_TYPE=LVCMOS33;
IO_LOC "joy[2]" 20; IO_PORT "joy[2]" PULL_MODE=NONE IO_TYPE=LVCMOS33;
IO_LOC "joyi"   19; IO_PORT "joyi"   PULL_MODE=UP   IO_TYPE=LVCMOS33;
```

top モジュールに以下のように書き加え

```verilog
input joyi, output [2:0] joy,
```

joystick モジュールを起動すると btn に A B SELECT START 上下左右 8 つのボタンの状態が保存されます。

```verilog
    wire [7:0] btn;
    joystick joystick(clk, joyi, joy, btn);
```

例えば以下のように書けばジョイスティックで押した情報が画面に緑で表示されます。

```verilog
module video#(WB=9,SW=640,SH=480)(input clk, [WB:0] sx, [9:0] sy, [7:0] btn, output reg [23:0] rgb);
    always @(posedge clk)
        rgb <= 64 <= sx && sx < 640-64 ? {8'd0,{8{btn[(sx-64)/64]}},8'd0} : 24'h444444;
endmodule
```
