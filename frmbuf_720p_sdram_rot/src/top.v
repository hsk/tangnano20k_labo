import configPackage::*;

module top(
  input I_clk27, I_reset, I_play_audio, rxd,
	output tmds_clk_n, tmds_clk_p, [2:0] tmds_d_n, [2:0] tmds_d_p,
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
  wire clk_pixel;         // HDMI or VGA pixel clock           27MHz for 480p, 74.25MHz for 720p
  wire clk_hdmi_serial;   // HDMI serial clock (5 x clk_pixel) 135MHz for 480p, 371.25MHz for 720p
  wire clk_audio;         // HDMI audio clock 32kHz
  wire rst_n;
  clocks #(.DEVICE("GW2AR-18C")) clocks(I_clk27,~I_reset, clk_pixel, clk_hdmi_serial, clk_audio, rst_n);

  wire [23:0] rgb;
  wire [VIDEO_X_BITWIDTH-1:0] x, frameWidth, screenWidth;
  wire [VIDEO_Y_BITWIDTH-1:0] y, frameHeight, screenHeight;
  gen_video video(.clk(clk_pixel), .rst(rst_n),
    .x1(x), .y1(y),
    .rgb(rgb), .rxd(rxd),
    .O_sdram_clk(O_sdram_clk),
    .O_sdram_cke(O_sdram_cke),
    .O_sdram_cs_n(O_sdram_cs_n),
    .O_sdram_cas_n(O_sdram_cas_n),
    .O_sdram_ras_n(O_sdram_ras_n),
    .O_sdram_wen_n(O_sdram_wen_n),
    .IO_sdram_dq(IO_sdram_dq),
    .O_sdram_addr(O_sdram_addr),
    .O_sdram_ba(O_sdram_ba),
    .O_sdram_dqm(O_sdram_dqm)
  );

  wire [AUDIO_BIT_WIDTH-1:0] sample_gen, sample;
  gen_audio sin_1kHz(.I_clk_audio(clk_audio), .I_reset_n(rst_n), .sample(sample_gen));
  assign sample = (I_play_audio == 1) ? sample_gen : 16'd0;

  hdmi2_top#(.PRODUCT_DESCRIPTION({"Tang Nano 2Ok", 24'd0})) hdmi(.I_reset_n(rst_n),    // system reset (Active low)
    .I_clk_pixel(clk_pixel), .I_clk_serial(clk_hdmi_serial), .I_clk_audio(clk_audio),
    .rgb(rgb), .sample(sample), .pixX(x), .pixY(y),
    .frameWidth(frameWidth), .frameHeight(frameHeight),
    .screenWidth(screenWidth), .screenHeight(screenHeight),
    // HDMI output signals
    .tmds_clk_n(tmds_clk_n), .tmds_clk_p(tmds_clk_p), .tmds_d_n(tmds_d_n), .tmds_d_p(tmds_d_p));
endmodule
