# Dockerセットアップ(ローカルテストとデモンストレーション)

[English version](docker-setup.md)

このガイドは、ローカルテストとデモンストレーション目的のものです。Docker環境により、AWSアクセスや本番システムの変更を必要とせずに、tmux + emacsセットアップをテストできます。

**対象読者**: AWSに展開する前に、環境をローカルでテストまたはデモンストレーションしたい開発者。

---

## 目次

1. [概要](#概要)
2. [前提条件](#前提条件)
3. [クイックスタート](#クイックスタート)
4. [Dockerコマンド](#dockerコマンド)
5. [トラブルシューティング](#トラブルシューティング)
6. [次のステップ](#次のステップ)

---

## 概要

Dockerセットアップで提供されるもの:
- Ubuntu 24.04 LTS環境
- emacs対応設定を持つtmux 3.4(Ctrl+^プレフィックス)
- emacs 29.3
- ポート2222のSSHサーバー
- 永続的なホームディレクトリボリューム
- sudo権限を持つユーザー`developer`

これはローカルテスト用にAWS EC2環境をミラーリングします。

---

## 前提条件

- システムにインストールされたDocker([Dockerを入手](https://docs.docker.com/get-docker/))
- インストールされたDocker Compose
- SSHキーペア([ssh-setup.ja.md](ssh-setup.ja.md)を参照)

---

## クイックスタート

### 1. リポジトリをクローン

```bash
git clone https://github.com/BobKerns/tmux-demo.git
cd tmux-demo
```

### 2. コンテナをビルドして起動

```bash
docker-compose up -d --build
```

これにより、以下を含む`tmux-demo`という名前のコンテナが作成されます:
- ポート2222のSSHサーバー(コンテナのポート22からマッピング)
- sudo権限を持つユーザー`developer`
- 永続的なホームディレクトリボリューム

### 3. SSHアクセスをセットアップ

まだSSH鍵を持っていない場合は生成します:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/tmux_demo_key -C "tmux-demo"
```

公開鍵をコンテナにコピーします:

```bash
docker exec tmux-demo bash -c "mkdir -p /home/developer/.ssh && chmod 700 /home/developer/.ssh"
docker cp ~/.ssh/tmux_demo_key.pub tmux-demo:/tmp/key.pub
docker exec -u developer tmux-demo bash -c "cat /tmp/key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

または、セットアップスクリプトを使用します(コンテナ内から):

```bash
docker exec -it tmux-demo bash
./scripts/setup-ssh.sh /path/to/your/public/key.pub
```

### 4. 接続をテスト

```bash
ssh -i ~/.ssh/tmux_demo_key -p 2222 developer@localhost
```

### 5. tmuxを起動

```bash
tmux
```

**重要**: プレフィックスキーは**Ctrl+^**です(Ctrl+bではありません)!

---

## Dockerコマンド

| コマンド | 説明 |
| --------- | ------------- |
| `docker-compose up -d` | バックグラウンドでコンテナを起動 |
| `docker-compose down` | コンテナを停止して削除 |
| `docker-compose logs -f` | コンテナログを表示 |
| `docker exec -it tmux-demo bash` | コンテナでシェルを開く |
| `docker-compose restart` | コンテナを再起動 |
| `docker-compose build` | イメージを再ビルド |
| `docker ps` | 実行中のコンテナをリスト |
| `docker port tmux-demo` | ポートマッピングを表示 |

---

## トラブルシューティング

### SSHで接続できない

**症状**: localhost:2222にSSHしようとすると`Connection refused`またはタイムアウト

**解決策**:
1. コンテナが実行中であることを確認:
   ```bash
   docker ps
   ```
   リストに`tmux-demo`が表示されるはずです

2. ポートマッピングを確認:
   ```bash
   docker port tmux-demo
   ```
   `22/tcp -> 0.0.0.0:2222`と表示されるはずです

3. SSH鍵のパーミッションを確認:
   ```bash
   chmod 600 ~/.ssh/tmux_demo_key
   ```

4. SSHログを表示:
   ```bash
   docker logs tmux-demo
   ```
   SSHサーバーの起動メッセージを探します

5. コンテナを再起動:
   ```bash
   docker-compose restart
   ```

### tmuxが動作しない

**症状**: `tmux: command not found`または設定が適用されていない

**解決策**:
1. tmuxのインストールを確認:
   ```bash
   docker exec tmux-demo tmux -V
   ```
   `tmux 3.4`以降が表示されるはずです

2. 設定ファイルを確認:
   ```bash
   docker exec -u developer tmux-demo cat ~/.tmux.conf
   ```
   emacs対応の設定が表示されるはずです

3. コンテナを再ビルド:
   ```bash
   docker-compose down
   docker-compose up -d --build
   ```

### パーミッション拒否

**症状**: 特定のファイルやディレクトリにアクセスできない

**解決策**:
1. 正しいユーザーとしてコマンドを実行していることを確認:
   ```bash
   docker exec -u developer tmux-demo whoami
   ```
   `developer`が返されるはずです

2. ファイルの所有権を修正(必要に応じて):
   ```bash
   docker exec tmux-demo chown -R developer:developer /home/developer
   ```

### コンテナが起動しない

**症状**: コンテナがすぐに終了するか、起動しない

**解決策**:
1. ログを確認:
   ```bash
   docker logs tmux-demo
   ```

2. Docker Compose設定を検証:
   ```bash
   docker-compose config
   ```

3. 既存のコンテナとボリュームを削除:
   ```bash
   docker-compose down -v
   docker-compose up -d --build
   ```

---

## 次のステップ

Docker環境が動作したら:

1. **VS Code Remote-SSHをテスト**: Docker設定を使用して[VS Code Remote-SSHガイド](vscode-remote-ssh.ja.md)に従う
2. **Windows PSMUXを試す**: Windowsの場合、PSMUXターミナルクライアントをテスト(メインREADMEを参照)
3. **tmuxを練習**: tmuxコマンドを学ぶ(メインREADMEのクイックリファレンスを参照)
4. **AWSに展開**: メインREADMEのAWS EC2セットアップ手順を使用

---

## 追加リソース

- [Dockerドキュメント](https://docs.docker.com/)
- [Docker Composeリファレンス](https://docs.docker.com/compose/compose-file/)
- [tmuxチートシート](https://tmuxcheatsheet.com/)
- [メインREADME](../README.ja.md) - AWSセットアップと使用ガイド

---

**質問や問題がありますか？** GitHubでissueを開くか、上記のトラブルシューティングセクションを参照してください。
