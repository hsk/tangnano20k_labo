//*****************************************************************************
// Serial受信モジュール
//*****************************************************************************
module Serial_rx(
    input CLK, RST, RXD,
    output reg FLAG,  // データの受信が完了したことを示すフラグ
    output reg [7:0] receivedChar
);
    reg [2:0] state;  // 受信状態を表すステート変数
    reg [3:0] bitCount;  // 受信したビットの数をカウントする変数
    reg [7:0] data;  // 受信したデータを一時的に保存する変数
    reg [15:0] divisor_counter;  // ボーレート生成のためのカウンタ

    parameter DELAY_FRAMES = 232/2;  //27,000,000 (27Mhz) / 115200 Baud rate
    parameter HALF_DELAY_WAIT = 116/2;  // 27,000,000 (27Mhz) / 115200 Baud rate /2

    localparam RX_STATE_IDLE = 0;  // 受信状態: アイドル
    localparam RX_STATE_START_BIT = 1;  // 受信状態: スタートビット
    localparam RX_STATE_READ_WAIT = 2;  // 受信状態: データ読み取り待機
    localparam RX_STATE_READ = 3;  // 受信状態: データ読み取り
    localparam RX_STATE_STOP_BIT = 4;  // 受信状態: ストップビット
    localparam RX_STATE_DATA_BITS = 5;  // 受信状態: データビット

    always @(posedge CLK) begin
        if (!RST) begin  // リセットがアクティブな場合
            state <= RX_STATE_IDLE;
            bitCount <= 4'b0000;
            data <= 8'b00000000;
            FLAG <= 1'b0;
            receivedChar <= 8'b00000000;
            divisor_counter <= 16'b0000000000000000;
        end else begin
            case (state)
                RX_STATE_IDLE: begin  // アイドル状態
                    if (RXD == 1'b0) begin  // スタートビットの検出
                        state <= RX_STATE_START_BIT;  // スタートビットの状態に遷移
                        divisor_counter <= 1;  // ボーレート生成のためのカウンタを初期化
                        data <= 8'b00000000;  // 受信データを初期化
                        bitCount <= 0;  // ビットカウントをリセット
                        FLAG <= 0;  // データ受信フラグをリセット
                    end
                end 
                RX_STATE_START_BIT: begin  // スタートビット状態
                    if (divisor_counter == HALF_DELAY_WAIT) begin
                        state <= RX_STATE_READ_WAIT;  // データ読み取り待機状態に遷移
                        divisor_counter <= 1;  // カウンタを初期化
                    end else 
                        divisor_counter <= divisor_counter + 1;  // カウンタをインクリメント
                end
                RX_STATE_READ_WAIT: begin  // データ読み取り待機状態
                    divisor_counter <= divisor_counter + 1;  // カウンタをインクリメント
                    if ((divisor_counter + 1) == DELAY_FRAMES) begin
                        state <= RX_STATE_READ;  // データ読み取り状態に遷移
                    end
                end
                RX_STATE_READ: begin  // データ読み取り状態
                    divisor_counter <= 1;  // カウンタを初期化
                    data <= {RXD, data[7:1]};  // 受信データを更新
                    bitCount <= bitCount + 1;  // ビットカウントをインクリメント
                    if (bitCount == 4'b0111)
                        state <= RX_STATE_STOP_BIT;  // ストップビット状態に遷移
                    else
                        state <= RX_STATE_READ_WAIT;  // データ読み取り待機状態に遷移
                end
                RX_STATE_STOP_BIT: begin  // ストップビット状態
                    divisor_counter <= divisor_counter + 1;  // カウンタをインクリメント
                    if ((divisor_counter + 1) == DELAY_FRAMES) begin
                        state <= RX_STATE_DATA_BITS;  // データビット状態に遷移
                        divisor_counter <= 0;  // カウンタをリセット
                        FLAG <= 1'b1;  // データ受信フラグをセット
                    end
                end
                RX_STATE_DATA_BITS: begin  // データビット状態
                    state <= RX_STATE_IDLE;  // アイドル状態に戻る
                    receivedChar <= data;  // 受信したデータを保存
                    FLAG <= 1'b0;  // データ受信フラグをリセット
                end
           endcase
        end
    end
endmodule
