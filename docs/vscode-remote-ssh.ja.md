# VS Code Remote-SSH 完全ガイド

[English](vscode-remote-ssh.md)

Visual Studio CodeのRemote-SSH拡張機能を使用してリモートマシンで開発する包括的なガイド。

---

## 目次

1. [概要](#概要)
2. [前提条件](#前提条件)
3. [インストール](#インストール)
4. [設定](#設定)
5. [接続](#接続)
6. [リモートでの作業](#リモートでの作業)
7. [tmuxとの統合](#tmuxとの統合)
8. [トラブルシューティング](#トラブルシューティング)
9. [ヒントとベストプラクティス](#ヒントとベストプラクティス)
10. [クイックリファレンス](#クイックリファレンス)

---

## 概要

VS Code Remote-SSHを使用すると、ローカルマシンのVS Codeエディタを使って、SSH経由でリモートマシン上のコードを開発できます。

### 仕組み

1. **ローカルVS Code:** ユーザーインターフェースがローカルで実行
2. **SSH接続:** リモートマシンへの安全な接続
3. **リモートVS Code Server:** リモートマシンで自動的にインストール・実行
4. **透過的な体験:** ローカルで作業しているかのように感じる

### メリット

- **強力なリモートリソース:** 軽量なラップトップで強力なサーバーを使用
- **一貫した環境:** どのデバイスからも同じ開発環境
- **ローカルのような体験:** 通常のVS Code機能がすべて動作
- **低帯域幅:** UI traffic のみ、ファイルはリモートに保存
- **拡張機能のサポート:** ほとんどの拡張機能がリモートで動作

---

## 前提条件

### ローカルマシン

- **VS Code** 1.35以降
- **SSHクライアント**
  - macOS/Linux: 通常プリインストール
  - Windows 10/11: OpenSSH Client (通常含まれる)
  - 古いWindows: [Git for Windows](https://git-scm.com/download/win)をインストール

SSHクライアントの確認:

```bash
ssh -V
```

出力例: `OpenSSH_8.x`

### リモートマシン

- **SSHサーバー実行中**
- **サポートされるOS:**
  - Linux (x86_64、ARMv7l、ARMv8l/AArch64)
  - macOS 10.14以降
  - Windows 10/Server 2016/2019 (WSL経由)

**このプロジェクトの場合:**

- **Docker:** Ubuntu 24.04、SSHはポート2222
- **AWS EC2:** Ubuntu 24.04、SSHはポート22

---

## インストール

### 方法 1: 拡張機能ビュー(推奨)

**1. VS Codeを開く**

**2. 拡張機能ビューを開く:**

- macOS: `Cmd+Shift+X`
- Windows/Linux: `Ctrl+Shift+X`

**3. "Remote - SSH"を検索**

**4. Microsoftが提供する"Remote - SSH"をインストール**

![Remote - SSH拡張機能](https://code.visualstudio.com/assets/docs/remote/ssh/remote-ssh-extension.png)

### 方法 2: コマンドライン

```bash
code --install-extension ms-vscode-remote.remote-ssh
```

### 方法 3: 拡張機能パック

**"Remote Development"**拡張機能パックには以下が含まれます:

- Remote - SSH
- Remote - Containers
- Remote - WSL

```bash
code --install-extension ms-vscode-remote.vscode-remote-extensionpack
```

### インストール確認

インストール後、VS Codeの左下隅に緑色の**"リモートウィンドウを開く"**ボタンが表示されます。

---

## 設定

### SSH設定ファイル

最適な体験のため、SSH設定ファイルを作成:

**ファイルの場所:**

- macOS/Linux: `~/.ssh/config`
- Windows: `C:\Users\YourName\.ssh\config`

### 設定例

**Dockerとポート:**

```
Host tmux-demo
    HostName localhost
    Port 2222
    User developer
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**AWS EC2:**

```
Host aws-dev
    HostName ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
    Port 22
    User ubuntu
    IdentityFile ~/.ssh/aws-key.pem
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host aws-prod
    HostName ec2-yy-yyy-yyy-yyy.compute-1.amazonaws.com
    Port 22
    User ubuntu
    IdentityFile ~/.ssh/aws-prod-key.pem
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### 重要なオプション

| オプション | 目的 | Docker | AWS |
| ----------- | ------ | -------- | ----- |
| `ServerAliveInterval` | キープアライブ(秒) | オプション | **必須** |
| `ServerAliveCountMax` | 切断までの再試行 | オプション | **推奨** |
| `StrictHostKeyChecking` | ホスト鍵検証 | `no` (テスト) | `yes` (本番) |
| `UserKnownHostsFile` | 既知ホスト保存 | `/dev/null` | デフォルト |

### VS Code SSH設定

**VS Code設定 (`settings.json`):**

```json
{
  "remote.SSH.showLoginTerminal": true,
  "remote.SSH.remotePlatform": {
    "tmux-demo": "linux",
    "aws-dev": "linux",
    "aws-prod": "linux"
  },
  "remote.SSH.connectTimeout": 15,
  "remote.SSH.enableDynamicForwarding": true
}
```

**設定の説明:**

- `showLoginTerminal`: 接続ログを表示(デバッグに有用)
- `remotePlatform`: リモートOSを指定(自動検出の高速化)
- `connectTimeout`: 接続タイムアウト(秒)
- `enableDynamicForwarding`: 動的ポートフォワーディング

---

## 接続

### 方法 1: コマンドパレット(推奨)

**1. コマンドパレットを開く:**

- macOS: `Cmd+Shift+P`
- Windows/Linux: `Ctrl+Shift+P`

**2. "Remote-SSH: Connect to Host..."を入力**

**3. ホストを選択:**

- 設定ファイルのホスト (例: `tmux-demo`, `aws-dev`)
- または "Configure SSH Hosts..." で新しいホストを追加

**4. 新しいVS Codeウィンドウが開きます**

初回接続時:

- VS Code Serverがリモートマシンにインストールされます
- フィンガープリントの確認を求められる場合があります
- リモートOS認識メッセージ

### 方法 2: Remote Explorer

**1. アクティビティバーの"Remote Explorer"をクリック**

![Remote Explorer アイコン](https://code.visualstudio.com/assets/docs/remote/ssh/remote-explorer-icon.png)

**2. "SSH Targets"セクションを展開**

**3. ホストにマウスオーバーして"Connect"をクリック**

### 方法 3: クイック接続

**1. 左下隅の緑色のボタンをクリック**

**2. "Connect to Host..."を選択**

**3. ホストを選択またはSSH接続文字列を入力:**

```
user@hostname
```

### 接続状態の確認

接続成功時:

- **左下隅:**  `SSH: tmux-demo`または`SSH: aws-dev`と表示
- **ターミナル:** リモートマシンのシェルプロンプト
- **ファイルエクスプローラー:** リモートマシンのファイルシステム

---

## リモートでの作業

接続後、通常どおりVS Codeを使用します。すべてがリモートで実行されます!

### フォルダーを開く

**1. "File" → "Open Folder..."** または `Cmd/Ctrl+O`

**2. リモートマシン上のフォルダーに移動:**

```
/home/developer/projects
/home/ubuntu/myapp
```

**3. "OK"をクリック**

VS Codeがフォルダーをリモートで開きます。

### ターミナル

**統合ターミナルを開く:**

- macOS: `` Ctrl+` ``
- Windows/Linux: `` Ctrl+` ``

ターミナルは**リモートマシン上**で実行されます!

```bash
# リモートマシン上
pwd            # リモートの作業ディレクトリ
ls             # リモートのファイル
tmux           # tmuxを起動
```

**複数ターミナル:**

- 新しいターミナル: `Cmd/Ctrl+Shift+` `
- ターミナル間を切り替え: ドロップダウン

### 拡張機能

拡張機能はローカルまたはリモートにイン各ストールできます。

**リモートに拡張機能をインストール:**

**1. 拡張機能ビューを開く:** `Cmd/Ctrl+Shift+X`

**2. 拡張機能を見つける**

**3. "Install in SSH: tmux-demo"をクリック**

**推奨されるリモート拡張機能:**

- **Python:** `ms-python.python`
- **Pylance:** `ms-python.vscode-pylance`
- **GitLens:** `eamodio.gitlens`
- **Docker:** `ms-azuretools.vscode-docker`
- **Remote - SSH: Editing Configuration Files:** リモートで設定編集

**ローカルに留まる拡張機能:**

- テーマ
- キーマップ
- スニペット (プロジェクト固有でない限り)

### Gitの使用

Git操作はリモートで実行:

**1. 統合ターミナル:**

```bash
git clone https://github.com/user/repo.git
cd repo
git checkout -b feature
```

**2. ソース管理ビュー:**

- 変更をステージング
- コミット
- プッシュ/プル
- ブランチ切り替え

すべてリモートリポジトリで動作します!

### デバッグ

リモートマシンでコードをデバッグ:

**1. ブレークポイントを設定**

**2. "Run and Debug"ビューを開く:** `Cmd/Ctrl+Shift+D`

**3. デバッグ設定を選択またはCopilot成**

**4. デバッグセッション変数が開始:** ブレークポイント、変数、デバッグコンソールがリモートで動作

---

## tmuxとの統合

VS Code Remote-SSHとtmuxを組み合わせることで最大の柔軟性が得られます。

### シナリオ: いつtmuxを使用するか

**VS Code Remote-SSHのみ:**

- VS Codeでコード編集
- 短時間のタスク (コンパイル、テスト)
- 主にGUIツールを使用

**Remote-SSH + tmux:**

- 長時間実行プロセス (サーバー、ビルド)
- VS Code接続が切れてもプロセスを保持
- 複数ペイン/ウィンドウ
- SSHターミナルからも同じセッションにアクセス

### オプション 1: 手動でtmuxを使用

最もシンプル - 必要に応じて起動:

**1. VS CodeリモートターミナルでOKomu**

**2. tmuxを起動:**

```bash
tmux
# またはコマンド名付きセッション
tmux new -s myproject
```

**3. 通常どおり作業**

**4. デタッチ:** `Ctrl+^ d`

**5. 再接続:**

```bash
tmux attach -t myproject
```

### オプション 2: 自動tmux接続

VS Codeターミナルが開くたびに自動的にtmuxセッションに接続:

**VS Code `settings.json`:**

```json
{
  "terminal.integrated.profiles.linux": {
    "tmux": {
      "path": "tmux",
      "args": ["new-session", "-A", "-s", "vscode"]
    }
  },
  "terminal.integrated.defaultProfile.linux": "tmux"
}
```

**この設定:**

- 新しいターミナルが "vscode" セッションに自動接続
- セッションが存在しない場合は作成
- すべてのターミナルが同じtmuxセッションを共有

**注意:** すべてのターミナルが同じセッションに接続されます。独立したターミナルが必要な場合は、手動方法を使用してください。

### オプション 3: シェルプロファイルでカスタム

より高度な制御:

**`~/.bashrc` または `~/.zshrc` に追加:**

```bash
# VS Codeリモート環境でのみtmuxを自動起動
if [ -n "$VSCODE_IPC_HOOK_CLI" ] && command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    # tmuxセッションに接続、無ければ作成
    tmux attach-session -t vscode || tmux new-session -s vscode
fi
```

**この設定:**

- VS Codeのターミナルでのみ動作
- 既にtmux内にいる場合はネストしない
- セッション "vscode" を使用

**もっと高度な:** 異なる動作:

```bash
# ~/.bashrc
if [ -n "$VSCODE_IPC_HOOK_CLI" ]; then
    # VS Codeから
    if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
        echo "tmuxセッション利用可能:"
        tmux list-sessions 2>/dev/null
        echo "接続コマンド: tmux attach -t <name>"
        echo "新規: tmux new -s <name>"
    fi
else
    # Regular SSH
    if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
        # 通常のSSHでは自動接続
        tmux attach || tmux new
    fi
fi
```

### ベストプラクティス: Remote-SSH + tmux

**1. プロジェクトごとに名前付きセッション:**

```bash
tmux new -s frontend
tmux new -s backend
tmux new -s database
```

**2. VS Codeで編集、tmuxで実行:**

- **VS Code:** コード編集、Git、デバッグ
- **tmux:** サーバー実行、ログ監視、長時間ビルド

**3. tmux設定で接続が切れてもプロセス継続:**

VS Code接続が切れても:

```bash
# 別のターミナルから
ssh tmux-demo
tmux attach
# すべてがまだ実行中!
```

**4. tmuxでウインドウと組み合わせを使用:**

```bash
# ウィンドウ 0: エディタ(ただしVS Codeを使う場合は不要)
# ウィンドウ 1: サーバー実行
tmux new-window -n server
npm run dev

# ウィンドウ 2: ログ
tmux new-window -n logs
tail -f /var/log/app.log

# ウィンドウ 3: データベース
tmux new-window -n db
psql myapp
```

**5. マウスモードを使用:**

`.tmux.conf` に既に設定されています:

```
set -g mouse on
```

VS Codeターミナル内でペイン切り替えにクリック可能!

---

## トラブルシューティング

### 接続に失敗

**症状:**

```
Could not establish connection to "tmux-demo"
```

**解決策:**

**1. SSH接続を確認:**

通常のSSH接続をテスト:

```bash
ssh tmux-demo
```

動作しない場合は、[SSHセットアップガイド](ssh-setup.ja.md)を参照

**2. VS Code出力を確認:**

- "View" → "Output"
- ドロップダウンから "Remote - SSH" を選択
- エラーメッセージをチェック

**3. 詳細ログを有効化:**

`settings.json`:

```json
{
  "remote.SSH.showLoginTerminal": true,
  "remote.SSH.logLevel": "trace"
}
```

**4. 接続をリトライ:**

- コマンドパレット: `キャッシュRemote-SSH: Kill VS Code Server on Host...`
- 再接続

### VS Code Serverのインストールに失敗

**症状:**

```
VS Code Server failed to install
```

**解決策:**

**1. ディスク容量を確認:**

```bash
# リモートマシン上で
df -h
```

VS Code Serverには ~200MB必要

**2. パーミッションを確認:**

```bash
ls -la ~/.vscode-server
# インストールできない場合システムは削除:
rm -rf ~/.vscode-server
```

**3. 手動インストール:**

VS Codeが自動的に再試行します。または:

```bash
# ~/.vscode-server/ を削除
rm -rf ~/.vscode-server
# VS Codeに再インストールさせる
```

**4. プロキシ/ファイアウォール:**

リモートマシンがインターネットにアクセスできるか確認:

```bash
curl -I https://update.code.visualstudio.com
```

### タイムアウト/スロー接続

**症状:**

接続が非常に遅い、またはタイムアウト

**解決策:**

**1. タイムアウトを増やす:**

`settings.json`:

```json
{
  "remote.SSH.connectTimeout": 60
}
```

**2. SSH接続を保持:**

`.ssh/config`:

```
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
```

**3. SSH圧縮を無効化 (速いネットワークの場合):**

`.ssh/config`:

```
Host fast-network-host
    Compression no
```

**4. IPv6を無効化 (問題がある場合):**

`.ssh/config`:

```
Host problematic-host
    AddressFamily inet
```

### 拡張機能が動作しない

**症状:**

ローカルでは動作する拡張機能がリモートで動作しない

**解決策:**

**1. リモートにインストール:**

拡張機能ビューで "Install in SSH: hostname" をクリック

**2. 拡張機能の再読み込み:**

- コマンドパレット: `Developer: Reload Window`

**3. 拡張機能のリモートサポート確認:**

すべての拡張機能がリモートをサポートしているわけではありません。拡張機能ページで確認してください。

**4. 依存関係をインストール:**

一部の拡張機能にはリモートツールが必要:

```bash
# 例: Python拡張機能
sudo apt install python3 python3-pip
```

### パーミッションエラー

**症状:**

```
EACCES: permission denied
```

**解決策:**

**1. ファイルパーミッションを確認:**

```bash
ls -la /path/to/file
chmod 644 file  # ファイルの場合
chmod 755 dir   # ディレクトリの場合
```

**2. リモートフォルダーの所有者:**

```bash
# developerとして実行している場合
chownおよび/または-R developer:developer /home/developer/project
```

**3. sudoが必要:**

VS Codeは通常ユーザーとして実行。sudoが必要なタスクはターミナルで実行:

```bash
sudo systemctl restart myservice
```

### ファイルウォッチャーの上限

**症状:**

```
Visual Studio Code is unable to watch for file changes in this large workspace
```

**解決策:**

**リモートマシン上で:**

```bash
# 現在の上限を確認
cat /proc/sys/fs/inotify/max_user_watches

# 上限を増やす(一時的)
sudo sysctl fs.inotify.max_user_watches=524288

# 恒久的に
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### ポート転送が動作しない

**症状:**

リモートポート (例: localhost:3000) にローカルでアクセスできない

**解決策:**

**1. 自動ポート転送は有効:**

VS Codeは通常ショウ動的にポートを転送します。

**2. 手動でポート転送:**

- "Ports"ビューを開く (ターミナルパネル横)
- "Forward a Port"をクリック
- ポート番号を入力: `3000`

**3. SSH設定:**

`.ssh/config`:

```
Host tmux-demo
    LocalForwardことができる 3000 localhost:3000
```

**4. ファイアウォール確認:**

リモートマシンでポートがリッスンしているか確認:

```bash
netstat -tln | grep 3000
```

---

## ヒントとベストプラクティス

### 1. ワークスペースを使用

リモートフォルダーをワークスペースとして保存:

**"File" → "Save Workspace As..."**

次回からワークスペースを開くだけで自動的にリモート接続されます!

### 2. リモート vs ローカル設定

VS Code設定は分離可能:

- **ローカル設定** (`~/Library/Application Support/Code/User/settings.json`): テーマ、フォント
- **リモート設定** (`~/.vscode-server/data/Machine/settings.json`): パス、ツール設定

コマンドパレット:

- `Preferences: Open Settings (UI)`
- ドロップダウンから "Remote" を選択

### 3. SSH Agent転送

ローカルSSHキーをリモートで使用:

`.ssh/config`:

```
Host trusted-host
    ForwardAgent yes
```

**注意:** セキュリティリスクあり。信頼できるホストのみ!

### 4. 開発コンテナへの接続

リモートマシン上のDockerコンテナに接続:

**1. Remote-SSHで接続**

**2. "Remote - Containers"拡張機能をインストール**

**3. コマンドパレット:接続** `Remote-Containers: Attach to Running Container...`

### 5. dotfilesを同期

リモートマシンでdotfilesを自動的にセットアップ:

`settings.json`:

```json
{
  "remote.SSH.enableDotfiles": true,
  "remote.SSH.dotfilesRepository": "https://github.com/yourusername/dotfiles",
  "remote.SSH.dotfilesTargetPath": "~/dotfiles",
  "remote.SSH.dotfilesInstallCommand": "~/dotfiles/install.sh"
}
```

初回接続時にdotfilesがクローン・インストールされます!

### 6. スナップショットを保存 (AWS)

AWS EC2でAMIスナップショットを作成:

- 開発環境をセットアップ
- EC2 → インスタンス → アクション → イメージを作成
- 新しいインスタンスで同じセットアップを再利用

### 7. コスト削減 (AWS)

- **未使用時は停止:** インスタンスを停止 (Elastic IPで同じIP保持)
- **スケジュール:** Lambda関数で自動起動/停止
- **スポットインスタンス:** 開発環境で最大90%節約

### 8. 複数プロジェクト

複数のリモートプロジェクト:

```
Host project1
    HostName ec2-11-111-111-111.compute-1.amazonaws.com
    User ubuntu
    IdentityFile ~/.ssh/project1-key.pem

Host project2
    HostName ec2-22-222-222-222.compute-1.amazonaws.com
    User ubuntu
    IdentityFile ~/.ssh/project2-key.pem
```

各プロジェクトに個別に接続!

### 9. Jump Host

中間サーバー (bastion) 経由で接続:

```
Host bastion
    HostName bastion.company.com
    User您 admin
    IdentityFile ~/.ssh/bastion-key.pem

Host private-server
    HostName 10.0.1.100
    User developer
    ProxyJump bastion
    IdentityFile ~/.ssh/private-key.pem
```

VS Code正しく使い方わAutoると自動的に bastion 経由で private-server に接続します!

### 10. パフォーマンス最適化

**`settings.json`:**

```json
{
  // ウォッチャーを減らす
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/dist/**": true,
    "**/build/**": true
  },

  // ファイルサーチを速く
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/*.code-search": true,
    "**/dist": true,
    "**/build": true
  },

  // シンボリックリンクをフォローしない
  "files.followSymlinks": false
}
```

---

## クイックリファレンス

### キーボードショートカット

| アクション | macOS | Windows/Linux |
| ---------- | ------- | --------------- |
| コマンドパレット | `Cmd+Shift+P` | `Ctrl+Shift+P` |
| ターミナルを開く | `` Ctrl+` `` | `` Ctrl+` `` |
| 新しいターミナル | `` Cmd+Shift+` `` | `` Ctrl+Shift+` `` |
| フォルダーを開く | `Cmd+O` | `Ctrl+O` |
| 拡張機能 | `Cmd+Shift+X` | `Ctrl+Shift+X` |

### よく使うコマンド

| コマンド | 説明 |
| --------- | ------ |
| `Remote-SSH: Connect to Host...` | リモート接続 |
| `Remote-SSH: Open Configuration File...` | SSH設定編集 |
| `Remote-SSH: Kill VS Code Server on Host...` | サーバー再起動 |
| `Remote-SSH: Show Log` | ログ表示 |
| `Forward a Port` | ポート詰転送 |

### 接続クイックテスト

```bash
# 1. SSH接続テスト
ssh tmux-demo

# 2. リモートでtmuxテスト
tmux
Ctrl+^ c    # 新しいウィンドウ
Ctrl+^ d    # デタッチ

# 3. VS Code接続
# Cmd/Ctrl+Shift+P → "Remote-SSH: Connect to Host..." → tmux-demo
```

### ファイル同期

**VS Code Remote-SSHはファイルを同期しません** - リモートで直接編集します!

ファイルのコピーが必要な場合:

```bash
# ローカル → リモート
scp localfile.txt tmux-demo:~/

# リモート → ローカル
scp tmux-demo:~/remotefile.txt ./
```

---

## 参考リンク

- **[SSHセットアップ](ssh-setup.ja.md)** - SSH鍵の作成と設定
- **[PSMUXガイド](psmux-guide.ja.md)** - Windows tmuxクライアント
- **[メインREADME](../README.ja.md)** - プロジェクト概要

### 公式ドキュメント

- [VS Code Remote-SSH Documentation](https://code.visualstudio.com/docs/remote/ssh)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
- [OpenSSH Documentation](https://www.openssh.com/manual.html)

---

**リモート開発をお楽しみください! 🚀**
