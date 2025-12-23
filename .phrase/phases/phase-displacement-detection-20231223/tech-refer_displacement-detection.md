# 技术参考：位移检测增强方案

> 目标：增强动作完成检测算法，支持力竭/匀速场景下的多轴位移检测

---

## 1. 背景与动机

### 1.1 当前算法局限

当前 `ActionRecognizer` 基于**加速度峰值检测**：

```
加速度 = 速度变化率 = dv/dt
```

**问题**：
- 爆发力动作：加速度信号明显 ✅
- 力竭/匀速动作：速度恒定，加速度 ≈ 0 ❌

### 1.2 实际训练场景

| 场景 | 去程（向心） | 回程（离心） | 当前算法 |
|-----|------------|------------|---------|
| 爆发训练 | 加速度峰值 ✅ | 加速度峰值 ✅ | 可识别 |
| 力竭阶段 | 微弱加速度 | 匀速/缓慢 | 可能漏检 |
| 离心控制 | 加速度峰值 ✅ | 刻意匀速控制 | 回程可能漏检 |
| 康复训练 | 匀速 | 匀速 | 可能漏检 |

### 1.3 核心洞察

> "做完就是胜利" —— 无论是新手力竭还是高手刻意控制，匀速完成动作也应计数。

离心控制（Eccentric Control）是高质量训练的主动选择：
- 增加肌肉时间张力（TUT）
- 强化离心收缩刺激
- 更好地控制重量

---

## 2. 技术方案

### 2.1 方案比较

| 方案 | 描述 | 优点 | 缺点 |
|-----|------|-----|------|
| A. 纯加速度 | 当前方案 | 简单可靠 | 匀速漏检 |
| B. 加速度积分位移 | 二次积分估计位移 | 理论完整 | 积分漂移严重 |
| C. 短周期位移估计 | 动作期间短时积分 | 漂移可控 | 需要调参 |
| D. 时间+稳定性回程 | 去程检测+时间回程 | 简单有效 | 可能误检 |
| **E. 混合检测（推荐）** | 加速度 OR 位移 OR 时间稳定性 | 覆盖全场景 | 复杂度中等 |

### 2.2 推荐方案：混合检测模式

```
动作完成检测 = 去程完成 AND 回程完成

去程完成 = 加速度达标 OR 累积位移达标
回程完成 = 回归基线 OR 反向位移达标 OR (时间窗口内+信号稳定)
```

**核心改进**：
1. **多信号源**：加速度峰值 + 位移估计 + 时间稳定性
2. **OR 逻辑**：任一条件满足即可，提高召回率
3. **短周期积分**：仅在动作期间（1-3秒）积分，重置避免漂移
4. **双轴支持**：主轴 + 次轴，适应复合动作

### 2.3 位移估计算法

#### 2.3.1 短周期积分

```pseudocode
// 仅在动作期间（DEPARTING/PEAK_ZONE/RETURNING 状态）进行积分
// 每次动作完成或超时后重置

STATE displacement:
    velocity: (primary: Double, secondary: Double) = (0, 0)
    position: (primary: Double, secondary: Double) = (0, 0)
    lastTimestamp: TimeInterval = 0

FUNCTION updateDisplacement(primaryAcc, secondaryAcc, timestamp):
    dt = timestamp - lastTimestamp
    IF dt <= 0 OR dt > 0.1 THEN  // 防止异常时间间隔
        lastTimestamp = timestamp
        RETURN
    END IF
    
    // 速度积分：v = v0 + a * dt
    velocity.primary += primaryAcc * dt
    velocity.secondary += secondaryAcc * dt
    
    // 位移积分：s = s0 + |v| * dt（累积绝对位移）
    position.primary += ABS(velocity.primary) * dt
    position.secondary += ABS(velocity.secondary) * dt
    
    lastTimestamp = timestamp
END FUNCTION
```

#### 2.3.2 漂移控制策略

1. **短周期**：每次动作完成后重置积分状态
2. **高通滤波**：去除加速度中的直流分量（重力残留）
3. **阈值门限**：忽略过小的加速度（噪声）
4. **对称性校正**：利用去程-回程的对称性进行校正（可选）

### 2.4 回程宽松检测

对于刻意控制的离心回程，放宽检测条件：

```pseudocode
FUNCTION checkReturnComplete(value, timestamp):
    duration = timestamp - departureTime
    
    // 条件1：传统加速度回归基线
    IF value <= baseline + baselineWindow THEN
        RETURN TRUE
    END IF
    
    // 条件2：累积位移达标（新增）
    IF displacement.position.primary >= displacementThreshold THEN
        RETURN TRUE
    END IF
    
    // 条件3：时间窗口内信号趋于稳定（新增）
    IF duration >= minDuration AND isSignalStable(recentValues) THEN
        RETURN TRUE
    END IF
    
    RETURN FALSE
END FUNCTION
```

---

## 3. 数据结构变更

### 3.1 新增：位移估计结构

```swift
// 位移估计数据
struct DisplacementEstimate {
    var velocity: (primary: Double, secondary: Double) = (0, 0)
    var position: (primary: Double, secondary: Double) = (0, 0)
    var lastTimestamp: TimeInterval = 0
    
    mutating func reset() {
        velocity = (0, 0)
        position = (0, 0)
        lastTimestamp = 0
    }
}
```

### 3.2 扩展：检测参数配置

```swift
struct DetectionParams {
    // ... 现有字段 ...
    
    // 新增：次要监测轴（用于复合动作）
    let secondaryAxis: PrimaryAxis?
    
    // 新增：位移检测配置
    let displacementThreshold: Double   // 位移阈值（米），0 表示禁用
    let useDisplacementFallback: Bool   // 是否启用位移回退检测
    
    // 新增：回程宽松配置
    let relaxedReturnEnabled: Bool      // 是否启用宽松回程检测
    let stableWindowSize: Int           // 稳定性判断窗口大小
    let stableThreshold: Double         // 稳定性阈值（方差）
}
```

### 3.3 动作参数更新示例

```swift
// 直臂下压 - Z轴位移为主
case .straightArmPushdown:
    return DetectionParams(
        primaryAxis: .z,
        secondaryAxis: nil,
        initialPeakThreshold: 1.0,
        minPeakRatio: 0.3,
        timeWindow: (min: 0.5, max: 3.0),
        baselineWindow: 0.3,
        adaptiveEnabled: true,
        // 新增
        displacementThreshold: 0.15,      // 15cm
        useDisplacementFallback: true,
        relaxedReturnEnabled: true,
        stableWindowSize: 10,
        stableThreshold: 0.1
    )

// 面拉 - Y轴（水平）为主，Z轴为辅
case .facePull:
    return DetectionParams(
        primaryAxis: .y,
        secondaryAxis: .z,               // 双轴监测
        initialPeakThreshold: 0.8,
        minPeakRatio: 0.3,
        timeWindow: (min: 0.6, max: 3.5),
        baselineWindow: 0.3,
        adaptiveEnabled: true,
        // 新增
        displacementThreshold: 0.20,      // 20cm
        useDisplacementFallback: true,
        relaxedReturnEnabled: true,
        stableWindowSize: 10,
        stableThreshold: 0.1
    )
```

---

## 4. 状态机增强

### 4.1 增强后的状态转换

```
                      加速度 > departure threshold
                      OR 速度变化检测到启动
          ┌───────────────────────────────────────────┐
          │                                           ▼
      ┌───┴────┐                               ┌─────────────┐
      │BASELINE│◄──────── 周期完成 ────────────│  DEPARTING  │
      └────────┘                               │  (追踪峰值)  │
          ▲                                    │  (累积位移)  │ ← 新增
          │                                    └──────┬──────┘
          │                                           │
          │                                           │ 加速度回落
          │                                           │ OR 位移达标
          │                                           ▼
          │    回归基线                         ┌─────────────┐
          │    OR 位移达标                      │  PEAK_ZONE  │
          │    OR 时间+稳定性                   │  (确认峰值)  │
          │◄───────────────────────────────────└──────┬──────┘
          │                                           │
          │                                           │ 加速度 < returnThreshold
          │                                           │ OR 反向位移开始
          │                                           ▼
          │    验证完成条件                     ┌─────────────┐
          │    (加速度 OR 位移 OR 稳定性)       │  RETURNING  │
          └────────────────────────────────────│  (等待回归)  │
                                               └─────────────┘
```

### 4.2 完成判定逻辑

```pseudocode
FUNCTION isMotionComplete():
    duration = currentTime - departureTime
    
    // 时间窗口验证
    IF duration < timeWindow.min OR duration > timeWindow.max THEN
        RETURN FALSE
    END IF
    
    // 三选一完成条件
    accelerationComplete = (currentValue <= baseline + baselineWindow)
    displacementComplete = (displacement.position.primary >= displacementThreshold)
    stabilityComplete = (relaxedReturnEnabled AND isSignalStable())
    
    RETURN accelerationComplete OR displacementComplete OR stabilityComplete
END FUNCTION
```

---

## 5. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|-----|------|---------|
| 积分漂移 | 位移估计不准 | 短周期重置 + 高通滤波 |
| 误检增加 | 非动作被计数 | 保持时间窗口验证 + 峰值门限 |
| 参数调试复杂 | 不同动作需不同参数 | 提供合理默认值 + 自适应学习 |
| 性能开销 | 实时积分计算 | 仅在运动状态计算 |

---

## 6. 实现计划

### Phase 任务拆分

1. **task001**: 扩展 `DetectionParams` 结构，增加位移检测相关配置
2. **task002**: 实现 `DisplacementEstimate` 位移估计模块
3. **task003**: 修改 `ActionRecognizer` 状态机，集成位移检测
4. **task004**: 更新动作参数配置，为关键动作启用位移检测
5. **task005**: 更新核心算法文档 `docs/01-核心算法说明文档.md`
6. **task006**: 在 TestModeView 中增加位移数据显示，便于调试

### 验证方式

- 单元测试：模拟匀速运动数据，验证位移检测触发
- 手动测试：在 TestModeView 中观察力竭/匀速场景的计数效果
- 对比测试：同一组动作，对比新旧算法的识别率

---

## 7. 决策记录

| 决策 | 选项 | 理由 |
|-----|------|-----|
| 位移检测作为回退 | 主用加速度，位移为辅 | 加速度更可靠，位移解决边缘场景 |
| OR 逻辑而非 AND | 任一条件满足即计数 | 提高召回率，宁可多计不漏计 |
| 短周期积分 | 每次动作后重置 | 避免长期漂移 |
| 双轴支持 | 可选配置次轴 | 支持面拉等复合动作 |

---

*文档版本: 1.0.0*
*创建日期: 2024-12-23*
*状态: DRAFT*
