module top(input clk, rst, joyi, output [2:0] joy, [3:0] tmdsp, tmdsn);
    localparam FW=800,FH=525,SW=640,SH=480,HSYNC=16,HSYNCW=96,VSYNC=10,VSYNCH=2,FCLK="25.2",INV=1,WB=9; //640x480   VGA
    //localparam FW=858,FH=525,SW=720,SH=480,HSYNC=16,HSYNCW=62,VSYNC=9,VSYNCH=6,FCLK="27",INV=1,WB=9;    //720x480   480p
    //localparam FW=1650,FH=750,SW=1280,SH=720,HSYNC=110,HSYNCW=40,VSYNC=5,VSYNCH=5,FCLK="74.25",INV=0,WB=10;//1280x720 720p
    wire [7:0] btn;
    joystick joystick(clk, joyi, joy, btn);
    wire [WB:0] sx, sy; wire [23:0] rgb;
    video#(WB,SW,SH) video(clk, sx, sy, btn, rgb);
    wire clk5x, hsync, vsync, de;
    hdmi#(FW,FH,SW,SH,HSYNC,HSYNCW,VSYNC,VSYNCH,FCLK,INV,WB)
    hdmi(clk,rst,rgb, clk5x, hsync, vsync, de, sx, sy, tmdsp, tmdsn);
endmodule

module video#(WB=9,SW=640,SH=480)(input clk, [WB:0] sx, [9:0] sy, [7:0] btn, output reg [23:0] rgb);
    always @(posedge clk)
        rgb <= 64 <= sx && sx < 640-64 ? {8'd0,{8{btn[(sx-64)/64]}},8'd0} : 24'h444444;
endmodule

module joystick#(PIXEL_CLOCK=25_200_000)(input clk_pixel, joyi, output [2:0] joy, [7:0] btn);
    reg clk250k;                   // controller main clock at 250Khz
    localparam SCLK_DELAY = PIXEL_CLOCK / 250_000 / 2;   // FREQ / 250000 / 2
    reg [$clog2(SCLK_DELAY)-1:0] cnt;
    // Generate clk250k
    always @(posedge clk_pixel) begin
        cnt <= cnt + 1;
        if (cnt == SCLK_DELAY-1) begin
            clk250k = ~clk250k;
            cnt <= 0;
        end
    end
    wire [7:0] o[0:1];     // 6 RX bytes for all button/axis state
    dualshock_controller controller(
        .I_CLK250K(clk250k), .I_RSTn(1'b1), .I_psRXD(joyi),
        .O_psCLK(joy[0]), .O_psSEL(joy[1]), .O_psTXD(joy[2]),
        .O_RXD_1(o[0]), .O_RXD_2(o[1]), .O_RXD_3(),
        .O_RXD_4(), .O_RXD_5(), .O_RXD_6(),
        // config=1, mode=1(analog), mode_en=1
        .I_CONF_SW(1'b0), .I_MODE_SW(1'b1), .I_MODE_EN(1'b0),
        .I_VIB_SW(2'b00), .I_VIB_DAT(8'hff));     // no vibration
    // o[0:1] dualshock buttons: 0:(L D R U St R3 L3 Se)  1:(□ X O △ R1 L1 R2 L2)
    // btn[0:1] NES buttons:      (R L D U START SELECT B A)
    // O is A, X is B
    assign btn = {~o[0][5], ~o[0][7], ~o[0][6], ~o[0][4], 
                  ~o[0][3], ~o[0][0], ~o[1][6], ~o[1][5]};
endmodule
