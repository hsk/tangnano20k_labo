# tangnano20k-hdmi-bg2

これは FPGAのtangnano20k で BG 表示を HDMI 出力をするプロジェクトです。


https://github.com/user-attachments/assets/d4d2faf3-d10f-4f1f-aea3-354b029290a1


gen_video.v 内で BGを表示するためのROMが定義されていて、そこから読み込んで HDMI 表示します。

PCから python を使って UART で情報を送りその情報を受け取ってBGの表示を変化させます。



