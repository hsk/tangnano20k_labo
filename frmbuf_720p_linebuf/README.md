# tangnano20k-frmbuf_720p_linebuf

これは FPGAのtangnano20k で256x256x8bitのフレームバッファを作って表示するサンプルコードです。

gen_video.v 内でフレームバッファを表示するためのROMが定義されていて、そこから読み込んで HDMI 表示します。

PCから python を使って UART で情報を送りその情報を受け取ってフレームバッファの表示を変化させます。

エスケープ処理をするよりも安定して短いデータでデータ長付きの通信を可能とする COBS を用いて通信し、0が送られてきた場合はリセットがかかるような実装になっています。

720p の 74.2 MHz での動作を可能にしてます。
この解像度で動作させることのメリットは、ピクセルのクロックが非常に高いことです。

ラインバッファを使うように変更します。
