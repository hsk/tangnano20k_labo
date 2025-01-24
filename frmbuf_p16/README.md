# tangnano20k-frmbuf_p16

これは FPGAのtangnano20k で256x256x4bitのフレームバッファを作って表示するサンプルコードです。


https://github.com/user-attachments/assets/a3336aa9-85b7-4e05-b027-aab5dbb01dcf


gen_video.v 内でフレームバッファを表示するためのROMが定義されていて、そこから読み込んで HDMI 表示します。

PCから python を使って UART でパレットとビットマップデータを送りその情報を受け取ってフレームバッファの表示を変化させます。

エスケープ処理をするよりも安定して短いデータでデータ長付きの通信を可能とする COBS を用いて通信し、0が送られてきた場合はリセットがかかるような実装になっています。

frmbuf_16 は 1バイトで2ドットの構成ですが、frmbuf_p16 は 8192 バイト * 4 プレーンで構成されています。
