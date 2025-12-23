//
//  Models.swift
//  fitness Watch App
//
//  核心数据模型定义
//

import Foundation
import Combine

// MARK: - 动作类型枚举
enum ActionCode: String, Codable, CaseIterable {
    case benchPress = "ACT_001"      // 杠铃卧推
    case chestFly = "ACT_002"        // 器械夹胸
    case dumbbellCurl = "ACT_003"    // 哑铃弯举
    
    var name: String {
        switch self {
        case .benchPress: return "杠铃卧推"
        case .chestFly: return "器械夹胸"
        case .dumbbellCurl: return "哑铃弯举"
        }
    }
    
    var category: String {
        switch self {
        case .benchPress, .chestFly: return "胸部"
        case .dumbbellCurl: return "手臂"
        }
    }
    
    var description: String {
        switch self {
        case .benchPress: return "上下直线推举运动"
        case .chestFly: return "水平面内双臂夹合"
        case .dumbbellCurl: return "前臂旋转运动"
        }
    }
}

// MARK: - 动作模型
struct Action: Identifiable, Hashable {
    let id: String
    let code: ActionCode
    
    var name: String { code.name }
    var category: String { code.category }
    var description: String { code.description }
    
    init(code: ActionCode) {
        self.id = code.rawValue
        self.code = code
    }
    
    static let allActions: [Action] = ActionCode.allCases.map { Action(code: $0) }
}

// MARK: - 传感器读数
struct SensorReading {
    var x: Double
    var y: Double
    var z: Double
    var timestamp: TimeInterval
    
    static let zero = SensorReading(x: 0, y: 0, z: 0, timestamp: 0)
    
    var magnitude: Double {
        sqrt(x * x + y * y + z * z)
    }
    
    var xyMagnitude: Double {
        sqrt(x * x + y * y)
    }
}

// MARK: - 融合传感器数据
struct FusedSensorData {
    var rawAcc: SensorReading
    var rawGyro: SensorReading
    var filteredAcc: SensorReading
    var filteredGyro: SensorReading
    var timestamp: TimeInterval
    
    var accMagnitude: Double { filteredAcc.magnitude }
    var gyroMagnitude: Double { filteredGyro.magnitude }
}

// MARK: - 动作检测状态（文档：去回周期检测）
enum DetectionState {
    case baseline       // 基线状态，等待运动开始
    case departing      // 去程：检测到离开基线，正在远离
    case peakZone       // 峰值区：到达运动极值附近
    case returning      // 回程：从峰值返回，正在接近基线
}

// MARK: - 动作检测参数配置（文档对应）
struct DetectionParams {
    let primaryAxis: PrimaryAxis
    let initialPeakThreshold: Double  // 初始峰值阈值（用于前几次动作）
    let minPeakRatio: Double          // 最小峰值比例（相对于学习到的平均峰值）
    let timeWindow: (min: Double, max: Double)  // 动作时长范围（秒）
    let baselineWindow: Double        // 基线判定范围
    let adaptiveEnabled: Bool         // 是否启用自适应阈值
    
    enum PrimaryAxis {
        case x, y, z           // 加速度轴
        case xyCombined        // XY平面组合
        case magnitude         // 加速度向量模长
        case gyroX, gyroY, gyroZ  // 陀螺仪轴
    }
}

// MARK: - 自适应阈值配置常量
struct AdaptiveConfig {
    static let learningCount = 3           // 学习前 N 次动作
    static let minPeakRatio = 0.4          // 最低峰值比例（平均值的 40%）
    static let absoluteMinThreshold = 0.5  // 绝对最低阈值（m/s²）
    static let decayFactor = 0.95          // 每次动作后的衰减因子
    static let maxHistory = 10             // 保留最近 N 次峰值
}

// MARK: - 基线配置常量
struct BaselineConfig {
    static let windowSize = 20         // 基线计算窗口
    static let updateInterval = 100    // 更新间隔（ms）
    static let stableThreshold = 0.2   // 稳定判定阈值
}

// MARK: - 动作检测参数配置表（文档对应）
extension ActionCode {
    var detectionParams: DetectionParams {
        switch self {
        case .benchPress:
            // ACT_001: 杠铃卧推 - Z轴加速度（上下运动）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.5,     // 初始阈值 m/s²
                minPeakRatio: 0.4,             // 力竭时最低接受平均值的 40%
                timeWindow: (min: 0.6, max: 3.0),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .chestFly:
            // ACT_002: 器械夹胸 - XY平面组合（水平运动）
            return DetectionParams(
                primaryAxis: .xyCombined,
                initialPeakThreshold: 1.2,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.8, max: 3.5),
                baselineWindow: 0.25,
                adaptiveEnabled: true
            )
        case .dumbbellCurl:
            // ACT_003: 哑铃弯举 - Y轴陀螺仪（前臂旋转）
            return DetectionParams(
                primaryAxis: .gyroY,
                initialPeakThreshold: 50,      // 初始阈值 °/s
                minPeakRatio: 0.35,            // 弯举幅度衰减更明显
                timeWindow: (min: 0.4, max: 2.5),
                baselineWindow: 10,            // 角速度基线范围 °/s
                adaptiveEnabled: true
            )
        }
    }
}

// MARK: - 组次数据
struct SetData: Codable, Identifiable {
    var id: UUID = UUID()
    var setNumber: Int
    var targetReps: Int
    var actualReps: Int
    var startTime: Date
    var endTime: Date?
    
    var setDuration: Int {
        guard let endTime = endTime else { return 0 }
        return Int(endTime.timeIntervalSince(startTime))
    }
}

// MARK: - 训练记录
struct TrainingRecord: Codable, Identifiable {
    var id: String
    var actionCode: String
    var actionName: String
    var date: String
    var timestamp: Date
    var sets: [SetData]
    
    var totalReps: Int {
        sets.reduce(0) { $0 + $1.actualReps }
    }
    
    var duration: Int {
        sets.reduce(0) { $0 + $1.setDuration }
    }
    
    var setsCount: Int {
        sets.count
    }
    
    init(actionCode: ActionCode, sets: [SetData]) {
        self.id = Self.generateRecordId()
        self.actionCode = actionCode.rawValue
        self.actionName = actionCode.name
        self.timestamp = Date()
        self.date = Self.formatDate(Date())
        self.sets = sets
    }
    
    static func generateRecordId() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: Date())
        let random = String(format: "%03d", Int.random(in: 0...999))
        return "rec_\(dateStr)_\(random)"
    }
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 用户统计
struct UserStats: Codable {
    var totalWorkouts: Int = 0
    var totalReps: Int = 0
    var totalDuration: Int = 0
    var lastWorkoutDate: String = ""
    
    static let empty = UserStats()
}

// MARK: - 当前训练会话
@MainActor
class TrainingSession: ObservableObject {
    @Published var actionCode: ActionCode
    @Published var actionName: String
    @Published var currentSet: Int = 1
    @Published var targetReps: Int = 12
    @Published var actualReps: Int = 0
    @Published var sets: [SetData] = []
    @Published var isTraining: Bool = false
    @Published var startTime: Date?
    
    init(action: Action, targetReps: Int = 12) {
        self.actionCode = action.code
        self.actionName = action.name
        self.targetReps = targetReps
    }
    
    func startNewSet() {
        actualReps = 0
        startTime = Date()
        isTraining = true
    }
    
    func completeSet() {
        let setData = SetData(
            setNumber: currentSet,
            targetReps: targetReps,
            actualReps: actualReps,
            startTime: startTime ?? Date(),
            endTime: Date()
        )
        sets.append(setData)
        isTraining = false
    }
    
    func nextSet() {
        currentSet += 1
        actualReps = 0
    }
    
    func incrementCount() {
        actualReps += 1
    }
    
    func toRecord() -> TrainingRecord {
        return TrainingRecord(actionCode: actionCode, sets: sets)
    }
}

// MARK: - 状态转换阈值比例（文档对应）
struct StateTransitionRatios {
    static let departureStart = 0.5    // 离开基线阈值 = threshold * 0.5
    static let peakFallback = 0.85     // 峰值回落判定 = peakValue * 0.85
    static let returnConfirm = 0.6     // 确认回程 = peakValue * 0.6
}

// MARK: - 配置常量
struct AppConfig {
    static let windowSize = 5
    static let sensorBufferSize = 100
    static let recognitionBufferSize = 50
    static let defaultTargetReps = 12
    static let maxTargetReps = 50
    static let minTargetReps = 1
    static let sensorStartDelay: TimeInterval = 1.0
    static let setCompleteDelay: TimeInterval = 1.5
    static let toastDisplayDelay: TimeInterval = 0.5
    static let countdownSeconds = 3
}

// MARK: - 验证范围
struct ValidationRange {
    static let accelerometerMax: Double = 200  // ±200 m/s² (约±20g)
    static let gyroscopeMax: Double = 2000     // ±2000 °/s
}
