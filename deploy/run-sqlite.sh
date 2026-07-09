#!/bin/bash
cd "$(dirname "$0")/.."
mkdir -p data
exec java -Dconf=config-sqlite.edn -cp target/ocvate.jar clojure.main -m ocvate.core
