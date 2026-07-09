# 企业资产图表分析 — Web 服务端

为「企业资产图表分析」单页应用提供 HTTP 服务，支持 **Oracle 12c**（生产）和 **SQLite**（测试）两种数据库后端。

## 项目结构

```
ocvate/
├── deps.edn                        # Clojure 依赖管理
├── config.edn                      # Oracle 配置（默认）
├── config-sqlite.edn               # SQLite 测试配置
├── src/
│   └── ocvate/
│       ├── core.clj                # 入口点
│       ├── config.clj              # 配置加载
│       ├── db.clj                  # 数据库连接池 + 查询函数
│       └── server.clj              # Web 路由与处理器
├── resources/
│   └── public/
│       └── index.html              # 前端单页应用
└── data/
    └── test.db                     # SQLite 数据库文件（自动创建）
```

## 快速开始（SQLite 测试）

无需 Oracle 数据库，一键启动：

```bash
clojure -J-Dconf=config-sqlite.edn -M -m ocvate.core
```

服务器将：
- 自动创建 `data/test.db`
- 建立 10 张匹配前端 Excel 数据结构的表
- 插入中文示例数据（煤矿企业场景）
- 在 `http://127.0.0.1:8080` 启动

### 验证

```bash
curl http://127.0.0.1:8080/api/health
curl http://127.0.0.1:8080/api/assets/by-type
curl http://127.0.0.1:8080/api/assets/by-dept
```

## 生产环境（Oracle 12c）

编辑 `config.edn`，填入数据库连接信息：

```clojure
{:db {:dbtype "oracle"
      :dbname "XE"
      :host  "127.0.0.1"
      :port  1521
      :user  "scott"
      :password "tiger"}
 :server {:port 8080}}
```

运行：

```bash
clojure -M -m ocvate.core
```

## API 端点

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/health` | 健康检查 |
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

所有 API 返回 `{"ok": true, "data": [...]}` 格式。

## SQLite 测试数据

数据匹配前端 Excel 导入结构的 10 张表：

| 表名 | 对应 Excel Sheet | 说明 |
|------|-----------------|------|
| `dept_rank` | 资产部门排行 | 8 个部门 |
| `asset_type` | 资产类型 | 5 个分类 |
| `depreciation` | 折旧到期 | 7 条折旧记录 |
| `annual_dynamics` | 年度资产动态 | 6 年数据 |
| `outbound_summary` | 出库汇总 | 5 条汇总 |
| `outbound_details` | 出库明细 | 6 条明细 |
| `repairs` | 维修明细 | 10 条维修记录 |
| `monthly_fuel` | 月度油耗 | 18 个月数据 |
| `department_fuel` | 部门油耗 | 5 个部门 |
| `vehicle_fuel` | 单车油耗 | 7 辆车 |

## 注意事项

- 需要 Java 17+ 和 Clojure CLI 1.12+
- Oracle JDBC 驱动通过 deps.edn 从 Maven 自动下载
- 当前前端为独立 HTML，数据通过 XLSX 文件导入；API 端点为后续前端改造预留
