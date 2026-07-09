@echo off
chcp 65001 >nul
setlocal

set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..

cd /d "%PROJECT_DIR%"

echo ╔══════════════════════════════════════════╗
echo ║   企业资产图表分析 — SQLite 测试模式     ║
echo ╚══════════════════════════════════════════╝
echo.

if not exist "target\ocvate.jar" (
    echo [错误] 未找到 target\ocvate.jar，请先运行 deploy\build.bat
    pause
    exit /b 1
)

if not exist "data" mkdir data

echo [启动] SQLite 模式 (自动建表+测试数据)
echo [地址] http://127.0.0.1:8080
echo [停止] 按 Ctrl+C
echo.

java -Dconf=config-sqlite.edn -cp target\ocvate.jar clojure.main -m ocvate.core
