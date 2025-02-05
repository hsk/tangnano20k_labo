# TangNano20k研究

本当は入門記事的にリポジトリを作りたいんですが、取り止めもなく色々作ってるものを置く場所が欲しくなったので、置いておきます。

基本

- [x] [led](led) Lチカ。 LED を点滅させる

グラフィックス

- [x] [bg1](bg1) テキストを表示して変える
- [x] [bg2_uart_rx](bg2_uart_rx) テキストを表示して UART で操作する
- [x] [bg3_uart_cobs](bg3_uart_cobs) テキストを表示して UART で COBS エンコーディングで操作する
- [ ] [bg_scr](bg4) テキスト表示＋スクロール
- [ ] [bg_pcg2](bg5_pcg2) PCGが2色のモード
- [ ] [bg_pcg16](bg5_pcg16) PCGが16色のモード
- [ ] [bg_pcg16_scr](bg_pcg16_scr) PCG16色でスクロール
- [ ] [bg_pcg16_rasscr](bg_pcg16_rasscr) PCG16色でラスタスクロール
- [ ] [bg_pcg16_hvrasscr](bg_pcg16_hvrasscr) PCG16色で縦横ラスタスクロール
- [ ] [bg_pcg16_hvcrasscr](bg_pcg16_hvcrasscr) PCG16色で縦横ラスタスクロール+色換え

- [x] [sp](sp) スプライト1個表示する
- [x] [sp1](sp1) スプライトが128個表示する (ラインの制限はなし)
- [x] [frmbuf_uart_cobs](frmbuf_uart_cobs) 256x192で256色のフレームバッファ表示
- [x] [frmbuf_16](frmbuf_16) 1バイトで2ドットの16色でパレット表示のフレームバッファ
- [ ] [frmbuf_p8](frmbuf_p8) 3プレーン8色のRGBフレームバッファ
- [x] [frmbuf_p64](frmbuf_p64) 6プレーン64色のRGBフレームバッファ
- [x] [frmbuf_ham6](frmbuf_ham6) 16色パレット|(r|g|b)の輝度設定のAMIGAのHAM的なフレームバッファ
- [ ] [frmbuf_ham8](frmbuf_ham8) 64色パレット|(r|g|b)の輝度設定のAMIGAのHAM8的なフレームバッファ
- [ ] MSX研鑚推進委員会さんの画像圧縮をハードウェア化

- [ ] [frmbuf_16zoom](frmbuf_16zoom) フレームバッファの拡大縮小
- [ ] ラスタ色かえができるハードウェア
- [ ] スペースハリアーな市松模様
- [ ] F1レースな2車線道路の描画
- [ ] 3車線
- [ ] アップダウンのある道路描画
- [ ] 分岐のある道路描画

オーディオ

- [x] [ym2149](ym2149) HDMIでPSG音源1音鳴らす
- [x] [ym2149_3op](ym2149_3op) HDMIでPSG音源3音鳴らす
- [ ] [ym2413](ym2413) HDMIでOPLLを１音鳴らす
- [ ] [ym2413_3op](ym2413_3op) HDMIでOPLLを３音鳴らす

CPU

- [x] [stack_utx1](stack_utx1) スタックマシンとuart_txで出力1
- [x] [stack_utx2](stack_utx2) スタックマシンとuart_txで出力2
- [ ] [stack_utx3](stack_utx3) スタックマシンとuart_txで出力3
- [ ] [femto8](femto8) femto8

メモリ

SSRAM Shadow SRAM 41472bits 5184bytes
BSRAM Block SRAM 828Kbits   103.5bytes 18Kbits * 46 2.25KBytes * 46
Numbers of B-SRAM 	46
