// 下のテストベンチは27MHzのiClkをシミュレーションするものです．
// sClk
// ファイル名をsim.vとします．

`timescale 1ns / 1ps

import configPackage::*;

module sim_top;
  reg baseClk,iSClk,iClk,iAClk;
  reg [32:0] iSCnt,iCnt,iACnt;
  wire oClk;
  Test uut(iClk,iSClk,iACnt);
  initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0, uut);
    $dumpvars(1, hdmi);
    baseClk = 0;
    iSClk = 0; iSCnt = 0;
    iClk = 0; iCnt = 0;
    iAClk = 0; iACnt = 0;
    rst_n = 1;
    rgb = 0;
    sample = 0;
    forever
      // #0.9259259259259259 baseClk = ~baseClk; // 1/(27*20*2)*1000
      #1.8518518518518519 baseClk = ~baseClk; // 1/(27*2*10)*1000
      // #3.7037037 iSClk = ~iSClk; // 1/(27*2*5) * 1000 = 3.7037037037037037
  end
  always @(posedge baseClk) begin
//  if (iACnt == 16875 - 1) begin iACnt <= 0; iAClk = ~iAClk; end
    if (iACnt == 1125 - 1) begin iACnt <= 0; iAClk = ~iAClk; end
    else                    iACnt <= iACnt + 1;
//  if (iSCnt == 4-1) begin iSCnt <= 0; iSClk = ~iSClk; end 
    if (iSCnt == 2-1) begin iSCnt <= 0; iSClk = ~iSClk; end 
    else                    iSCnt <= iSCnt + 1;
  end
  always @(posedge iSClk) begin
    if (iCnt == 5-1) begin iCnt <= 0; iClk = ~iClk; end 
    else             iCnt <= iCnt + 1;
  end
  initial #70000000 $finish;
  reg rst_n;
  reg [23:0] rgb;
  reg [AUDIO_BIT_WIDTH-1:0] sample;
  wire [VIDEO_X_BITWIDTH-1:0] pixX, frameWidth, screenWidth;
  wire [VIDEO_Y_BITWIDTH-1:0] pixY, frameHeight, screenHeight;
	wire tmds_clk_n, tmds_clk_p;
  wire [2:0] tmds_d_n, tmds_d_p;

  hdmi2_top#(.PRODUCT_DESCRIPTION({"Tang Nano 2Ok", 24'd0})) hdmi(.I_reset_n(rst_n),    // system reset (Active low)
    .I_clk_pixel(iClk), .I_clk_serial(iSClk), .I_clk_audio(iAClk),
    .rgb(rgb), .sample(sample), .pixX(pixX), .pixY(pixY),
    .frameWidth(frameWidth), .frameHeight(frameHeight),
    .screenWidth(screenWidth), .screenHeight(screenHeight),
    // HDMI output signals
    .tmds_clk_n(tmds_clk_n), .tmds_clk_p(tmds_clk_p), .tmds_d_n(tmds_d_n), .tmds_d_p(tmds_d_p));

endmodule

module Test (input iClk, iSClk, iAClk);
endmodule
/*
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
  wire [VIDEO_X_BITWIDTH-1:0] pixX, frameWidth, screenWidth;
  wire [VIDEO_Y_BITWIDTH-1:0] pixY, frameHeight, screenHeight;
  gen_video video(.I_clk_pixel(clk_pixel), .I_reset_n(rst_n),
    .screenWidth(screenWidth), .screenHeight(screenHeight),
    .pixX(pixX), .pixY(pixY), .rgb(rgb));

  wire [AUDIO_BIT_WIDTH-1:0] sample_gen, sample;
  gen_audio sin_1kHz(.I_clk_audio(clk_audio), .I_reset_n(rst_n), .sample(sample_gen));
  assign sample = (I_play_audio == 1) ? sample_gen : 16'd0;

  hdmi2_top#(.PRODUCT_DESCRIPTION({"Tang Nano 2Ok", 24'd0})) hdmi(.I_reset_n(rst_n),    // system reset (Active low)
    .I_clk_pixel(clk_pixel), .I_clk_serial(clk_hdmi_serial), .I_clk_audio(clk_audio),
    .rgb(rgb), .sample(sample), .pixX(pixX), .pixY(pixY),
    .frameWidth(frameWidth), .frameHeight(frameHeight),
    .screenWidth(screenWidth), .screenHeight(screenHeight),
    // HDMI output signals
    .tmds_clk_n(tmds_clk_n), .tmds_clk_p(tmds_clk_p), .tmds_d_n(tmds_d_n), .tmds_d_p(tmds_d_p));
endmodule
*/