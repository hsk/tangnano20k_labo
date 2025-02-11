module hdmi_vga(
    input clk, rst, [23:0] rgb,
    output reg [9:0] sx, sy,
    output reg hsync, vsync, de,
	output [3:0] tmdsp, tmdsn
);
    wire clk250;
    HDMI_rPLL rPLL(.clkin(clk), .clkout(clk250));
    wire clk_TMDS;
    BUFG uut(.I(clk250), .O(clk_TMDS));
    wire [23:0] rgb2;
    assign rgb2 = rst_cnt ? 24'h40 : rgb;
    reg [23:0] rst_cnt =  34'h400000;
    reg [23:0] rst_cnt2 = 24'h100000;
    always @(posedge clk) begin
        rst_cnt2 <= rst ? 24'h100000 : rst_cnt2 ? rst_cnt2 - 24'h1 : rst_cnt2;
        rst_cnt <= rst ? 24'h400000 : rst_cnt ? rst_cnt - 24'h1 : rst_cnt;
        sy <= sx != 799 ? sy : sy==524 ? 10'd0 : sy+10'd1;
        sx <= sx == 799 ? 10'd0 : sx+10'd1;
        de <= 0 <= sx && sx < 640+0 && sy <= 480;
        hsync <= 656+0 <= sx && sx<752+0;
        vsync <= 490 <= sy && sy < 492;
    end
    wire [29:0] TMDS;
    TMDS_encoder eb(.clk(clk), .VD(rgb2[ 7: 0]), .CD({vsync,hsync}), .VDE(de), .TMDS(TMDS[ 9: 0]));
    TMDS_encoder eg(.clk(clk), .VD(rgb2[15: 8]), .CD(2'b00)        , .VDE(de), .TMDS(TMDS[19:10]));
    TMDS_encoder er(.clk(clk), .VD(rgb2[23:16]), .CD(2'b00)        , .VDE(de), .TMDS(TMDS[29:20]));
    reg [3:0] TMDS_count=0;  // modulus 10 counter
    reg [29:0] TMDS_RGB=0;
    reg TMDS_shift=0;
    always @(posedge clk_TMDS) begin
        TMDS_count <= TMDS_count==4'd9 ? 4'd0 : TMDS_count+4'd1;
        TMDS_shift <= TMDS_count==4'd9;
        TMDS_RGB[ 9: 0] <= TMDS_shift ? TMDS[ 9: 0] : TMDS_RGB[ 9: 1];
        TMDS_RGB[19:10] <= TMDS_shift ? TMDS[19:10] : TMDS_RGB[19:11];
        TMDS_RGB[29:20] <= TMDS_shift ? TMDS[29:20] : TMDS_RGB[29:21];	
    end
    TLVDS_OBUF OBUF_C(.I(rst_cnt2?1'bz:clk), .O(tmdsp[0]), .OB(tmdsn[0]));
    TLVDS_OBUF OBUF_B(.I(rst_cnt2?1'bz:TMDS_RGB[ 0]), .O(tmdsp[1]), .OB(tmdsn[1]));
    TLVDS_OBUF OBUF_G(.I(rst_cnt2?1'bz:TMDS_RGB[10]), .O(tmdsp[2]), .OB(tmdsn[2]));
    TLVDS_OBUF OBUF_R(.I(rst_cnt2?1'bz:TMDS_RGB[20]), .O(tmdsp[3]), .OB(tmdsn[3]));
endmodule

module TMDS_encoder(
	input clk,
	input [7:0] VD,  // video data (red, green or blue)
	input [1:0] CD,  // control data
	input VDE,  // video data enable, to choose between CD (when VDE=0) and VD (when VDE=1)
	output reg [9:0] TMDS = 0
);
	wire [3:0] Nb1s = VD[0] + VD[1] + VD[2] + VD[3] + VD[4] + VD[5] + VD[6] + VD[7];
	wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && VD[0]==1'b0);
	wire [8:0] q_m = {~XNOR, q_m[6:0] ^ VD[7:1] ^ {7{XNOR}}, VD[0]};
	reg [3:0] balance_acc = 0;
	wire [3:0] balance = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;
	wire balance_sign_eq = (balance[3] == balance_acc[3]);
	wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
	wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
	wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
	wire [9:0] TMDS_data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};
	wire [9:0] TMDS_code = CD[1] ? (CD[0] ? 10'b1010101011 : 10'b0101010100) : (CD[0] ? 10'b0010101011 : 10'b1101010100);
	always @(posedge clk) TMDS <= VDE ? TMDS_data : TMDS_code;
	always @(posedge clk) balance_acc <= VDE ? balance_acc_new : 4'h0;
endmodule

module HDMI_rPLL (clkout, clkin);
    output clkout;
    input clkin;
    wire lock_o;
    wire clkoutp_o;
    wire clkoutd_o;
    wire clkoutd3_o;
    wire gw_gnd;
    assign gw_gnd = 1'b0;
    rPLL rpll_inst (
        .CLKOUT(clkout),
        .LOCK(lock_o),
        .CLKOUTP(clkoutp_o),
        .CLKOUTD(clkoutd_o),
        .CLKOUTD3(clkoutd3_o),
        .RESET(gw_gnd),
        .RESET_P(gw_gnd),
        .CLKIN(clkin),
        .CLKFB(gw_gnd),
        .FBDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
        .IDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
        .ODSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
        .PSDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
        .DUTYDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
        .FDLY({gw_gnd,gw_gnd,gw_gnd,gw_gnd})
    );
    defparam rpll_inst.FCLKIN = "25";
    defparam rpll_inst.DYN_IDIV_SEL = "false";
    defparam rpll_inst.IDIV_SEL = 0;
    defparam rpll_inst.DYN_FBDIV_SEL = "false";
    defparam rpll_inst.FBDIV_SEL = 9;
    defparam rpll_inst.DYN_ODIV_SEL = "false";
    defparam rpll_inst.ODIV_SEL = 2;
    defparam rpll_inst.PSDA_SEL = "0000";
    defparam rpll_inst.DYN_DA_EN = "true";
    defparam rpll_inst.DUTYDA_SEL = "1000";
    defparam rpll_inst.CLKOUT_FT_DIR = 1'b1;
    defparam rpll_inst.CLKOUTP_FT_DIR = 1'b1;
    defparam rpll_inst.CLKOUT_DLY_STEP = 0;
    defparam rpll_inst.CLKOUTP_DLY_STEP = 0;
    defparam rpll_inst.CLKFB_SEL = "internal";
    defparam rpll_inst.CLKOUT_BYPASS = "false";
    defparam rpll_inst.CLKOUTP_BYPASS = "false";
    defparam rpll_inst.CLKOUTD_BYPASS = "false";
    defparam rpll_inst.DYN_SDIV_SEL = 2;
    defparam rpll_inst.CLKOUTD_SRC = "CLKOUT";
    defparam rpll_inst.CLKOUTD3_SRC = "CLKOUT";
    defparam rpll_inst.DEVICE = "GW2AR-18C";
endmodule //Gowin_rPLL
