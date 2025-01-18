import configPackage::*;

module top(
  input I_clk27, I_reset, I_play_audio,
	output led, tmds_clk_n, tmds_clk_p, [2:0] tmds_d_n, [2:0] tmds_d_p
);
  wire clk_pixel;         // HDMI or VGA pixel clock           27MHz for 480p, 74.25MHz for 720p
  wire clk_hdmi_serial;   // HDMI serial clock (5 x clk_pixel) 135MHz for 480p, 371.25MHz for 720p
  wire clk_audio;         // HDMI audio clock 32kHz
  wire rst_n;
  clocks #(.DEVICE("GW2AR-18C")) clocks(I_clk27,~I_reset, clk_pixel, clk_hdmi_serial, clk_audio, rst_n);

  wire [23:0] rgb;
  wire [VIDEO_X_BITWIDTH-1:0] pixX, frameWidth, screenWidth;
  wire [VIDEO_Y_BITWIDTH-1:0] pixY, frameHeight, screenHeight;
  wire [AUDIO_BIT_WIDTH-1:0] sample_gen, sample;
  gen_video video(.I_clk_pixel(clk_pixel), .I_reset_n(rst_n),
    .screenWidth(screenWidth), .screenHeight(screenHeight),
    .pixX(pixX), .pixY(pixY), .sample(sample), .rgb(rgb));

  assign led = sample[AUDIO_BIT_WIDTH-1];
  gen_audio audio(.clk_27MHz(I_clk27), .I_clk_audio(clk_audio), .I_reset_n(rst_n), .sample(sample_gen));
  assign sample = sample_gen;

  hdmi2_top#(.PRODUCT_DESCRIPTION({"Tang Nano 2Ok", 24'd0})) hdmi(.I_reset_n(rst_n),    // system reset (Active low)
    .I_clk_pixel(clk_pixel), .I_clk_serial(clk_hdmi_serial), .I_clk_audio(clk_audio),
    .rgb(rgb), .sample(sample), .pixX(pixX), .pixY(pixY),
    .frameWidth(frameWidth), .frameHeight(frameHeight),
    .screenWidth(screenWidth), .screenHeight(screenHeight),
    // HDMI output signals
    .tmds_clk_n(tmds_clk_n), .tmds_clk_p(tmds_clk_p), .tmds_d_n(tmds_d_n), .tmds_d_p(tmds_d_p));
endmodule
