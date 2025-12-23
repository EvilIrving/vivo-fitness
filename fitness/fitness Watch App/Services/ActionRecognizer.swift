//
//  ActionRecognizer.swift
//  fitness Watch App
//
//  动作完成检测引擎 - 使用状态机检测动作完成（去程→峰值→回程）
//  核心设计：用户先选择动作类型，算法只需识别"动作是否完成一次"
//

import Foundation
import Combine

@MainActor
class ActionRecognizer: ObservableObject {
    
    // MARK: - 配置参数
    private var params: DetectionParams
    
    // MARK: - 状态机
    private var currentState: DetectionState = .baseline
    private var departureTime: TimeInterval = 0    // 离开基线时间
    private var peakValue: Double = 0              // 当前周期峰值
    private var peakTime: TimeInterval = 0         // 峰值时间
    
    // MARK: - 动态基线
    private var baselineBuffer: [Double] = []
    private var dynamicBaseline: Double = 0
    
    // MARK: - 自适应阈值系统
    private var learnedPeaks: [Double] = []        // 学习到的峰值历史
    private var averagePeak: Double = 0            // 平均峰值
    private var currentThreshold: Double = 0       // 当前有效阈值
    
    // MARK: - 计数
    @Published var completedCount: Int = 0
    
    // MARK: - 回调
    var onActionComplete: ((Double, Double) -> Void)?  // (duration, peakValue)
    
    // MARK: - 初始化
    init(actionCode: ActionCode) {
        self.params = actionCode.detectionParams
        self.currentThreshold = params.initialPeakThreshold
    }
    
    // MARK: - 重置（每组训练开始时调用）
    func reset() {
        currentState = .baseline
        departureTime = 0
        peakValue = 0
        peakTime = 0
        
        // 重置自适应学习
        learnedPeaks.removeAll()
        averagePeak = 0
        currentThreshold = params.initialPeakThreshold
        
        // 重置基线
        baselineBuffer.removeAll()
        dynamicBaseline = 0
        
        // 重置计数
        completedCount = 0
        
        #if DEBUG
        print("[ActionRecognizer] 新组开始，自适应状态重置")
        #endif
    }
    
    // MARK: - 更新动作类型
    func updateAction(_ actionCode: ActionCode) {
        params = actionCode.detectionParams
        reset()
    }
    
    // MARK: - 处理传感器数据（主入口）
    func processData(_ fusedData: FusedSensorData) {
        let value = extractPrimaryValue(fusedData)
        let timestamp = fusedData.timestamp
        
        // 更新动态基线（仅在基线状态）
        updateBaseline(value)
        
        // 获取当前有效阈值
        let threshold = getEffectiveThreshold()
        
        // 状态机处理
        switch currentState {
        case .baseline:
            handleBaseline(value: value, timestamp: timestamp, threshold: threshold)
        case .departing:
            handleDeparting(value: value, timestamp: timestamp, threshold: threshold)
        case .peakZone:
            handlePeakZone(value: value, timestamp: timestamp)
        case .returning:
            handleReturning(value: value, timestamp: timestamp)
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
        case .magnitude:
            return acc.magnitude
        case .gyroX:
            return abs(gyro.x)
        case .gyroY:
            return abs(gyro.y)
        case .gyroZ:
            return abs(gyro.z)
        }
    }
    
    // MARK: - ========== 状态处理逻辑 ==========
    
    /// 基线状态：等待去程开始
    private func handleBaseline(value: Double, timestamp: TimeInterval, threshold: Double) {
        let departureThreshold = threshold * StateTransitionRatios.departureStart
        
        if value > dynamicBaseline + departureThreshold {
            // 检测到离开基线，开始去程
            currentState = .departing
            departureTime = timestamp
            peakValue = value
            
            #if DEBUG
            print("[ActionRecognizer] 去程开始, value: \(String(format: "%.2f", value)), threshold: \(String(format: "%.2f", departureThreshold))")
            #endif
        }
    }
    
    /// 去程状态：追踪峰值
    private func handleDeparting(value: Double, timestamp: TimeInterval, threshold: Double) {
        // 持续追踪最大值
        if value > peakValue {
            peakValue = value
            peakTime = timestamp
        }
        
        // 检测是否开始回落（进入峰值区）
        let fallbackRatio = StateTransitionRatios.peakFallback
        if value < peakValue * fallbackRatio && peakValue >= threshold {
            // 峰值足够且开始回落，进入峰值区
            currentState = .peakZone
            
            #if DEBUG
            print("[ActionRecognizer] 进入峰值区，峰值: \(String(format: "%.2f", peakValue))")
            #endif
        }
        
        // 超时保护
        let elapsed = timestamp - departureTime
        if elapsed > params.timeWindow.max {
            resetToBaseline(reason: "去程超时")
        }
    }
    
    /// 峰值区状态：确认回程开始
    private func handlePeakZone(value: Double, timestamp: TimeInterval) {
        let returnThreshold = peakValue * StateTransitionRatios.returnConfirm
        
        if value < returnThreshold {
            // 确认进入回程
            currentState = .returning
            
            #if DEBUG
            print("[ActionRecognizer] 回程开始")
            #endif
        }
        
        // 如果又开始上升，可能是多峰动作，更新峰值
        if value > peakValue {
            peakValue = value
            peakTime = timestamp
        }
    }
    
    /// 回程状态：等待回归基线
    private func handleReturning(value: Double, timestamp: TimeInterval) {
        // 检测是否回归到基线附近
        if value <= dynamicBaseline + params.baselineWindow {
            // 回归基线，验证完整周期
            let duration = timestamp - departureTime
            
            if duration >= params.timeWindow.min && duration <= params.timeWindow.max {
                // ✅ 完整周期确认！触发计数
                onMotionComplete(duration: duration, peakValue: peakValue)
            } else {
                #if DEBUG
                print("[ActionRecognizer] 时间窗口验证失败: \(String(format: "%.2f", duration))秒")
                #endif
            }
            
            // 重置到基线状态
            resetToBaseline(reason: "周期完成")
        }
        
        // 如果又开始上升，可能用户中途改变，回到峰值区
        if value > peakValue * 0.7 {
            currentState = .peakZone
        }
    }
    
    /// 重置到基线状态
    private func resetToBaseline(reason: String) {
        currentState = .baseline
        peakValue = 0
        departureTime = 0
        
        #if DEBUG
        print("[ActionRecognizer] 重置到基线: \(reason)")
        #endif
    }
    
    // MARK: - ========== 动作完成回调 ==========
    
    private func onMotionComplete(duration: Double, peakValue: Double) {
        completedCount += 1
        
        // 学习此次峰值（用于自适应）
        if params.adaptiveEnabled {
            learnPeak(peakValue)
        }
        
        #if DEBUG
        print("[ActionRecognizer] ✅ 动作完成 #\(completedCount) 耗时: \(String(format: "%.2f", duration))秒，峰值: \(String(format: "%.2f", peakValue))")
        #endif
        
        // 触发回调
        onActionComplete?(duration, peakValue)
    }
    
    // MARK: - ========== 自适应阈值系统 ==========
    
    /// 学习峰值
    private func learnPeak(_ peakValue: Double) {
        // 添加到历史
        learnedPeaks.append(peakValue)
        
        // 限制历史长度
        if learnedPeaks.count > AdaptiveConfig.maxHistory {
            learnedPeaks.removeFirst()
        }
        
        // 重新计算平均峰值
        averagePeak = calculateAveragePeak()
        
        // 更新自适应阈值
        updateAdaptiveThreshold()
    }
    
    /// 计算平均峰值
    private func calculateAveragePeak() -> Double {
        guard !learnedPeaks.isEmpty else {
            return params.initialPeakThreshold
        }
        
        let sum = learnedPeaks.reduce(0, +)
        return sum / Double(learnedPeaks.count)
    }
    
    /// 更新自适应阈值
    private func updateAdaptiveThreshold() {
        if learnedPeaks.count < AdaptiveConfig.learningCount {
            // 学习阶段：使用初始阈值
            currentThreshold = params.initialPeakThreshold
        } else {
            // 适应阶段：基于平均峰值计算
            var adaptiveThreshold = averagePeak * params.minPeakRatio
            
            // 应用衰减因子（随疲劳进一步降低）
            let fatigueCount = completedCount - AdaptiveConfig.learningCount
            if fatigueCount > 0 {
                let fatigueAdjustment = pow(AdaptiveConfig.decayFactor, Double(fatigueCount))
                adaptiveThreshold = adaptiveThreshold * fatigueAdjustment
            }
            
            // 确保不低于绝对最低阈值
            currentThreshold = max(adaptiveThreshold, AdaptiveConfig.absoluteMinThreshold)
        }
        
        #if DEBUG
        print("[ActionRecognizer] 阈值更新: \(String(format: "%.2f", currentThreshold)) (平均峰值: \(String(format: "%.2f", averagePeak)))")
        #endif
    }
    
    /// 获取有效阈值
    private func getEffectiveThreshold() -> Double {
        if !params.adaptiveEnabled {
            return params.initialPeakThreshold
        }
        return currentThreshold
    }
    
    // MARK: - ========== 动态基线计算 ==========
    
    /// 更新动态基线（仅在静止状态更新）
    private func updateBaseline(_ value: Double) {
        // 只在基线状态更新基线
        guard currentState == .baseline else { return }
        
        baselineBuffer.append(value)
        if baselineBuffer.count > BaselineConfig.windowSize {
            baselineBuffer.removeFirst()
        }
        
        // 计算平均值作为基线（至少需要5个样本）
        if baselineBuffer.count >= 5 {
            let sum = baselineBuffer.reduce(0, +)
            dynamicBaseline = sum / Double(baselineBuffer.count)
        }
    }
}
