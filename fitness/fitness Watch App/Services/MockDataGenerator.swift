//
//  MockDataGenerator.swift
//  fitness Watch App
//
//  模拟传感器数据生成器 - 用于模拟器测试
//

import Foundation

/// 模拟数据生成器，生成符合各类动作特征的传感器数据
class MockDataGenerator {
    
    /// 动作模拟模式
    enum SimulationMode {
        case idle           // 静止状态
        case action         // 执行动作
        case continuous     // 连续动作（自动循环）
    }
    
    private var mode: SimulationMode = .idle
    private var actionCode: ActionCode = .benchPress
    private var timer: Timer?
    private var phase: Double = 0
    private var actionPhase: ActionPhase = .rest
    private var phaseProgress: Double = 0
    
    private enum ActionPhase {
        case rest       // 休息
        case rising     // 上升阶段
        case peak       // 峰值阶段
        case falling    // 下降阶段
    }
    
    var onDataGenerated: ((FusedSensorData) -> Void)?
    
    private let updateInterval: TimeInterval = 0.02  // 50 Hz，与真实传感器一致
    
    // MARK: - 启动模拟
    func startSimulation(action: ActionCode, mode: SimulationMode = .continuous) {
        self.actionCode = action
        self.mode = mode
        self.phase = 0
        self.actionPhase = .rest
        self.phaseProgress = 0
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.generateData()
        }
    }
    
    // MARK: - 停止模拟
    func stopSimulation() {
        timer?.invalidate()
        timer = nil
        mode = .idle
    }
    
    // MARK: - 触发单次动作
    func triggerSingleAction() {
        guard mode == .idle || actionPhase == .rest else { return }
        actionPhase = .rising
        phaseProgress = 0
    }
    
    // MARK: - 生成数据
    private func generateData() {
        let params = actionCode.detectionParams
        let timestamp = Date().timeIntervalSince1970
        
        // 根据动作阶段生成数据
        let (accValue, gyroValue) = generateValuesByPhase(params: params)
        
        // 创建传感器读数
        let accReading = createAccReading(primaryValue: accValue, params: params, timestamp: timestamp)
        let gyroReading = createGyroReading(primaryValue: gyroValue, params: params, timestamp: timestamp)
        
        // 添加噪声
        let noisyAcc = addNoise(to: accReading, level: 0.05)
        let noisyGyro = addNoise(to: gyroReading, level: 2.0)
        
        let fusedData = FusedSensorData(
            rawAcc: noisyAcc,
            rawGyro: noisyGyro,
            filteredAcc: accReading,  // 模拟滤波后数据
            filteredGyro: gyroReading,
            timestamp: timestamp
        )
        
        onDataGenerated?(fusedData)
        
        // 更新阶段
        updatePhase()
    }
    
    // MARK: - 根据阶段生成数值
    private func generateValuesByPhase(params: DetectionParams) -> (acc: Double, gyro: Double) {
        let peakAcc = params.initialPeakThreshold
        // 根据主轴类型确定陀螺仪峰值
        let peakGyro: Double = {
            switch params.primaryAxis {
            case .gyroX, .gyroY, .gyroZ:
                return params.initialPeakThreshold  // 陀螺仪主导时使用相同阈值
            default:
                return 30.0  // 默认陀螺仪阈值
            }
        }()
        
        switch actionPhase {
        case .rest:
            // 静止状态，低噪声
            return (0.1, 5.0)
            
        case .rising:
            // 上升阶段：从0到峰值
            let progress = easeInOut(phaseProgress)
            let accValue = peakAcc * progress * 1.2  // 略超过阈值
            let gyroValue = peakGyro * progress * 1.1
            return (accValue, gyroValue)
            
        case .peak:
            // 峰值阶段：保持在峰值附近
            let variation = sin(phaseProgress * .pi * 4) * 0.1
            let accValue = peakAcc * (1.1 + variation)
            let gyroValue = peakGyro * (1.05 + variation)
            return (accValue, gyroValue)
            
        case .falling:
            // 下降阶段：从峰值回到基线
            let progress = 1.0 - easeInOut(phaseProgress)
            let accValue = peakAcc * progress * 0.8
            let gyroValue = peakGyro * progress * 0.7
            return (accValue, gyroValue)
        }
    }
    
    // MARK: - 创建加速度读数
    private func createAccReading(primaryValue: Double, params: DetectionParams, timestamp: TimeInterval) -> SensorReading {
        var x = 0.0, y = 0.0, z = 0.0
        
        switch params.primaryAxis {
        case .x:
            x = primaryValue
        case .y:
            y = primaryValue
        case .z:
            z = primaryValue
        case .xyCombined:
            // 分配到 x 和 y
            let angle = phase * 0.5
            x = primaryValue * cos(angle) * 0.7
            y = primaryValue * sin(angle) * 0.7
        default:
            break
        }
        
        return SensorReading(x: x, y: y, z: z, timestamp: timestamp)
    }
    
    // MARK: - 创建陀螺仪读数
    private func createGyroReading(primaryValue: Double, params: DetectionParams, timestamp: TimeInterval) -> SensorReading {
        var x = 0.0, y = 0.0, z = 0.0
        
        // 根据主轴设置陀螺仪值
        switch params.primaryAxis {
        case .gyroX:
            x = primaryValue
        case .gyroY:
            y = primaryValue
        case .gyroZ:
            z = primaryValue
        default:
            // 非陀螺仪主导时，添加小的辅助值
            y = primaryValue * 0.3
        }
        
        return SensorReading(x: x, y: y, z: z, timestamp: timestamp)
    }
    
    // MARK: - 添加噪声
    private func addNoise(to reading: SensorReading, level: Double) -> SensorReading {
        return SensorReading(
            x: reading.x + Double.random(in: -level...level),
            y: reading.y + Double.random(in: -level...level),
            z: reading.z + Double.random(in: -level...level),
            timestamp: reading.timestamp
        )
    }
    
    // MARK: - 更新阶段
    private func updatePhase() {
        phase += updateInterval
        
        let params = actionCode.detectionParams
        let actionDuration = (params.timeWindow.min + params.timeWindow.max) / 2
        
        // 各阶段时长比例
        let risingDuration = actionDuration * 0.35
        let peakDuration = actionDuration * 0.15
        let fallingDuration = actionDuration * 0.35
        let restDuration = 1.0  // 动作间隔
        
        phaseProgress += updateInterval
        
        switch actionPhase {
        case .rest:
            if mode == .continuous && phaseProgress >= restDuration {
                actionPhase = .rising
                phaseProgress = 0
            }
            
        case .rising:
            if phaseProgress >= risingDuration {
                actionPhase = .peak
                phaseProgress = 0
            }
            
        case .peak:
            if phaseProgress >= peakDuration {
                actionPhase = .falling
                phaseProgress = 0
            }
            
        case .falling:
            if phaseProgress >= fallingDuration {
                actionPhase = .rest
                phaseProgress = 0
                
                if mode == .action {
                    mode = .idle
                }
            }
        }
        
        // 归一化进度到 0-1
        switch actionPhase {
        case .rest:
            phaseProgress = min(phaseProgress / restDuration, 1.0)
        case .rising:
            phaseProgress = min(phaseProgress / risingDuration, 1.0)
        case .peak:
            phaseProgress = min(phaseProgress / peakDuration, 1.0)
        case .falling:
            phaseProgress = min(phaseProgress / fallingDuration, 1.0)
        }
    }
    
    // MARK: - 缓动函数
    private func easeInOut(_ t: Double) -> Double {
        return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
}

// MARK: - 预设测试序列
extension MockDataGenerator {
    
    /// 生成预设的测试数据序列（用于单元测试）
    static func generateTestSequence(for action: ActionCode, reps: Int = 3) -> [FusedSensorData] {
        var sequence: [FusedSensorData] = []
        let params = action.detectionParams
        let actionDuration = (params.timeWindow.min + params.timeWindow.max) / 2
        
        var timestamp: TimeInterval = 0
        let dt: TimeInterval = 0.02
        
        for rep in 0..<reps {
            // 休息期
            let restFrames = Int(0.5 / dt)
            for _ in 0..<restFrames {
                let data = createIdleData(timestamp: timestamp)
                sequence.append(data)
                timestamp += dt
            }
            
            // 上升期
            let risingFrames = Int(actionDuration * 0.35 / dt)
            for i in 0..<risingFrames {
                let progress = Double(i) / Double(risingFrames)
                let value = params.initialPeakThreshold * 1.2 * progress
                let gyroValue = 30.0 * 1.1 * progress  // 默认陀螺仪值
                let data = createActionData(
                    accValue: value,
                    gyroValue: gyroValue,
                    params: params,
                    timestamp: timestamp
                )
                sequence.append(data)
                timestamp += dt
            }
            
            // 峰值期
            let peakFrames = Int(actionDuration * 0.15 / dt)
            for _ in 0..<peakFrames {
                let data = createActionData(
                    accValue: params.initialPeakThreshold * 1.15,
                    gyroValue: 30.0 * 1.1,
                    params: params,
                    timestamp: timestamp
                )
                sequence.append(data)
                timestamp += dt
            }
            
            // 下降期
            let fallingFrames = Int(actionDuration * 0.35 / dt)
            for i in 0..<fallingFrames {
                let progress = 1.0 - Double(i) / Double(fallingFrames)
                let value = params.initialPeakThreshold * 0.8 * progress
                let gyroValue = 30.0 * 0.7 * progress
                let data = createActionData(
                    accValue: value,
                    gyroValue: gyroValue,
                    params: params,
                    timestamp: timestamp
                )
                sequence.append(data)
                timestamp += dt
            }
            
            print("[MockDataGenerator] 生成第 \(rep + 1) 次动作数据")
        }
        
        return sequence
    }
    
    private static func createIdleData(timestamp: TimeInterval) -> FusedSensorData {
        let acc = SensorReading(x: 0.05, y: 0.05, z: 0.1, timestamp: timestamp)
        let gyro = SensorReading(x: 2, y: 2, z: 2, timestamp: timestamp)
        return FusedSensorData(
            rawAcc: acc,
            rawGyro: gyro,
            filteredAcc: acc,
            filteredGyro: gyro,
            timestamp: timestamp
        )
    }
    
    private static func createActionData(
        accValue: Double,
        gyroValue: Double,
        params: DetectionParams,
        timestamp: TimeInterval
    ) -> FusedSensorData {
        var accX = 0.0, accY = 0.0, accZ = 0.0
        var gyroX = 0.0, gyroY = 0.0, gyroZ = 0.0
        
        // 设置主轴
        switch params.primaryAxis {
        case .x: accX = accValue
        case .y: accY = accValue
        case .z: accZ = accValue
        case .xyCombined:
            accX = accValue * 0.7
            accY = accValue * 0.7
        case .magnitude:
            let v = accValue / sqrt(3.0)
            accX = v
            accY = v
            accZ = v
        case .gyroX: gyroX = accValue
        case .gyroY: gyroY = accValue
        case .gyroZ: gyroZ = accValue
        }
        
        // 添加辅助陀螺仪值
        if params.primaryAxis != .gyroX && params.primaryAxis != .gyroY && params.primaryAxis != .gyroZ {
            gyroY = gyroValue
        }
        
        let acc = SensorReading(x: accX, y: accY, z: accZ, timestamp: timestamp)
        let gyro = SensorReading(x: gyroX, y: gyroY, z: gyroZ, timestamp: timestamp)
        
        return FusedSensorData(
            rawAcc: acc,
            rawGyro: gyro,
            filteredAcc: acc,
            filteredGyro: gyro,
            timestamp: timestamp
        )
    }
}
