#!/bin/bash
cd "$(dirname "$0")/.."
mkdir -p data

# 优先使用 bundled runtime
JAVA_CMD="java"
if [ -f "./runtime/bin/java" ]; then
    JAVA_CMD="./runtime/bin/java"
fi

exec $JAVA_CMD -Dconf=config-sqlite.edn -cp target/ocvate.jar clojure.main -m ocvate.core
