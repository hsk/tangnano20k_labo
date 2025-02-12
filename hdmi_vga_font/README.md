# hdmi_vga_font

Sipeed Tang nano 20Kで8x8のフォントをHDMI出力を自前でするサンプルです。

フォント情報は256文字 reg/font.png で画像データとして用意してあり、mk.pyでsrc/char.txtに出力して $readmemb を用いてメモリ上に読み込みます。

HDPI IPは使わず、rPLLだけを使ってRGB信号をDVI信号に変換してHDMI端子に送っています。
これは https://www.fpga4fun.com/HDMI.html からの移植で、 https://projectf.io/tutorials/ からのチュートリアルをマージしたもの https://github.com/GthiN89/FPGA-HDMI-TEST を改造したものです。

リセットボタンを押すと画面表示をリセットできるのでうまく表示されない場合はリセットボタンを押してみてください。
開発に使用しているキャプチャボードでは DVI 出力のみの場合に画像によって非表示のままになることがあります。
同期が着実に取れる画面を一定期間出力すると確実に表示されるので、zzの信号を送った後に暗い青画面を表示しリセットがかかります。
