/* *******************************************************************
 * Generate RGB color for pixel at position (x,y).
 * RGB data must be ready and stable in 1 clock cycle (!)
*/
module gen_video(
  input wire clk,
  input wire rst,
  input [VIDEO_X_BITWIDTH-1:0] x1,
  input [VIDEO_Y_BITWIDTH-1:0] y1,
  output reg [23:0] rgb
);
  wire [VIDEO_X_BITWIDTH-1:0] x = x1-10'd104;
  wire [VIDEO_Y_BITWIDTH-1:0] y = y1-10'd16;
  wire de = x < 512 && y < 448;


  wire [7:0] ram_read;
  reg [7:0] ram_write;
  reg ram_writeenable = 0;

  // RAM to hold 32x32 array of bytes
  // 40x30
  RAM_sync ram(
    .clk(clk),
    .dout(ram_read),
    .din(ram_write),
    .addr({y[8:4],x[8:4]}),
    .write_enable(ram_writeenable)
  );
  wire [23:0] c;
  Color col(x[3:1]+y[3:1],c);
  wire [7:0] data;
  digits_data rom({ram_read[3:0],y[3:1]},data);
  reg [4:0] cnt = 0;
  // Video generation
  always@(posedge clk) begin
    if (!rst)
      rgb <= 12'd0;
    else if (de) begin
      if (data[~x[3:1]])
           rgb <= c;
      else rgb <= {x[7:0],8'h00,y[7:0]};
    end else rgb <= 0;
    if(x1==0&&y==0)cnt <= cnt + 1'd1;
    if (de && cnt==0 && y[3:0] == 0) begin
        case (x[3:0])
            0: begin
                ram_write = (ram_read==9)?1'd0:(ram_read+1'd1);
                ram_writeenable = 1;
            end
            1: begin
              ram_writeenable = 0;
            end
        endcase
    end
  end

endmodule
module Color(input [1:0] addr, output [23:0] data);
  assign data = mem[addr];
  localparam [23:0] mem[0:3] = '{
      24'h888888,
      24'hbbbbbb,
      24'hffffff,
      24'hbbbbbb
  };
endmodule
module digits_data(input [6:0] addr, output [7:0] data
);
  assign data = bitarray[addr];

  localparam [7:0] bitarray[0:127] = '{
      8'b11111001,
      8'b10001000,
      8'b10001001,
      8'b10001000,
      8'b11111001,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      
      8'b01100000,
      8'b00100001,
      8'b00100000,
      8'b00100001,
      8'b11111000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b11111000,
      8'b00001000,
      8'b11111000,
      8'b10000000,
      8'b11111000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b11111000,
      8'b00001000,
      8'b11111000,
      8'b00001000,
      8'b11111000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b10001000,
      8'b10001000,
      8'b11111000,
      8'b00001000,
      8'b00001000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b11111000,
      8'b10000000,
      8'b11111000,
      8'b00001000,
      8'b11111000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b11111000,
      8'b10000000,
      8'b11111000,
      8'b10001000,
      8'b11111000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b11111000,
      8'b00001000,
      8'b00001000,
      8'b00001000,
      8'b00001000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b11111000,
      8'b10001000,
      8'b11111000,
      8'b10001000,
      8'b11111000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b11111000,
      8'b10001000,
      8'b11111000,
      8'b00001000,
      8'b11111000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,

      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000,
      8'b00000000
  };
endmodule

module RAM_sync(input clk, write_enable, [9:0] addr, [7:0] din, 
                output [7:0] dout);
  initial begin
    integer i,j;
    j=0;
    for (i=0;i<1024;i++) begin
      mem[i] = j;
      j = j == 9 ? 0 : j+1;
    end
  end
  reg [7:0] mem [0:1023]; // 1024バイトメモリ

  always @(posedge clk) begin
    if (write_enable)		// if write enabled
      mem[addr] = din;	// write memory from din
  end
  assign dout = mem[addr];	// read memory to dout (sync)
endmodule
