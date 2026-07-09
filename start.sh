#!/bin/bash
cd "$(dirname "$0")"

CONFIG="config-sqlite.edn"
MODE="SQLite"
[ "$1" = "oracle" ] && CONFIG="config.edn" && MODE="Oracle"

echo "╔══════════════════════════════════════════╗"
echo "║   企业资产图表分析 — ${MODE} 模式启动     ║"
echo "╚══════════════════════════════════════════╝"
echo

if [ ! -f "$CONFIG" ]; then
    echo "[错误] 未找到 $CONFIG"
    [ "$MODE" = "Oracle" ] && echo "请配置 config.edn 中的数据库连接"
    exit 1
fi

JAVA_CMD=$(which java 2>/dev/null)
if [ -z "$JAVA_CMD" ]; then
    echo "[错误] 未找到 Java，请安装 JDK 17+"
    exit 1
fi

if [ ! -f "target/ocvate.jar" ]; then
    echo "[错误] 未找到 target/ocvate.jar"
    echo "请运行: clojure -M:uberdeps -m uberdeps.uberjar --main-class ocvate.core"
    exit 1
fi

mkdir -p data
echo "启动 ${MODE} 模式..."
echo "地址: http://127.0.0.1:8080"
echo "停止: Ctrl+C"
echo

exec "$JAVA_CMD" "-Dconf=$CONFIG" -cp target/ocvate.jar clojure.main -m ocvate.core
