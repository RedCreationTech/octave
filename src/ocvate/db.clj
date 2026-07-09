(ns ocvate.db
  "数据库连接池管理与查询函数。
   支持 Oracle 和 SQLite 两种数据库后端。"
  (:require [ocvate.config :as cfg]
            [clojure.java.jdbc :as jdbc]
            [clojure.string :as str])
  (:import [com.zaxxer.hikari HikariConfig HikariDataSource]))

;; ──────────────────────────────────────────────────────────────────────
;; 驱动与 URL 构建
;; ──────────────────────────────────────────────────────────────────────

(defn- db-type [] (keyword (or (:dbtype (cfg/db-config)) "oracle")))

(defn- oracle-url [db-cfg]
  (str "jdbc:oracle:thin:@" (:host db-cfg) ":" (:port db-cfg) "/" (:dbname db-cfg)))

(defn- sqlite-url [db-cfg]
  (str "jdbc:sqlite:" (:dbname db-cfg)))

(defn- make-oracle-datasource [db-cfg]
  (let [hc (HikariConfig.)]
    (.setJdbcUrl         hc (oracle-url db-cfg))
    (.setUsername        hc (:user db-cfg))
    (.setPassword        hc (:password db-cfg))
    (.setDriverClassName hc "oracle.jdbc.OracleDriver")
    (.setMaximumPoolSize    hc (or (:pool-size db-cfg) 10))
    (.setConnectionTimeout  hc (or (:connection-timeout-ms db-cfg) 30000))
    (.setIdleTimeout        hc (or (:idle-timeout-ms db-cfg) 600000))
    (.setMaxLifetime        hc (or (:max-lifetime-ms db-cfg) 1800000))
    (.setAutoCommit         hc false)
    (HikariDataSource. hc)))

(defn- make-sqlite-datasource [db-cfg]
  (let [hc (HikariConfig.)]
    (.setJdbcUrl         hc (sqlite-url db-cfg))
    (.setDriverClassName hc "org.sqlite.JDBC")
    (.setMaximumPoolSize hc 1)
    (.setAutoCommit      hc true)
    (HikariDataSource. hc)))

(defn make-datasource [db-cfg]
  (case (keyword (:dbtype db-cfg))
    :sqlite (make-sqlite-datasource db-cfg)
    (make-oracle-datasource db-cfg)))

(defonce ^:dynamic *datasource*
  (delay
    (let [db-cfg (cfg/db-config)
          kind   (keyword (:dbtype db-cfg "oracle"))]
      (println (str "🔌 连接数据库: " (name kind) " — "
                    (case kind :sqlite (:dbname db-cfg)
                          (str (:host db-cfg) ":" (:port db-cfg) "/" (:dbname db-cfg)))))
      (make-datasource db-cfg))))

(defn datasource [] @*datasource*)

;; ──────────────────────────────────────────────────────────────────────
;; 查询工具
;; ──────────────────────────────────────────────────────────────────────

(defn- with-conn*
  "打开连接, 以 {:connection conn} 调用 f"
  [f]
  (with-open [conn (.getConnection ^HikariDataSource (datasource))]
    (f {:connection conn})))

(defn query
  "执行查询，返回结果序列。"
  [sql & params]
  (with-conn*
    (fn [db]
      (apply jdbc/query db (if (sequential? (first params))
                             (concat [sql] params)
                             (conj params sql))))))

(defn execute!
  "执行 DDL/DML。"
  [sql & params]
  (with-conn*
    (fn [db]
      (apply jdbc/execute! db (if (sequential? (first params))
                                (concat [sql] params)
                                (conj params sql))))))

;; ──────────────────────────────────────────────────────────────────────
;; 具名查询函数
;; ──────────────────────────────────────────────────────────────────────

(defn get-assets-by-type
  ([] (get-assets-by-type {}))
  ([_] (query "SELECT category, asset_count, count_ratio, value, value_ratio
               FROM asset_type ORDER BY asset_count DESC")))

(defn get-assets-by-dept
  ([] (get-assets-by-dept {}))
  ([_] (query "SELECT department, asset_count, ratio, idle_asset_count,
                      fixed_asset_count, fixed_asset_original_value
               FROM dept_rank ORDER BY asset_count DESC")))

(defn get-depreciation-summary
  ([] (get-depreciation-summary {}))
  ([_] (query "SELECT category, year, depreciation_count, original_value
               FROM depreciation ORDER BY year")))

(defn get-annual-dynamics
  ([] (get-annual-dynamics {}))
  ([_] (query "SELECT year, added_count, added_value, pending_count, pending_value
               FROM annual_dynamics ORDER BY year")))

(defn get-outbound-summary
  ([] (get-outbound-summary {}))
  ([_] (query "SELECT year, warehouse_code, warehouse_name, department_code, department,
                      amount, quantity, yoy, mom
               FROM outbound_summary ORDER BY year, warehouse_code")))

(defn get-outbound-details
  ([] (get-outbound-details {}))
  ([_] (query "SELECT warehouse_code, warehouse_name, department_code, department,
                      ticket_no, spare_code, spare_name, quantity, unit,
                      class01, class02, class03, unit_price, total_price, time
               FROM outbound_details ORDER BY time DESC")))

(defn get-repairs
  ([] (get-repairs {}))
  ([_] (query "SELECT year, month, department_code, department,
                      asset_code, equipment_name, plate_no, total_cost
               FROM repairs ORDER BY year, month")))

(defn get-monthly-fuel
  ([] (get-monthly-fuel {}))
  ([_] (query "SELECT year, month, fuel_volume FROM monthly_fuel ORDER BY year, month")))

(defn get-department-fuel
  ([] (get-department-fuel {}))
  ([_] (query "SELECT year, month, department, fuel_type, fuel_volume, total_ratio,
                      energy_type, energy_method, energy, mom, yoy
               FROM department_fuel ORDER BY year, month")))

(defn get-vehicle-fuel
  ([] (get-vehicle-fuel {}))
  ([_] (query "SELECT year, month, asset_code, equipment_name, plate_no, fuel_volume
               FROM vehicle_fuel ORDER BY year, month")))

;; ──────────────────────────────────────────────────────────────────────
;; SQLite 初始化（每条语句独立执行以避免 jdbc 不支持多语句）
;; ──────────────────────────────────────────────────────────────────────

(def sqlite-init-ddl
  ["CREATE TABLE IF NOT EXISTS dept_rank (department TEXT, asset_count INTEGER, ratio REAL, idle_asset_count INTEGER, fixed_asset_count INTEGER, fixed_asset_original_value REAL)"
   "CREATE TABLE IF NOT EXISTS asset_type (category TEXT, asset_count INTEGER, count_ratio REAL, value REAL, value_ratio REAL)"
   "CREATE TABLE IF NOT EXISTS depreciation (category TEXT, year INTEGER, depreciation_count INTEGER, original_value REAL)"
   "CREATE TABLE IF NOT EXISTS annual_dynamics (year INTEGER, added_count INTEGER, added_value REAL, pending_count INTEGER, pending_value REAL)"
   "CREATE TABLE IF NOT EXISTS outbound_summary (year INTEGER, warehouse_code TEXT, warehouse_name TEXT, department_code TEXT, department TEXT, amount REAL, quantity INTEGER, yoy REAL, mom REAL)"
   "CREATE TABLE IF NOT EXISTS outbound_details (warehouse_code TEXT, warehouse_name TEXT, department_code TEXT, department TEXT, ticket_no TEXT, spare_code TEXT, spare_name TEXT, quantity INTEGER, unit TEXT, class01 TEXT, class02 TEXT, class03 TEXT, unit_price REAL, total_price REAL, time TEXT)"
   "CREATE TABLE IF NOT EXISTS repairs (year INTEGER, month INTEGER, department_code TEXT, department TEXT, asset_code TEXT, equipment_name TEXT, plate_no TEXT, total_cost REAL)"
   "CREATE TABLE IF NOT EXISTS monthly_fuel (year INTEGER, month INTEGER, fuel_volume REAL)"
   "CREATE TABLE IF NOT EXISTS department_fuel (year INTEGER, month INTEGER, department TEXT, fuel_type TEXT, fuel_volume REAL, total_ratio REAL, energy_type TEXT, energy_method TEXT, energy REAL, mom REAL, yoy REAL)"
   "CREATE TABLE IF NOT EXISTS vehicle_fuel (year INTEGER, month INTEGER, asset_code TEXT, equipment_name TEXT, plate_no TEXT, fuel_volume REAL)"])

(def sqlite-init-data
  ["DELETE FROM dept_rank"
   "INSERT INTO dept_rank VALUES ('采掘一队',120,0.231,3,85,4250),('采掘二队',98,0.188,2,72,3600),('运输队',76,0.146,5,58,2800),('机电队',65,0.125,1,52,2600),('通风队',52,0.100,0,42,1900),('机修厂',48,0.092,4,38,1650),('供应科',35,0.067,2,28,1200),('技术部',25,0.048,0,20,980)"
   "DELETE FROM asset_type"
   "INSERT INTO asset_type VALUES ('采掘设备',186,0.358,9300,0.421),('运输设备',142,0.273,6200,0.281),('通风设备',68,0.131,2400,0.109),('机电设备',85,0.163,3200,0.145),('其他设备',39,0.075,980,0.044)"
   "DELETE FROM depreciation"
   "INSERT INTO depreciation VALUES ('采掘设备',5,12,3600),('采掘设备',8,8,2800),('采掘设备',10,5,1800),('运输设备',6,15,3200),('运输设备',8,10,2500),('通风设备',5,8,1200),('机电设备',8,6,1800)"
   "DELETE FROM annual_dynamics"
   "INSERT INTO annual_dynamics VALUES (2020,18,1200,5,320),(2021,22,1500,4,280),(2022,25,1800,6,350),(2023,30,2200,8,480),(2024,28,2600,7,420),(2025,32,2800,10,560)"
   "DELETE FROM outbound_summary"
   "INSERT INTO outbound_summary VALUES (2024,'01','中心库','A01','采掘一队',850000,320,0.15,0.08),(2024,'01','中心库','A02','采掘二队',720000,280,0.12,0.05),(2024,'01','中心库','B01','运输队',560000,210,0.18,0.10),(2024,'02','分库一','C01','机电队',380000,150,0.08,0.03),(2025,'01','中心库','A01','采掘一队',920000,350,0.08,-0.02)"
   "DELETE FROM outbound_details"
   "INSERT INTO outbound_details VALUES ('01','中心库','A01','采掘一队','TK-001','HY-001','液压千斤顶',5,'台','液压件','千斤顶','单体',12000,60000,'2024-06-01'),('01','中心库','A01','采掘一队','TK-002','DQ-001','矿用电缆',200,'米','电气件','电缆','动力',85,17000,'2024-06-05'),('01','中心库','A02','采掘二队','TK-003','JX-001','截齿',30,'个','机械件','刀具','截齿',350,10500,'2024-06-08'),('01','中心库','B01','运输队','TK-004','LT-001','轮胎',8,'条','轮胎','工程胎','巨胎',8500,68000,'2024-06-10'),('02','分库一','C01','机电队','TK-005','RH-001','润滑油',20,'桶','油脂','润滑油','机油',1200,24000,'2024-06-12'),('01','中心库','A01','采掘一队','TK-006','HY-002','液压阀组',2,'套','液压件','阀组','多路阀',25000,50000,'2024-06-15')"
   "DELETE FROM repairs"
   "INSERT INTO repairs VALUES (2024,1,'A01','采掘一队','ZC-001','采煤机A','',85000),(2024,2,'A01','采掘一队','ZC-001','采煤机A','',42000),(2024,3,'A02','采掘二队','JJ-001','掘进机B','',68000),(2024,4,'B01','运输队','PS-001','主皮带机','',35000),(2024,5,'C01','机电队','TF-001','通风机','',18000),(2024,6,'A01','采掘一队','ZC-002','采煤机C','',95000),(2024,7,'A02','采掘二队','JJ-002','掘进机D','',52000),(2024,8,'B01','运输队','KC-001','矿卡-001','晋A·12345',12000),(2024,9,'B01','运输队','KC-002','矿卡-002','晋A·12346',8000),(2025,1,'A01','采掘一队','ZC-001','采煤机A','',76000)"
   "DELETE FROM monthly_fuel"
   "INSERT INTO monthly_fuel VALUES (2024,1,45000),(2024,2,42000),(2024,3,48000),(2024,4,46000),(2024,5,49000),(2024,6,51000),(2024,7,53000),(2024,8,52000),(2024,9,48000),(2024,10,47000),(2024,11,44000),(2024,12,43000),(2025,1,42000),(2025,2,40000),(2025,3,46000),(2025,4,45000),(2025,5,47000),(2025,6,49000)"
   "DELETE FROM department_fuel"
   "INSERT INTO department_fuel VALUES (2024,6,'运输队','柴油',28000,0.549,'柴油','热值',980000,0.05,0.12),(2024,6,'采掘一队','柴油',12000,0.235,'柴油','热值',420000,-0.02,0.08),(2024,6,'采掘二队','柴油',8000,0.157,'柴油','热值',280000,0.03,0.06),(2024,6,'机电队','电力',15000,0.294,'电力','折标',1800,0.01,0.05),(2024,6,'技术部','汽油',3000,0.059,'汽油','热值',105000,0.08,0.10)"
   "DELETE FROM vehicle_fuel"
   "INSERT INTO vehicle_fuel VALUES (2024,6,'KC-001','矿卡-001','晋A·12345',4500),(2024,6,'KC-002','矿卡-002','晋A·12346',4200),(2024,6,'KC-003','矿卡-003','晋A·12347',3800),(2024,6,'PK-001','皮卡-001','晋A·23456',1200),(2024,6,'PK-002','皮卡-002','晋A·23457',900),(2024,6,'DC-001','电车-001','晋A·34567',3500),(2024,6,'DC-002','电车-002','晋A·34568',2800)"])

(defn init-sqlite!
  "建表并插入测试数据。"
  []
  (when (= (db-type) :sqlite)
    (println "🗄️  初始化 SQLite 测试数据...")
    (with-conn*
      (fn [db]
        (doseq [sql (concat sqlite-init-ddl sqlite-init-data)]
          (try (jdbc/execute! db [sql])
               (catch Exception e
                 (when-not (str/includes? (.getMessage e) "already exists")
                   (println "  ⚠️" (.getMessage e))))))))
    (println "✅ SQLite 测试数据已就绪")))

;; ──────────────────────────────────────────────────────────────────────
;; 关闭
;; ──────────────────────────────────────────────────────────────────────

(defn stop!
  []
  (when (and (realized? *datasource*) @*datasource*)
    (println "🔌 关闭数据库连接池")
    (.close ^HikariDataSource @*datasource*)))
