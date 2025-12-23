//
//  Models.swift
//  fitness Watch App
//
//  核心数据模型定义
//

import Foundation
import Combine

// MARK: - 动作分类
enum ActionCategory: String, CaseIterable {
    case chest = "胸部"
    case back = "背部"
    case shoulder = "肩部"
    case biceps = "肱二头肌"
    case triceps = "肱三头肌"
    case core = "核心"
    
    var displayOrder: Int {
        switch self {
        case .chest: return 0
        case .back: return 1
        case .shoulder: return 2
        case .biceps: return 3
        case .triceps: return 4
        case .core: return 5
        }
    }
}

// MARK: - 动作类型枚举
enum ActionCode: String, Codable, CaseIterable {
    // 胸部 (5个)
    case barbellBenchPress = "ACT_001"       // 杠铃卧推
    case inclineBarbellPress = "ACT_002"     // 上斜杠铃卧推
    case dumbbellBenchPress = "ACT_003"      // 哑铃卧推
    case machineChestPress = "ACT_004"       // 器械推胸
    case parallelBarDips = "ACT_005"         // 双杠臂屈伸
    
    // 背部 (4个)
    case latPulldown = "ACT_006"             // 高位下拉
    case seatedRow = "ACT_007"               // 坐姿划船
    case barbellRow = "ACT_008"              // 杠铃划船
    case dumbbellSingleArmRow = "ACT_009"    // 哑铃单臂划船
    
    // 肩部 (4个)
    case dumbbellShoulderPress = "ACT_010"   // 哑铃推举
    case barbellShoulderPress = "ACT_011"    // 杠铃推举
    case lateralRaise = "ACT_012"            // 侧平举
    case frontRaise = "ACT_013"              // 前平举
    
    // 肱二头肌 (4个)
    case dumbbellCurl = "ACT_014"            // 哑铃弯举
    case barbellCurl = "ACT_015"             // 杠铃弯举
    case hammerCurl = "ACT_016"              // 锤式弯举
    case concentrationCurl = "ACT_017"       // 集中弯举
    
    // 肱三头肌 (4个)
    case cablePushdown = "ACT_018"           // 绳索下压
    case overheadTricepsExt = "ACT_019"      // 哑铃颈后臂屈伸
    case closeGripBenchPress = "ACT_020"     // 窄距杠铃卧推
    case tricepsDips = "ACT_021"             // 双杠臂屈伸（侧重三头）
    
    // 核心 (1个)
    case crunch = "ACT_022"                  // 卷腹
    
    var name: String {
        switch self {
        // 胸部
        case .barbellBenchPress: return "杠铃卧推"
        case .inclineBarbellPress: return "上斜杠铃卧推"
        case .dumbbellBenchPress: return "哑铃卧推"
        case .machineChestPress: return "器械推胸"
        case .parallelBarDips: return "双杠臂屈伸"
        // 背部
        case .latPulldown: return "高位下拉"
        case .seatedRow: return "坐姿划船"
        case .barbellRow: return "杠铃划船"
        case .dumbbellSingleArmRow: return "哑铃单臂划船"
        // 肩部
        case .dumbbellShoulderPress: return "哑铃推举"
        case .barbellShoulderPress: return "杠铃推举"
        case .lateralRaise: return "侧平举"
        case .frontRaise: return "前平举"
        // 肱二头肌
        case .dumbbellCurl: return "哑铃弯举"
        case .barbellCurl: return "杠铃弯举"
        case .hammerCurl: return "锤式弯举"
        case .concentrationCurl: return "集中弯举"
        // 肱三头肌
        case .cablePushdown: return "绳索下压"
        case .overheadTricepsExt: return "哑铃颈后臂屈伸"
        case .closeGripBenchPress: return "窄距杠铃卧推"
        case .tricepsDips: return "双杠臂屈伸（三头）"
        // 核心
        case .crunch: return "卷腹"
        }
    }
    
    var category: ActionCategory {
        switch self {
        case .barbellBenchPress, .inclineBarbellPress, .dumbbellBenchPress, 
             .machineChestPress, .parallelBarDips:
            return .chest
        case .latPulldown, .seatedRow, .barbellRow, .dumbbellSingleArmRow:
            return .back
        case .dumbbellShoulderPress, .barbellShoulderPress, .lateralRaise, .frontRaise:
            return .shoulder
        case .dumbbellCurl, .barbellCurl, .hammerCurl, .concentrationCurl:
            return .biceps
        case .cablePushdown, .overheadTricepsExt, .closeGripBenchPress, .tricepsDips:
            return .triceps
        case .crunch:
            return .core
        }
    }
    
    var categoryName: String {
        category.rawValue
    }
    
    var description: String {
        switch self {
        // 胸部
        case .barbellBenchPress: return "上下直线推举运动"
        case .inclineBarbellPress: return "上斜角度推举运动"
        case .dumbbellBenchPress: return "哑铃平躺推举"
        case .machineChestPress: return "固定轨迹推胸"
        case .parallelBarDips: return "身体上下移动"
        // 背部
        case .latPulldown: return "从上往下拉动"
        case .seatedRow: return "水平划船拉动"
        case .barbellRow: return "俯身划船运动"
        case .dumbbellSingleArmRow: return "单臂划船运动"
        // 肩部
        case .dumbbellShoulderPress: return "哑铃过头推举"
        case .barbellShoulderPress: return "杠铃过头推举"
        case .lateralRaise: return "侧向抬臂运动"
        case .frontRaise: return "前向抬臂运动"
        // 肱二头肌
        case .dumbbellCurl: return "前臂旋转弯举"
        case .barbellCurl: return "杠铃弯举运动"
        case .hammerCurl: return "锤式握法弯举"
        case .concentrationCurl: return "孤立集中弯举"
        // 肱三头肌
        case .cablePushdown: return "绳索向下按压"
        case .overheadTricepsExt: return "颈后伸展运动"
        case .closeGripBenchPress: return "窄握距卧推"
        case .tricepsDips: return "侧重三头的臂屈伸"
        // 核心
        case .crunch: return "上背卷起运动"
        }
    }
}

// MARK: - 动作模型
struct Action: Identifiable, Hashable {
    let id: String
    let code: ActionCode
    
    var name: String { code.name }
    var category: ActionCategory { code.category }
    var categoryName: String { code.categoryName }
    var description: String { code.description }
    
    init(code: ActionCode) {
        self.id = code.rawValue
        self.code = code
    }
    
    static let allActions: [Action] = ActionCode.allCases.map { Action(code: $0) }
    
    /// 按分组返回动作列表
    static var groupedActions: [(category: ActionCategory, actions: [Action])] {
        let grouped = Dictionary(grouping: allActions) { $0.category }
        return ActionCategory.allCases
            .filter { grouped[$0] != nil }
            .sorted { $0.displayOrder < $1.displayOrder }
            .map { (category: $0, actions: grouped[$0]!) }
    }
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
        // MARK: 胸部动作 - 主要是Z轴上下运动
        case .barbellBenchPress:
            // 杠铃卧推 - Z轴加速度（上下推举）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.5,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.6, max: 3.0),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .inclineBarbellPress:
            // 上斜杠铃卧推 - Z轴（上斜角度推举）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.4,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.6, max: 3.0),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .dumbbellBenchPress:
            // 哑铃卧推 - Z轴（上下推举）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.3,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.6, max: 3.0),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .machineChestPress:
            // 器械推胸 - Z轴（固定轨迹）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.2,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.6, max: 3.0),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .parallelBarDips:
            // 双杠臂屈伸 - Z轴（身体上下）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.8,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.6, max: 3.0),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
            
        // MARK: 背部动作 - 拉拽运动
        case .latPulldown:
            // 高位下拉 - Y轴（从上往下拉）
            return DetectionParams(
                primaryAxis: .y,
                initialPeakThreshold: 1.5,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.6, max: 3.0),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .seatedRow:
            // 坐姿划船 - Y轴（水平拉动）
            return DetectionParams(
                primaryAxis: .y,
                initialPeakThreshold: 1.3,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.6, max: 3.0),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .barbellRow:
            // 杠铃划船 - Y轴（俯身拉动）
            return DetectionParams(
                primaryAxis: .y,
                initialPeakThreshold: 1.4,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.6, max: 3.0),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .dumbbellSingleArmRow:
            // 哑铃单臂划船 - Y轴（单臂拉动）
            return DetectionParams(
                primaryAxis: .y,
                initialPeakThreshold: 1.3,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.5, max: 2.5),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
            
        // MARK: 肩部动作 - 推举/抬臂
        case .dumbbellShoulderPress:
            // 哑铃推举 - Z轴（过头推举）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.5,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.5, max: 2.5),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .barbellShoulderPress:
            // 杠铃推举 - Z轴（过头推举）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.6,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.5, max: 2.5),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .lateralRaise:
            // 侧平举 - X轴（侧向抬臂）
            return DetectionParams(
                primaryAxis: .x,
                initialPeakThreshold: 1.2,
                minPeakRatio: 0.35,
                timeWindow: (min: 0.5, max: 3.0),
                baselineWindow: 0.25,
                adaptiveEnabled: true
            )
        case .frontRaise:
            // 前平举 - Y轴（前向抬臂）
            return DetectionParams(
                primaryAxis: .y,
                initialPeakThreshold: 1.2,
                minPeakRatio: 0.35,
                timeWindow: (min: 0.5, max: 3.0),
                baselineWindow: 0.25,
                adaptiveEnabled: true
            )
            
        // MARK: 肱二头肌动作 - 弯举
        case .dumbbellCurl:
            // 哑铃弯举 - 陀蝲仪 Y轴（前臂旋转）
            return DetectionParams(
                primaryAxis: .gyroY,
                initialPeakThreshold: 50,
                minPeakRatio: 0.35,
                timeWindow: (min: 0.4, max: 2.5),
                baselineWindow: 10,
                adaptiveEnabled: true
            )
        case .barbellCurl:
            // 杠铃弯举 - 陀蝲仪 Y轴（前臂旋转）
            return DetectionParams(
                primaryAxis: .gyroY,
                initialPeakThreshold: 45,
                minPeakRatio: 0.35,
                timeWindow: (min: 0.4, max: 2.5),
                baselineWindow: 10,
                adaptiveEnabled: true
            )
        case .hammerCurl:
            // 锤式弯举 - 陀蝲仪 Y轴
            return DetectionParams(
                primaryAxis: .gyroY,
                initialPeakThreshold: 45,
                minPeakRatio: 0.35,
                timeWindow: (min: 0.4, max: 2.5),
                baselineWindow: 10,
                adaptiveEnabled: true
            )
        case .concentrationCurl:
            // 集中弯举 - 陀蝲仪 Y轴（孤立弯举）
            return DetectionParams(
                primaryAxis: .gyroY,
                initialPeakThreshold: 40,
                minPeakRatio: 0.35,
                timeWindow: (min: 0.5, max: 3.0),
                baselineWindow: 10,
                adaptiveEnabled: true
            )
            
        // MARK: 肱三头肌动作 - 伸展/下压
        case .cablePushdown:
            // 绳索下压 - Z轴（向下按压）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.3,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.4, max: 2.5),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .overheadTricepsExt:
            // 哑铃颈后臂屈伸 - 陀蝲仪 X轴（颈后伸展）
            return DetectionParams(
                primaryAxis: .gyroX,
                initialPeakThreshold: 50,
                minPeakRatio: 0.35,
                timeWindow: (min: 0.5, max: 3.0),
                baselineWindow: 10,
                adaptiveEnabled: true
            )
        case .closeGripBenchPress:
            // 窄距杠铃卧推 - Z轴（上下推举）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.4,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.6, max: 3.0),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
        case .tricepsDips:
            // 双杠臂屈伸（三头） - Z轴（身体上下）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.7,
                minPeakRatio: 0.4,
                timeWindow: (min: 0.6, max: 3.0),
                baselineWindow: 0.3,
                adaptiveEnabled: true
            )
            
        // MARK: 核心动作
        case .crunch:
            // 卷腹 - Z轴（上背卷起）
            return DetectionParams(
                primaryAxis: .z,
                initialPeakThreshold: 1.0,
                minPeakRatio: 0.35,
                timeWindow: (min: 0.5, max: 3.0),
                baselineWindow: 0.3,
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
