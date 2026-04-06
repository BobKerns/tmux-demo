# tmux + emacs 開発環境

[English](README.md)

Ubuntu、tmux、emacs、VS Code Remote-SSH開発環境のセットアップガイド。

Dockerでローカルテスト、AWS EC2へ展開。emacs対応のtmux設定（Ctrl+^プレフィックス）を含みます。

---

## 目次

1. [Docker環境のセットアップ](#1-docker環境のセットアップ)
2. [AWS EC2のセットアップ](#2-aws-ec2のセットアップ)
3. [VS Code Remote-SSHの使用](#3-vs-code-remote-sshの使用)
4. [Windows PSMUXクライアント](#4-windows-psmuxクライアント)
5. [VS Codeターミナルとtmuxの統合](#5-vs-codeターミナルとtmuxの統合オプション)

---

## 1. Docker環境のセットアップ

Dockerを使用してローカル環境でセットアップをテストします。

### 前提条件

- Docker Desktop (Windows、macOS、Linux)
- SSH公開鍵・秘密鍵のペア

### 構築と実行

**1. イメージのビルド:**

```bash
docker-compose build
```

**2. コンテナの起動:**

```bash
docker-compose up -d
```

**3. コンテナの実行確認:**

```bash
docker ps
```

`tmux-demo` という名前のコンテナが実行中であることを確認してください。

### SSH設定

**公開鍵の追加:**

```bash
# Dockerコンテナ内に公開鍵をコピー
docker-compose exec tmux-demo bash -c "mkdir -p /home/developer/.ssh && chmod 700 /home/developer/.ssh"

# ローカルマシンから公開鍵をコピー
cat ~/.ssh/your_public_key.pub | docker-compose exec -T tmux-demo bash -c "cat >> /home/developer/.ssh/authorized_keys && chmod 600 /home/developer/.ssh/authorized_keys"
```

**またはスクリプトを使用:**

```bash
docker-compose exec tmux-demo /app/scripts/setup-ssh.sh /path/to/your/public/key.pub
```

### SSH接続

**SSHクライアントから接続:**

```bash
ssh -i ~/.ssh/your_private_key -p 2222 developer@localhost
```

**SSH configファイルの設定 (`~/.ssh/config`):**

```
Host tmux-demo
    HostName localhost
    Port 2222
    User developer
    IdentityFile ~/.ssh/your_private_key
```

その後、以下のコマンドで接続:

```bash
ssh tmux-demo
```

### tmux使用の開始

**接続後、tmuxを起動:**

```bash
tmux
```

**主要なtmuxコマンド (プレフィックス: Ctrl+^):**

- `Ctrl+^ c` - 新しいウィンドウを作成
- `Ctrl+^ |` - 横に分割(カスタム)
- `Ctrl+^ -` - 縦に分割(カスタム)
- `Ctrl+^ 矢印キー` - ペイン間の移動
- `Ctrl+^ d` - セッションからデタッチ

**セッションの再接続:**

```bash
tmux attach
```

---

## 2. AWS EC2のセットアップ

本番環境のAWS EC2インスタンスへの展開。

### EC2インスタンスの起動

**1. AWSコンソールでEC2インスタンスを起動:**

- **AMI:** Ubuntu Server 24.04 LTS
- **インスタンスタイプ:** t2.micro (または要件に応じて)
- **キーペア:** 既存のキーを選択するか新規作成
- **セキュリティグループ:**
  - SSH (ポート22) - 自分のIPからのアクセスを許可
  - カスタムTCP (必要に応じて)

**2. Elastic IPの関連付け (推奨):**

固定IPアドレスにより、接続設定が簡単になります。

### インスタンスへの接続

```bash
ssh -i ~/.ssh/aws-key.pem ubuntu@your-ec2-public-ip
```

### tmuxとEmacsのインストール

**提供されたスクリプトの使用:**

```bash
# スクリプトをインスタンスにコピー(ローカルマシンから実行)
scp -i ~/.ssh/aws-key.pem scripts/install-tmux-emacs.sh ubuntu@your-ec2-ip:~

# インスタンスに接続
ssh -i ~/.ssh/aws-key.pem ubuntu@your-ec2-ip

# スクリプトの実行
chmod +x install-tmux-emacs.sh
./install-tmux-emacs.sh
```

**手動インストール:**

```bash
# パッケージリストの更新
sudo apt update

# 必要なパッケージのインストール
sudo apt install -y tmux emacs-nox git curl wget vim build-essential

# tmux設定のコピー
# .tmux.confをローカルからscpするか、手動で作成
```

### .tmux.conf設定

**ローカルマシンから.tmux.confをコピー:**

```bash
scp -i ~/.ssh/aws-key.pem .tmux.conf ubuntu@your-ec2-ip:~/.tmux.conf
```

**または手動で作成:**

```bash
# EC2インスタンス上で
nano ~/.tmux.conf
# プロジェクトの.tmux.confの内容を貼り付け
```

### セキュリティのベストプラクティス

**1. パスワード認証を無効化:**

Dockerイメージではすでに無効化されています。EC2の場合:

```bash
sudo nano /etc/ssh/sshd_config
# 以下が設定されていることを確認:
# PasswordAuthentication no
# PubkeyAuthentication yes

sudo systemctl restart sshd
```

**2. ファイアウォールの設定 (オプション):**

```bash
sudo ufw allow 22/tcp
sudo ufw enable
```

**3. SSH鍵の定期的な更新**

**4. 未使用時はインスタンスを停止** (コスト削減のため)

---

## 3. VS Code Remote-SSHの使用

VS Codeからリモートマシン(DockerまたはAWS)に接続して開発します。

### Remote-SSH拡張機能のインストール

**1. VS Codeを開く**

**2. 拡張機能ビューを開く:**

- macOS: `Cmd+Shift+X`
- Windows/Linux: `Ctrl+Shift+X`

**3. "Remote - SSH"を検索してインストール**

発行者: Microsoft

### SSH設定

**`~/.ssh/config` ファイルを編集:**

```
# Docker環境
Host tmux-demo
    HostName localhost
    Port 2222
    User developer
    IdentityFile ~/.ssh/your_private_key

# AWS EC2
Host aws-dev
    HostName your-ec2-public-ip
    Port 22
    User ubuntu
    IdentityFile ~/.ssh/aws-key.pem
```

### リモートホストへの接続

**1. コマンドパレットを開く:**

- macOS: `Cmd+Shift+P`
- Windows/Linux: `Ctrl+Shift+P`

**2. "Remote-SSH: Connect to Host..."を選択**

**3. 設定したホストを選択:**

- `tmux-demo` (Docker)
- `aws-dev` (AWS EC2)

**4. 新しいVS Codeウィンドウが開きます** - リモートマシンに接続されています!

### リモート作業

- **フォルダーを開く:** リモートマシン上のプロジェクトフォルダーに移動
- **ターミナル:** 統合ターミナルはリモートマシン上で実行
- **拡張機能:** リモートでインストールする拡張機能を選択
- **ファイル編集:** 通常どおり、すべてリモートで保存

**詳細なガイドは以下を参照:**

[VS Code Remote-SSH完全ガイド](docs/vscode-remote-ssh.md)

---

## 4. Windows PSMUXクライアント

WindowsからtmuxセッションにネイティブClarkに接続します。

### PSMUXとは?

PSMUXは、Windows向けの最新のtmuxクライアントで以下の機能を提供します:

- ネイティブなWindows体験 (WSL不要)
- マウスサポート
- より良いレンダリング
- セッションプロファイル
- クリップボード統合

### クイック接続

**Dockerコンテナ:**

```powershell
psmux connect -h localhost -p 2222 -u developer -i C:\Users\YourName\.ssh\tmux_demo_key
```

**AWS EC2:**

```powershell
psmux connect -h your-ec2-public-ip -p 22 -u ubuntu -i C:\Users\YourName\.ssh\aws-key.pem
```

### SSH設定の使用

SSH設定ファイル (`C:\Users\YourName\.ssh\config`) がある場合:

```powershell
psmux connect tmux-demo
psmux connect aws-dev
```

PSMUXはSSH設定を自動的に読み込みます!

### 基本的な使用方法

接続後、tmuxコマンドを通常どおり使用:

```bash
tmux                          # 新しいセッションを開始
tmux ls                       # セッション一覧
tmux attach -t <name>         # セッションに再接続
```

プレフィックスキー (Ctrl+^) がemacsと競合しないことに注意してください!

**詳細なガイドは以下を参照:**

[PSMUX完全ガイド](docs/psmux-guide.md)

---

## 5. VS Codeターミナルとtmuxの統合（オプション）

*注: これはオプションの高度な機能で、基本的なRemote-SSH使用とは別のものです。*

### 概要

VS Code統合ターミナルをtmuxと連携させることで以下が可能:

- **永続的なセッション**: VS Code切断後もターミナル作業が継続
- **ターミナル多重化**: VS Codeターミナル内で複数ペイン
- **ネットワーク耐性**: 接続が切れても作業を継続可能

### クイック例

最もシンプルな方法 - VS Codeターミナルで手動でtmuxを実行:

1. Remote-SSHでリモートホストに接続
2. VS Codeターミナルを開く (`` Ctrl+` ``)
3. `tmux` を実行してセッション開始
4. プレフィックス `Ctrl+^` でtmuxを制御

### いつ使うべきか

✅ **適している場合**:
- 切断にも耐える長時間実行プロセス
- 複雑なマルチペインターミナル設定
- 不安定なネットワーク接続

❌ **不要な場合**:
- 基本的なRemote-SSH開発
- シンプルなターミナル使用
- 切断がほとんどない環境

### 完全ガイド

自動接続、シェルプロファイル統合、トラブルシューティングの詳細:

**📚 完全ガイドを参照:** [VS Code tmux統合](docs/vscode-tmux-integration.ja.md) ([English](docs/vscode-tmux-integration.md))

---

## ヘルプとリソース

### プロジェクト構成

```
tmux-demo/
├── Dockerfile              # Ubuntu 24.04 + SSH + tmux + emacs
├── docker-compose.yml      # Dockerサービス設定
├── .tmux.conf              # tmux設定 (Ctrl+^ プレフィックス)
├── .dockerignore          # Docker除外ファイル
├── scripts/
│   ├── setup-ssh.sh       # SSH鍵セットアップスクリプト
│   ├── install-tmux-emacs.sh  # AWS用インストールスクリプト
│   └── test-connection.sh # 接続テストスクリプト
├── docs/
│   ├── ssh-setup.md       # SSH詳細ガイド
│   ├── vscode-remote-ssh.md   # VS Code Remote-SSH詳細ガイド
│   └── psmux-guide.md     # PSMUX詳細ガイド
└── README.md              # このファイル
```

### 詳細ガイド

- **[SSHセットアップガイド](docs/ssh-setup.ja.md)** - SSH鍵生成、設定、トラブルシューティング
- **[VS Code Remote-SSHガイド](docs/vscode-remote-ssh.ja.md)** - 詳細なRemote-SSHセットアップ
- **[PSMUXガイド](docs/psmux-guide.ja.md)** - Windows tmuxクライアント完全ガイド

### よくある質問

**Q: DockerとAWS、どちらを使うべきですか?**

A: まずDockerでローカルテスト、その後AWS EC2に展開してください。Dockerは無料でクイックテストが可能です。

**Q: なぜプレフィックスがCtrl+^なのですか?**

A: Emacsユーザー向けです。デフォルトのCtrl+bやよく使われるCtrl+aはemacsのキーバインドと競合します。Ctrl+^は競合を避けます。

**Q: .tmux.confを変更できますか?**

A: もちろんです! `.tmux.conf`はよくコメントされており、ニーズに合わせてカスタマイズできます。

**Q: 複数のtmuxセッションを持てますか?**

A: はい:
```bash
tmux new -s work     # "work"セッションを作成
tmux new -s personal # "personal"セッションを作成
tmux ls              # すべてのセッションを一覧
tmux attach -t work  # "work"に接続
```

**Q: VS Code Remote-SSHでtmuxを使う必要がありますか?**

A: いいえ、これらは独立しています:
- **Remote-SSH:** VS Codeエディタ全体がリモートマシン上で動作
- **tmux:** セッション永続化とマルチペイン用のターミナルツール

両方を組み合わせることも可能です!

---

## 次のステップ

**1. ローカルでテスト:**

```bash
docker-compose up -d
ssh tmux-demo
tmux
```

**2. AWS EC2へ展開:**

- EC2インスタンスを起動
- `install-tmux-emacs.sh` を実行
- SSH経由で接続
- tmuxで開発開始!

**3. VS Code統合:**

- Remote-SSH拡張機能をインストール
- SSH設定を構成
- リモート接続してコーディング!

**4. PSMUXを試す (Windows):**

- PSMUXをインストール
- Dockerまたは AWS に接続
- ネイティブなtmux体験を楽しむ!

---

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 貢献

改善案やバグ報告を歓迎します!

---

**楽しい開発を! 🚀**
