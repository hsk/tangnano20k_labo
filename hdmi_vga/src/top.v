module top(input clk, rst, output [3:0] tmdsp, tmdsn);
    localparam FW=800,FH=525,SW=640,SH=480,HSYNC=16,HSYNCW=96,VSYNC=10,VSYNCH=2,FCLK="25.2",INV=1,WB=9; //640x480   VGA
    //localparam FW=858,FH=525,SW=720,SH=480,HSYNC=16,HSYNCW=62,VSYNC=9,VSYNCH=6,FCLK="27",INV=1,WB=9;    //720x480   480p
    //localparam FW=1650,FH=750,SW=1280,SH=720,HSYNC=110,HSYNCW=40,VSYNC=5,VSYNCH=5,FCLK="74.25",INV=0,WB=10;//1280x720 720p
    wire [WB:0] sx, sy; wire [23:0] rgb;
    video#(WB,SW,SH) video(clk, sx, sy, rgb);
    wire clk5x, hsync, vsync, de;
    hdmi#(FW,FH,SW,SH,HSYNC,HSYNCW,VSYNC,VSYNCH,FCLK,INV,WB)
    hdmi(clk,rst,rgb, clk5x, hsync, vsync, de, sx, sy, tmdsp, tmdsn);
endmodule

module video#(WB=9,SW=640,SH=480)(input clk, [WB:0] sx, [9:0] sy, output reg [23:0] rgb);
    always @(posedge clk) begin
        rgb <= (sx<1||sx>=SW-1||sy<=0||sy>=SH-1)?24'hffffff
             : (100<=sx && sx < SW - 100 && 100 <= sy && sy < SH-100) ? 24'hffffff : {8'd0,8'd0,8'hff};
        //rgb <= {sy[7:0],sx[7:0],8'd0};
    end
endmodule
