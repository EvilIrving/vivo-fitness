//
//  ActionRecognizer.swift
//  fitness Watch App
//
//  动作识别引擎 - 使用状态机识别健身动作
//

import Foundation
import Combine

@MainActor
class ActionRecognizer: ObservableObject {
    private var params: RecognitionParams
    private var currentState: RecognitionState = .idle
    private var peakValue: Double = 0
    private var peakTime: TimeInterval = 0
    private var motionStartTime: TimeInterval = 0
    private var dataBuffer: [FusedSensorData] = []
    
    @Published var recognizedCount: Int = 0
    
    var onActionComplete: ((Double, Double) -> Void)?  // (duration, peakValue)
    
    init(actionCode: ActionCode) {
        self.params = actionCode.recognitionParams
    }
    
    func reset() {
        currentState = .idle
        peakValue = 0
        peakTime = 0
        motionStartTime = 0
        dataBuffer.removeAll()
        recognizedCount = 0
    }
    
    func updateAction(_ actionCode: ActionCode) {
        params = actionCode.recognitionParams
        reset()
    }
    
    // MARK: - 处理传感器数据
    func processData(_ fusedData: FusedSensorData) {
        // 添加到缓冲区
        dataBuffer.append(fusedData)
        if dataBuffer.count > AppConfig.recognitionBufferSize {
            dataBuffer.removeFirst()
        }
        
        // 提取主值和辅助值
        let value = extractPrimaryValue(fusedData)
        let secondaryValue = extractSecondaryValue(fusedData)
        let timestamp = fusedData.timestamp
        
        // 状态机处理
        switch currentState {
        case .idle:
            handleIdleState(value: value, secondaryValue: secondaryValue, timestamp: timestamp)
        case .motionStart:
            handleMotionStartState(value: value, secondaryValue: secondaryValue, timestamp: timestamp)
        case .inProgress:
            handleInProgressState(value: value, secondaryValue: secondaryValue, timestamp: timestamp)
        case .peakDetected:
            handlePeakDetectedState(value: value, secondaryValue: secondaryValue, timestamp: timestamp)
        case .returning:
            handleReturningState(value: value, secondaryValue: secondaryValue, timestamp: timestamp)
        }
    }
    
    // MARK: - 主值提取
    private func extractPrimaryValue(_ fusedData: FusedSensorData) -> Double {
        let acc = fusedData.filteredAcc
        let gyro = fusedData.filteredGyro
        
        switch params.primaryAxis {
        case .x:
            return abs(acc.x)
        case .y:
            return abs(acc.y)
        case .z:
            return abs(acc.z)
        case .xyCombined:
            return acc.xyMagnitude
        case .gyroX:
            return abs(gyro.x)
        case .gyroY:
            return abs(gyro.y)
        case .gyroZ:
            return abs(gyro.z)
        }
    }
    
    // MARK: - 辅助值提取
    private func extractSecondaryValue(_ fusedData: FusedSensorData) -> Double? {
        guard let secondaryAxis = params.secondaryAxis else { return nil }
        
        let acc = fusedData.filteredAcc
        let gyro = fusedData.filteredGyro
        
        switch secondaryAxis {
        case .x:
            return abs(acc.x)
        case .y:
            return abs(acc.y)
        case .z:
            return abs(acc.z)
        case .gyroX:
            return abs(gyro.x)
        case .gyroY:
            return abs(gyro.y)
        case .gyroZ:
            return abs(gyro.z)
        }
    }
    
    // MARK: - 静止状态处理
    private func handleIdleState(value: Double, secondaryValue: Double?, timestamp: TimeInterval) {
        let startThreshold = params.peakThreshold * ThresholdRatios.motionStart
        
        if value > startThreshold {
            currentState = .motionStart
            motionStartTime = timestamp
            #if DEBUG
            print("[ActionRecognizer] 动作启动检测, value: \(value)")
            #endif
        }
    }
    
    // MARK: - 运动启动状态处理
    private func handleMotionStartState(value: Double, secondaryValue: Double?, timestamp: TimeInterval) {
        let continueThreshold = params.peakThreshold * ThresholdRatios.motionContinue
        
        if value > continueThreshold {
            currentState = .inProgress
            peakValue = value
            peakTime = timestamp
            #if DEBUG
            print("[ActionRecognizer] 动作进行中")
            #endif
        } else {
            // 超时检测
            let elapsed = timestamp - motionStartTime
            if elapsed > params.timeWindow.max {
                currentState = .idle
                #if DEBUG
                print("[ActionRecognizer] 运动启动超时，返回静止")
                #endif
            }
        }
    }
    
    // MARK: - 动作进行中状态处理
    private func handleInProgressState(value: Double, secondaryValue: Double?, timestamp: TimeInterval) {
        // 持续追踪峰值
        if value > peakValue {
            peakValue = value
            peakTime = timestamp
        }
        
        // 检测是否达到峰值阈值
        if peakValue >= params.peakThreshold {
            // 辅助轴验证
            var secondaryCheck = true
            if let secondary = secondaryValue, params.secondaryAxis != nil {
                secondaryCheck = secondary >= params.gyroThreshold
            }
            
            if secondaryCheck {
                currentState = .peakDetected
                #if DEBUG
                print("[ActionRecognizer] 峰值检测成功: \(peakValue)")
                #endif
            }
        }
        
        // 超时保护
        let elapsed = timestamp - motionStartTime
        if elapsed > params.timeWindow.max {
            currentState = .idle
            peakValue = 0
            #if DEBUG
            print("[ActionRecognizer] 动作进行超时，返回静止")
            #endif
        }
    }
    
    // MARK: - 峰值检测状态处理
    private func handlePeakDetectedState(value: Double, secondaryValue: Double?, timestamp: TimeInterval) {
        let fallThreshold = peakValue * ThresholdRatios.peakDetected
        
        if value < fallThreshold {
            currentState = .returning
            #if DEBUG
            print("[ActionRecognizer] 数值开始回落")
            #endif
        }
    }
    
    // MARK: - 回归基线状态处理
    private func handleReturningState(value: Double, secondaryValue: Double?, timestamp: TimeInterval) {
        let baselineThreshold = params.peakThreshold * ThresholdRatios.returning
        
        if value < baselineThreshold {
            let duration = timestamp - motionStartTime
            
            if duration >= params.timeWindow.min && duration <= params.timeWindow.max {
                // 动作完成！
                DispatchQueue.main.async {
                    self.recognizedCount += 1
                    self.onActionComplete?(duration, self.peakValue)
                }
                #if DEBUG
                print("[ActionRecognizer] ✅ 动作完成! 耗时: \(duration)秒, 峰值: \(peakValue)")
                #endif
            } else {
                #if DEBUG
                print("[ActionRecognizer] 时间窗口验证失败: \(duration)")
                #endif
            }
            
            // 重置状态
            currentState = .idle
            peakValue = 0
            motionStartTime = 0
        }
    }
}
