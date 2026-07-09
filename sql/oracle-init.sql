-- =============================================================================
-- 企业资产图表分析 — Oracle 建表脚本
-- =============================================================================
-- 目标: Oracle 12c+
-- 用途: 为前端展示提供数据的 10 张视图表
-- 使用: sqlplus scott/tiger@XE @sql/oracle-init.sql
-- =============================================================================

-- ============================================================
-- 1. 部门资产统计（前端: departments）
-- ============================================================
CREATE TABLE dept_rank (
    department              VARCHAR2(200) NOT NULL,
    asset_count             NUMBER(10)   DEFAULT 0,
    ratio                   NUMBER(8,6)  DEFAULT 0,
    idle_asset_count        NUMBER(10)   DEFAULT 0,
    fixed_asset_count       NUMBER(10)   DEFAULT 0,
    fixed_asset_original_value NUMBER(15,2) DEFAULT 0
);
COMMENT ON TABLE  dept_rank IS '部门资产统计数据';
COMMENT ON COLUMN dept_rank.department IS '部门名称';
COMMENT ON COLUMN dept_rank.asset_count IS '资产数量';
COMMENT ON COLUMN dept_rank.ratio IS '数量占比（0~1）';
COMMENT ON COLUMN dept_rank.idle_asset_count IS '闲置资产数量';
COMMENT ON COLUMN dept_rank.fixed_asset_count IS '固定资产数量';
COMMENT ON COLUMN dept_rank.fixed_asset_original_value IS '固定资产原值（万元）';

-- ============================================================
-- 2. 资产类型统计（前端: assetTypes）
-- ============================================================
CREATE TABLE asset_type (
    category                VARCHAR2(100) NOT NULL,
    asset_count             NUMBER(10)   DEFAULT 0,
    count_ratio             NUMBER(8,6)  DEFAULT 0,
    value                   NUMBER(15,2) DEFAULT 0,
    value_ratio             NUMBER(8,6)  DEFAULT 0
);
COMMENT ON TABLE  asset_type IS '资产类型统计数据';
COMMENT ON COLUMN asset_type.category IS '资产盘点分类';
COMMENT ON COLUMN asset_type.asset_count IS '资产数量';
COMMENT ON COLUMN asset_type.count_ratio IS '数量占比（0~1）';
COMMENT ON COLUMN asset_type.value IS '价值（万元）';
COMMENT ON COLUMN asset_type.value_ratio IS '价值占比（0~1）';

-- ============================================================
-- 3. 折旧到期统计（前端: depreciation）
-- ============================================================
CREATE TABLE depreciation (
    category                VARCHAR2(100) NOT NULL,
    year                    NUMBER(4)    NOT NULL,
    depreciation_count      NUMBER(10)   DEFAULT 0,
    original_value          NUMBER(15,2) DEFAULT 0
);
COMMENT ON TABLE  depreciation IS '折旧到期年限统计数据';
COMMENT ON COLUMN depreciation.category IS '设备分类';
COMMENT ON COLUMN depreciation.year IS '折旧到期年限（年份）';
COMMENT ON COLUMN depreciation.depreciation_count IS '已达折旧期资产数量';
COMMENT ON COLUMN depreciation.original_value IS '原价值（万元）';

-- ============================================================
-- 4. 年度资产动态（前端: annualDynamics）
-- ============================================================
CREATE TABLE annual_dynamics (
    year                    NUMBER(4)    NOT NULL,
    added_count             NUMBER(10)   DEFAULT 0,
    added_value             NUMBER(15,2) DEFAULT 0,
    pending_count           NUMBER(10)   DEFAULT 0,
    pending_value           NUMBER(15,2) DEFAULT 0
);
COMMENT ON TABLE  annual_dynamics IS '年度资产动态数据';
COMMENT ON COLUMN annual_dynamics.year IS '统计年度';
COMMENT ON COLUMN annual_dynamics.added_count IS '新增数量';
COMMENT ON COLUMN annual_dynamics.added_value IS '新增价值（万元）';
COMMENT ON COLUMN annual_dynamics.pending_count IS '待处置数量';
COMMENT ON COLUMN annual_dynamics.pending_value IS '待处置价值（万元）';

-- ============================================================
-- 5. 出库汇总（前端: outboundSummary）
-- ============================================================
CREATE TABLE outbound_summary (
    year                    NUMBER(4)    NOT NULL,
    warehouse_code          VARCHAR2(20) NOT NULL,
    warehouse_name          VARCHAR2(100),
    department_code         VARCHAR2(20) NOT NULL,
    department              VARCHAR2(100),
    amount                  NUMBER(15,2) DEFAULT 0,
    quantity                NUMBER(10)   DEFAULT 0,
    yoy                     NUMBER(8,6)  DEFAULT 0,
    mom                     NUMBER(8,6)  DEFAULT 0
);
COMMENT ON TABLE  outbound_summary IS '出库汇总数据';
COMMENT ON COLUMN outbound_summary.year IS '统计年度';
COMMENT ON COLUMN outbound_summary.warehouse_code IS '仓库编码';
COMMENT ON COLUMN outbound_summary.warehouse_name IS '仓库描述';
COMMENT ON COLUMN outbound_summary.department_code IS '部门编码';
COMMENT ON COLUMN outbound_summary.department IS '部门描述';
COMMENT ON COLUMN outbound_summary.amount IS '出库金额（万元）';
COMMENT ON COLUMN outbound_summary.quantity IS '出库数量';
COMMENT ON COLUMN outbound_summary.yoy IS '同比（0~1）';
COMMENT ON COLUMN outbound_summary.mom IS '环比（0~1）';

-- ============================================================
-- 6. 出库明细（前端: outboundDetails）
-- ============================================================
CREATE TABLE outbound_details (
    warehouse_code          VARCHAR2(20),
    warehouse_name          VARCHAR2(100),
    department_code         VARCHAR2(20),
    department              VARCHAR2(100),
    ticket_no               VARCHAR2(50),
    spare_code              VARCHAR2(50),
    spare_name              VARCHAR2(200),
    quantity                NUMBER(10)   DEFAULT 0,
    unit                    VARCHAR2(20),
    class01                 VARCHAR2(50),
    class02                 VARCHAR2(50),
    class03                 VARCHAR2(50),
    unit_price              NUMBER(15,4) DEFAULT 0,
    total_price             NUMBER(15,4) DEFAULT 0,
    time                    VARCHAR2(20)
);
COMMENT ON TABLE  outbound_details IS '出库明细数据';
COMMENT ON COLUMN outbound_details.ticket_no IS '领料票号';
COMMENT ON COLUMN outbound_details.spare_code IS '备件编码';
COMMENT ON COLUMN outbound_details.spare_name IS '备件描述';
COMMENT ON COLUMN outbound_details.class01 IS '大类';
COMMENT ON COLUMN outbound_details.class02 IS '中类';
COMMENT ON COLUMN outbound_details.class03 IS '小类';

-- ============================================================
-- 7. 维修明细（前端: repairs）
-- ============================================================
CREATE TABLE repairs (
    year                    NUMBER(4)    NOT NULL,
    month                   NUMBER(2)    NOT NULL,
    department_code         VARCHAR2(20),
    department              VARCHAR2(100),
    asset_code              VARCHAR2(50),
    equipment_name          VARCHAR2(200),
    plate_no                VARCHAR2(50),
    total_cost              NUMBER(15,2) DEFAULT 0
);
COMMENT ON TABLE  repairs IS '维修维护明细数据';
COMMENT ON COLUMN repairs.department_code IS '部门编码';
COMMENT ON COLUMN repairs.department IS '部门描述';
COMMENT ON COLUMN repairs.asset_code IS '资产编码';
COMMENT ON COLUMN repairs.equipment_name IS '设备名称';
COMMENT ON COLUMN repairs.plate_no IS '车牌号';
COMMENT ON COLUMN repairs.total_cost IS '总维修费用（元）';

-- ============================================================
-- 8. 月度油耗（前端: monthlyFuel）
-- ============================================================
CREATE TABLE monthly_fuel (
    year                    NUMBER(4)    NOT NULL,
    month                   NUMBER(2)    NOT NULL,
    fuel_volume             NUMBER(15,2) DEFAULT 0
);
COMMENT ON TABLE  monthly_fuel IS '月度油耗汇总';
COMMENT ON COLUMN monthly_fuel.fuel_volume IS '加油量（升）';

-- ============================================================
-- 9. 部门油耗（前端: departmentFuel）
-- ============================================================
CREATE TABLE department_fuel (
    year                    NUMBER(4)    NOT NULL,
    month                   NUMBER(2)    NOT NULL,
    department              VARCHAR2(100),
    fuel_type               VARCHAR2(50),
    fuel_volume             NUMBER(15,2) DEFAULT 0,
    total_ratio             NUMBER(8,6)  DEFAULT 0,
    energy_type             VARCHAR2(50),
    energy_method           VARCHAR2(50),
    energy                  NUMBER(15,4) DEFAULT 0,
    mom                     NUMBER(8,6)  DEFAULT 0,
    yoy                     NUMBER(8,6)  DEFAULT 0
);
COMMENT ON TABLE  department_fuel IS '部门油耗数据';
COMMENT ON COLUMN department_fuel.fuel_type IS '燃料类型';
COMMENT ON COLUMN department_fuel.fuel_volume IS '加油量（升）';
COMMENT ON COLUMN department_fuel.total_ratio IS '总占比（0~1）';
COMMENT ON COLUMN department_fuel.energy_type IS '能源类型';
COMMENT ON COLUMN department_fuel.energy_method IS '能耗计算方式';
COMMENT ON COLUMN department_fuel.energy IS '能耗值';

-- ============================================================
-- 10. 单车油耗（前端: vehicleFuel）
-- ============================================================
CREATE TABLE vehicle_fuel (
    year                    NUMBER(4)    NOT NULL,
    month                   NUMBER(2)    NOT NULL,
    asset_code              VARCHAR2(50),
    equipment_name          VARCHAR2(200),
    plate_no                VARCHAR2(50),
    fuel_volume             NUMBER(15,2) DEFAULT 0
);
COMMENT ON TABLE  vehicle_fuel IS '单车油耗数据';
COMMENT ON COLUMN vehicle_fuel.asset_code IS '资产编码';
COMMENT ON COLUMN vehicle_fuel.equipment_name IS '设备名称';
COMMENT ON COLUMN vehicle_fuel.plate_no IS '车牌号';
COMMENT ON COLUMN vehicle_fuel.fuel_volume IS '加油量（升）';

-- ============================================================
-- 索引（优化前端常用查询）
-- ============================================================
CREATE INDEX idx_dept_rank_dept      ON dept_rank (department);
CREATE INDEX idx_depreciation_cat    ON depreciation (category);
CREATE INDEX idx_annual_dynamics_yr  ON annual_dynamics (year);
CREATE INDEX idx_outbound_summary_yr ON outbound_summary (year, warehouse_code);
CREATE INDEX idx_outbound_details_t  ON outbound_details (time);
CREATE INDEX idx_repairs_ym          ON repairs (year, month);
CREATE INDEX idx_monthly_fuel_ym     ON monthly_fuel (year, month);
CREATE INDEX idx_vehicle_fuel_ym     ON vehicle_fuel (year, month);

COMMIT;
