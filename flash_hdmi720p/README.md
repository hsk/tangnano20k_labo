# tangnano20k-hdmi-flash

これは FPGAのtangnano20k で HDMI 出力をするプロジェクトです。
flash memory にVRAM情報を書き込んでおき、
起動時に flash memory から読み込みます。

以下のコマンドで flash memory の 0x100000 移行に res/sc8_3.bin を書き込めます。

```
	openFPGALoader --external-flash -o 0x100000 res/sc8_3.bin
```

UARTの通信などをしなくても、 make f としておくだけで電源を落としても flash から読み込んで画像を表示できるので便利です。

