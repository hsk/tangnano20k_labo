module hdmi_vga(
    input clk, rst, [23:0] rgb,
    output clk5x, reg hsync, vsync, de, reg [9:0] sx, sy, [3:0] tmdsp, tmdsn);
    HDMI_rPLL rPLL(clk, clk5x);
    reg [23:0] rst_cnt =  34'h400000;
    reg [23:0] rst_cnt2 = 24'h100000;
    wire [23:0] vd;
    assign vd = rst_cnt ? 24'h40 : rgb;
    always @(posedge clk) begin
        rst_cnt <= rst ? 24'h400000 : rst_cnt ? rst_cnt - 24'h1 : rst_cnt;
        rst_cnt2 <= rst ? 24'h100000 : rst_cnt2 ? rst_cnt2 - 24'h1 : rst_cnt2;
        sx <= sx == 799 ? 10'd0 : sx+10'd1;
        sy <= sx != 799 ? sy : sy==524 ? 10'd0 : sy+10'd1;
        de <= 0 <= sx && sx < 640+0 && sy <= 480;
        hsync <= 656+0 <= sx && sx<752+0;
        vsync <= 490 <= sy && sy < 492;
    end
    wire [29:0] enc;
    TMDS_encoder eb(clk, de, vd[ 7: 0], {vsync,hsync}, enc[ 9: 0]);
    TMDS_encoder eg(clk, de, vd[15: 8], 2'b0         , enc[19:10]);
    TMDS_encoder er(clk, de, vd[23:16], 2'b0         , enc[29:20]);
    reg [3:0] cnt=0; reg [29:0] tmds=0; reg sht=0;
    always @(posedge clk5x) begin
        cnt <= cnt==4'd9 ? 4'd0 : cnt+4'd1;
        sht <= cnt==4'd9;
        tmds[ 9: 0] <= sht ? enc[ 9: 0] : tmds[ 9: 1];
        tmds[19:10] <= sht ? enc[19:10] : tmds[19:11];
        tmds[29:20] <= sht ? enc[29:20] : tmds[29:21];	
    end
    TLVDS_OBUF OBUF_C(.I(rst_cnt2?1'bz:     clk), .O(tmdsp[0]), .OB(tmdsn[0]));
    TLVDS_OBUF OBUF_B(.I(rst_cnt2?1'bz:tmds[ 0]), .O(tmdsp[1]), .OB(tmdsn[1]));
    TLVDS_OBUF OBUF_G(.I(rst_cnt2?1'bz:tmds[10]), .O(tmdsp[2]), .OB(tmdsn[2]));
    TLVDS_OBUF OBUF_R(.I(rst_cnt2?1'bz:tmds[20]), .O(tmdsp[3]), .OB(tmdsn[3]));
endmodule

module TMDS_encoder(
	input clk,
	input de,  // video data enable, to choose between cd (when de=0) and vd (when de=1)
	input [7:0] vd,  // video data (red, green or blue)
	input [1:0] cd,  // control data
	output reg [9:0] tmds
);
    initial tmds = 0;
	wire [3:0] Nb1s = vd[0] + vd[1] + vd[2] + vd[3] + vd[4] + vd[5] + vd[6] + vd[7];
	wire XNOR = Nb1s>4'd4 || (Nb1s==4'd4 && vd[0]==1'b0);
	wire [8:0] q_m = {~XNOR, q_m[6:0] ^ vd[7:1] ^ {7{XNOR}}, vd[0]};
	wire [3:0] balance = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;
	reg [3:0] balance_acc = 0;
	wire balance_sign_eq = balance[3] == balance_acc[3];
	wire invert_q_m = balance==0 || balance_acc==0 ? ~q_m[8] : balance_sign_eq;
	wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
	wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
	always @(posedge clk) balance_acc <= de ? balance_acc_new : 4'h0;
	wire [9:0] data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};
	wire [9:0] code = cd[1] ? (cd[0] ? 10'b1010101011 : 10'b0101010100) : (cd[0] ? 10'b0010101011 : 10'b1101010100);
	always @(posedge clk) tmds <= de ? data : code;
endmodule

module HDMI_rPLL(input clk, output clk5x);
    wire clk10x,clkoutp,clkoutd,clkoutd3,lock;
    rPLL#(
        .FCLKIN("25"),
        .DYN_IDIV_SEL("false"),  .IDIV_SEL(0),
        .DYN_FBDIV_SEL("false"), .FBDIV_SEL(9),
        .DYN_ODIV_SEL("false"),  .ODIV_SEL(2),
        .PSDA_SEL("0000"), .DYN_DA_EN("true"), .DUTYDA_SEL("1000"),
        .CLKOUT_FT_DIR(1'b1), .CLKOUTP_FT_DIR(1'b1),
        .CLKOUT_DLY_STEP(0), .CLKOUTP_DLY_STEP(0), .CLKFB_SEL("internal"),
        .CLKOUT_BYPASS("false"), .CLKOUTP_BYPASS("false"), .CLKOUTD_BYPASS("false"),
        .DYN_SDIV_SEL(2), .CLKOUTD_SRC("CLKOUT"), .CLKOUTD3_SRC("CLKOUT"),
        .DEVICE("GW2AR-18C")
    )rpll_inst(
        .CLKIN(clk), .CLKOUT(clk10x), .RESET(1'b0), .RESET_P(1'b0), .CLKFB(1'b0),
        .FBDSEL(6'b0), .IDSEL(6'b0), .ODSEL(6'b0),
        .PSDA(4'b0), .DUTYDA(4'b0), .FDLY(4'b0),
        .CLKOUTP(clkoutp), .CLKOUTD(clkoutd), .CLKOUTD3(clkoutd3), .LOCK(lock)
    );
    BUFG uut(.I(clk10x), .O(clk5x));
endmodule
