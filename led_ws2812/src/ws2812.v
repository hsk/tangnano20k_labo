module top (
	input  clk,  //入力 クロック・ソース
	output WS2812 //WS2812インターフェースへの出力
);
	RYGCBMLed rgbled(clk,WS2812);
//	RGB8Led rgbled(clk,WS2812);
//	RGBLed rgbled(clk,0,WS2812);
endmodule
// Red -> Yellow -> Green -> Cyan -> Blue -> Magenta
module RYGCBMLed(
	input clk,  //入力 クロック・ソース
	output WS2812 //WS2812インターフェースへの出力
);
	initial begin
		rgb = 24'hff_00_00;
		state = R;
	end
	localparam R = 0, Y = 1, G = 2, C = 3, B = 4, M = 5;
	reg [2:0] state = R; 
	reg [31:0] clk_count = 0;
	reg [23:0] rgb;
	always@(posedge clk) begin
		if (clk_count < 27_000_000/3000 - 1) 
			clk_count <= clk_count + 1;
		else begin
			clk_count <= 0;
			case(state)
			R: if (rgb[15:8]!=8'hff) rgb[15:8] <= rgb[15:8] + 8'd1;
			   else state <= state + 3'd1;
			Y: if (rgb[23:16]!=8'h00) rgb[23:16] <= rgb[23:16] - 8'd1;
			   else state <= state + 3'd1;
			G: if (rgb[7:0]!=8'hff) rgb[7:0] <= rgb[7:0] + 8'd1;
			   else state <= state + 3'd1;
			C: if (rgb[15:8]!=8'h00) rgb[15:8] <= rgb[15:8] - 8'd1;
			   else state <= state + 3'd1;
			B: if (rgb[23:16]!=8'hff) rgb[23:16] <= rgb[23:16] + 8'd1;
			   else state <= state + 3'd1;
			M: if (rgb[7:0]!=8'h00) rgb[7:0] <= rgb[7:0] - 8'd1;
			   else state <= R;
			endcase
		end
	end
	RGBLed rgb_led(clk,rgb,WS2812);
endmodule

module RGBLed(
	input 		 clk,  //入力 クロック・ソース
	input [23:0] rgb,
	output reg WS2812 //WS2812インターフェースへの出力
);
	initial begin
		bit_send = 23;
	end
	localparam CLK_FRE 	 	= 27_000_000; // CLKの周波数（mHZ）
	localparam DELAY1 = (CLK_FRE / 1_000_000 * 0.85) - 1; //≈850ns±150ns 1 高レベル時間
	localparam DELAY0 = (CLK_FRE / 1_000_000 * 0.40) - 1; //≈400ns±150ns 1 低レベル時間
	localparam DELAY_RESET = (CLK_FRE / 2_000_0 ) - 1; // 50us リセット時間 ＞50us

	//ステートマシン宣言
	localparam RESET 	 		= 0; // リセット状態
	localparam DATA_SEND  		= 1; // データ送信状態
	localparam BIT_SEND_HIGH   	= 2;
	localparam BIT_SEND_LOW   	= 3;

	reg [ 1:0] state       = 0; // synthesis preserve //メイン・ステートマシン制御
	reg [ 5:0] bit_send    = 31; // amount of bit sent // increase it for larger led strips/matrix
	reg [31:0] clk_count   = 0; // レイテンシー
	reg [23:0] rgbout = 24'h1; // WS2812の色データ
	always@(posedge clk)
		case (state)
			RESET:begin // リセット状態
				WS2812 <= 0; // 0 を設定する
				if (clk_count < DELAY_RESET) 
					clk_count <= clk_count + 1;
				else begin
					clk_count <= 0;
					rgbout <= {rgb[15:8],rgb[23:16],rgb[7:0]};
					state <= state+2'd1;
				end
			end
			DATA_SEND: // データ送信状態
				if (bit_send < 24) // 1個のLEDのデータを全部送ってない
					state <= state+2'd1;
				else begin// 1個のLEDのデータは全部送った
					bit_send <= 23;     // ビットはリセット
					state    <= RESET;  // ステート変更
				end
			BIT_SEND_HIGH:begin // 1を送る
				WS2812 <= 1;
				if (rgbout[bit_send])
					if (clk_count < DELAY1) // ビットが立つ場合のウェイト
						clk_count <= clk_count + 1;
					else begin
						clk_count <= 0;
						state <= state+2'd1;
					end
				else 
					if (clk_count < DELAY0) // ビットが落ちる場合のウェイト
						clk_count <= clk_count + 1;
					else begin
						clk_count <= 0;
						state <= state+2'd1;
					end
			end
			BIT_SEND_LOW:begin
				WS2812 <= 0;
				if (rgbout[bit_send])
					if (clk_count < DELAY0) // ビットが立つ場合のウェイト
						clk_count <= clk_count + 1;
					else begin
						clk_count <= 0;
						bit_send <= bit_send - 6'd1;
						state    <= DATA_SEND;
					end
				else 
					if (clk_count < DELAY1) // ビットが落ちる場合のウェイト
						clk_count <= clk_count + 1;
					else begin
						clk_count <= 0;
						bit_send <= bit_send - 6'd1;
						state    <= DATA_SEND;
					end
			end
		endcase
endmodule
