# トラブル対応パッド

Flutter Webで動く、トラブル対応記録用のサンプルアプリです。

## 起動方法

Flutter SDKをインストールした環境で、リポジトリ直下から次を実行します。

```bash
flutter pub get
flutter run -d chrome
```

Chromeを直接使えない環境では、次のようにWebサーバーとして起動できます。

```bash
flutter run -d web-server
```

表示された `http://localhost:xxxxx` のURLをブラウザで開いてください。

## データ保存

入力した `TroubleRecord` はブラウザの `localStorage` に保存されます。
そのため、同じブラウザで画面更新しても新規保存・編集保存・ステータス変更の内容が残ります。
初回起動時だけサンプルデータを作成します。
