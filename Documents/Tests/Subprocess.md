# 終了状態APIのテスト観点

- TerminationStatus: exited/signaled、等価比較、isSuccess、exitCode、signal、description。
- wait statusの復号: 0/255、シグナル、core dumpビット、未終了状態の拒否。
- Result.init/status/output/error/asBinary/asString/map: 通常成功・非ゼロ終了・シグナル終了と部分出力の保持。
- wait: SIGTERM/SIGKILLとexit 143の区別、stdout/stderrの回収。
- stream: 正常・非ゼロ・シグナルの終了イベント、待機エラーの送出、偽の終了イベントを生成しないこと。

Unitsは値と変換、Semanticsは実プロセスの終了とストリームの意味を検証する。
