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
    case shoulderPress = "ACT_004"   // 坐姿推肩
    case legPress = "ACT_005"        // 腿举
    
    var name: String {
        switch self {
        case .benchPress: return "杠铃卧推"
        case .chestFly: return "器械夹胸"
        case .dumbbellCurl: return "哑铃弯举"
        case .shoulderPress: return "坐姿推肩"
        case .legPress: return "腿举"
        }
    }
    
    var category: String {
        switch self {
        case .benchPress, .chestFly: return "胸部"
        case .dumbbellCurl: return "手臂"
        case .shoulderPress: return "肩部"
        case .legPress: return "腿部"
        }
    }
    
    var description: String {
        switch self {
        case .benchPress: return "上下直线推举运动"
        case .chestFly: return "水平面内双臂夹合"
        case .dumbbellCurl: return "前臂旋转运动"
        case .shoulderPress: return "垂直向上推举"
        case .legPress: return "下肢推蹬运动"
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

// MARK: - 动作识别状态
enum RecognitionState {
    case idle           // 静止状态，等待运动开始
    case motionStart    // 运动启动，检测到初始加速
    case inProgress     // 动作进行中，持续监测峰值
    case peakDetected   // 峰值检测成功，等待回落
    case returning      // 回归基线，准备确认动作完成
}

// MARK: - 识别参数配置
struct RecognitionParams {
    let primaryAxis: PrimaryAxis
    let secondaryAxis: SecondaryAxis?
    let peakThreshold: Double
    let gyroThreshold: Double
    let timeWindow: (min: Double, max: Double)
    let baselineRange: Double
    
    enum PrimaryAxis {
        case x, y, z, xyCombined
        case gyroX, gyroY, gyroZ
    }
    
    enum SecondaryAxis {
        case x, y, z
        case gyroX, gyroY, gyroZ
    }
}

// MARK: - 动作识别参数配置表
extension ActionCode {
    var recognitionParams: RecognitionParams {
        switch self {
        case .benchPress:
            return RecognitionParams(
                primaryAxis: .z,
                secondaryAxis: .gyroY,
                peakThreshold: 1.5,
                gyroThreshold: 30,
                timeWindow: (min: 0.8, max: 2.5),
                baselineRange: 0.5
            )
        case .chestFly:
            return RecognitionParams(
                primaryAxis: .xyCombined,
                secondaryAxis: .gyroZ,
                peakThreshold: 1.2,
                gyroThreshold: 45,
                timeWindow: (min: 1.0, max: 3.0),
                baselineRange: 0.4
            )
        case .dumbbellCurl:
            return RecognitionParams(
                primaryAxis: .gyroY,
                secondaryAxis: .x,
                peakThreshold: 0.8,
                gyroThreshold: 60,
                timeWindow: (min: 0.5, max: 2.0),
                baselineRange: 0.3
            )
        case .shoulderPress:
            return RecognitionParams(
                primaryAxis: .z,
                secondaryAxis: .gyroY,
                peakThreshold: 1.8,
                gyroThreshold: 35,
                timeWindow: (min: 0.8, max: 2.5),
                baselineRange: 0.6
            )
        case .legPress:
            return RecognitionParams(
                primaryAxis: .xyCombined,
                secondaryAxis: nil,
                peakThreshold: 0.8,
                gyroThreshold: 0,
                timeWindow: (min: 1.5, max: 4.0),
                baselineRange: 0.3
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

// MARK: - 阈值系数常量
struct ThresholdRatios {
    static let motionStart: Double = 0.5
    static let motionContinue: Double = 0.7
    static let peakDetected: Double = 0.6
    static let returning: Double = 0.5
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
