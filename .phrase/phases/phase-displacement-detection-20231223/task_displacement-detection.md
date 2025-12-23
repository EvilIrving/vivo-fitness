# 任务清单：位移检测增强

> Phase: displacement-detection-20231223
> 依据: spec_displacement-detection.md, tech-refer_displacement-detection.md

---

## 任务列表

### 数据结构与配置

- [ ] **task001** 扩展 `DetectionParams` 结构
  - 产出：在 Models.swift 中增加 `secondaryAxis`、`displacementThreshold`、`useDisplacementFallback`、`relaxedReturnEnabled` 等字段
  - 验证：编译通过，现有代码不受影响
  - 影响：Models.swift

- [ ] **task002** 实现 `DisplacementEstimate` 位移估计结构
  - 产出：新增位移估计数据结构，包含速度/位移/时间戳及 reset 方法
  - 验证：编译通过
  - 影响：Models.swift

### 核心算法

- [ ] **task003** 增强 `ActionRecognizer` 支持位移检测
  - 产出：修改 ActionRecognizer.swift，集成位移估计和多条件判定逻辑
  - 验证：编译通过 + 手动测试正常场景不受影响
  - 影响：ActionRecognizer.swift

- [ ] **task004** 实现信号稳定性检测
  - 产出：增加 `isSignalStable()` 方法，用于宽松回程检测
  - 验证：编译通过
  - 影响：ActionRecognizer.swift

### 动作参数配置

- [ ] **task005** 为现有动作配置默认位移检测参数
  - 产出：更新 ActionCode.detectionParams 扩展，为所有动作添加新字段默认值
  - 验证：编译通过，现有行为不变（useDisplacementFallback 默认 false）
  - 影响：Models.swift

- [ ] **task006** 为关键动作启用位移检测
  - 产出：为绳索下压、面拉等适合匀速完成的动作启用位移检测
  - 验证：手动测试匀速动作可被识别
  - 影响：Models.swift
  - 依赖：task005

### 调试与验证

- [ ] **task007** TestModeView 增加位移数据显示
  - 产出：在测试界面显示实时位移估计值
  - 验证：运行 App 可看到位移数据
  - 影响：TestModeView.swift
  - 依赖：task003

### 文档更新

- [ ] **task008** 更新核心算法说明文档
  - 产出：在 docs/01-核心算法说明文档.md 中增加位移检测章节
  - 验证：文档内容完整，与实现一致
  - 影响：docs/01-核心算法说明文档.md
  - 依赖：task003

---

## 完成标准

- 所有任务标记 [x]
- spec 中 Acceptance Criteria 全部通过
- 无编译错误
- 现有功能回归测试通过

---

*创建日期: 2024-12-23*
*状态: IN_PROGRESS*
