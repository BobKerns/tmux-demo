# VS Code Remote-SSH トラブルシューティング

[English](vscode-troubleshooting.md)

VS Code Remote-SSHを使用する際の一般的な問題と解決策。

---

## 目次

1. [接続失敗](#接続失敗)
2. [VS Code Serverのインストール失敗](#vs-code-serverのインストール失敗)
3. [接続の切断/タイムアウト](#接続の切断タイムアウト)
4. [Permission Denied](#permission-denied)
5. [拡張機能が動作しない](#拡張機能が動作しない)
6. [ファイルウォッチャーの制限(Linux)](#ファイルウォッチャーの制限linux)
7. [パフォーマンスの低下](#パフォーマンスの低下)
8. [追加のヒント](#追加のヒント)

---

## 接続失敗

**症状:**
```
Could not establish connection to "hostname".
The process tried to write to a pipe that has been closed.
```

**解決策:**

### 1. 手動でSSH接続をテスト

```bash
ssh -v hostname
```

詳細出力でエラーを確認。一般的な問題:
- ホストに到達できない
- Permission denied
- 接続拒否
- ポートが間違っている

### 2. SSH設定を確認

`~/.ssh/config`のエントリを確認:

```
Host myserver
    HostName correct.server.address
    User correct-username
    Port 22
    IdentityFile ~/.ssh/correct-key
```

手動でテスト:
```bash
ssh -F ~/.ssh/config hostname
```

### 3. 鍵のパーミッションを確認

SSHは不適切なパーミッションの鍵を拒否します:

```bash
# 秘密鍵のパーミッションを修正
chmod 600 ~/.ssh/your-key

# .sshディレクトリを修正
chmod 700 ~/.ssh
```

### 4. Docker: コンテナが実行中であることを確認

```bash
# コンテナのステータスを確認
docker ps

# 停止している場合は起動
docker start tmux-demo

# ログを確認
docker logs tmux-demo
```

### 5. EC2: セキュリティグループを確認

- セキュリティグループがあなたのIPからのSSH(ポート22)を許可している必要があります
- AWSコンソール → EC2 → セキュリティグループを確認
- ルールを追加: Type=SSH、Source=My IP

### 6. 企業ネットワークの場合

- 企業のファイアウォールがSSHをブロックしている可能性があります
- 別のネットワークから試してください
- プロキシ設定についてIT部門に確認

---

## VS Code Serverのインストール失敗

**症状:**
```
Failed to install VS Code Server
Could not install Visual Studio Code Server
```

**解決策:**

### 1. リモートのディスク空き容量を確認

VS Code Serverには少なくとも1GBの空き容量が必要:

```bash
# ディスク使用量を確認
df -h ~

# ホームディレクトリのサイズを確認
du -sh ~/.vscode-server
```

必要に応じて空き容量を確保:
```bash
# 古いサーバーバージョンを削除
rm -rf ~/.vscode-server/bin/*
```

### 2. 手動クリーンアップと再試行

完全リセット:

```bash
# VS Code Serverディレクトリ全体を削除
rm -rf ~/.vscode-server

# 拡張機能も削除(オプション)
rm -rf ~/.vscode-server-insiders
```

その後、VS Codeから再接続。

### 3. リモートのインターネット接続を確認

VS CodeはMicrosoftからサーバーをダウンロードします:

```bash
# 接続をテスト
curl -I https://update.code.visualstudio.com

# 期待される結果: HTTP/2 200
```

curlが失敗する場合:
- リモートホストにインターネットがない
- ファイアウォールがダウンロードをブロック
- DNS解決の問題

### 4. ダウンロードをブロックするファイアウォール

企業のファイアウォールが`update.code.visualstudio.com`をブロックしている可能性:

- IT部門に連絡
- VS Codeドメインのホワイトリスト登録を依頼
- 別のネットワーク(自宅、モバイルホットスポット)から試す

### 5. 手動インストール

サーバーを手動でダウンロード:

```bash
# VS CodeのコミットIDを取得
code --version  # 最初の行がコミットID

# サーバーを手動でダウンロード(リモート上で)
wget https://update.code.visualstudio.com/commit:$COMMIT_ID/server-linux-x64/stable

# ~/.vscode-server/bin/$COMMIT_IDに展開
```

---

## 接続の切断/タイムアウト

**症状:**
- 接続は最初は動作するが、非アクティブ後に切断される
- "Connection lost"エラー
- 頻繁に再接続が必要

**解決策:**

### 1. SSH設定にキープアライブを追加

SSHのタイムアウトを防ぐ:

```
Host myserver
    HostName server.address
    User developer
    IdentityFile ~/.ssh/tmux_demo_key
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

**説明:**
- `ServerAliveInterval 60`: 60秒ごとにキープアライブを送信
- `ServerAliveCountMax 3`: あきらめる前に3回試行
- 合計タイムアウト: 180秒

### 2. 不安定な接続にはtmuxを使用

**信頼性の低いネットワークに最適な解決策:**

[tmux統合ガイド](vscode-tmux-integration.md)を参照

利点:
- 作業は切断を生き延びる
- すぐに再接続して再開
- バックグラウンドプロセスが実行し続ける

クイックセットアップ:
```bash
# リモートにtmuxをインストール(まだの場合)
sudo apt install tmux

# セッションを開始
tmux new -s vscode

# 後で: 切断後に再接続
tmux attach -t vscode
```

### 3. VS Codeタイムアウト設定を調整

接続タイムアウトを増加:

```json
{
  "remote.SSH.connectTimeout": 60,
  "remote.SSH.serverPickPortsFromRange": {
    "5000": "5100"
  }
}
```

VS Codeユーザー設定に追加。

### 4. ネットワークの安定性を確認

```bash
# 接続の安定性をテスト
ping -c 100 your-server.com

# パケット損失を確認
mtr your-server.com
```

高いping時間やパケット損失はネットワークの問題を示します。

---

## Permission Denied

**症状:**
```
Permission denied (publickey).
developer@server: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
```

**解決策:**

### 1. SSH鍵が設定されていることを確認

SSH設定を確認:

```bash
cat ~/.ssh/config
```

`IdentityFile`が正しい鍵を指していることを確認:
```
Host myserver
    IdentityFile ~/.ssh/tmux_demo_key
```

### 2. 公開鍵がリモートにあることを確認

あなたの**公開鍵**(`.pub`)がリモートの`authorized_keys`にある必要があります:

```bash
# リモートホスト上で
cat ~/.ssh/authorized_keys

# あなたの公開鍵が含まれているはず
```

ない場合は追加:
```bash
# 公開鍵をクリップボードにコピー
cat ~/.ssh/tmux_demo_key.pub

# リモートにSSHして追加
ssh user@host
echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

または`ssh-copy-id`を使用:
```bash
ssh-copy-id -i ~/.ssh/tmux_demo_key.pub user@host
```

### 3. 鍵のパーミッションを確認

**ローカルマシン:**
```bash
chmod 600 ~/.ssh/tmux_demo_key
chmod 644 ~/.ssh/tmux_demo_key.pub
chmod 700 ~/.ssh
```

**リモートマシン:**
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### 4. SSHエージェント内の鍵を確認(使用している場合)

```bash
# エージェント内の鍵を一覧表示
ssh-add -l

# 空の場合、鍵を追加
ssh-add ~/.ssh/tmux_demo_key
```

### 5. 詳細出力で手動テスト

```bash
ssh -vv user@host

# 以下を探す:
# "Trying private key: /home/user/.ssh/tmux_demo_key"
# "Authentication succeeded (publickey)"
```

完全なSSHセットアップヘルプについては:
[SSH セットアップガイド - トラブルシューティング](ssh-setup.md#troubleshooting)

---

## 拡張機能が動作しない

**症状:**
- 拡張機能はインストールされているが機能しない
- 機能が欠けている
- 拡張機能のコマンドが表示されない

**解決策:**

### 1. ローカルではなくリモートに拡張機能をインストール

Remote-SSH経由で接続時:

1. 拡張機能ビューを開く(`Ctrl+Shift+X`)
2. 拡張機能を見つける
3. "Install in SSH: hostname"ボタンを探す
4. クリックしてリモートにインストール

**理由:** 一部の拡張機能はリモートマシン上で実行する必要があります。

### 2. 拡張機能がリモートをサポートしていることを確認

すべての拡張機能がRemote-SSHで動作するわけではありません:

- 拡張機能ページで"Remote"バッジを確認
- サポートされている機能で"Remote Development"を探す
- 一部のUIのみの拡張機能はローカルでのみ動作

### 3. VS Codeウィンドウをリロード

拡張機能インストール後:

```
Ctrl+Shift+P → "Developer: Reload Window"
```

これにより拡張機能が適切にアクティブ化されます。

### 4. 拡張機能ホストログを確認

```
Ctrl+Shift+P → "Developer: Show Logs" → "Extension Host"
```

拡張機能からのエラーを探す。

### 5. 拡張機能を再インストール

1. 拡張機能をアンインストール(リモート上で)
2. ウィンドウをリロード
3. 拡張機能を再インストール
4. 再度ウィンドウをリロード

---

## ファイルウォッチャーの制限(Linux)

**症状:**
```
Visual Studio Code is unable to watch for file changes in this large workspace
```

**原因:**

Linuxはファイル監視の数を制限します(inotify)。大規模プロジェクトはデフォルト制限を超えます。

**解決策:**

### 一時的な増加

```bash
sudo sysctl fs.inotify.max_user_watches=524288
```

再起動でリセットされます。

### 永続的な増加

```bash
# sysctl設定に追加
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf

# すぐに適用
sudo sysctl -p
```

### 代替: 監視からディレクトリを除外

制限を増やさず、監視するファイルを減らす:

```json
{
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/**": true,
    "**/dist/**": true,
    "**/build/**": true,
    "**/__pycache__/**": true,
    "**/.venv/**": true
  }
}
```

ワークスペース設定に追加。

---

## パフォーマンスの低下

**症状:**
- 入力の遅延
- ファイル操作が遅い
- IntelliSenseの遅延
- 高いCPU/メモリ使用量

**解決策:**

### 1. ファイルウォッチャーを削減

不要なディレクトリを除外:

```json
{
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/node_modules/**": true,
    "**/dist/**": true,
    "**/build/**": true,
    "**/__pycache__/**": true,
    "**/.pytest_cache/**": true,
    "**/.venv/**": true,
    "**/venv/**": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.venv": true
  }
}
```

### 2. 未使用の拡張機能を無効化

各拡張機能がリソースを消費:

1. 拡張機能ビューを開く(`Ctrl+Shift+X`)
2. 未使用の拡張機能を右クリック
3. "Disable"または"Disable (Workspace)"を選択

### 3. 未使用のターミナルを閉じる

各ターミナルがメモリとCPUを消費:

- 使用していないターミナルを閉じる
- 1つのターミナルで複数のシェルを管理するにはtmuxを使用

### 4. 検索範囲を削減

検索時:

```json
{
  "search.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/.git": true,
    "**/__pycache__": true
  }
}
```

### 5. 言語サービスの問題を確認

Python用:

```json
{
  "python.analysis.indexing": true,
  "python.analysis.autoImportCompletions": false
}
```

インデックス作成は最初の接続時に遅くなる可能性があります - 完了を待ちます。

### 6. EC2: 適切なインスタンスタイプを使用

- 最小: t3.small (2 vCPU、2GB RAM)
- 推奨: t3.medium (2 vCPU、4GB RAM)
- 大規模プロジェクト用: t3.large以上

CloudWatchでインスタンスメトリクスを確認。

### 7. ネットワーク遅延

高いping時間は応答性に影響:

```bash
# 遅延を確認
ping -c 20 your-server.com

# 許容範囲: < 50ms
# 気になる遅延: > 100ms
# 遅い: > 200ms
```

解決策:
- 同じリージョンのサーバーを使用
- すべてのターミナル作業にtmuxを使用
- 非常に高い遅延の場合はローカル開発を検討

---

## 追加のヒント

### 接続トラブルシューティングワークフロー

```bash
# 1. 基本的な接続性をテスト
ping server.address

# 2. 手動でSSHをテスト
ssh -v user@server

# 3. VS CodeのSSH設定でテスト
ssh -F ~/.ssh/config hostname

# 4. VS Code Remote-SSHの出力を確認
# View → Output → Remote-SSH
```

### より多くの診断情報を取得

VS Codeで:

1. `Ctrl+Shift+P`
2. "Remote-SSH: Show Log"
3. エラー、警告を探す
4. ヘルプを求める際に関連セクションをコピー

### すべてをリセット

何も機能しない場合の最終手段:

```bash
# ローカルマシン上で
rm -rf ~/.ssh/config.d/vscode-*
rm -rf ~/.vscode/extensions/ms-vscode-remote.*

# リモートマシン上で
rm -rf ~/.vscode-server

# VS Codeを再起動
```

その後、最初から再設定。

---

## 関連ドキュメント

- [VS Code Remote-SSHセットアップ](vscode-remote-ssh.md)
- [SSHセットアップガイド](ssh-setup.md)
- [tmux統合ガイド](vscode-tmux-integration.md)(接続の安定性のため)
- [公式VS Code Remote-SSHトラブルシューティング](https://code.visualstudio.com/docs/remote/troubleshooting)

**それでも解決しない場合:**
- [VS Code Remote-SSH GitHubイシュー](https://github.com/microsoft/vscode-remote-release/issues)を確認
- [VS Codeディスカッション](https://github.com/microsoft/vscode-discussions)で質問
- 含める情報: VS Codeバージョン、OS、SSHログ出力
