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
:: 构建还需要 clojure CLI（因为要用 uberdeps）
where clojure >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 未找到 clojure 命令，请先安装 Clojure CLI
    pause
    exit /b 1
)

echo ╔══════════════════════════════════════════╗
echo ║   企业资产图表分析 — 构建可执行 JAR      ║
echo ╚══════════════════════════════════════════╝
echo.

cd /d "%PROJECT_DIR%"

echo [1/1] 构建 uber JAR (含全部依赖)...
clojure -M:uberdeps -m uberdeps.uberjar --main-class ocvate.core
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 构建失败
    pause
    exit /b 1
)

echo.
echo ✅ 构建完成: target\ocvate.jar
echo    大小: 
for %%I in ("target\ocvate.jar") do echo    %%~zI 字节
echo.
echo    启动: deploy\run-sqlite.bat
echo    启动: deploy\run.bat
echo.
pause
