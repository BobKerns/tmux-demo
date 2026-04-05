# SSHセットアップガイド

[English](ssh-setup.md)

SSH鍵の生成、設定、DockerコンテナやAWS EC2インスタンスへの接続に関する完全ガイド。

---

## 目次

1. [SSH鍵について](#ssh鍵について)
2. [SSH鍵の生成](#ssh鍵の生成)
3. [公開鍵の追加](#公開鍵の追加)
4. [SSH設定ファイル](#ssh設定ファイル)
5. [接続](#接続)
6. [トラブルシューティング](#トラブルシューティング)
7. [ベストプラクティス](#ベストプラクティス)

---

## SSH鍵について

SSHShia(Secure Shell)鍵は、パスワードなしでリモートサーバーに安全に接続できるようにします。

### SSH鍵のメリット

- **より安全:** パスワードより長く複雑
- **便利:** 毎回パスワードを入力する必要なし
- **自動化可能:** スクリプトで使用可能
- **強制可能:** パスワード認証を完全に無効化可能

### 鍵の種類

| タイプ | 鍵長 | 推奨度 | 備考 |
| -------- | ------ | -------- | ------ |
| **ED25519** | 256 bit | ✅ 推奨 | 最速、最も安全、小さい |
| RSA | 4096 bit | ✅ 良い | 広くサポート、大きい |
| ECDSA | 256-521 bit | ⚠️ 可 | 一部のシステムで問題あり |
| DSA | 1024 bit | ❌ 非推奨 | 古い、安全でない |

**このガイドではED25519を使用します。**

---

## SSH鍵の生成

### macOS / Linux

**ターミナルを開いて:**

```bash
# ED25519鍵を生成(推奨)
ssh-keygen -t ed25519 -C "your_email@example.com"
```

**プロンプトが表示されます:**

```bash
Enter file in which to save the key (/Users/you/.ssh/id_ed25519):
```

**オプション:**

- **Enter** - デフォルトの場所を使用
- または特定のパスを入力: `/Users/you/.ssh/tmux_demo_key`

**パスフレーズのプロンプト:**

```bash
Enter passphrase (empty for no passphrase):
```

**オプション:**

- **Enter** (2回) - パスフレーズなし (便利だが安全性は低い)
- またはパスフレーズを入力 (推奨、追加のセキュリティ層)

**結果:**

```bash
Your identification has been saved in /Users/you/.ssh/id_ed25519
Your public key has been saved in /Users/you/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:abc123... your_email@example.com
```

**生成されたファイル:**

- `id_ed25519` - 秘密鍵 (共有しないでください!)
- `id_ed25519.pub` - 公開鍵 (サーバーと共有)

### Windows

#### Windows 10/11 (PowerShell)

Windows 10以降には既にOpenSSHクライアントが含まれています:

```powershell
# PowerShellを開く
ssh-keygen -t ed25519 -C "your_email@example.com"
```

プロンプトはmacOS/Linuxと同じです。

**鍵の場所:**

```text
C:\Users\YourName\.ssh\id_ed25519
C:\Users\YourName\.ssh\id_ed25519.pub
```

#### 古いWindows (PuTTYgen)

**1. PuTTYをダウンロード:**

- [putty.org](https://www.putty.org/)からPuTTYをダウンロード
- PuTTYgenが含まれています

**2. PuTTYgenを起動**

**3. 鍵を生成:**

- タイメールプ: "ED25519"を選択
- "Generate"をクリック
- マウスを動かしてランダム性を生成

**4. 鍵を保存:**

- "Key comment"を設定: `your_email@example.com`
- "Save public key" - `tmux_demo_key.pub`
- "Save private key" - `tmux_demo_key.ppk`

**5. OpenSSH形式に変換 (オプション):**

PuTTYgen → Conversions → Export OpenSSH key

**メモ:** `.ppk`はPuTTY形式です。VS CodeやPSMUXにはOpenSSH形式 (`.pem`または拡張子なし) が必要な場合があります。

---

## リモートホストへの鍵の追加

対象環境に応じて方法を選択してください:

### Dockerコンテナ用（ローカルテスト）

**Dockerコンテナはパスワード認証が無効**になっているため、Dockerコマンドを使用して鍵を追加する必要があります:

```bash
# ステップ1: コンテナが実行中であることを確認
docker compose ps

# ステップ2: 公開鍵をコンテナにコピーしてauthorized_keysに追加
docker cp ~/.ssh/tmux_demo_key.pub tmux-demo:/tmp/key.pub && \
docker exec -u developer tmux-demo bash -c \
  "mkdir -p ~/.ssh && \
   chmod 700 ~/.ssh && \
   cat /tmp/key.pub >> ~/.ssh/authorized_keys && \
   chmod 600 ~/.ssh/authorized_keys && \
   rm /tmp/key.pub"

# ステップ3: 接続をテスト
ssh -i ~/.ssh/tmux_demo_key -p 2222 developer@localhost
```

**Windowsユーザー（PowerShell）:**
```powershell
docker cp $env:USERPROFILE\.ssh\tmux_demo_key.pub tmux-demo:/tmp/key.pub
docker exec -u developer tmux-demo bash -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat /tmp/key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm /tmp/key.pub"
```

### AWS EC2インスタンス用

AWS EC2インスタンスには通常、初期鍵（インスタンス作成時に取得した`.pem`ファイル）が既に設定されています。以下の2つのオプションがあります:

#### オプションA：既存のAWS鍵を使用して鍵を追加

元のAWS `.pem`鍵がある場合:

```bash
# ステップ1: 新しい公開鍵をインスタンスにコピー
scp -i ~/.ssh/your-aws-key.pem ~/.ssh/tmux_demo_key.pub ubuntu@ec2-xx-xxx.compute-1.amazonaws.com:/tmp/

# ステップ2: AWS鍵でSSH接続
ssh -i ~/.ssh/your-aws-key.pem ubuntu@ec2-xx-xxx.compute-1.amazonaws.com

# ステップ3: 新しい鍵をauthorized_keysに追加
cat /tmp/tmux_demo_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
rm /tmp/tmux_demo_key.pub
exit

# ステップ4: 新しい鍵でテスト
ssh -i ~/.ssh/tmux_demo_key ubuntu@ec2-xx-xxx.compute-1.amazonaws.com
```

**ssh-copy-idを使用する方法**（既存のアクセスがある場合）:
```bash
ssh-copy-id -i ~/.ssh/tmux_demo_key.pub -o "IdentityFile ~/.ssh/your-aws-key.pem" ubuntu@ec2-xx-xxx.compute-1.amazonaws.com
```

#### オプションB：AWSコンソール/Session Manager経由で鍵を追加

コンソールアクセスのみの場合（AWS Systems Manager Session Manager）:

1. AWSコンソールでセッションを開始
2. ユーザーに切り替え:
   ```bash
   sudo su - ubuntu
   ```
3. authorized_keysを編集:
   ```bash
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   nano ~/.ssh/authorized_keys
   ```
4. 公開鍵を新しい行に貼り付け
   - 公開鍵を取得: ローカルマシンで`cat ~/.ssh/tmux_demo_key.pub`を実行
   - 出力全体をコピー（`ssh-ed25519`または`ssh-rsa`で始まる）
   - nanoエディタに貼り付け
5. 保存して終了（Ctrl+X、Y、Enter）
6. 権限を設定:
   ```bash
   chmod 600 ~/.ssh/authorized_keys
   ```
7. ローカルマシンからテスト:
   ```bash
   ssh -i ~/.ssh/tmux_demo_key ubuntu@ec2-xx-xxx.compute-1.amazonaws.com
   ```

#### オプションC：セットアップスクリプトを使用

このリポジトリを既にEC2インスタンスにコピーしている場合:

```bash
# EC2インスタンス上で（.pubキーをコピーした後）
./scripts/setup-ssh.sh /path/to/tmux_demo_key.pub
```

---

## SSH設定ファイル

SSH設定ファイル (`~/.ssh/config`) により接続が簡単になります。

### 設定ファイルの作成

**MacOS/Linux:**

```bash
# ファイルが存在しない場合は作成
touch ~/.ssh/config
chmod 600 ~/.ssh/config

# お好みのエディタで編集
nano ~/.ssh/config
# または
vim ~/.ssh/config
```

**Windows:**

```powershell
# PowerShellで
New-Item -ItemType File -Path C:\Users\YourName\.ssh\config -Force

# メモ帳で編集
notepad C:\Users\YourName\.ssh\config
```

### 設定例

**Docker と AWS の両方:**

```
# Docker ローカル環境
Host tmux-demo
    HostName localhost
    Port 2222
    User developer
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# AWS EC2 開発環境
Host aws-dev
    HostName ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
    Port 22
    User ubuntu
    IdentityFile ~/.ssh/aws-key.pem
    ServerAliveInterval 60
    ServerAliveCountMax 3

# AWS EC2 本番環境
Host aws-prod
    HostName ec2-yy-yyy-yyy-yyy.compute-1.amazonaws.com
    Port 22
    User ubuntu
    IdentityFile ~/.ssh/aws-prod-key.pem
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### 設定オプションの説明

| オプション | 説明 |
| ----------- | ------ |
| `Host` | この設定のエイリアス |
| `HostName` | 実際のホスト名またはIP |
| `Port` | SSHポート (デフォルト: 22) |
| `User` | リモートユーザー名 |
| `IdentityFile` | 秘密鍵のパス |
| `StrictHostKeyChecking` | ホスト鍵の検証 (Dockerは`no`、本番は`yes`または`ask`) |
| `UserKnownHostsFile` | 既知のホスト保存場所 (`/dev/null` = 保存しない) |
| `ServerAliveInterval` | キープアライブ秒数 |
| `ServerAliveCountMax` | 切断までの再試行回数 |

**警告:** `StrictHostKeyChecking no`は便利ですが、中間者攻撃に対して脆弱です。本番環境には使用しないでください!

---

## 接続

### 設定ファイル使用

これが最も簡単です:

```bash
# Docker
ssh tmux-demo

# AWS開発
ssh aws-dev

# AWS本番
ssh aws-prod
```

### 設定ファイル不使用

**Docker:**

```bash
ssh -i ~/.ssh/id_ed25519 -p 2222 developer@localhost
```

**AWS EC2:**

```bash
ssh -i ~/.ssh/aws-key.pem ubuntu@ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com
```

### 初回接続

初回接続時にホスト鍵のフィンガープリントを承認するよう求められます:

```
The authenticity of host 'example.com (192.0.2.1)' can't be established.
ED25519 key fingerprint is SHA256:abc123...
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

**`yes`と入力してEnter**

このフィンガープリントが `~/.ssh/known_hosts` に保存されます。

### パスフレーズ付き鍵

鍵にパスフレーズを設定した場合、接続時に毎回入力を求められます。

**これを避けるには ssh-agent を使用:**

```bash
# MacOS
ssh-add ~/.ssh/id_ed25519

# Linux
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519

# Windows (PowerShell)
Start-Service ssh-agent
ssh-add C:\Users\YourName\.ssh\id_ed25519
```

パスフレーズを1回入力すると、そのセッション中は記憶されます。

---

## トラブルシューティング

### 接続拒否

**症状:**

```
ssh: connect to host localhost port 2222: Connection refused
```

**原因と解決策:**

**1. SSHサーバーが実行されていない**

Docker:
```bash
docker ps  # コンテナが実行中か確認
docker-compose up -d  # 必要に応じて起動
```

AWS:
```bash
# EC2インスタンスがAWSコンソールで実行中か確認
```

**2. 間違ったポート**

Docker: ポート `2222`
AWS: ポート `22`

```bash
ssh -p 2222 developer@localhost  # Dockerの場合
ssh -p 22 ubuntu@ec2-ip          # AWSの場合
```

**3. ファイアウォール/セキュリティグループ**

AWS: EC2セキュリティグループがポート22への接続を許可しているか確認

### パーミッション拒否 (公開鍵)

**症状:**

```
Permission denied (publickey).
```

**原因と解決策:**

**1. 鍵ファイルのパーミッションが間違っている**

```bash
# MacOS/Linux
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 700 ~/.ssh

# または
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub
chmod 700 ~/.ssh
```

Windows: 右クリック → プロパティ → セキュリティ → 自分のユーザーのみがアクセス可能であることを確認

**2. 公開鍵がサーバーに追加されていない**

```bash
# サーバー上で確認
cat ~/.ssh/authorized_keys

# ローカルの公開鍵がリストにあるか確認
cat ~/.ssh/id_ed25519.pub
```

一致しない場合は、[公開鍵の追加](#公開鍵の追加)を参照してください。

**3. サーバー上のauthorized_keysのパーミッション**

```bash
# サーバー上で
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

**4. 間違った秘密鍵を使用**

```bash
ssh -i ~/.ssh/correct_key user@host
```

設定ファイルまたは `-i` フラグで正しい鍵を指定してください。

**5. PEM形式の問題 (AWS)**

AWS `.pem` ファイルは正しいパーミッションが必要です:

```bash
chmod 400 ~/.ssh/aws-key.pem
```

### タイムアウト

**症状:**

```
ssh: connect to host example.com port 22: Operation timed out
```

**原因と解決策:**

**1. 間違ったIPアドレス/ホスト名**

```bash
ping your-ec2-public-ip
```

**2. EC2インスタンスが停止している**

AWSコンソールで確認し、必要に応じて起動します。

**3. セキュリティグループ規則**

AWS EC2 → セキュリティグループ:
- インバウンド規則
- タイプ: SSH
- ポート: 22
- ソース: 自分のIP (or 0.0.0.0/0、ただしセキュリティ低)

**4. VPN/プロキシの問題**

企業VPNがSSHをブロックしている可能性があります。

### 警告: リモートホスト識別が変更されました

**症状:**

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

**原因:**

ホスト鍵が変更されました(サーバーの再インストール、Dockerコンテナの再構築など)

**解決策:**

**オプション 1: 古いエントリを削除**

```bash
ssh-keygen -R localhost  # Dockerの場合
ssh-keygen -R your-ec2-ip  # AWSの場合

# またはポートを指定
ssh-keygen -R [localhost]:2222
```

**オプション 2: known_hostsファイルを編集**

```bash
nano ~/.ssh/known_hosts
# 該当する行を削除 (メッセージに行番号が表示されます)
```

**オプション 3: known_hostsを無視 (Dockerの場合のみ)**

設定ファイル:
```
Host tmux-demo
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**警告:** 本番環境では使用しないでください!

---

## ベストプラクティス

### 1. パスフレーズを使用

鍵にパスフレーズを設定:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# パスフレーズのプロンプトで入力
```

利便性のためssh-agentを使用してください。

### 2. 異なる目的ごとに異なる鍵

```bash
# 作業用
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_work -C "work@company.com"

# 個人用
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal -C "personal@gmail.com"

# AWS用
ssh-keygen -t ed25519 -f ~/.ssh/aws_prod_key -C "aws-prod"
```

SSH設定で使い分け:

```
Host work-server
    IdentityFile ~/.ssh/id_ed25519_work

Host personal-server
    IdentityFile ~/.ssh/id_ed25519_personal

Host aws-prod
    IdentityFile ~/.ssh/aws_prod_key
```

### 3. 秘密鍵を保護

- **共有しない:** 秘密鍵は絶対に共有しない
- **バックアップ:** 安全な場所にバックアップを保存
- **パーミッション:** 常に `chmod 600`
- **Gitにコミットしない:** `.gitignore`に追加

```bash
# .gitignoreに追加
*.pem
*.ppk
id_*
!*.pub
```

### 4. 鍵を定期的にローテーション

年に1回以上:

1. **新しい鍵を生成**
2. **新しい公開鍵をサーバーに追加**
3. **新しい鍵でテスト**
4. **古い公開鍵をサーバーから削除**
5. **古い秘密鍵をローカルから削除**

### 5. パスワード認証を無効化

SSH鍵のみを使用するようにサーバーを設定:

```bash
# サーバー上で
sudo nano /etc/ssh/sshd_config

# 以下を設定
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no

# SSHを再起動
sudo systemctl restart sshd
```

**注意:** 再起動前に鍵認証が動作することを確認してください!

### 6. ServerAliveIntervalを使用

接続が切れないようにする:

```
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### 7. SSH Agent転送に注意

便利ですがセキュリティリスクがあります:

```
Host trusted-server
    ForwardAgent yes  # 信頼できるサーバーのみ
```

**より安全な代替策:** ProxyJumpを使用

```
Host final-destination
    ProxyJump jump-server
```

---

## クイックリファレンス

### 鍵の生成

```bash
# ED25519 (推奨)
ssh-keygen -t ed25519 -C "your_email@example.com"

# パスフレーズなし (テスト用のみ)
ssh-keygen -t ed25519 -N "" -f ~/.ssh/test_key
```

### 公開鍵の表示

```bash
cat ~/.ssh/id_ed25519.pub
```

### 鍵のコピー

```bash
# MacOS/Linux
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host

# または手動で
cat ~/.ssh/id_ed25519.pub | ssh user@host "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 鍵のパーミッション

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/config
```

### SSH接続テスト

```bash
# 詳細出力
ssh -v user@host

# さらに詳細
ssh -vvv user@host

# 特定の鍵
ssh -i ~/.ssh/specific_key user@host
```

---

## 参考リンク

- [VS Code Remote-SSH](vscode-remote-ssh.ja.md)
- [PSMUXガイド](psmux-guide.ja.md)
- [メインREADME](../README.ja.md)

---

**ハッピーSSH接続! 🔐**
