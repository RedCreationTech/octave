#!/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "╔══════════════════════════════════════════╗"
echo "║   企业资产图表分析 — 构建可执行 JAR      ║"
echo "╚══════════════════════════════════════════╝"
echo
echo "[1/1] 构建 uber JAR..."
clojure -M:uberdeps -m uberdeps.uberjar --main-class ocvate.core
echo
echo "✅ 构建完成: target/ocvate.jar"
