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
7. [ヒントとベストプラクティス](#ヒントとベストプラクティス)
8. [次のステップ](#次のステップ)

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

**推奨されるPython開発用拡張機能:**

- **Python** (Microsoft提供) - IntelliSense、リンティング、デバッグ、コードフォーマット
- **Pylance** (Microsoft提供) - 高速で機能豊富なPython言語サポート
- **Python Debugger** (Microsoft提供) - デバッグサポート
- **GitLens** (GitKraken提供) - Git機能の拡張
- **autoDocstring** (Nils Werner提供) - Pythonドキュメント文字列の自動生成
- **Black Formatter** (Microsoft提供) - Blackによるコードフォーマット

**Python拡張機能のインストール:**

1. 拡張機能ビューを開く(`Ctrl+Shift+X`)
2. 「Python」を検索
3. 各拡張機能の「Install in SSH: hostname」をクリック
4. プロンプトが表示されたらウィンドウをリロード: `Ctrl+Shift+P` → 「Developer: Reload Window」

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

**3. デバッグ設定を選択または作成**

**4. デバッグセッションが開始:** ブレークポイント、変数、デバッグコンソールがリモートで動作

---

## ヒントとベストプラクティス

### 1. ワークスペースを使用

リモートフォルダーをワークスペースとして保存:

**"File" → "Save Workspace As..."**

次回からワークスペースを開くだけで自動的にリモート接続されます!

### 2. リモート vs ローカル設定

- **ユーザー設定**: どこでも適用
- **リモート設定**: 特定のSSH接続のみ
- **ワークスペース設定**: 現在のワークスペースのみ

アクセス方法: `Ctrl+Shift+P` → "Preferences: Open Remote Settings"

### 3. Python仮想環境

VS CodeはPython仮想環境を自動検出:

```bash
# リモートで仮想環境を作成
python3 -m venv .venv

# VS Codeがこのインタープリターの選択を促します
# または手動で: Ctrl+Shift+P → "Python: Select Interpreter"
```

### 4. ポート転送

Webアプリ用にリモートからローカルにポートを転送:

1. リモートでアプリケーションを起動(例: ポート8000で`python app.py`)
2. VS Codeがポートを自動検出
3. または手動で: ターミナル → Portsパネル → "Forward a Port"
4. ローカルマシンで`http://localhost:8000`経由でアクセス

### 5. 複数接続

複数のリモートマシンで同時に作業:

- 各接続で新しいウィンドウが開きます
- ウィンドウは独立しています
- 異なるホストに接続できます

### 6. SSHエージェントを使用

パスフレーズを繰り返し入力しないようにする:

```bash
# SSHエージェントを起動
eval "$(ssh-agent -s)"

# 鍵を追加
ssh-add ~/.ssh/tmux_demo_key

# ログアウトまで鍵が保持されます
```

---

## クイックリファレンス

### 接続

| アクション | コマンド |
| -------- | --------- |
| ホストに接続 | `Ctrl+Shift+P` → "Remote-SSH: Connect to Host" |
| 切断 | "SSH: hostname"をクリック → "Close Remote Connection" |
| ウィンドウをリロード | `Ctrl+Shift+P` → "Developer: Reload Window" |

### ターミナル

| アクション | コマンド |
| -------- | --------- |
| 新しいターミナル | `` Ctrl+Shift+` `` または `` Ctrl+` `` |
| ターミナルを終了 | `Ctrl+Shift+P` → "Terminal: Kill Active Terminal" |

### Python

| アクション | コマンド |
| -------- | --------- |
| インタープリター選択 | `Ctrl+Shift+P` → "Python: Select Interpreter" |
| Pythonファイル実行 | `Ctrl+Shift+P` → "Python: Run Python File in Terminal" |
| Pythonファイルデバッグ | F5 |

### ファイル

| アクション | コマンド |
| -------- | --------- |
| フォルダーを開く | `Ctrl+K Ctrl+O` |
| ファイルをクイック検索 | `Ctrl+P` |
| ファイル内を検索 | `Ctrl+Shift+F` |

---

## 次のステップ

### オプションの拡張機能

- **[VS Code tmux統合ガイド](vscode-tmux-integration.ja.md)** - 永続的なセッションのためにtmuxを使用(オプション)
- **[Windows PSMUXガイド](psmux-guide.ja.md)** - Windows用tmuxクライアント

### トラブルシューティング

- **[VS Codeトラブルシューティング](vscode-troubleshooting.ja.md)** - 一般的な問題と解決策
- **[SSHセットアップガイド](ssh-setup.ja.md)** - SSH設定と鍵のトラブルシューティング

### 追加リソース

- [公式VS Code Remote-SSHドキュメント](https://code.visualstudio.com/docs/remote/ssh)
- [SSH設定ファイルリファレンス](https://man.openbsd.org/ssh_config)
- [VS CodeでのPython](https://code.visualstudio.com/docs/python/python-tutorial)
- [メインREADMEに戻る](../README.md)
