module top (input  clk, output WS2812);
	RGBLedOff rgbled(clk,WS2812);
endmodule

module RGBLedOff(input clk, output reg WS2812);
	reg [ 1:0] s = 0;
	reg [ 4:0] b = 0;
	reg [10:0] i = 0;
	always@(posedge clk) begin
		WS2812 <= s[0];
		i <= i + 11'd1;
		if (s == 0 && i == 0) begin // 75us リセット時間 ＞50us 
			b <= 0;
			s <= 2'd1;
		end else
		if (s == 1 && i == 10) s <= 2'd2; //≈400ns±150ns 1 低レベル時間
		if (s == 2 && i == 32) begin      //≈850ns±150ns 0 レベル時間
			i <= 1;
			b <= b + 5'd1;
			s <= b != 24;
		end
	end
endmodule
