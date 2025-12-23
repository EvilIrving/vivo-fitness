//
//  TestModeView.swift
//  fitness Watch App
//
//  测试模式视图 - 用于在模拟器中验证动作识别功能
//

import SwiftUI

struct TestModeView: View {
    @StateObject private var motionManager = MotionManager()
    @StateObject private var recognizer: ActionRecognizer
    
    @State private var selectedAction: ActionCode = .barbellBenchPress
    @State private var isRunning = false
    @State private var recognizedCount = 0
    @State private var lastPeakValue: Double = 0
    @State private var lastDuration: Double = 0
    @State private var sensorStatus: String = "待启动"
    @State private var currentAccValue: Double = 0
    @State private var currentGyroValue: Double = 0
    
    init() {
        _recognizer = StateObject(wrappedValue: ActionRecognizer(actionCode: .barbellBenchPress))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 标题
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.orange)
                    Text("模拟测试")
                        .font(.headline)
                }
                .padding(.bottom, 4)
                
                // 动作选择器
                Picker("选择动作", selection: $selectedAction) {
                    ForEach(ActionCode.allCases, id: \.self) { action in
                        Text(action.name).tag(action)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 60)
                .onChange(of: selectedAction) { _, newValue in
                    recognizer.updateAction(newValue)
                    recognizedCount = 0
                }
                
                // 状态显示
                VStack(spacing: 6) {
                    StatusRow(label: "状态", value: sensorStatus, color: isRunning ? .green : .gray)
                    StatusRow(label: "已识别", value: "\(recognizedCount) 次", color: .blue)
                    StatusRow(label: "加速度", value: String(format: "%.2f m/s²", currentAccValue), color: .cyan)
                    StatusRow(label: "陀螺仪", value: String(format: "%.1f °/s", currentGyroValue), color: .purple)
                }
                .padding(.vertical, 8)
                
                // 最近动作信息
                if lastDuration > 0 {
                    VStack(spacing: 4) {
                        Text("最近一次动作")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        HStack {
                            VStack {
                                Text(String(format: "%.2fs", lastDuration))
                                    .font(.system(.body, design: .monospaced))
                                Text("时长")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Divider()
                                .frame(height: 30)
                            VStack {
                                Text(String(format: "%.2f", lastPeakValue))
                                    .font(.system(.body, design: .monospaced))
                                Text("峰值")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                }
                
                // 控制按钮
                Button(action: toggleTest) {
                    HStack {
                        Image(systemName: isRunning ? "stop.fill" : "play.fill")
                        Text(isRunning ? "停止测试" : "开始测试")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(isRunning ? .red : .green)
            }
            .padding()
        }
        .navigationTitle("测试模式")
        .onDisappear {
            stopTest()
        }
    }
    
    private func toggleTest() {
        if isRunning {
            stopTest()
        } else {
            startTest()
        }
    }
    
    private func startTest() {
        recognizer.reset()
        recognizedCount = 0
        lastDuration = 0
        lastPeakValue = 0
        
        // 设置数据回调
        motionManager.onDataUpdate = { fusedData in
            // 更新显示值
            currentAccValue = fusedData.filteredAcc.magnitude
            currentGyroValue = fusedData.filteredGyro.magnitude
            
            // 传递给识别器
            recognizer.processData(fusedData)
        }
        
        // 设置动作完成回调
        recognizer.onActionComplete = { duration, peakValue in
            recognizedCount += 1
            lastDuration = duration
            lastPeakValue = peakValue
            
            // 震动反馈
            WKInterfaceDevice.current().play(.success)
        }
        
        // 启动模拟
        motionManager.startSimulation(action: selectedAction, continuous: true)
        
        isRunning = true
        sensorStatus = "模拟运行中"
    }
    
    private func stopTest() {
        motionManager.stopMonitoring()
        isRunning = false
        sensorStatus = "已停止"
        currentAccValue = 0
        currentGyroValue = 0
    }
}

// MARK: - 状态行组件
struct StatusRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

// MARK: - 预览
#Preview {
    NavigationStack {
        TestModeView()
    }
}
