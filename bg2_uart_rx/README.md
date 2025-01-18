# tangnano20k-hdmi-bg2

これは FPGAのtangnano20k で BG 表示を HDMI 出力をするプロジェクトです。


https://github.com/user-attachments/assets/3a10e844-5958-4bab-afbf-b520e686d0da


gen_video.v 内で BGを表示するためのROMが定義されていて、そこから読み込んで HDMI 表示します。

PCから python を使って UART で情報を送りその情報を受け取ってBGの表示を変化させます。
