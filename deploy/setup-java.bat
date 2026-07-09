@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..
set RUNTIME_DIR=%PROJECT_DIR%\runtime
set JAVA_EXE=%RUNTIME_DIR%\bin\java.exe

echo ╔══════════════════════════════════════════╗
echo ║   企业资产图表分析 — 配置 Java 运行时    ║
echo ╚══════════════════════════════════════════╝
echo.

if exist "%JAVA_EXE%" (
    echo [已配置] Java 运行时已存在于: %RUNTIME_DIR%
    "%JAVA_EXE%" -version 2>&1 | findstr "version"
    echo.
    echo 如需重新配置，请先删除 runtime 文件夹
    pause
    exit /b 0
)

echo [信息] 正在下载 Java 21 (Eclipse Temurin)...
echo [信息] 下载源: https://api.adoptium.net
echo.

set DOWNLOAD_URL=https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse?project=jdk
set TEMP_FILE=%TEMP%\jdk21.zip

echo [1/3] 正在下载 (约 190MB，请耐心等待)...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_FILE%' -UseBasicParsing }"
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 下载失败，请检查网络连接
    echo [提示] 您也可以手动下载并解压到 runtime 文件夹:
    echo        https://adoptium.net/temurin/releases/?version=21
    pause
    exit /b 1
)

echo [2/3] 正在解压...
if not exist "%PROJECT_DIR%\runtime_tmp" mkdir "%PROJECT_DIR%\runtime_tmp"
powershell -Command "Expand-Archive -Path '%TEMP_FILE%' -DestinationPath '%PROJECT_DIR%\runtime_tmp' -Force"
if %ERRORLEVEL% NEQ 0 (
    echo [错误] 解压失败
    pause
    exit /b 1
)

echo [3/3] 正在配置...
:: 查找解压后的目录 (jdk-21.x.x)
for /d %%i in ("%PROJECT_DIR%\runtime_tmp\jdk*") do (
    if exist "%%i\bin\java.exe" (
        move "%%i" "%RUNTIME_DIR%" >nul 2>&1
    )
)

if not exist "%JAVA_EXE%" (
    echo [错误] 配置失败，未找到 java.exe
    pause
    exit /b 1
)

rd /s /q "%PROJECT_DIR%\runtime_tmp" 2>nul
del "%TEMP_FILE%" 2>nul

echo.
echo ✅ Java 运行时配置完成
"%JAVA_EXE%" -version 2>&1 | findstr "version"
echo.
echo 路径: %RUNTIME_DIR%
echo.
pause
