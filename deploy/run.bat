@echo off
chcp 65001 >nul
setlocal

set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..
set RUNTIME_DIR=%PROJECT_DIR%\runtime

:: 优先使用 bundled runtime
if exist "%RUNTIME_DIR%\bin\java.exe" (
    set JAVA_CMD=%RUNTIME_DIR%\bin\java.exe
) else (
    where java >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [错误] 未找到 Java，请先运行 deploy\setup-java.bat
        pause
        exit /b 1
    )
    set JAVA_CMD=java
)

echo ╔══════════════════════════════════════════╗
echo ║   企业资产图表分析 — Oracle 生产模式     ║
echo ╚══════════════════════════════════════════╝
echo.

cd /d "%PROJECT_DIR%"

if not exist "target\ocvate.jar" (
    echo [错误] 未找到 target\ocvate.jar，请先运行 deploy\build.bat
    pause
    exit /b 1
)

if not exist "config.edn" (
    echo [错误] 未找到 config.edn
    echo 请从 config-sqlite.edn 复制并修改数据库连接
    pause
    exit /b 1
)

echo [启动] Oracle 模式
echo Java: "%JAVA_CMD%"
echo 配置: config.edn
echo 地址: http://127.0.0.1:8080
echo 停止: 按 Ctrl+C
echo.

"%JAVA_CMD%" -Dconf=config.edn -cp "target\ocvate.jar" clojure.main -m ocvate.core
pause
