module gen_video(
  input wire clk,
  input wire rst,
  input [VIDEO_X_BITWIDTH-1:0] x1,
  input [VIDEO_Y_BITWIDTH-1:0] y1,
  input [VIDEO_X_BITWIDTH-1:0] frameWidth,
  input [VIDEO_Y_BITWIDTH-1:0] frameHeight,
  input wire rxd,
  output [23:0] rgb,
	//	SDRAM
  output        O_sdram_clk,  // Internal
  output        O_sdram_cke,  // Internal
  output        O_sdram_cs_n, // Internal
  output        O_sdram_cas_n,// Internal
  output        O_sdram_ras_n,// Internal
  output        O_sdram_wen_n,// Internal
  inout  [31:0] IO_sdram_dq,  // Internal
  output [10:0] O_sdram_addr, // Internal
  output [1:0]  O_sdram_ba,   // Internal
  output [3:0]  O_sdram_dqm   // Internal
);
  // 通信で書き込みアドレスとデータを取得する
  wire [7:0] u_w_wd; wire [15:0] u_w_ad; wire u_w_en;
  UART uart(clk, rst, rxd, u_w_wd, u_w_ad, u_w_en);
  // 書き込みタイミングを待って書き込む
  reg [7:0] b_w_wd; reg [15:0] b_w_ad; reg b_w_en;
  always@( posedge clk) begin
    if (u_w_en) begin
      b_w_wd <= u_w_wd;
      b_w_ad <= u_w_ad;
      b_w_en <= u_w_en;
    end
    if (b_w_en && rend_c[3:0]==8) b_w_en <= 0;
  end
  // ----------------------------------------------------------------
  // SDRAM reset
  reg [31:0] reset_cnt = 0;
  wire reset_n;
  assign reset_n = ~(reset_cnt < 74_200_000/100);
  always @(posedge clk)
    if (reset_cnt < 74_200_000/100) reset_cnt <= reset_cnt + 32'd1;
  // SDRAM
  wire sdram_init_busy;
  wire [12:0] rend_c;
  wire [31:0] sdram_rdata;
  ip_sdram u_sdram(
    .reset_n(reset_n),
    .clk(clk),
    .clk_sdram(clk),
    .O_sdram_clk(O_sdram_clk),
    .O_sdram_cke(O_sdram_cke),
    .O_sdram_cs_n(O_sdram_cs_n),
    .O_sdram_cas_n(O_sdram_cas_n),
    .O_sdram_ras_n(O_sdram_ras_n),
    .O_sdram_wen_n(O_sdram_wen_n),
    .IO_sdram_dq(IO_sdram_dq),
    .O_sdram_addr(O_sdram_addr),
    .O_sdram_ba(O_sdram_ba),
    .O_sdram_dqm(O_sdram_dqm),
    .sdram_init_busy(sdram_init_busy),
    .mreq_n(~((rend_c[3:0]==0 && b_r_en) || rend_c[3:0]==8)),
    .address(rend_c[3] ? b_w_ad : b_r_ad),
    .wr_n(~(rend_c[3:0]==8 && b_w_en)),
    .rd_n(~b_r_en),
    .rfsh_n(~(rend_c[3:0]==8 && ~b_w_en)),
    .wdata(b_w_wd),
    .rdata(sdram_rdata)
  );
  // 読み込みデータ生成
  wire b_r_en; wire [7:0] b_r_rd; wire [15:0] b_r_ad;
  reg [31:0] rdata;
  always@(posedge clk) if (rend_c[3:0]==7) rdata <= sdram_rdata; 
  assign b_r_rd = rend_c[1:0] == 0 ? rdata[7:0]
                : rend_c[1:0] == 1 ? rdata[15:8]
                : rend_c[1:0] == 2 ? rdata[23:16]
                :                    rdata[31:24];
  // 色を取得
  VideoRenderer renderer(
    clk, rst, x1, frameWidth, y1, frameHeight,
    b_r_en, b_r_ad, b_r_rd, sdram_init_busy, rend_c, rgb);
endmodule

module UART(
  input clk, rst, rxd,
  output reg [7:0]  b_w_wd,
  output reg [15:0] b_w_ad,
  output reg        b_w_en
);
  wire [7:0] DATA; // データ（ASCIIコードの文字）
  wire FLAG;
  // Serial受信
  Serial_rx r0(.CLK(clk),.RST(rst), .RXD(rxd), .FLAG(FLAG), .receivedChar(DATA));
  wire [7:0] o_data; // データ（ASCIIコードの文字）
  wire flag;
  reg busy = 0;
  localparam ST_MODE = 0, ST_DATA = 1, ST_ADDR1 = 2, ST_ADDR2 = 3;
  reg [2:0] state = ST_MODE;
  COBS_decoder dec(.clk(clk), .rst(rst), .rxd(rxd), .flag(FLAG), .busy(busy), .data(DATA),
               .o_flag(flag), .o_data(o_data));
  always @(posedge clk) begin
    if (DATA==0) begin
      state = ST_MODE;
    end
    if (flag && b_w_en==0) begin
      if (state == ST_MODE) begin // モード入力状態
        state <= 3'(o_data); // モードを設定
      end else if (state == ST_DATA) begin // データ入力モード
        busy <= 1;
        b_w_en <= 1;
        b_w_wd <= o_data;
      end else if (state == ST_ADDR1) begin// アドレス入力モード1 (下位バイト)
        b_w_ad[7:0] <= o_data;
        state <= ST_ADDR2;
      end else if (state == ST_ADDR2) begin// アドレス入力モード2 (上位バイト)
        b_w_ad[15:7] <= o_data;
        state <= ST_ADDR1;
      end
    end else if (flag==0 && b_w_en) begin
      busy <= 0;
      if (state == ST_DATA) begin
        b_w_en <= 0;
        b_w_ad <= b_w_ad + 16'd1;
      end
    end
  end
endmodule

module VideoRenderer(
  input clk, rst, [VIDEO_X_BITWIDTH-1:0] x1, frameWidth, [9:0] y1, frameHeight,
  output b_r_en, [15:0] b_r_ad, input [7:0] b_r_rd,
  input sdram_init_busy,
  output [12:0] rend_c,
  output [23:0] rgb);
  // x,y座標を求める
  wire [7:0] x, y; wire [1:0] yc;
  GetXY getxy(clk, x1, frameWidth, y1, frameHeight, x, y, yc, rend_c);
  // ラインの描画
  wire lb_w_en; wire [7:0] lb_w_wd; wire [8:0] lb_w_ad;
  LineRenderer render(
    clk, rend_c, y,
    b_r_en, b_r_ad, b_r_rd,
    lb_w_en, lb_w_ad, lb_w_wd);
  // ラインバッファ
  wire [7:0] lb_r_rd; wire [8:0] lb_r_ad;
  LineBuffer buffer(clk, lb_w_en, lb_w_ad, lb_w_wd, lb_r_ad, lb_r_rd);
  // ラインの描画 8bit色を取得
  wire [7:0] col;
  LineView view(clk, x1, y1, x, y, lb_r_ad, lb_r_rd, col);
  // 24bit色を取得
  assign rgb = {col[7:5],col[7:5],col[7:6],
                col[4:2],col[4:2],col[4:3],
                col[1:0],col[1:0],col[1:0],col[1:0]};
endmodule

module GetXY(input clk,
  input [VIDEO_X_BITWIDTH-1:0] x1, [VIDEO_X_BITWIDTH-1:0] frameWidth,
  input [VIDEO_Y_BITWIDTH-1:0] y1, [VIDEO_Y_BITWIDTH-1:0] frameHeight,
  output reg [7:0] x, reg [7:0] y, reg [1:0] yc, reg [12:0] rend_c);
  reg [1:0] xc;
  always @(posedge clk) begin
    // x座標更新
    if (x1==256-1) begin
      xc <= 0; x <= 0;
    end else if (xc < 2) xc <= xc + 2'd1;
    else begin
      xc <= 0; x <= x + 8'd1;
    end
    // y座標更新
    if (x1==frameWidth-1) begin
      if (y1 == 72-3-1) begin
        yc <= 0; y <= 0;
      end else if (yc < 2)
        yc <= yc + 2'd1;
      else begin
        yc <= 0; y <= y + 8'd1;
      end
    end
    rend_c <= (x1==frameWidth-1 && yc == 2) ? 13'd0 : rend_c + 13'd1;
  end
endmodule

// ラインバッファに描画する
// 16ドットおきに、読み込んで登録する
module LineRenderer(input clk, [12:0] rend_c, [7:0] y,
  output b_r_en, [15:0] b_r_ad, input [7:0] b_r_rd,
  output lb_w_en, [8:0] lb_w_ad, [7:0] lb_w_wd);
  // vram読み込み設定
  wire [7:0] read_x;
  assign read_x = {rend_c[9:4], 2'd0};// 読み込みx座標は16ドットごとに4個移動
  assign b_r_en = rend_c < 256*4 && rend_c[3:0]==0 && y < 192; // 読み込むタイミングは16ドットごとの0番目
  assign b_r_ad = {y,read_x}; // 読み込みアドレスは xとyから決まる
  // vramデータをラインバッファに書き込む
  wire rend_en; wire [7:0] rend_x;
  assign rend_en = rend_c < 256*4 && 8<=rend_c[3:0] && rend_c[3:0]<12 && y < 192; // 8,9,10,11にある場合
  assign rend_x = {rend_c[9:4],rend_c[1:0]};// 8,9,10,11で書き込み
  // ラインバッファに書き込み
  assign lb_w_wd = b_r_rd; // バッファから読み込んだデータをラインバッファに書き込む
  assign lb_w_ad = {!y[0], rend_x}; // ラインバッファのアドレス
  assign lb_w_en = rend_en;
endmodule

// 表示エリアないならラインバッファから読み出して表示する。
module LineView(input clk, [VIDEO_X_BITWIDTH-1:0] x1, [VIDEO_Y_BITWIDTH-1:0] y1, [7:0] x, y,
  output [8:0] lb_r_ad, input [7:0] lb_r_rd,
  output [7:0] col);
  wire view;
  assign view = 256 <= x1 && x1 < 256*4 && 72 <= y1 && y1 < 72+192*3; // 表示エリアなら
  assign lb_r_ad = {y[0],x}; // ラインバッファの読み込みのアドレス
  assign col = view ? lb_r_rd : 7; // ラインバッファの色を読み込む
endmodule

module LineBuffer(
  input        clk,
  input        lb_w_en, // 書き込みフラグ
         [8:0] lb_w_ad, // 書き込みアドレス
         [7:0] lb_w_wd, // 書き込みデータ
  input  [8:0] lb_r_ad, // 読み込みアドレス
  output [7:0] lb_r_rd  // 読み込みデータ
);
  reg [7:0] line[512]; // ラインバッファ 256ドット*2ライン
  assign lb_r_rd = line[lb_r_ad]; // 読み込み
  always @(posedge clk) if (lb_w_en) line[lb_w_ad] <= lb_w_wd; // 書き込み
endmodule
