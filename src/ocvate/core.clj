(ns ocvate.core
  "企业资产图表分析 — 入口点。"
  (:require [ocvate.config :as cfg]
            [ocvate.db :as db]
            [ocvate.server :as server])
  (:import [org.eclipse.jetty.server Server])
  (:gen-class))

(defn -main
  "应用程序入口。"
  [& args]
  (println "╔══════════════════════════════════════════╗")
  (println "║     企业资产图表分析 — 服务端启动        ║")
  (println "╚══════════════════════════════════════════╝")
  (println)

  (let [db-cfg  (cfg/db-config)
        srv-cfg (cfg/server-config)
        dtype   (keyword (:dbtype db-cfg "oracle"))]
    (println "📋 服务器配置:")
    (println "  端口:" (:port srv-cfg 8080))
    (println)
    (println "📋 数据库配置:")
    (println "  类型:" (name dtype))
    (case dtype
      :sqlite (println "  文件:" (:dbname db-cfg))
      (do (println "  URL: jdbc:oracle:thin:@" (:host db-cfg) ":" (:port db-cfg) "/" (:dbname db-cfg))
          (println "  用户名:" (:user db-cfg))))
    (println))

  ;; 初始化连接池 + SQLite 建表
  (println "⏳ 初始化数据库...")
  (db/datasource)     ;; 建立连接池
  (db/init-sqlite!)   ;; SQLite 建表 + 测试数据
  (println "✅ 数据库就绪")
  (println)

  ;; 启动服务器
  (let [server (server/start)]
    (.addShutdownHook (Runtime/getRuntime)
      (Thread. (fn []
                 (println "\n⏳ 正在关闭...")
                 (server/stop server)
                 (db/stop!)
                 (println "✅ 已安全关闭"))))
    (.join server)))
