# sample-java-simple-releases-packages

シンプルな Java で GitHub Releases と Packages を試すサンプルプロジェクトです。

## 概要

このプロジェクトは、GitHub Releases でのリリース作成と GitHub Packages への Maven パッケージの公開を示すサンプルです。

## 前提条件

- GitHub アカウントを持っていること
- リポジトリへのプッシュ権限があること
- ローカル環境に以下がインストールされていること：
  - Java 21
  - Maven
  - Git
  - GitHub CLI（オプション：プルリクエストの自動作成に必要）

## リリースプロセス

このプロジェクトでは、以下の2つのリリース方法を提供しています：

1. バッチファイルを使用した自動リリース作成（推奨）
2. 手動でのリリース作成

### バッチファイルを使用したリリース作成（推奨）

`scripts/release.bat`を使用することで、リリースプロセスを自動化できます。

#### 使用方法

```bash
scripts\release.bat [作業ブランチ] [リリースブランチ] [バージョン]
```

例：

```bash
scripts\release.bat features/release main 1.0.0
```

#### バッチファイルの機能

- 指定したバージョンでのリリース作成を自動化
- pom.xml のバージョン更新
- 未コミットの変更の自動コミット
- リモートブランチとの自動同期（リベースによる変更の統合）
- プルリクエストの作成（GitHub CLI がインストールされている場合）
- タグの作成とプッシュ
- エラー発生時の適切なエラーハンドリングとプロセスの中断

#### 使用上の注意

- バージョン番号の先頭の「v」は省略可能です（自動的に付加されます）
- プルリクエストのマージは手動で行う必要があります
- GitHub CLI がインストールされていない場合は、プルリクエストの作成は手動で行う必要があります
- エラーが発生した場合、プロセスは自動的に中断され、エラーメッセージが表示されます
- コンソール出力は SJIS エンコーディングで設定されます

### 手動でのリリース作成

手動でリリースを作成する場合は、以下の手順に従ってください。

#### 1. コードの準備

```bash
# リモートの最新情報を取得
git fetch

# ブランチの切り替え（作業用のブランチに切り替える）
git checkout features/release

# 変更状態の確認
git status

# 変更のコミット（未コミットの変更がある場合）
git add .
git commit -m "リリース準備完了"

# 変更のプッシュ
git push origin features/release
```

#### 2. バージョンの設定

```bash
# Mavenのバージョンを設定（例：1.0.0）
mvn versions:set -DnewVersion=1.0.0

# バージョン変更をコミット
git add pom.xml
git commit -m "バージョンを1.0.0に更新"

# バックアップファイルを削除
rm pom.xml.versionsBackup

# リモートの変更を取り込む（リベースを使用）
git pull origin features/release --rebase

# 変更をプッシュ
git push origin features/release
```

#### 3. プルリクエストの作成とマージ

```bash
# プルリクエストの作成（GitHub CLIを使用する場合）
gh pr create --base main --head features/release --title "リリース1.0.0" --body "リリース1.0.0のプルリクエストです。"
```

#### 4. タグの作成とプッシュ

```bash
# ブランチの切り替え（リリースをするブランチ）
git checkout main

# プル
git pull origin main

# タグの作成（vから始める必要があります）
git tag v1.0.0

# タグのプッシュ
git push origin v1.0.0
```

## パッケージの使用

このプロジェクトで公開されたパッケージを他のプロジェクトで使用するには：

### 1. 認証設定

`~/.m2/settings.xml`に以下を追加して GitHub Packages の認証を設定：

```xml
<settings>
  <servers>
    <server>
      <id>github</id>
      <username>YOUR_GITHUB_USERNAME</username>
      <password>YOUR_GITHUB_TOKEN</password>
    </server>
  </servers>
</settings>
```
### 2. 依存関係の追加

使用したいプロジェクトの`pom.xml`に以下を追加：

```xml
<repositories>
    <repository>
        <id>github</id>
        <url>https://maven.pkg.github.com/OWNER/REPOSITORY</url>
    </repository>
</repositories>

<dependencies>
    <dependency>
        <groupId>com.example</groupId>
        <artifactId>sample-simple-java-packages</artifactId>
        <version>0.1.0</version>
    </dependency>
</dependencies>
```

## 自動化されるプロセス

タグをプッシュすると、GitHub Actions によって以下の処理が自動的に実行されます：

1. プロジェクトのビルド
2. JARファイルの生成
3. GitHub Packages へのパッケージの公開
4. GitHub リリースの作成
5. JARファイルのリリースへの添付
6. リリースノートの自動生成

## トラブルシューティング

リリース作成に問題が発生した場合：

1. GitHub Actions のログを確認
2. エラーメッセージを確認
3. 必要に応じてタグを削除して再試行：

   ```bash
   # ローカルのタグを削除
   git tag -d v1.0.0
   # リモートのタグを削除
   git push --delete origin v1.0.0
   ```

## 注意事項

- GitHub Personal Access Token (PAT) には以下の権限が必要です：
  - パッケージの使用：`read:packages`
  - パッケージの公開：`write:packages`
- リポジトリ名とパスは適宜置き換えてください

## ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。
