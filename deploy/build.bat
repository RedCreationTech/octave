@echo off
chcp 65001 >nul
setlocal

set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..

echo ╔══════════════════════════════════════════╗
echo ║   企业资产图表分析 — 构建可执行 JAR      ║
echo ╚══════════════════════════════════════════╝
echo.

cd /d "%PROJECT_DIR%"

echo [1/1] 构建 uber JAR (含全部依赖)...
clojure -M:uberdeps -m uberdeps.uberjar --main-class ocvate.core
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 构建失败，请检查 Clojure CLI 是否已安装
    pause
    exit /b 1
)

echo.
echo ✅ 构建完成: target\ocvate.jar
echo    运行: deploy\run-sqlite.bat 或 deploy\run.bat
pause
