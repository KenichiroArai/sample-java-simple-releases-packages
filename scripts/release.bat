@ECHO off
REM -*- mode: bat; coding: shift-jis -*-

REM ===========================================
REM リリース自動化スクリプト
REM ===========================================
REM
REM 前提条件：
REM - GitHub アカウントを持っていること
REM - リポジトリへのプッシュ権限があること
REM - 以下がインストールされていること：
REM   - Java 21
REM   - Maven
REM   - Git
REM   - GitHub CLI（オプション：プルリクエストの自動作成に必要）
REM
REM 使用方法：
REM   release.bat [作業ブランチ] [リリースブランチ] [バージョン]
REM   例：release.bat features/release main 1.0.0
REM
REM 機能：
REM - 指定したバージョンでのリリース作成を自動化
REM - pom.xml のバージョン更新
REM - 未コミットの変更の自動コミット
REM - リモートブランチとの自動同期
REM - プルリクエストの作成（GitHub CLI使用時）
REM - タグの作成とプッシュ
REM
REM 注意事項：
REM - バージョン番号の先頭の「v」は省略可能（自動的に付加）
REM - プルリクエストのマージは手動で行う必要あり
REM - GitHub CLI未インストール時はプルリクエストを手動で作成
REM - このバッチファイルはSJISでコンソール出力を設定
REM
REM ファイル形式に関する注意事項：
REM - このバッチファイルはShift-JIS（SJIS）で保存する必要があります
REM - 改行コードはCRLF（Windows形式）を使用してください
REM - ファイル先頭の mode: bat; coding: shift-jis 指定を削除しないでください
REM ===========================================

CHCP 932 > nul
SETLOCAL enabledelayedexpansion

REM PowerShellのエンコーディング設定
powershell -command "[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding('shift-jis')"
powershell -command "$OutputEncoding = [System.Text.Encoding]::GetEncoding('shift-jis')"

REM リリース自動化スクリプト
REM ===========================================

IF "%~1"=="" (
    ECHO 使用方法：release.bat [作業ブランチ] [リリースブランチ] [バージョン]
    ECHO 例：release.bat features/release main 1.0.0
    EXIT /b 1
)

SET WORK_BRANCH=%~1
SET RELEASE_BRANCH=%~2
SET VERSION=%~3

IF NOT "%VERSION:~0,1%"=="v" (
    SET VERSION=v%VERSION%
)

ECHO リリースプロセスを開始します...
ECHO 作業ブランチ: %WORK_BRANCH%
ECHO リリースブランチ: %RELEASE_BRANCH%
ECHO バージョン: %VERSION%

REM リモートリポジトリから最新の情報を取得
git fetch
IF errorlevel 1 GOTO error

REM 指定された作業ブランチに切り替え
git checkout %WORK_BRANCH%
IF errorlevel 1 GOTO error

REM 未コミットの変更をステージングエリアに追加
git add .
REM 変更をコミット（変更がない場合はスキップ）
git commit -m "リリース準備：未コミットの変更を追加" || ECHO 未コミットの変更なし

REM Maven プロジェクトのバージョンを更新（vを除いたバージョン番号を使用）
CALL mvn versions:set -DnewVersion=%VERSION:~1%
IF errorlevel 1 GOTO error

REM 更新された pom.xml をステージングエリアに追加
git add pom.xml
REM バージョン更新をコミット（変更がない場合はスキップ）
git commit -m "バージョンを %VERSION:~1% に更新" || ECHO バージョン変更なし

REM Maven が作成したバックアップファイルを削除
DEL pom.xml.versionsBackup

REM リモートの変更を取得し、ローカルの変更を上に重ねる（コンフリクトを防ぐため）
git pull origin %WORK_BRANCH% --rebase
IF errorlevel 1 GOTO error

REM 作業ブランチとリリースブランチの差分を確認
git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
IF %errorlevel% equ 0 (
    ECHO 作業ブランチとリリースブランチに差分がありません。
    ECHO プルリクエストをスキップしてタグ作成に進みます。
    GOTO create_tag
)

REM ローカルの変更をリモートリポジトリにプッシュ
ECHO 変更をプッシュ中...
git push origin %WORK_BRANCH%
IF errorlevel 1 GOTO error

REM GitHub CLI（gh）がインストールされているか確認
WHERE gh >nul 2>nul
IF %errorlevel% equ 0 (
    REM 再度差分を確認（念のため）
    git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
    IF errorlevel 1 (
        ECHO プルリクエストを作成中...
        REM GitHub CLI を使用してプルリクエストを作成
        gh pr create --base %RELEASE_BRANCH% --head %WORK_BRANCH% --title "リリース%VERSION%" --body "リリース%VERSION%のプルリクエストです。"
        IF errorlevel 1 GOTO error
    ) ELSE (
        ECHO 変更がないため、プルリクエストをスキップします。
    )
) ELSE (
    ECHO GitHub CLI がインストールされていません。
    ECHO 手動でプルリクエストを作成してください。
    PAUSE
)

ECHO プルリクエストがマージされるまで待機します...
ECHO マージが完了したら Enter キーを押してください...
PAUSE

:create_tag
REM リリースブランチに切り替える前に、マージ完了を確認
git fetch
IF errorlevel 1 GOTO error

REM マージ状態を確認
git rev-list --count origin/%RELEASE_BRANCH%..%WORK_BRANCH% > nul 2>&1
IF errorlevel 1 (
    ECHO マージが完了していることを確認中...
    git pull origin %RELEASE_BRANCH% --ff-only
    IF errorlevel 1 (
        ECHO マージが完了していないか、コンフリクトが発生しています。
        ECHO プルリクエストのマージを確認してください。
        EXIT /b 1
    )
)

REM リリースブランチに切り替え
git checkout %RELEASE_BRANCH%
IF errorlevel 1 GOTO error

REM リリースブランチの最新の変更を取得
git pull origin %RELEASE_BRANCH%
IF errorlevel 1 GOTO error

REM 既存のタグがある場合は削除（エラーは無視）
git tag -d %VERSION% 2>nul
REM リモートの既存タグも削除（エラーは無視）
git push origin :refs/tags/%VERSION% 2>nul
REM 新しいタグを作成
git tag %VERSION%
REM タグをリモートにプッシュ
git push origin %VERSION%
IF errorlevel 1 GOTO error

REM 最終確認のため、もう一度プル
git pull origin %RELEASE_BRANCH%
IF errorlevel 1 GOTO error

ECHO リリースプロセスが完了しました。
ECHO GitHub Actions でリリースが作成されるまでお待ちください。
EXIT /b 0

:error
ECHO エラーが発生しました。
EXIT /b 1
