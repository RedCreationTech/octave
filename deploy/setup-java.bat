@echo off
chcp 65001 >nul
setlocal

set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..
set RUNTIME_DIR=%PROJECT_DIR%\runtime
set JAVA_EXE=%RUNTIME_DIR%\bin\java.exe

echo ╔══════════════════════════════════════════╗
echo ║   企业资产图表分析 — 配置 Java 运行时    ║
echo ╚══════════════════════════════════════════╝
echo.

if exist "%JAVA_EXE%" (
    echo [已配置] Java 运行时
    echo 路径: %RUNTIME_DIR%
    echo.
    "%JAVA_EXE%" -version 2>&1 | findstr "version"
    echo.
    echo 如需重置，请删除 runtime 文件夹后重新运行此脚本
    pause
    exit /b 0
)

echo [错误] 未找到 %JAVA_EXE%
echo.
echo 请将 Windows JDK 21 (Eclipse Temurin) 解压到 runtime 目录:
echo   runtime\bin\java.exe
echo.
echo 下载地址: https://adoptium.net/temurin/releases/?version=21
echo.
pause
