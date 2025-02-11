module top(input clk, rst, output [3:0] tmdsp, tmdsn);
    wire [9:0] sx, sy; wire [23:0] rgb;
    video video(clk, sx, sy, rgb);
    wire hsync, vsync, de;
    hdmi_vga hdmi_vga(clk,rst,rgb, sx, sy, hsync, vsync, de, tmdsp, tmdsn);
endmodule

module video(input clk, [9:0] sx, sy, output reg [23:0] rgb);
    always @(posedge clk) begin
        rgb <= (sx<1||sx>=639||sy<=0||sy>=479)?24'hffffff
             : (100<=sx && sx < 540 && 100 <= sy && sy < 380) ? 24'hffffff : {8'd0,8'd0,8'hff};
    end
endmodule
