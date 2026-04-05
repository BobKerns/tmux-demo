# Windows PSMUX Tmux クライアントガイド

[English](psmux-guide.md)

Windows用最新tmuxクライアントPSMUXを使用したリモート開発環境への接続ガイド。

---

## 目次

1. [PSMUXとは?](#psmuxとは)
2. [インストール](#インストール)
3. [リモートへの接続](#リモートへの接続)
4. [基本的な使用方法](#基本的な使用方法)
5. [設定](#設定)
6. [トラブルシューティング](#トラブルシューティング)
7. [代替ツール](#代替ツール)

---

## PSMUXとは?

PSMUXは、Windows向けのネイティブtmuxクライアントで以下の機能を提供します:

- **ネイティブなWindows体験**: WSLやCygwin不要
- **マウスサポート**: クリックでペイン切り替え、マウスホイールでスクロール
- **優れたレンダリング**: 最新のフォントレンダリングとカラーサポート
- **セッションプロファイル**: 接続設定の保存
- **クリップボード統合**: WindowsクリップボードとのコピーCorte&ペーストが動作

### PSMUX vs 従来のSSHクライアント

| 機能 | PSMUX | PuTTY | Windows Terminal |
| ------ | ------- | ------- | ------------------ |
| ネイティブtmuxサポート | ✅ あり | ❌ なし | ⚠️ SSH経由のみ |
| tmux内のマウス | ✅ 優秀 | ⚠️ 限定的 | ⚠️ 基本的 |
| セッションプロファイル保存 | ✅ あり | ✅ あり | ⚠️ 手動設定 |
| モダンUI | ✅ あり | ❌ なし | ✅ あり |
| クリップボード統合 | ✅ シームレス | ⚠️ 限定的 | ✅ 良好 |

**注意**: 2026年4月現在、PSMUXは仮想的な例です。実際のWindows tmux使用については、[代替ツール](#代替ツール)セクションを参照してください。

---

## インストール

### 前提条件

- **Windows 10以降**
- **OpenSSH Client** (通常Windows 10+にプリインストール)
  - 確認: PowerShellで`ssh`と入力
  - 未インストールの場合: 設定 → アプリ → オプション機能 → OpenSSH Clientを追加

### インストール手順

#### 方法 1: インストーラー(推奨)

1. **最新インストーラーをダウンロード:**
   - [PSMUX Releases](https://github.com/example/psmux/releases)にアクセス (例示URL)
   - `PSMUX-Setup-x64.msi` または `PSMUX-Setup-x64.exe` をダウンロード

2. **インストーラーを実行:**
   - ダウンロードしたファイルをダブルクリック
   - インストールウィザードに従う
   - デフォルトインストール場所: `C:\Program Files\PSMUX`

3. **インストールを確認:**
   ```powershell
   psmux --version
   ```

#### 方法 2: ポータブル版(インストール不要)

1. `PSMUX-Portable-x64.zip` をダウンロード
2. フォルダーに解凍 (例: `C:\Tools\PSMUX`)
3. PATHに追加 (オプション):
   - システム → 詳細設定 → 環境変数
   - `C:\Tools\PSMUX` をPATHに追加

#### 方法 3: パッケージマネージャー (Chocolatey)

```powershell
# Chocolateyがインストールされている場合
choco install psmux
```

#### 方法 4: Scoop

```powershell
scoop install psmux
```

---

## リモートへの接続

### クイック接続

最も簡単な接続方法:

```powershell
psmux connect -h <host> -u <user> -i <keyfile>
```

**例:**

**Dockerコンテナ:**
```powershell
psmux connect -h localhost -p 2222 -u developer -i C:\Users\YourName\.ssh\tmux_demo_key
```

**AWS EC2:**
```powershell
psmux connect -h ec2-xx-xxx-xxx-xxx.compute-1.amazonaws.com -p 22 -u ubuntu -i C:\Users\YourName\.ssh\aws-key.pem
```

### SSH設定の使用

SSH設定ファイル (`C:\Users\YourName\.ssh\config`) がある場合:

```powershell
# 設定ファイルのホストエイリアスを使用して接続
psmux connect tmux-demo
```

PSMUXはSSH設定を自動的に読み込みます!

### GUI経屠接続

1. **PSMUXを起動** (スタートメニューまたはデスクトップアイコン)
2. **"New Connection"をクリック**
3. **詳細を入力:**
   - Host: `localhost` (Docker) またはEC2アドレス
   - Port: `2222` (Docker) または `22` (EC2)
   - Username: `developer` または `ubuntu`
   - Key file: 秘密鍵を参照
4. **"Connect"をクリック**
5. **オプション**: プロファイルとして保存

---

## 基本的な使用方法

### Emacs対応プレフィックスでのtmuxコマンド

重要: この環境では **Ctrl+^** をプレフィックスとして使用 (Ctrl+bではありません)

#### 基本コマンド

| コマンド | 説明 |
| --------- | ------ |
| `tmux` | 新しいセッション開始 |
| `tmux ls` | セッション一覧 |
| `tmux attach -t <name>` | セッションに再接続 |
| `tmux kill-session -t <name>` | セッションを終了 |

#### プレフィックス付き (Ctrl+^)

| キー | アクション |
| ------ | ---------- |
| `Ctrl+^ c` | 新しいウィンドウ作成 |
| `Ctrl+^ ,` | 現在のウィンドウ名変更 |
| `Ctrl+^ n` | 次のウィンドウ |
| `Ctrl+^ p` | 前のウィンドウ |
| `Ctrl+^ 0-9` | ウィンドウ 0-9 に切り替え |
| `Ctrl+^ \|` | ペインを横に分割(カスタム) |
| `Ctrl+^ -` | ペインを縦に分割(カスタム) |
| `Ctrl+^ 矢印キー` | ペイン間を移動 |
| `Ctrl+^ d` | セッションからデタッチ |
| `Ctrl+^ [` | スクロールモード開始 (矢印キーでスクロール、`q`で終了) |
| `Ctrl+^ ?` | すべてのキーバインド一覧 |

### PSMUX固有の機能

#### マウスサポート

PSMUXはtmuxのマウスモードを完全サポート (`.tmux.conf`で有効化済み):

- **ペインをクリック** で切り替え
- **マウスホイール** でペイン内をスクロール
- **仕切りをドラッグ** でペインリサイズ
- **右クリック** でコンテキストメニュー (PSMUX機能)

#### クリップボード

**tmuxからWindowsへコピー:**
1. tmuxコピーモード開始: `Ctrl+^ [`
2. マウスまたはキーボードでテキスト選択
3. `Enter`を押してコピー
4. Windowsのどこでも`Ctrl+V`でペースト

**WindowsからtmuxへペースCapt状:**
1. Windowsでテキストをコピー
2. PSMUXでペインをクリック
3. 右クリック → "Paste" または `Shift+Insert`

#### タブ

PSMUXは複数接続をタブで開けます:

- **新しいタブ**: `Ctrl+T`
- **タブを閉じる**: `Ctrl+W`
- **次のタブ**: `Ctrl+Tab`
- **前のタブ**: `Ctrl+Shift+Tab`

各タブは別々のSSH接続です!

---

## 設定

### セッションプロファイル

よく使う接続を保存:

1. **ホストに接続**
2. **接続を右クリック** → "Save as Profile"
3. **プロファイル名を入力**: "Dev Docker", "AWS Prod"など
4. **次回**: プロファイルをクリックして即座に接続

### キーボードショートカット

PSMUXショートカットをカスタマイズ:

1. **Settings** → "Keyboard"
2. バインド修正:
   - New tab
   - Split window
   - Copy/Paste
   - Font size

**警告**: tmuxバインドと競合しないように!

### 外観

**フォント:**
- Settings → "Appearance" → "Font"
- 推奨: "Cascadia Code", "JetBrains Mono", "Fira Code"
- コード可読性向上のため合字を有効化

**カラー:**
- Settings → "Appearance" → "Color Scheme"
- 定義済みスキームから選択またはカスタマイズ
- tmuxステータスバーの色は `.tmux.conf` から

**透明度:**
- Settings → "Appearance" → "Opacity"
- ドキュメントを参照しながら作業するのに便利

### サウンド

有効化/無効化:
- ベル音
- ビジュアルベル
- 通知

### 詳細設定

**接続:**
```json
{
  "connection": {
    "keepAlive": true,
    "keepAliveInterval": 60,
    "timeout": 30
  }
}
```

**ターミナル:**
```json
{
  "terminal": {
    "scrollback": 10000,
    "cursorBlink": true,
    "fastScrollModifier": "shift"
  }
}
```

---

## トラブルシューティング

### PSMUXが起動しない

**症状:**
アプリケーション起動時にクラッシュ

**解決策:**

1. **前提条件を確認:**
   - Windows 10以降
   - .NET Framework (必要な場合)
   - OpenSSH Clientインストール済み

2. **再インストール:**
   - PSMUXをアンインストール
   - `C:\Users\YourName\AppData\Local\PSMUX` を削除
   - 再インストール

3. **管理者として実行** (1回):
   - PSMUX右クリック → "管理者として実行"

### 接続に失敗

**症状:**
```
Failed to connect to host
```

**解決策:**

1. **SSHを手動テスト:**
   ```powershell
   ssh -i C:\Users\YourName\.ssh\key user@host
   ```

2. **鍵ファイルのパーミッション確認:**
   - 鍵ファイル右クリック → プロパティ → セキュリティ
   - 自分のユーザーのみがアクセス可能であることを確認

3. **Docker相手件の場合**: コンテナが実行中か確認
   ```powershell
   docker ps
   ```

4. **SSH設定の構文確認** (設定ファイル使用時)

### プレフィックスキーが動作しない

**症状:**
Ctrl+^がtmuxプレフィックスとして動作しない

**解決策:**

1. **キーボードレイアウトを確認:**
   - `^`文字の場所はキーボードによって異なります
   - 日本語キーボード: `^`の位置を確認
   - USキーボード: `Shift+6`で`^`
   - 試行: `Ctrl+Shift+6`を押す

2. **tmux設定を確認:**
   ```bash
   # リモートホスト上で
   cat ~/.tmux.conf | grep prefix
   ```
   表示されるべき内容: `set-option -g prefix C-^`

3. **通常のtmuxでテスト:**
   ```powershell
   ssh user@host
   tmux
   # Ctrl+^ c を試す
   ```

4. **代替手段**: `.tmux.conf`で別のキーに再マップ

### コピー&ペーストが動作しない

**症状:**
tmuxからWindowsクリップボードへコピーできない

**解決策:**

1. **tmuxマウスモード有効確認:**
   ```bash
   # リモートtmux内で
   tmux show -g mouse
   # 表示されるべき: mouse on
   ```

2. **PSMUXコピー機能使用:**
   - マウスでテキスト選択
   - 右クリック → "Copy"

3. **PSMUXを最新バージョンに更新**

### フォントレンダリング問題

**症状:**
テキストがぼやける、または間隔が不自然

**解決策:**

1. **フォント変更:**
   - Settings → "Appearance" → "Font"
   - 試行: Cascadia Code, Consolas, Courier New

2. **フォントサイズ調整:**
   - 大きめのフォント (12-14pt) の方がレンダリングが良好な場合が多い

3. **ClearTypeを無効化** (ぼやける場合):
   - Windows → "ClearTypeテキストの調整"

### 高DPIスケーリング問題

**症状:**
高解像度ディスプレイでテキストが小さすぎる、または大きすぎる

**解決策:**

1. **アプリケーションスケーリング:**
   - PSMUX.exe右クリック → プロパティ → 互換性
   - DPI設定を変更
   - オーバーライド: アプリケーション

2. **PSMUX設定:**
   - Settings → "Appearance" → "DPI Scaling"
   - 倍率を調整

---

## ベストプラクティス

### 1. セッションプロファイルを使用

すべての環境をプロファイルとして保存:
- **Dev Local**: Dockerコンテナ
- **Dev AWS**: 開発EC2
- **Prod AWS**: 本番EC2 (確認付き)

### 2. タブで整理

- **タブ 1**: アプリケーションサーバー接続
- **タブ 2**: データベースサーバー接続
- **タブ 3**: 監視/ログサーバー

### 3. マウス+キーボード組み合わせをマスター

- クイックなペイン切り替えにはマウス使用
- 複雑な操作にはキーボード使用
- 両方の良いとこ取り!

### 4. 慎重にカスタマイズ

デフォルトから始め、徐々にカスタマイズ:
1. まずtmuxに慣れる
2. 次にPSMUXショートカットをカスタマイズ
3. PSMUXとtmux間の競合を避ける

### 5. PSMUXを最新に保つ

更新には以下が含まれることが多い:
- より良いtmux互換性
- パフォーマンス改善
- バグ修正

---

## 代替ツール

PSMUXが合わない場合、以下の代替ツールを検討:

### 1. Windows Terminal + SSH

**Microsoftの公式ツール:**

```powershell
# Microsoft StoreからWindows Terminalをインストール
# 接続:
wt ssh -i C:\Users\YourName\.ssh\key user@host
# その後: tmux
```

**長所:**
- Microsoft公式製品
- 優れたレンダリング
- タブサポート
- 高度なカスタマイズ

**短所:**
- 特別なtmux機能なし
- マウスサポートは状況による

### 2. MobaXterm

**オールインワンツール:**

- 組み込みSSHクライアント
- X11サーバー含む
- セッションマネージャー
- 無料版 (Home Edition) と有料版 (Professional)

**ダウンロード**: [mobatek.net](https://mobaxterm.mobatek.net/)

### 3. PuTTY

**クラシックSSHクライアント:**

- 無料でオープンソース
- 非常に安定
- 軽量
- 豊富な設定

**ダウンロード**: [putty.org](https://www.putty.org/)

### 4. WSL2 + Windows Terminal

**WindowsでフルLinux体験:**

```powershell
# WSL2をインストール
wsl --install

# WSL内で:
ssh user@host
tmux
```

**長所:**
- 本物のLinux環境
- 完璧なtmux互換性
- Linuxツールを実行可能

**短所:**
- より複雑なセットアップ
- WSL2が必要

---

## クイックリファレンス

### 接続

```powershell
# クイック接続
psmux connect -h host -p port -u user -i keyfile

# SSH設定使用
psmux connect alias

# GUI
psmux
```

### tmuxコマンド (プレフィックス: Ctrl+^)

| アクション | キー |
| ---------- | ------ |
| 新しいウィンドウ | `Ctrl+^ c` |
| 横に分割 | `Ctrl+^ \|` |
| 縦に分割 | `Ctrl+^ -` |
| ペイン移動 | `Ctrl+^ 矢印キー` |
| デタッチ | `Ctrl+^ d` |
| スクロールモード | `Ctrl+^ [` |

### PSMUXショートカット

| アクション | キー |
| ---------- | ------ |
| 新しいタブ | `Ctrl+T` |
| タブを閉じる | `Ctrl+W` |
| 次のタブ | `Ctrl+Tab` |
| コピー | 選択 + `Ctrl+C` |
| ペースト | `Ctrl+V` または `Shift+Insert` |

---

## 参考資料

- [tmuxチートシート](https://tmuxcheatsheet.com/)
- [SSHセットアップ](ssh-setup.ja.md)
- [VS Code Remote-SSH](vscode-remote-ssh.ja.md)
- [メインREADME](../README.ja.md)

---

**注意**: PSMUXはWindows向け最新tmuxクライアントの例として使用しています。2026年4月現在では仮想的なツールです。最新の利用可能なツールを確認してください。概念はWindows上のどのSSH/tmuxクライアントにも適用できます。
