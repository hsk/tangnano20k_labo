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
    input clk, rstn,
    input [22:0] fl_a, fl_cs, output reg [15:0] fl_o,
    output mspio[2], inout mspid[2],
    output reg busy
);
    assign mspio = {clk,mspi_cs};
    reg mspi_cs;
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
    assign mspid[1]   = output_en[1]?data_out[1]:1'bz;
    assign mspid[0]   = output_en[0]?data_out[0]:1'bz;

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
            (state== 6'd8)?{1'b0,fl_a[22]}:
            (state== 6'd9)?fl_a[21:20]:
            (state==6'd10)?fl_a[19:18]:
            (state==6'd11)?fl_a[17:16]:
            (state==6'd12)?fl_a[15:14]:
            (state==6'd13)?fl_a[13:12]:
            (state==6'd14)?fl_a[11:10]:
            (state==6'd15)?fl_a[9:8]:
            (state==6'd16)?fl_a[7:6]:
            (state==6'd17)?fl_a[5:4]:
            (state==6'd18)?fl_a[3:2]:
            (state==6'd19)?{fl_a[1],1'b0}:
            (state==6'd20)?M[7:6]:
            (state==6'd21)?M[5:4]:
            (state==6'd22)?M[3:2]:
            (state==6'd23)?M[1:0]:
            2'bzz;   
    
    wire [1:0] dspi_in = { mspid[1], mspid[0] };  
    
    always @(posedge clk or negedge rstn) begin
        reg csD, csD2;
        
        if(!rstn) begin
            // initially assume regular spi mode
            dspi_mode <= 1'b0;
            mspi_cs <= 1'b1;      
            busy <= 1'b0;
            init <= 5'd20;
            csD <= 1'b0;
        end else begin
            csD <= fl_cs; // flash_csをローカル・クロック・ドメインに取り込む
            csD2 <= csD;     // 立ち上がりエッジ検出遅延

            // send 16 1's on IO0 to make sure M4 = 1 and dspi is left and we are in a known state
            if(init != 5'd0) begin
                if(init == 5'd20) mspi_cs <= 1'b0;  // select flash chip at begin of 16 1's	 
                if(init == 5'd4)  mspi_cs <= 1'b1;  // de-select flash chip at end of 16 1's
                if(init != 5'd1 || !busy)
                    init <= init - 5'd1;
            end
            
            // wait for rising edge of fl_cs or end of init phase
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
                if(state == 6'd25) fl_o[15:14] <= dspi_in;
                if(state == 6'd26) fl_o[13:12] <= dspi_in;
                if(state == 6'd27) fl_o[11:10] <= dspi_in;
                if(state == 6'd28) fl_o[9:8]   <= dspi_in;
                if(state == 6'd29) fl_o[7:6]   <= dspi_in;
                if(state == 6'd30) fl_o[5:4]   <= dspi_in;
                if(state == 6'd31) fl_o[3:2]   <= dspi_in;
                if(state == 6'd32) fl_o[1:0]   <= dspi_in;

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
  input clk,
  output reg [7:0] bw, reg [15:0] bw_a, reg bw_e,
  output mspio[2], inout mspid[2]
);
  reg fl_cs; reg [22:0] fl_a; wire [15:0] fl_o;
  reg rstn = 0;
  always @(posedge clk) rstn <= 1;
  reg [31:0] t; reg [7:0] bw_buf;
  // 通信で書き込みアドレスとデータを取得する
  always @(posedge clk) begin
      if (!rstn) begin
          t <= 32'd0;
          fl_cs <= 1'b0;
          fl_a <= 23'h100000;
          bw_a <= 0;
      end else if (!fl_a[16]) begin
          t <= t + 32'd1;
          fl_cs <= 1'b0; // 基本的には読み込みフラグは立てない
          if(t == 32'd15) fl_cs <= 1'b1; // 読み込みフラグを立てる
          if(t == 32'd15+31) begin // １バイト目読み込み
              bw_e <= 1;
              bw <= fl_o[7:0];
              bw_a <= fl_a+1'd1;
              bw_buf <= fl_o[15:8];
              fl_a = fl_a + 23'd2;
              if (!fl_a[16]) fl_cs <= 1'b1;// 次の読み込みを開始する
          end
          if(t == 32'd15+31+1) begin // ２バイト目を読み込み
              bw <= bw_buf;
              bw_a <= bw_a-1'd1;
          end
          if(t == 32'd15+31+2) begin // アドレスとカウンタを更新してループ
              t <= 32'd18;
              bw_e <= 0;
          end
      end
  end
  wire busy;
  flash flash (
      .clk(clk), .rstn(rstn),
      .fl_a(fl_a), .fl_cs(fl_cs), .fl_o(fl_o),
      .mspio(mspio), .mspid(mspid), .busy(busy));
endmodule
