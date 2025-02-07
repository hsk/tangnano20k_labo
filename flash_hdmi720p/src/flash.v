//
// flash_dspi.v - reading W25Q64FV, 64MBit spi flash
//
// このモジュールはDSPI/IOモードでSPIフラッシュを動作させる。
// このモードでは、フラッシュはアドレスとデータに2ビットIOを使用する。
// このモードでは、完全なランダム16ビット読み出しサイクルは32クロックかかる。
// さらに、最初の読み出しでは「連続読み出しモード」が有効になっており、24サイクルで1回の16ビット読み出しが可能である。
//
// 80MHzでは、この結果、ランダムアクセス時間は300nsとなる。
// 100MHzでは240ns、最大許容104MHzでは230nsとなる。
module flash (
    input flash_clk, flash_resetn,
    input [22:0] flash_adr, flash_cs, output reg [15:0] flash_dout,
    output reg mspi_cs, inout mspi_di, mspi_do,
    output reg busy
);
    // drive hold and wp to their static default
    reg dspi_mode; wire [1:0] dspi_out;
    wire [1:0] output_en = { 
        dspi_mode?(state<=6'd22):1'b0,    // io1 is do in SPI mode and thus never driven
        dspi_mode?(state<=6'd22):1'b1     // io0 is di in SPI mode and thus always driven
    };
    wire [1:0] data_out = {
        dspi_mode?dspi_out[1]:1'bx,      // never driven in SPI mode
        dspi_mode?dspi_out[0]:spi_di       
    };
    assign mspi_do   = output_en[1]?data_out[1]:1'bz;
    assign mspi_di   = output_en[0]?data_out[0]:1'bz;

    // use "fast read dual IO" command
    wire [7:0] CMD_RD_DIO = 8'hbb;  
    // M(5:4) = 1,0 -> “Continuous Read Mode”
    wire [7:0] M = 8'b0010_0000;
        
    reg [5:0] state; reg [4:0] init;

    // flash is ready when init phase has ended
    wire flash_ready;
    assign flash_ready = (init == 5'd0);  
    
    // send 16 1's during init on IO0 to make sure M4 = 1 and dspi is left
    wire spi_di = (init>1)?1'b1:CMD_RD_DIO[3'd7-state[2:0]];  // the command is sent in spi mode
    assign dspi_out = 
            (state== 6'd8)?{1'b0,flash_adr[22]}:
            (state== 6'd9)?flash_adr[21:20]:
            (state==6'd10)?flash_adr[19:18]:
            (state==6'd11)?flash_adr[17:16]:
            (state==6'd12)?flash_adr[15:14]:
            (state==6'd13)?flash_adr[13:12]:
            (state==6'd14)?flash_adr[11:10]:
            (state==6'd15)?flash_adr[9:8]:
            (state==6'd16)?flash_adr[7:6]:
            (state==6'd17)?flash_adr[5:4]:
            (state==6'd18)?flash_adr[3:2]:
            (state==6'd19)?{flash_adr[1],1'b0}:
            (state==6'd20)?M[7:6]:
            (state==6'd21)?M[5:4]:
            (state==6'd22)?M[3:2]:
            (state==6'd23)?M[1:0]:
            2'bzz;   
    
    wire [1:0] dspi_in = { mspi_do, mspi_di };  
    
    always @(posedge flash_clk or negedge flash_resetn) begin
        reg csD, csD2;
        
        if(!flash_resetn) begin
            // initially assume regular spi mode
            dspi_mode <= 1'b0;
            mspi_cs <= 1'b1;      
            busy <= 1'b0;
            init <= 5'd20;
            csD <= 1'b0;
        end else begin
            csD <= flash_cs; // flash_csをローカル・クロック・ドメインに取り込む
            csD2 <= csD;     // 立ち上がりエッジ検出遅延

            // send 16 1's on IO0 to make sure M4 = 1 and dspi is left and we are in a known state
            if(init != 5'd0) begin
                if(init == 5'd20) mspi_cs <= 1'b0;  // select flash chip at begin of 16 1's	 
                if(init == 5'd4)  mspi_cs <= 1'b1;  // de-select flash chip at end of 16 1's
                if(init != 5'd1 || !busy)
                    init <= init - 5'd1;
            end
            
            // wait for rising edge of flash_cs or end of init phase
            if((csD && !csD2 && !busy)||(init == 5'd2)) begin
                mspi_cs <= 1'b0;	  // select flash chip	 
                busy <= 1'b1;

                // skip sending command if already in DSPI mode and M(5:4) == (1:0) sent
                if(dspi_mode) state <= 6'd8;
                else	        state <= 6'd0;
            end 

            // run state machine
            if(busy) begin
                state <= state + 6'd1;

                // enter dspi mode after command has been sent
                if(state == 6'd7)
                    dspi_mode <= 1'b1;

                // latch output
                if(state == 6'd25) flash_dout[15:14] <= dspi_in;
                if(state == 6'd26) flash_dout[13:12] <= dspi_in;
                if(state == 6'd27) flash_dout[11:10] <= dspi_in;
                if(state == 6'd28) flash_dout[9:8]   <= dspi_in;
                if(state == 6'd29) flash_dout[7:6]   <= dspi_in;
                if(state == 6'd30) flash_dout[5:4]   <= dspi_in;
                if(state == 6'd31) flash_dout[3:2]   <= dspi_in;
                if(state == 6'd32) flash_dout[1:0]   <= dspi_in;

                // signal that the transfer is done
                if(state == 6'd32) begin
                    state <= 6'd0;	    
                    busy <= 1'b0;
                    mspi_cs <= 1'b1;	// deselect flash chip	 
                end
            end
        end
    end
endmodule

module LoadFromFlash(
  input wire clk,
  input wire rst,
  output reg [7:0] b_w_wd, reg [15:0] b_w_ad, reg b_w_en,
  output mspi_cs, mspi_clk, inout mspi_di, mspi_do
);
  reg flash_cs; reg [22:0] flash_adr; wire [15:0] flash_dout;
  assign mspi_clk = clk;
  reg flash_resetn = 0;
  always @(posedge clk) flash_resetn <= 1;
  reg [31:0] counter;
  // 通信で書き込みアドレスとデータを取得する
  always @(posedge clk) begin
      if(!flash_resetn) begin
          counter <= 32'd0;
          flash_cs <= 1'b0;
          flash_adr <= 23'h100000;
          b_w_ad <= 0;
      end else if (!flash_adr[16]) begin
          counter <= counter + 32'd1;
          flash_cs <= 1'b0; // trigger flash read after 1s
          if(counter == 32'd16_0) flash_cs <= 1'b1; // 1秒後に読み込み
          if(counter == 32'd32_0) begin // 2秒後にアドレスとカウンタを更新してループ
              b_w_en <= 1;
              b_w_wd <= flash_dout[7:0];
              b_w_ad <= {flash_adr[15:1],1'd1};
          end
          if(counter == 32'd32_0+1) begin // 2秒後にアドレスとカウンタを更新してループ
              b_w_wd <= flash_dout[15:8];
              b_w_ad <= {flash_adr[15:1],1'd0};
          end
          if(counter == 32'd32_0+2) begin // 2秒後にアドレスとカウンタを更新してループ
              flash_adr <= flash_adr + 23'd2;
              counter <= 32'd0;
              b_w_en <= 0;
          end
      end
  end
  wire busy;
  flash flash (
      .flash_clk(clk), .flash_resetn(flash_resetn),
      .flash_adr(flash_adr ), .flash_cs( flash_cs ), .flash_dout(flash_dout),
      .mspi_cs(mspi_cs), .mspi_di(mspi_di), .mspi_do(mspi_do), .busy(busy)
  );
endmodule
