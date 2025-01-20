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
  wire [VIDEO_Y_BITWIDTH-1:0] y = y1-10'd16;
  wire de = x < 512 && y < 448;


  wire [7:0] ram_read;
  reg [7:0] ram_write;
  reg ram_writeenable = 0;
  reg [15:0] waddr = 0;

  // RAM to hold 256x256 array of bytes
  RAM_sync ram(
    .clk(clk),
    .dout(ram_read),
    .din(ram_write),
    .waddr(waddr),
    .addr({y[7:0],x[7:0]}),
    .write_enable(ram_writeenable)
  );
  // Video generation
  always@(posedge clk) begin
    if (!rst)
      rgb <= 12'd0;
    else if (de) begin
      rgb <= {
        ram_read[7:5],ram_read[7:5],ram_read[7:6],
        ram_read[4:2],ram_read[4:2],ram_read[4:3],
        ram_read[1:0],ram_read[1:0],ram_read[1:0],ram_read[1:0]
      };
      //rgb <= {x[7:0],8'h00,y[7:0]};
    end else rgb <= 0;
  end
  
  wire [7:0] DATA; // データ（ASCIIコードの文字）
  wire FLAG;


  // Serial受信
  Serial_rx r0(.CLK(clk),.RST(rst), .RXD(rxd), .FLAG(FLAG), .receivedChar(DATA));
  wire [7:0] o_data; // データ（ASCIIコードの文字）
  wire flag;
  reg busy = 0;
  localparam ST_MODE = 0, ST_DATA = 1, ST_ADDR1 = 2, ST_ADDR2 = 3;
  reg [2:0] state = ST_MODE;
  COBS_decoder(.clk(clk), .rst(rst), .rxd(rxd), .flag(FLAG), .busy(busy), .data(DATA),
               .o_flag(flag), .o_data(o_data));
  always @(posedge clk) begin
    if (DATA==0) begin
      state = ST_MODE;
    end
    if (flag && ram_writeenable==0) begin
      if (state == ST_MODE) begin
        state <= o_data;
      end else if (state == ST_DATA) begin
        busy <= 1;
        ram_writeenable <= 1;
        ram_write <= o_data;
      end else if (state == ST_ADDR1) begin
        waddr[7:0] <= o_data;
        state <= ST_ADDR2;
      end else if (state == ST_ADDR2) begin
        waddr[15:7] <= o_data;
        state <= ST_ADDR1;
      end
    end else if (flag==0 && ram_writeenable) begin
      busy <= 0;
      if (state == ST_DATA) begin
        ram_writeenable <= 0;
        waddr <= waddr + 1;
      end
    end
  end

endmodule

module RAM_sync(input clk, write_enable, [15:0] waddr, [7:0] din, [15:0] addr,
                output [7:0] dout);
  initial begin
    integer i,x,y;
    i = 0;
    for (y=0;y<256;y++) begin
      for (x=0;x<256;x++) begin
        mem[i] = 0;
        i++;
      end
    end
  end
  reg [7:0] mem [0:65535]; // 1024バイトメモリ

  always @(posedge clk) begin
    if (write_enable)		// if write enabled
      mem[waddr] = din;	// write memory from din
  end
  assign dout = mem[addr];	// read memory to dout (sync)
endmodule
