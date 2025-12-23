//
//  TrainingActiveView.swift
//  fitness Watch App
//
//  训练进行页 - 核心训练页面，实时计数
//

import SwiftUI

struct TrainingActiveView: View {
    let action: Action
    let targetReps: Int
    let currentSet: Int
    
    @StateObject private var motionManager = MotionManager()
    @StateObject private var recognizer: ActionRecognizer
    @StateObject private var session: TrainingSession
    
    @State private var currentCount: Int = 0
    @State private var isTraining: Bool = true
    @State private var navigateToComplete = false
    @State private var countColor: Color = .blue
    @State private var showInvalidDataAlert = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(action: Action, targetReps: Int, currentSet: Int) {
        self.action = action
        self.targetReps = targetReps
        self.currentSet = currentSet
        
        let recognizerInstance = ActionRecognizer(actionCode: action.code)
        let sessionInstance = TrainingSession(action: action, targetReps: targetReps)
        _recognizer = StateObject(wrappedValue: recognizerInstance)
        _session = StateObject(wrappedValue: sessionInstance)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部信息
            headerView
            
            Spacer()
            
            // 计数显示
            counterView
            
            Spacer()
            
            // 控制按钮
            controlsView
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            setupRecognizer()
            startTraining()
        }
        .onDisappear {
            motionManager.stopMonitoring()
        }
        .navigationDestination(isPresented: $navigateToComplete) {
            SetCompleteView(
                action: action,
                targetReps: targetReps,
                actualReps: currentCount,
                currentSet: currentSet,
                session: session
            )
        }
        .alert("训练已取消", isPresented: $showInvalidDataAlert) {
            Button("确定") {
                dismissToHome()
            }
        } message: {
            Text("未检测到有效动作数据")
        }
    }
    
    // MARK: - 顶部信息
    private var headerView: some View {
        HStack(spacing: 4) {
            Text(action.name)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("第 \(currentSet) 组")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.top, 8)
    }
    
    // MARK: - 计数显示
    private var counterView: some View {
        HStack(spacing: 4) {
            Text("\(currentCount)")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundColor(countColor)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: currentCount)
            
            Text("/")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text("\(targetReps)")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .baselineOffset(-8)
        }
    }
    

    
    // MARK: - 控制按钮
    private var controlsView: some View {
        Group {
            if isTraining {
                // 训练中：暂停按钮
                Button {
                    pauseTraining()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else {
                // 暂停中：继续和结束按钮
                HStack(spacing: 24) {
                    Button {
                        resumeTraining()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        stopTraining()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - 设置识别器
    private func setupRecognizer() {
        session.currentSet = currentSet
        session.targetReps = targetReps
        
        recognizer.onActionComplete = { [self] duration, peakValue in
            DispatchQueue.main.async {
                self.currentCount += 1
                self.session.actualReps = self.currentCount
                HapticManager.shared.vibrate(for: .repComplete)
                
                // 检查是否达到目标
                if self.currentCount >= self.targetReps {
                    self.onTargetReached()
                }
            }
        }
    }
    
    // MARK: - 开始训练
    private func startTraining() {
        session.startNewSet()
        countColor = .blue
        
        // 延迟启动传感器
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.sensorStartDelay) {
            motionManager.onDataUpdate = { [weak recognizer] data in
                recognizer?.processData(data)
            }
            motionManager.startMonitoring()
        }
    }
    
    // MARK: - 暂停训练
    private func pauseTraining() {
        isTraining = false
        countColor = .orange
        motionManager.stopMonitoring()
        HapticManager.shared.vibrate(for: .pause)
    }
    
    // MARK: - 恢复训练
    private func resumeTraining() {
        isTraining = true
        countColor = .blue
        motionManager.startMonitoring()
        HapticManager.shared.vibrate(for: .resume)
    }
    
    // MARK: - 停止训练
    private func stopTraining() {
        motionManager.stopMonitoring()
        session.actualReps = currentCount
        session.completeSet()
        
        if currentCount > 0 {
            // 有有效数据，跳转到结果页面
            navigateToComplete = true
        } else {
            // 无有效数据，提示用户并返回主页
            showInvalidDataAlert = true
        }
    }
    
    // MARK: - 返回主页
    private func dismissToHome() {
        // 通过多次 dismiss 返回首页
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
        }
    }
    
    // MARK: - 达到目标
    private func onTargetReached() {
        countColor = .green
        motionManager.stopMonitoring()
        session.actualReps = currentCount
        session.completeSet()
        HapticManager.shared.vibrate(for: .targetReached)
        
        // 延迟跳转完成页
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.setCompleteDelay) {
            navigateToComplete = true
        }
    }
}

#Preview {
    NavigationStack {
        TrainingActiveView(action: Action(code: .barbellBenchPress), targetReps: 12, currentSet: 1)
    }
}
