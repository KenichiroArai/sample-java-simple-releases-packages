@ECHO off
REM -*- mode: bat; coding: shift-jis -*-

REM ===========================================
REM �����[�X�������X�N���v�g
REM ===========================================
REM
REM �O������F
REM - GitHub �A�J�E���g�������Ă��邱��
REM - ���|�W�g���ւ̃v�b�V�����������邱��
REM - �ȉ����C���X�g�[������Ă��邱�ƁF
REM   - Java 21
REM   - Maven
REM   - Git
REM   - GitHub CLI�i�I�v�V�����F�v�����N�G�X�g�̎����쐬�ɕK�v�j
REM
REM �g�p���@�F
REM   release.bat [��ƃu�����`] [�����[�X�u�����`] [�o�[�W����]
REM   ��Frelease.bat features/release main 1.0.0
REM
REM �@�\�F
REM - �w�肵���o�[�W�����ł̃����[�X�쐬��������
REM - pom.xml �̃o�[�W�����X�V
REM - ���R�~�b�g�̕ύX�̎����R�~�b�g
REM - �����[�g�u�����`�Ƃ̎�������
REM - �v�����N�G�X�g�̍쐬�iGitHub CLI�g�p���j
REM - �^�O�̍쐬�ƃv�b�V��
REM
REM ���ӎ����F
REM - �o�[�W�����ԍ��̐擪�́uv�v�͏ȗ��\�i�����I�ɕt���j
REM - �v�����N�G�X�g�̃}�[�W�͎蓮�ōs���K�v����
REM - GitHub CLI���C���X�g�[�����̓v�����N�G�X�g���蓮�ō쐬
REM - ���̃o�b�`�t�@�C����SJIS�ŃR���\�[���o�͂�ݒ�
REM
REM �t�@�C���`���Ɋւ��钍�ӎ����F
REM - ���̃o�b�`�t�@�C����Shift-JIS�iSJIS�j�ŕۑ�����K�v������܂�
REM - ���s�R�[�h��CRLF�iWindows�`���j���g�p���Ă�������
REM - �t�@�C���擪�� mode: bat; coding: shift-jis �w����폜���Ȃ��ł�������
REM ===========================================

CHCP 932 > nul
SETLOCAL enabledelayedexpansion

REM PowerShell�̃G���R�[�f�B���O�ݒ�
powershell -command "[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding('shift-jis')"
powershell -command "$OutputEncoding = [System.Text.Encoding]::GetEncoding('shift-jis')"

REM �����[�X�������X�N���v�g
REM ===========================================

IF "%~1"=="" (
    ECHO �g�p���@�Frelease.bat [��ƃu�����`] [�����[�X�u�����`] [�o�[�W����]
    ECHO ��Frelease.bat features/release main 1.0.0
    EXIT /b 1
)

SET WORK_BRANCH=%~1
SET RELEASE_BRANCH=%~2
SET VERSION=%~3

IF NOT "%VERSION:~0,1%"=="v" (
    SET VERSION=v%VERSION%
)

ECHO �����[�X�v���Z�X���J�n���܂�...
ECHO ��ƃu�����`: %WORK_BRANCH%
ECHO �����[�X�u�����`: %RELEASE_BRANCH%
ECHO �o�[�W����: %VERSION%

REM �����[�g���|�W�g������ŐV�̏����擾
git fetch
IF errorlevel 1 GOTO error

REM �w�肳�ꂽ��ƃu�����`�ɐ؂�ւ�
git checkout %WORK_BRANCH%
IF errorlevel 1 GOTO error

REM ���R�~�b�g�̕ύX���X�e�[�W���O�G���A�ɒǉ�
git add .
REM �ύX���R�~�b�g�i�ύX���Ȃ��ꍇ�̓X�L�b�v�j
git commit -m "�����[�X�����F���R�~�b�g�̕ύX��ǉ�" || ECHO ���R�~�b�g�̕ύX�Ȃ�

REM Maven �v���W�F�N�g�̃o�[�W�������X�V�iv���������o�[�W�����ԍ����g�p�j
CALL mvn versions:set -DnewVersion=%VERSION:~1%
IF errorlevel 1 GOTO error

REM �X�V���ꂽ pom.xml ���X�e�[�W���O�G���A�ɒǉ�
git add pom.xml
REM �o�[�W�����X�V���R�~�b�g�i�ύX���Ȃ��ꍇ�̓X�L�b�v�j
git commit -m "�o�[�W������ %VERSION:~1% �ɍX�V" || ECHO �o�[�W�����ύX�Ȃ�

REM Maven ���쐬�����o�b�N�A�b�v�t�@�C�����폜
DEL pom.xml.versionsBackup

REM �����[�g�̕ύX���擾���A���[�J���̕ύX����ɏd�˂�i�R���t���N�g��h�����߁j
git pull origin %WORK_BRANCH% --rebase
IF errorlevel 1 GOTO error

REM ��ƃu�����`�ƃ����[�X�u�����`�̍������m�F
git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
IF %errorlevel% equ 0 (
    ECHO ��ƃu�����`�ƃ����[�X�u�����`�ɍ���������܂���B
    ECHO �v�����N�G�X�g���X�L�b�v���ă^�O�쐬�ɐi�݂܂��B
    GOTO create_tag
)

REM ���[�J���̕ύX�������[�g���|�W�g���Ƀv�b�V��
ECHO �ύX���v�b�V����...
git push origin %WORK_BRANCH%
IF errorlevel 1 GOTO error

REM GitHub CLI�igh�j���C���X�g�[������Ă��邩�m�F
WHERE gh >nul 2>nul
IF %errorlevel% equ 0 (
    REM �ēx�������m�F�i�O�̂��߁j
    git diff %WORK_BRANCH% %RELEASE_BRANCH% --quiet
    IF errorlevel 1 (
        ECHO �v�����N�G�X�g���쐬��...
        REM GitHub CLI ���g�p���ăv�����N�G�X�g���쐬
        gh pr create --base %RELEASE_BRANCH% --head %WORK_BRANCH% --title "�����[�X%VERSION%" --body "�����[�X%VERSION%�̃v�����N�G�X�g�ł��B"
        IF errorlevel 1 GOTO error
    ) ELSE (
        ECHO �ύX���Ȃ����߁A�v�����N�G�X�g���X�L�b�v���܂��B
    )
) ELSE (
    ECHO GitHub CLI ���C���X�g�[������Ă��܂���B
    ECHO �蓮�Ńv�����N�G�X�g���쐬���Ă��������B
    PAUSE
)

ECHO �v�����N�G�X�g���}�[�W�����܂őҋ@���܂�...
ECHO �}�[�W������������ Enter �L�[�������Ă�������...
PAUSE

:create_tag
REM �����[�X�u�����`�ɐ؂�ւ���O�ɁA�}�[�W�������m�F
git fetch
IF errorlevel 1 GOTO error

REM �}�[�W��Ԃ��m�F
git rev-list --count origin/%RELEASE_BRANCH%..%WORK_BRANCH% > nul 2>&1
IF errorlevel 1 (
    ECHO �}�[�W���������Ă��邱�Ƃ��m�F��...
    git pull origin %RELEASE_BRANCH% --ff-only
    IF errorlevel 1 (
        ECHO �}�[�W���������Ă��Ȃ����A�R���t���N�g���������Ă��܂��B
        ECHO �v�����N�G�X�g�̃}�[�W���m�F���Ă��������B
        EXIT /b 1
    )
)

REM �����[�X�u�����`�ɐ؂�ւ�
git checkout %RELEASE_BRANCH%
IF errorlevel 1 GOTO error

REM �����[�X�u�����`�̍ŐV�̕ύX���擾
git pull origin %RELEASE_BRANCH%
IF errorlevel 1 GOTO error

REM �����̃^�O������ꍇ�͍폜�i�G���[�͖����j
git tag -d %VERSION% 2>nul
REM �����[�g�̊����^�O���폜�i�G���[�͖����j
git push origin :refs/tags/%VERSION% 2>nul
REM �V�����^�O���쐬
git tag %VERSION%
REM �^�O�������[�g�Ƀv�b�V��
git push origin %VERSION%
IF errorlevel 1 GOTO error

REM �ŏI�m�F�̂��߁A������x�v��
git pull origin %RELEASE_BRANCH%
IF errorlevel 1 GOTO error

ECHO �����[�X�v���Z�X���������܂����B
ECHO GitHub Actions �Ń����[�X���쐬�����܂ł��҂����������B
EXIT /b 0

:error
ECHO �G���[���������܂����B
EXIT /b 1
