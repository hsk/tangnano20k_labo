# tangnano20k-flash

Flashメモリにデータを書き込んでおき、UARTで出力するサンプルです。
100MHzくらいで動くのがマックスっぽいです。

Nano9kとの違いは2バイト読み込みのモードを使っていることで、半分のアドレス値で読み込みます。

書き込み方法は以下のようにすると書けます。

```
	openFPGALoader --external-flash -o 0x100000 text.txt
	openFPGALoader impl/pnr/project.fs
```

0x100000 を読みこむには 0x080000 で読み込むことになる感じなので注意が必要です。

以下のようにコマンド入力するとビットストリームのサイズがわかります:

```
$ python a.py impl/pnr/project.fs
cnt 6EC4D0 bit DD89A bytes 907418.000000 bytes
$ ls -la impl/pnr/project.bin
-r-xr-xr-x  1 hiroshisakurai  staff  907418  2  8 02:15 impl/pnr/project.bin
```

*.fs ファイルは // の後ろはコメントで0か1がデータビットになるテキスト形式のようです。
*.bin ファイルはバイナリ形式のビットストリームデータのようですから、まとめて一気に送れると良さそうです。


