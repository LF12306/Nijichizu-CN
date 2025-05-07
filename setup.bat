@echo off
setlocal enabledelayedexpansion

>nul reg add "HKCU\Console" /v "CodePage" /t REG_DWORD /d 65001 /f
chcp 65001 >nul
title 虹之咲字幕组未来地图汉化补丁

:: 主程序

echo ===========================================

echo 正在应用汉化补丁...
powershell -ExecutionPolicy Bypass -File "%~dp0patch.ps1"

echo ===========================================

:: 删除 patch.ps1

echo 正在删除 patch.ps1...

del /f /q "%~dp0patch.ps1"

:: 删除文件夹

echo 正在删除文件夹：虹之咲字幕组汉化补丁...

rmdir /s /q "%~dp0虹之咲字幕组汉化补丁"

:: 用 PowerShell 实现自删除

echo 正在准备自删除：setup.bat...

powershell -command "Start-Sleep -Seconds 1; Remove-Item -LiteralPath '%~f0' -Force"

exit /b
