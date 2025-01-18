# tangnano20k-hdmi-bg3

これは FPGAのtangnano20k で BG 表示を HDMI 出力をするプロジェクトです。


https://github.com/user-attachments/assets/d4d2faf3-d10f-4f1f-aea3-354b029290a1


gen_video.v 内で BGを表示するためのROMが定義されていて、そこから読み込んで HDMI 表示します。

PCから python を使って UART で情報を送りその情報を受け取ってBGの表示を変化させます。

bg2 で作った UARTのシリアル通信は同期がいい加減でした。
できればデータ長を設定してデータを送り最初の１バイトで振り分けるなどしたい。
そこでここでは通信方式を用いることでエスケープ処理をするよりも安定して短いデータでデータ長付きの通信を可能とする COBS を用いて通信します。
