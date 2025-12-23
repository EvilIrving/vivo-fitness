# 计划：位移检测增强

> Phase: displacement-detection-20231223

---

## 里程碑

| 阶段 | 目标 | 预计完成 |
|-----|------|---------|
| M1 | 数据结构扩展 (task001-002) | Day 1 |
| M2 | 核心算法实现 (task003-004) | Day 1 |
| M3 | 动作参数配置 (task005-006) | Day 1 |
| M4 | 调试验证与文档 (task007-008) | Day 1 |

---

## 范围

### In Scope

- `DetectionParams` 结构扩展
- `DisplacementEstimate` 位移估计模块
- `ActionRecognizer` 状态机增强
- 动作参数配置更新
- TestModeView 调试显示
- 核心算法文档更新

### Out of Scope

- UI/UX 流程变更
- 新动作类型添加
- 机器学习模型

---

## 优先级

1. **P0 - 必须**: task001-005（核心功能）
2. **P1 - 重要**: task006-007（实用性验证）
3. **P2 - 建议**: task008（文档完善）

---

## 风险与依赖

| 风险 | 影响 | 缓解 |
|-----|------|-----|
| 积分漂移导致位移不准 | 中 | 短周期重置 + 仅作为辅助判定 |
| 误检率上升 | 中 | 保持时间窗口 + OR 逻辑中加速度优先 |
| 参数调优复杂 | 低 | 提供合理默认值 + TestModeView 可视化 |

### 依赖

- 现有 `ActionRecognizer` 状态机架构
- `MotionManager` 传感器数据源

---

## 回滚方案

如发现位移检测导致问题：
1. 将所有动作的 `useDisplacementFallback` 设为 `false`
2. 系统自动回退到纯加速度检测模式

---

*创建日期: 2024-12-23*
*状态: ACTIVE*
