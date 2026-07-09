# 企业资产图表分析 — Web 服务端

为「企业资产图表分析」单页应用提供 HTTP 服务，支持 **Oracle 12c**（生产）和 **SQLite**（测试）两种数据库。

---

## 项目结构

```
ocvate/
├── start.bat                ← Windows 一键启动
├── start.sh                 ← macOS/Linux 一键启动
├── config.edn               ← Oracle 生产配置
├── config-sqlite.edn        ← SQLite 测试配置
├── target/
│   └── ocvate.jar           ← uber JAR（含全部依赖）
├── sql/
│   ├── oracle-views.sql     ← Oracle 10 个视图定义（DBA 执行）
│   └── oracle-test-tables.sql ← 测试环境建表（可选）
├── runtime/                 ← JDK 运行时（手动放置）
├── deploy/                  ← 构建/部署脚本
│   ├── build.bat / .sh      ← 构建 uber JAR
│   ├── setup-java.bat       ← 配置 Java 运行时
│   └── run.bat / run-sqlite.bat
├── src/ocvate/              ← Clojure 源码
│   ├── core.clj             ← 入口点
│   ├── config.clj           ← 配置加载
│   ├── db.clj               ← 连接池 + 查询
│   └── server.clj           ← Web 路由
├── resources/public/
│   └── index.html           ← 前端单页应用
└── data/
    └── test.db              ← SQLite 数据库（自动创建）
```

---

## Windows 完整部署手册（Oracle 生产环境）

### 第一步：获取 Java 运行时

本应用需要 Java 21。有两种方式获取：

**方式 A：自动下载（推荐）**

双击 `start.bat oracle`，脚本会自动从 Adoptium 下载 JDK 21 到 `runtime\` 目录。

**方式 B：手动下载**

1. 打开 https://adoptium.net/temurin/releases/?version=21
2. 选择操作系统 **Windows x64**，类型 **JDK**，下载 `.zip` 文件
3. 解压，将 `jdk-21.0.11+10` 文件夹重命名为 `runtime`
4. 放入项目根目录，确保路径为 `runtime\bin\java.exe`

验证：
```cmd
runtime\bin\java -version
```
输出应显示 `openjdk version "21.0.11"`。

---

### 第二步：构建 uber JAR

在**开发机**（装有 Clojure CLI）上执行：

```cmd
deploy\build.bat
```

或手动执行：

```cmd
clojure -M:uberdeps -m uberdeps.uberjar --main-class ocvate.core
```

产出 `target\ocvate.jar`（约 29MB），包含全部依赖：
- Clojure 运行时
- Ring + Jetty Web 服务器
- Compojure 路由
- HikariCP 连接池
- Oracle JDBC 驱动（ojdbc11）
- SQLite JDBC 驱动
- Cheshire JSON 库

> **注意**：`target\ocvate.jar` 只需构建一次，之后可以复制到客户机。

---

### 第三步：DBA 创建 Oracle 视图（仅首次）

将 `sql\oracle-views.sql` 交给 DBA，在 Oracle 上执行：

```sql
sqlplus 用户名/密码@数据库SID @sql\oracle-views.sql
```

该脚本会创建 10 个视图，将现有业务表映射为应用所需的数据结构。

DBA 需要根据实际情况修改每个视图的 `FROM` 子句，将 `your_xxx_table` 替换为实际的业务表名。

**10 个视图列表：**

| 视图名 | 前端字段 | 说明 |
|--------|----------|------|
| `dept_rank` | `departments` | 部门资产统计 |
| `asset_type` | `assetTypes` | 资产类型统计 |
| `depreciation` | `depreciation` | 折旧到期统计 |
| `annual_dynamics` | `annualDynamics` | 年度资产动态 |
| `outbound_summary` | `outboundSummary` | 出库汇总 |
| `outbound_details` | `outboundDetails` | 出库明细 |
| `repairs` | `repairs` | 维修明细 |
| `monthly_fuel` | `monthlyFuel` | 月度油耗 |
| `department_fuel` | `departmentFuel` | 部门油耗 |
| `vehicle_fuel` | `vehicleFuel` | 单车油耗 |

每个视图的字段名和类型详见 `sql\oracle-views.sql`。

---

### 第四步：配置数据库连接

编辑 `config.edn`，填入实际的 Oracle 连接信息：

```clojure
{:db
 {:dbtype "oracle"               ;; 固定为 oracle
  :dbname "XE"                   ;; Oracle SID 或 Service Name
  :host  "192.168.1.100"         ;; 数据库服务器 IP 或主机名
  :port  1521                    ;; Oracle 监听端口
  :user  "asset_user"            ;; 数据库用户名
  :password "password123"        ;; 密码
  :pool-size 10                  ;; 连接池大小（可选，默认 10）
  :connection-timeout-ms 30000   ;; 连接超时毫秒（可选）
  :idle-timeout-ms 600000        ;; 空闲超时毫秒（可选）
  :max-lifetime-ms 1800000}      ;; 连接最大存活毫秒（可选）

 :server
 {:port 8080}}                   ;; Web 端口（可选，默认 8080）
```

> ⚠️ 应用启动时**不会**自动创建表或视图。所有 10 个视图必须由 DBA 提前创建好。

---

### 第五步：启动服务

```cmd
start.bat oracle
```

启动日志示例：

```
╔══════════════════════════════════════════╗
║   企业资产图表分析 — Oracle 模式启动     ║
╚══════════════════════════════════════════╝

[1/3] JAR 已就绪
[2/3] Java 运行时已就绪
openjdk version "21.0.11" 2026-04-21 LTS
[3/3] 启动服务...
   模式: Oracle
   配置: config.edn
   地址: http://127.0.0.1:8080
   停止: 关闭此窗口或 Ctrl+C

🔌 oracle — 192.168.1.100:1521/XE
🌐 服务器启动: http://127.0.0.1:8080
```

---

### 第六步：验证

启动后访问：

| 地址 | 说明 |
|------|------|
| http://127.0.0.1:8080 | 前端页面 |
| http://127.0.0.1:8080/api/health | 健康检查（含数据库连通性） |
| http://127.0.0.1:8080/api/assets/by-type | 资产类型统计 |
| http://127.0.0.1:8080/api/all | 全部数据（前端自动调用） |

---

## SQLite 测试模式（无需 Oracle）

如果只是想预览前端效果，不需要连接 Oracle：

```cmd
start.bat
```

自动完成：
1. 检测 JAR → 不存在则构建
2. 检测 JDK → 不存在则下载
3. 创建 SQLite 数据库 + 插入测试数据（机场资产管理场景，10 张表 150+ 条记录）
4. 启动服务

---

## API 清单

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/health` | 健康检查 |
| GET | `/api/all` | 获取全部 10 个数据集（前端唯一调用） |
| GET | `/api/assets/by-type` | 资产类型统计 |
| GET | `/api/assets/by-dept` | 部门排名 |
| GET | `/api/depreciation` | 折旧到期统计 |
| GET | `/api/annual-dynamics` | 年度资产动态 |
| GET | `/api/outbound/summary` | 出库汇总 |
| GET | `/api/outbound/details` | 出库明细 |
| GET | `/api/repairs` | 维修明细 |
| GET | `/api/fuel/monthly` | 月度油耗 |
| GET | `/api/fuel/department` | 部门油耗 |
| GET | `/api/fuel/vehicle` | 单车油耗 |

所有 API 返回 `{"ok": true, "data": [...]}` 格式，key 为 camelCase。

---

## 常见问题

**Q: 启动时提示找不到 config.edn？**  
A: 确保 `config.edn` 在项目根目录，并填入了正确的数据库连接信息。

**Q: Oracle 连接失败？**  
A: 检查网络连通性、用户名密码、Oracle 监听状态。验证 SQL\*Plus 能正常连接。

**Q: 前端页面打开后图表都是空的？**  
A: 前端加载时会调用 `/api/all`。检查浏览器 DevTools → Network 标签，确认请求是否有返回数据。

**Q: 404 Page not found？**  
A: `index.html` 未正确打包。重新构建 JAR：`deploy\build.bat`。

**Q: runtime/lib/modules 太大能否剔除？**  
A: 可以用 `jlink` 裁剪不需要的模块，但非必须。完整的 JDK 约 330MB，已包含所有 Java 标准库。
