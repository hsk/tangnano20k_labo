import configPackage::*;

module top(
  input I_clk27, I_reset, I_play_audio,
	output tmds_clk_n, tmds_clk_p, [2:0] tmds_d_n, [2:0] tmds_d_p
);
  wire clk_pixel;         // HDMI or VGA pixel clock           27MHz for 480p, 74.25MHz for 720p
  wire clk_hdmi_serial;   // HDMI serial clock (5 x clk_pixel) 135MHz for 480p, 371.25MHz for 720p
  wire clk_audio;         // HDMI audio clock 32kHz
  wire rst_n;
  clocks #(.DEVICE("GW2AR-18C")) clocks(I_clk27,~I_reset, clk_pixel, clk_hdmi_serial, clk_audio, rst_n);

  wire [23:0] rgb;
  wire [VIDEO_X_BITWIDTH-1:0] pixX, frameWidth;
  wire [VIDEO_Y_BITWIDTH-1:0] pixY, frameHeight;
  gen_video video(.clk(clk_pixel), .rst(rst_n),
    .frameWidth(frameWidth), .frameHeight(frameHeight),
    .pixX(pixX), .py(pixY), .rgb(rgb));

  wire [AUDIO_BIT_WIDTH-1:0] sample_gen, sample;
  gen_audio sin_1kHz(.I_clk_audio(clk_audio), .I_reset_n(rst_n), .sample(sample_gen));
  assign sample = (I_play_audio == 1) ? sample_gen : 16'd0;

  hdmi2_top#(.PRODUCT_DESCRIPTION({"Tang Nano 2Ok", 24'd0})) hdmi(.I_reset_n(rst_n),    // system reset (Active low)
    .I_clk_pixel(clk_pixel), .I_clk_serial(clk_hdmi_serial), .I_clk_audio(clk_audio),
    .rgb(rgb), .sample(sample), .pixX(pixX), .pixY(pixY),
    .frameWidth(frameWidth), .frameHeight(frameHeight),
    // HDMI output signals
    .tmds_clk_n(tmds_clk_n), .tmds_clk_p(tmds_clk_p), .tmds_d_n(tmds_d_n), .tmds_d_p(tmds_d_p));
endmodule
