/* *******************************************************************
 * Generate RGB color for pixel at position (x,y).
 * RGB data must be ready and stable in 1 clock cycle (!)
*/
module gen_video(
  input wire clk,
  input wire rst,
  input [VIDEO_X_BITWIDTH-1:0] x1,
  input [VIDEO_Y_BITWIDTH-1:0] y1,
  input wire rxd,
  output reg [23:0] rgb
);
  wire [VIDEO_X_BITWIDTH-1:0] x = x1-10'd104;
  wire [VIDEO_X_BITWIDTH-1:0] xa = x1-10'd103;
  wire [VIDEO_Y_BITWIDTH-1:0] y = y1-10'd48;

  wire [7:0] ram_write;
  wire ram_writeenable;
  wire [14:0] waddr;
  wire [3:0] pal;
  // RAM to hold 256x256 array of bytes
  RAM_sync ram(
    .clk(clk),
    .y(y[8:1]),
    .x(xa[8:1]),
    .pal(pal),
    .din(ram_write),
    .waddr(waddr),
    .write_enable(ram_writeenable)
  );

  wire pram_writeenable;
  wire [3:0] pwaddr;
  wire [11:0] pram_write;
  wire [11:0] c;
  PaletteRAM pram(
    .clk(clk),
    .pram_writeenable(pram_writeenable),
    .pwaddr(pwaddr),
    .pin(pram_write),
    .pal(pal),
    .cout(c)
  );
  // Video generation
  always@(posedge clk) begin
    if (!rst) begin
      rgb <= 24'd0;
    end else if (x < 256*2 && y < 192*2) begin
      if (x < 256*2 && y < 192*2) rgb <= {c[10:8],c[10:8],c[10:9],c[6:4],c[6:4],c[6:5],c[2:0],c[2:0],c[2:1]};
    end else rgb <= 0;
  end
  UART1 uart1(
    .clk(clk),
    .rst(rst),
    .rxd(rxd),
    .ram_writeenable(ram_writeenable),
    .ram_write(ram_write),
    .waddr(waddr),
    .pram_writeenable(pram_writeenable),
    .pwaddr(pwaddr),
    .pram_write(pram_write)
  );
endmodule
module UART1(
  input clk, rst, rxd,
  output reg ram_writeenable,
  output reg [7:0] ram_write,
  output reg [14:0] waddr,
  output reg pram_writeenable,
  output reg [3:0] pwaddr,
  output reg [11:0] pram_write
);
  wire [7:0] DATA; // データ（ASCIIコードの文字）
  wire FLAG;


  // Serial受信
  Serial_rx r0(.CLK(clk),.RST(rst), .RXD(rxd), .FLAG(FLAG), .receivedChar(DATA));
  wire [7:0] o_data; // データ（ASCIIコードの文字）
  wire flag;
  reg busy = 0;
  localparam ST_MODE = 0, ST_DATA = 1, ST_ADDR1 = 2, ST_ADDR2 = 3, ST_PALETTE = 4, ST_PALETTE2 = 5;
  reg [2:0] state = ST_MODE;
  COBS_decoder cdec(.clk(clk), .rst(rst), .rxd(rxd), .flag(FLAG), .busy(busy), .data(DATA),
               .o_flag(flag), .o_data(o_data));
  always @(posedge clk) begin
    if (DATA==0) begin
      state = ST_MODE;
    end
    if (flag && ram_writeenable==0 && pram_writeenable==0) begin
      if (state == ST_MODE) begin
        state <= o_data[2:0];
        if (o_data[2:0] == ST_PALETTE) begin
          pwaddr <= 0;
        end
      end else if (state == ST_DATA) begin
        busy <= 1;
        ram_writeenable <= 1;
        ram_write <= o_data;
      end else if (state == ST_ADDR1) begin
        waddr[7:0] <= o_data;
        state <= ST_ADDR2;
      end else if (state == ST_ADDR2) begin
        waddr[14:8] <= o_data[6:0];
        state <= ST_ADDR1;
      end else if (state == ST_PALETTE) begin
        pram_write <= o_data;
        state <= ST_PALETTE2;
      end else if (state == ST_PALETTE2) begin
        busy <= 1;
        pram_writeenable <= 1;
        pram_write <= {o_data[3:0],pram_write[7:0]};
        state <= ST_PALETTE;
      end
    end else if (flag==0 && (ram_writeenable||pram_writeenable)) begin
      busy <= 0;
      if (state == ST_DATA) begin
        ram_writeenable <= 0;
        waddr <= 15'(waddr + 1);
      end else begin
        pram_writeenable <= 0;
        pwaddr <= 5'(pwaddr + 1);
      end
    end
  end

endmodule
module PaletteRAM(
  input clk, pram_writeenable, [3:0] pwaddr, [11:0] pin,
  input [3:0] pal, output [11:0] cout);
  reg [11:0] pmem[16];
  always @(posedge clk) begin
    if (pram_writeenable)
      pmem[pwaddr] = pin;
  end
  assign cout = pmem[pal];
endmodule

module RAM_sync(input clk, write_enable, [14:0] waddr, [7:0] din,
                input [7:0] x, input [7:0] y,
                output [3:0] pal);
  initial begin
    integer i,j,k=0;
    for (j=0;j<128;j++) begin
      for (i=0;i<256;i++,k++) begin
        mem[k] = 0;
      end
    end
  end
  reg [7:0] mem [32768];
  reg [2:0] s;
  reg [7:0] pal1;
  reg [7:0] pal2;
  reg [7:0] pal3;
  reg [7:0] pal4;
  reg [2:0] xx;
  always @(posedge clk) begin
    if (write_enable)		// if write enabled
      mem[waddr] = din;	// write memory from din
    pal1 <= mem[{2'd0,y,x[7:3]}];
    pal2 <= mem[{2'd1,y,x[7:3]}];
    pal3 <= mem[{2'd2,y,x[7:3]}];
    pal4 <= mem[{2'd3,y,x[7:3]}];
    xx <= 7-x[2:0];
  end
  assign pal = getPal(pal1,pal2,pal3,pal4,xx);

  function [3:0] getPal(input [7:0] pal1,input [7:0] pal2,input [7:0] pal3,input [7:0] pal4,input [2:0] x);
    getPal = {1'((pal1>>x)&1),1'((pal2>>x)&1),1'((pal3>>x)&1),1'((pal4>>x)&1)};
  endfunction

endmodule

