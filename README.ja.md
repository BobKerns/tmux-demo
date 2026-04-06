# tmux + emacs 開発環境

[English version](README.md)

tmux、emacs、VS Code Remote-SSHを使用したAWSリモート開発のセットアップガイド。AWS EC2でのGPU集約型ML学習タスクに最適化されています。

永続的なターミナルセッション用のemacs対応tmux設定(Ctrl+^プレフィックス)を含みます。

> **tmux初心者の方へ**: セッション、ウィンドウ、推奨ワークフローを理解するために[**使用ガイド**](docs/USAGE.ja.md)から始めてください。
>
> **注意**: AWSアクセスなしでローカルテストを行う場合は、[Dockerセットアップガイド](docs/docker-setup.ja.md)を参照してください。

---

## 目次

1. [AWS EC2セットアップ](#セクション1-aws-ec2セットアップ)
2. [VS Code Remote-SSH](#セクション2-vs-code-remote-ssh)
3. [Windows PSMUXターミナルクライアント](#セクション3-windows-psmux-tmuxクライアント)
4. [VS Codeターミナルとtmuxの統合](#セクション4-vs-codeターミナルとtmuxの統合オプション)

---

## セクション1: AWS EC2セットアップ

tmuxとemacsを使用したリモート開発のためのAWS EC2インスタンスをセットアップします。

### 前提条件

- Linux実行中のAWS EC2インスタンス(Ubuntu/Debian用に最適化)
- インスタンスへのSSHアクセス
- SSHキーペア([docs/ssh-setup.ja.md](docs/ssh-setup.ja.md)を参照)

### セットアップ手順

#### 1. インスタンスに接続

```bash
ssh -i ~/.ssh/your-aws-key.pem <ユーザー名>@<EC2ホスト名>
```

#### 2. tmuxとemacsをインストール

**オプションA: インストールスクリプトを使用**(推奨):

```bash
# このリポジトリをクローン
git clone https://github.com/BobKerns/tmux-demo.git
cd tmux-demo

# インストールスクリプトを実行
./scripts/install-tmux-emacs.sh
```

**オプションB: 手動インストール**:

```bash
# パッケージリストを更新
sudo apt-get update

# tmux、emacs、および必須ツールをインストール
sudo apt-get install -y tmux emacs-nox git curl wget vim build-essential

# インストールを確認
tmux -V
emacs --version
```

#### 3. tmux設定をセットアップ

```bash
# emacs対応のtmux設定をダウンロード
wget https://raw.githubusercontent.com/BobKerns/tmux-demo/main/.tmux.conf -O ~/.tmux.conf

# またはクローンしたリポジトリからコピー
cp ~/tmux-demo/.tmux.conf ~/.tmux.conf
```

#### 4. tmuxをテスト

```bash
# 新しいtmuxセッションを開始
tmux

# プレフィックスキー(Ctrl+^)をテスト
# 新しいウィンドウを作成してみる: Ctrl+^ の後に c
```

**重要**: プレフィックスキーは**Ctrl+^**です(Ctrl+bではありません)!

---

## セクション2: VS Code Remote-SSH

VS Codeを AWS EC2リモート環境に接続します。

### インストール

1. **VS Codeをインストール**([ダウンロード](https://code.visualstudio.com/))

2. **Remote-SSH拡張機能をインストール**:
   - VS Codeを開く
   - `Ctrl+Shift+X`(macOSでは`Cmd+Shift+X`)を押す
   - "Remote - SSH"を検索
   - Microsoft提供の拡張機能をインストール

### 設定

#### AWS EC2

1. **SSH設定ファイルを開く**:
   - `Ctrl+Shift+P` → "Remote-SSH: Open SSH Configuration File"
   - SSH設定を選択(通常は`~/.ssh/config`)

2. **設定を追加**:
   ```
   Host aws-ml
       HostName <EC2ホスト名>
       User <ユーザー名>
       Port 22
       IdentityFile ~/.ssh/your-aws-key.pem
   ```

3. **接続**:
   - `Ctrl+Shift+P` → "Remote-SSH: Connect to Host"
   - `aws-ml`を選択
   - 初回接続時にVS Code Serverがインストールされます

### Remote-SSHの使用

接続後:

- **ファイルエクスプローラー**: サイドバーでリモートファイルを閲覧
- **ターミナル**: リモートマシンで開く(`` Ctrl+` ``を押す)
- **拡張機能**: リモートに拡張機能をインストール(一部はリモートインストールが必要)
- **Git**: リモートマシン上のリポジトリで動作
- **デバッグ**: リモートで実行されるコードをデバッグ

### よくあるタスク

| タスク | コマンド |
| ------ | --------- |
| リモートフォルダを開く | `Ctrl+K Ctrl+O` → フォルダを選択 |
| 新しいターミナル | `` Ctrl+Shift+` `` |
| リモート接続を閉じる | 左下の"SSH: hostname"をクリック → "Close Remote Connection" |
| ウィンドウをリロード | `Ctrl+Shift+P` → "Developer: Reload Window" |

---

## セクション3: Windows PSMUX Tmuxクライアント

PSMUXは、ネイティブな体験を提供するWindows用の最新tmuxクライアントです。

### インストール

1. **PSMUXをインストール**:
   - [PSMUX GitHubリリース](https://github.com/lupont/psmux)を訪問(例URL)
   - Windows用の最新`.exe`または`.msi`インストーラーをダウンロード
   - インストーラーを実行してプロンプトに従う

2. **インストールを確認**:
   ```powershell
   psmux --version
   ```

### リモートtmuxへの接続

#### AWS EC2に接続

```powershell
# EC2インスタンスの詳細に置き換えてください
psmux connect -h <EC2ホスト名> -p 22 -u <ユーザー名> -i C:\Users\YourName\.ssh\aws-key.pem
```

### 基本的なtmuxコマンド(PSMUX経由)

重要: プレフィックスは**Ctrl+^**です(Ctrl+bではありません)

| コマンド | 説明 |
| --------- | ------------- |
| `Ctrl+^ c` | 新しいウィンドウを作成 |
| `Ctrl+^ \|` | ペインを水平分割 |
| `Ctrl+^ -` | ペインを垂直分割 |
| `Ctrl+^ arrow` | ペイン間を移動 |
| `Ctrl+^ d` | セッションからデタッチ |
| `Ctrl+^ [` | スクロールモードに入る(矢印キーでスクロール、`q`で終了) |

### PSMUX固有の機能

- **ネイティブWindows統合**: コピー/ペーストがWindowsクリップボードで動作
- **マウスサポート**: 完全なマウスサポート(クリックでペイン選択、スクロールでナビゲート)
- **セッション管理**: 複数のtmuxセッションを管理するGUI
- **フォントレンダリング**: 従来のターミナルエミュレーターよりも優れたフォントレンダリング

### セッションプロファイルの作成

PSMUXは、AWS環境への素早いアクセスのために接続プロファイルを保存できます。

詳細なPSMUX使用方法については、[docs/psmux-guide.md](docs/psmux-guide.md)を参照してください。

---

## セクション4: VS Codeターミナルとtmuxの統合(オプション)

**注意**: これはオプションの高度な機能で、基本的なRemote-SSH使用とは別のものです。

### 概要

VS Codeの統合ターミナルがtmuxと自動的に連携するように設定できます:

- **永続的なセッション**: VS Codeの切断後もターミナル作業が持続
- **ターミナル多重化**: VS Codeターミナル内で複数のペイン
- **ネットワーク耐性**: 接続が切れても作業を継続

### クイック例

最も簡単な方法 - VS Codeのターミナルで手動でtmuxを実行:

1. Remote-SSH経由でリモートホストに接続
2. VS Codeターミナルを開く(`` Ctrl+` ``)
3. `tmux`を実行してセッションを開始
4. プレフィックス`Ctrl+^`でtmuxを制御

### これを使用する場合

✅ **適している場合**:
- 切断後も持続する必要がある長時間実行プロセス
- 複雑な複数ペインターミナルセットアップ
- 不安定なネットワーク接続

❌ **不要な場合**:
- 基本的なRemote-SSH開発
- シンプルなターミナル使用
- めったに切断しない場合

### 完全ガイド

自動アタッチ、シェルプロファイル統合、トラブルシューティングの詳細なセットアップについては:

**📚 完全ガイドを参照:** [VS Code tmux統合](docs/vscode-tmux-integration.ja.md)

---

## クイックリファレンス

### tmux基礎(プレフィックス: Ctrl+^)

| コマンド | 説明 |
| --------- | ------------- |
| `tmux` | 新しいセッションを開始 |
| `tmux ls` | セッションをリスト |
| `tmux attach -t <name>` | セッションにアタッチ |
| `Ctrl+^ c` | 新しいウィンドウ |
| `Ctrl+^ \|` | 水平分割 |
| `Ctrl+^ -` | 垂直分割 |
| `Ctrl+^ d` | セッションをデタッチ |
| `Ctrl+^ [` | スクロールモード |

### 便利なコマンド

```bash
# 接続をテスト
./scripts/test-connection.sh <host> <port> <key> <user>

# SSH鍵をセットアップ
./scripts/setup-ssh.sh ~/.ssh/your_key.pub

# 新しいUbuntuにインストール(AWS EC2)
./scripts/install-tmux-emacs.sh
```

---

## コントリビューション

コントリビューションを歓迎します！お気軽にPull Requestを提出してください。

---

## ライセンス

MIT License - [LICENSE](LICENSE)ファイルで詳細を参照

---

## 追加リソース

### ドキュメント

- [**tmux使用ガイド**](docs/USAGE.ja.md) - セッション、ウィンドウ、ワークフローの必須ガイド ⭐
- [SSH設定ガイド](docs/ssh-setup.ja.md) - SSH鍵の生成と設定
- [VS Code Remote-SSHガイド](docs/vscode-remote-ssh.ja.md) - 詳細なRemote-SSHセットアップ
- [VS Codeトラブルシューティング](docs/vscode-troubleshooting.ja.md) - よくある問題と解決策
- [Dockerセットアップガイド](docs/docker-setup.ja.md) - ローカルテスト環境(オプション)

### 外部リソース

- [tmuxチートシート](https://tmuxcheatsheet.com/)
- [emacsチュートリアル](https://www.gnu.org/software/emacs/tour/)
- [VS Codeリモート開発](https://code.visualstudio.com/docs/remote/remote-overview)
- [AWS EC2ユーザーガイド](https://docs.aws.amazon.com/ec2/)

---

**質問や問題がありますか？** GitHubでissueを開くか、`docs/`ディレクトリ内の詳細ガイドを参照してください。
