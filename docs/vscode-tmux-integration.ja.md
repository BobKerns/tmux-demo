# VS Code tmux 統合 (オプション)

[English](vscode-tmux-integration.md)

このガイドでは、tmuxをVS Code Remote-SSHと統合して、切断に耐える永続的なターミナルセッションを実現する方法を説明します。

---

## なぜVS Codeでtmuxを使うのか?

**利点:**
- **セッションの永続性**: ネットワーク切断後も作業が継続
- **複数のペイン**: VS Code内でターミナルを分割
- **バックグラウンドプロセス**: VS Codeを閉じた後もプロセスが実行継続
- **tmuxワークフロー**: 好みのtmuxキーバインディングとワークフローを使用

**使用すべき場合:**
- 不安定なネットワーク接続
- 長時間実行されるプロセス(ビルド、サーバー、データベース操作)
- tmuxのウィンドウ/ペイン管理を好む場合
- 複数のSSHセッションで作業する場合

**不要な場合:**
- 安定したローカルネットワーク(localhost上のDockerコンテナ)
- 短時間の編集セッション
- VS Codeの組み込みターミナル管理を好む場合

---

## 目次

1. [前提条件](#前提条件)
2. [方法1: 手動使用](#方法1-手動使用)
3. [方法2: 自動接続設定](#方法2-自動接続設定)
4. [方法3: シェルプロファイル統合](#方法3-シェルプロファイル統合)
5. [キーバインディングの考慮事項](#キーバインディングの考慮事項)
6. [ベストプラクティス](#ベストプラクティス)

---

## 前提条件

- VS Code Remote-SSH拡張機能がインストールおよび設定済み
- tmuxがインストールされたリモートホストに接続済み
- [tmuxの基本](../README.md#tmux-basics)に精通していること

---

## 方法1: 手動使用

**最もシンプルなアプローチ - 必要なときにtmuxを起動:**

1. VS Code Remote-SSH経由でリモートホストに接続
2. 統合ターミナルを開く(`` Ctrl+` ``)
3. tmuxを起動:
   ```bash
   # 新しいセッションを作成
   tmux

   # または既存のセッションに接続
   tmux attach -t my-session

   # または名前付きセッションを作成/接続
   tmux new-session -A -s vscode
   ```

4. tmux内で通常通り作業
5. 完了したらデタッチ: `Ctrl+^ d` (設定済みのprefix + d)

**切断後に再開するには:**
1. VS Code Remote-SSH経由で再接続
2. ターミナルを開く
3. 再接続: `tmux attach -t vscode`

---

## 方法2: 自動接続設定

**新しいVS Codeターミナルごとに自動的にtmuxを起動:**

### VS Codeターミナルプロファイルの設定

1. リモートホストに接続
2. `Ctrl+Shift+P`を押す
3. "Preferences: Open Remote Settings (SSH: hostname)"と入力
4. この設定を追加:

```json
{
  "terminal.integrated.profiles.linux": {
    "tmux": {
      "path": "tmux",
      "args": ["new-session", "-A", "-s", "vscode"],
      "icon": "terminal"
    }
  },
  "terminal.integrated.defaultProfile.linux": "tmux"
}
```

**この設定の動作:**
- "tmux"という名前のターミナルプロファイルを作成
- `tmux new-session -A -s vscode`を使用(「vscode」という名前のセッションに接続または作成)
- tmuxをデフォルトのターミナルプロファイルに設定

### テスト

1. 新しいターミナルを開く(`` Ctrl+` ``)
2. 自動的にtmuxセッション「vscode」内に入ります
3. ターミナルの下部に`[vscode]`インジケータが表示されます
4. ターミナルを閉じて再度開く - 同じセッションに再接続されます!

---

## 方法3: シェルプロファイル統合

**すべてのターミナルセッション(VS Codeだけでなく)で自動的にtmuxを起動:**

### リモートシェルプロファイルに追加

リモートホストの`~/.bashrc`または`~/.zshrc`を編集:

```bash
# tmuxを自動起動(ただしVS Codeの統合ターミナルからは除く)
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -z "$VSCODE_IPC_HOOK_CLI" ]; then
    # "main"セッションに接続を試み、存在しない場合は作成
    tmux attach -t main || tmux new -s main
fi
```

**説明:**
- `command -v tmux`: tmuxがインストールされているか確認
- `[ -z "$TMUX" ]`: まだtmux内にいない
- `[ -z "$VSCODE_IPC_HOOK_CLI" ]`: VS Code統合ターミナル内ではない
- セッション「main」に接続、または作成

**注意:** これは通常のSSHセッションにも影響します!

---

## キーバインディングの考慮事項

### 潜在的な競合

VS Codeが一部のtmuxキーの組み合わせをキャプチャする可能性があります:

| tmuxコマンド | キーバインディング | 競合 |
| ------------ | ---------- | -------- |
| Prefix | `Ctrl+^` | 一般的に動作 |
| 水平分割 | `Ctrl+^ -` | 動作 |
| 垂直分割 | `Ctrl+^ \|` | 動作 |
| 前のウィンドウ | `Ctrl+^ p` | VS Codeの「Quick Open」と競合する可能性 |
| 新しいウィンドウ | `Ctrl+^ c` | 動作 |

### 解決策

**オプション1: マウスモードを使用(推奨)**

`.tmux.conf`でマウスサポートが有効になっています:
- ペインを選択するにはクリック
- 境界をドラッグしてサイズ変更
- 右クリックでコンテキストメニュー
- スクロールして履歴をナビゲート

**オプション2: VS Code経由でキーを送信**

カスタムVS Codeキーバインディングを作成(`keybindings.json`):

```json
[
  {
    "key": "ctrl+shift+6",
    "command": "workbench.action.terminal.sendSequence",
    "args": { "text": "\u001e" },
    "when": "terminalFocus",
    "comment": "tmux prefixのためにCtrl+^をターミナルに送信"
  }
]
```

**オプション3: 集中的なtmux使用には通常のSSHを使用**

集中的なtmuxワークフローには:
- 専用のSSHクライアント(Terminal.app、iTerm2、Windows Terminal)を使用
- 編集にはVS Code Remote-SSHを使用
- 必要に応じてツール間を切り替え

---

## ベストプラクティス

### 1. セッション名の命名

わかりやすいセッション名を使用:

```bash
# 開発作業
tmux new -s dev

# テスト/QA
tmux new -s test

# 本番環境の監視
tmux new -s prod
```

セッション一覧: `tmux ls`

### 2. ウィンドウの整理

コンテキストごとに作業を整理:

```bash
Ctrl+^ c     # 新しいウィンドウ
Ctrl+^ ,     # ウィンドウ名を変更
Ctrl+^ n     # 次のウィンドウ
Ctrl+^ p     # 前のウィンドウ
Ctrl+^ 0-9   # 番号でウィンドウにジャンプ
```

### 3. ペインレイアウト

ペインレイアウトを事前設定:

```bash
# コード+ターミナル用の水平分割
Ctrl+^ -

# 並んで編集するための垂直分割
Ctrl+^ |

# レイアウトを循環
Ctrl+^ Space
```

### 4. 意図的にデタッチ

VS Codeを閉じるだけでなく、適切にデタッチ:

```bash
# セッションからデタッチ(実行を継続)
Ctrl+^ d

# または入力
tmux detach
```

### 5. 古いセッションをクリーンアップ

定期的に未使用のセッションを削除:

```bash
# セッション一覧
tmux ls

# 特定のセッションを終了
tmux kill-session -t old-session

# 現在以外のすべてを終了
tmux kill-session -a
```

### 6. VS Code機能と組み合わせる

**両方のツールの長所を使用:**
- **VS Code**: ファイル編集、Git UI、デバッグ、拡張機能
- **tmux**: 永続的なシェル、長時間実行プロセス、複数のペイン

**ワークフロー例:**
1. VS Codeエディタでコードを編集
2. tmuxターミナルでテストを実行
3. 別のtmuxペインでログを監視
4. 自由に切断/再接続 - すべての作業が継続

---

## クイックコマンドリファレンス

### tmuxセッション管理

```bash
# 新しいセッションを作成
tmux new -s myname

# セッションに接続
tmux attach -t myname

# 作成または接続
tmux new-session -A -s myname

# セッション一覧
tmux ls

# セッションを終了
tmux kill-session -t myname

# デタッチ
Ctrl+^ d
```

### tmuxウィンドウ管理

```bash
Ctrl+^ c        # ウィンドウを作成
Ctrl+^ ,        # ウィンドウ名を変更
Ctrl+^ n        # 次のウィンドウ
Ctrl+^ p        # 前のウィンドウ
Ctrl+^ 0-9      # ウィンドウ0-9を選択
Ctrl+^ &        # ウィンドウを終了
```

### tmuxペイン管理

```bash
Ctrl+^ |        # 垂直分割
Ctrl+^ -        # 水平分割
Ctrl+^ arrow    # ペインをナビゲート
Ctrl+^ z        # ペインズームを切り替え
Ctrl+^ x        # ペインを終了
Ctrl+^ Space    # レイアウトを循環
```

---

## トラブルシューティング

### ターミナルに生の制御文字が表示される

**問題:** 入力すると`^M`などが表示される

**解決策:** tmuxが正しく初期化されていない可能性があります
```bash
exit        # tmuxを終了
tmux kill-server  # tmuxサーバーを終了
tmux        # 新しく起動
```

### VS Code再接続後にtmuxにアクセスできない

**問題:** tmuxセッションは存在するが接続できない

**解決策:**
```bash
# セッション一覧
tmux ls

# 強制接続(他の接続をデタッチ)
tmux attach -t vscode -d
```

### tmuxでマウスが動作しない

**問題:** クリックしてもペインが選択されない

**解決策:** `.tmux.conf`に以下が含まれているか確認:
```bash
set -g mouse on
```

設定を再読み込み:
```bash
tmux source-file ~/.tmux.conf
```

---

## 関連ドキュメント

- [メインREADME - tmux基本](../README.md#tmux-basics)
- [VS Code Remote-SSHセットアップ](vscode-remote-ssh.md)
- [VS Codeトラブルシューティング](vscode-troubleshooting.md)
- [公式tmuxドキュメント](https://github.com/tmux/tmux/wiki)

**利点まとめ:**
✅ 永続的なセッションは切断を生き延びる
✅ コンテキストごとに整理された複数のペインとウィンドウ
✅ バックグラウンドプロセスが実行し続ける
✅ VS Code + tmuxの強みを組み合わせた柔軟なワークフロー
