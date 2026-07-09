(ns ocvate.server
  "Web 服务器 — 路由与处理器。"
  (:require [ocvate.config :as cfg]
            [ocvate.db :as db]
            [compojure.core :refer [defroutes GET context]]
            [compojure.route :as route]
            [ring.middleware.defaults :refer [wrap-defaults site-defaults]]
            [ring.middleware.not-modified :refer [wrap-not-modified]]
            [ring.util.response :as resp]
            [cheshire.core :as json]
            [ring.adapter.jetty :as jetty]))

;; ──────────────────────────────────────────────────────────────────────
;; API 处理器
;; ──────────────────────────────────────────────────────────────────────

(defn- json-response
  "返回 JSON 响应。"
  [data]
  (-> (resp/response (json/generate-string data))
      (resp/header "Content-Type" "application/json; charset=utf-8")
      (resp/header "Access-Control-Allow-Origin" "*")))

(defn- ok [data]
  (json-response {:ok true :data data}))

(defn- err [msg]
  (json-response {:ok false :error msg}))

;; ─── 健康检查 ───

(defn api-health [_]
  (try
    (db/query "SELECT 1 AS ok")
    (json-response {:ok true :database "connected" :status "healthy"})
    (catch Exception e
      (json-response {:ok false :database "disconnected" :error (.getMessage e)}))))

;; ─── 资产相关 ───

(defn api-assets-by-type [_]
  (try (ok (db/get-assets-by-type))
       (catch Exception e (err (.getMessage e)))))

(defn api-assets-by-dept [_]
  (try (ok (db/get-assets-by-dept))
       (catch Exception e (err (.getMessage e)))))

(defn api-depreciation [_]
  (try (ok (db/get-depreciation-summary))
       (catch Exception e (err (.getMessage e)))))

(defn api-annual-dynamics [_]
  (try (ok (db/get-annual-dynamics))
       (catch Exception e (err (.getMessage e)))))

;; ─── 出库 ───

(defn api-outbound-summary [_]
  (try (ok (db/get-outbound-summary))
       (catch Exception e (err (.getMessage e)))))

(defn api-outbound-details [_]
  (try (ok (db/get-outbound-details))
       (catch Exception e (err (.getMessage e)))))

;; ─── 维修 ───

(defn api-repairs [_]
  (try (ok (db/get-repairs))
       (catch Exception e (err (.getMessage e)))))

;; ─── 油耗 ───

(defn api-monthly-fuel [_]
  (try (ok (db/get-monthly-fuel))
       (catch Exception e (err (.getMessage e)))))

(defn api-department-fuel [_]
  (try (ok (db/get-department-fuel))
       (catch Exception e (err (.getMessage e)))))

(defn api-vehicle-fuel [_]
  (try (ok (db/get-vehicle-fuel))
       (catch Exception e (err (.getMessage e)))))

;; ─── 出库明细（支持按仓库字段过滤）───

(defn api-outbound-details-filtered [req]
  (try
    (let [wh    (get-in req [:params :warehouse])
          dept  (get-in req [:params :department])
          data  (db/get-outbound-details)
          data  (if wh  (filter #(= (:warehouse_code %) wh)  data) data)
          data  (if dept (filter #(= (:department %) dept) data) data)]
      (ok data))
    (catch Exception e (err (.getMessage e)))))

;; ──────────────────────────────────────────────────────────────────────
;; 静态文件服务
;; ──────────────────────────────────────────────────────────────────────

(defn serve-index
  "提供 index.html。"
  [_]
  (let [idx (clojure.java.io/resource "public/index.html")]
    (if idx
      (-> (resp/resource-response "public/index.html")
          (resp/content-type "text/html; charset=utf-8"))
      (resp/not-found "<h1>404 — index.html 未找到</h1>"))))

;; ──────────────────────────────────────────────────────────────────────
;; 路由定义
;; ──────────────────────────────────────────────────────────────────────

(defroutes app-routes
  ;; API
  (GET "/api/health"                    [] api-health)
  (GET "/api/assets/by-type"            [] api-assets-by-type)
  (GET "/api/assets/by-dept"            [] api-assets-by-dept)
  (GET "/api/depreciation"              [] api-depreciation)
  (GET "/api/annual-dynamics"           [] api-annual-dynamics)
  (GET "/api/outbound/summary"          [] api-outbound-summary)
  (GET "/api/outbound/details"          [] api-outbound-details)
  (GET "/api/outbound/details/search"   [warehouse department] api-outbound-details-filtered)
  (GET "/api/repairs"                   [] api-repairs)
  (GET "/api/fuel/monthly"              [] api-monthly-fuel)
  (GET "/api/fuel/department"           [] api-department-fuel)
  (GET "/api/fuel/vehicle"              [] api-vehicle-fuel)

  ;; 静态资源
  (route/resources "/" {:root "public"})

  ;; SPA 兜底
  (GET "/*" [] serve-index))

;; ──────────────────────────────────────────────────────────────────────
;; 中间件
;; ──────────────────────────────────────────────────────────────────────

(def app
  (-> app-routes
      (wrap-defaults (assoc-in site-defaults [:security :anti-forgery] false))
      wrap-not-modified))

;; ──────────────────────────────────────────────────────────────────────
;; 启动 / 停止
;; ──────────────────────────────────────────────────────────────────────

(defn start []
  (let [port (get (cfg/server-config) :port 8080)
        server (jetty/run-jetty app {:port port :join? false})]
    (println (str "🌐 服务器启动: http://127.0.0.1:" port))
    (println (str "📄 健康检查: http://127.0.0.1:" port "/api/health"))
    server))

(defn stop [server]
  (when server
    (.stop ^org.eclipse.jetty.server.Server server)
    (println "🌐 服务器已停止")))
