# tangnano20k-frmbuf_uart_cobs

これは FPGAのtangnano20k で256x256x8bitのフレームバッファを作って表示するサンプルコードです。


https://github.com/user-attachments/assets/96eb738b-b23f-4885-b3dc-f562d4946520


gen_video.v 内でフレームバッファを表示するためのROMが定義されていて、そこから読み込んで HDMI 表示します。

PCから python を使って UART で情報を送りその情報を受け取ってフレームバッファの表示を変化させます。

エスケープ処理をするよりも安定して短いデータでデータ長付きの通信を可能とする COBS を用いて通信し、0が送られてきた場合はリセットがかかるような実装になっています。
