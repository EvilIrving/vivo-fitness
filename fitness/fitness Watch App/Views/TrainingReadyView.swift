//
//  TrainingReadyView.swift
//  fitness Watch App
//
//  训练准备页 - 3秒倒计时
//

import SwiftUI

struct TrainingReadyView: View {
    let action: Action
    let targetReps: Int
    
    @State private var countdown: Int = 0
    @State private var isCountingDown = false
    @State private var navigateToTraining = false
    @State private var timer: Timer?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            if countdown == 0 {
                // 准备阶段
                prepareView
            } else {
                // 倒计时阶段
                countdownView
            }
        }
        .navigationBarBackButtonHidden(isCountingDown)
        .navigationDestination(isPresented: $navigateToTraining) {
            TrainingActiveView(action: action, targetReps: targetReps, currentSet: 1)
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - 准备阶段视图
    private var prepareView: some View {
        VStack(spacing: 0) {
            // 动作名称
            Text(action.name)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 16)
            
            Spacer()
            
            // 目标次数
            VStack(spacing: 4) {
                Text("\(targetReps)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                Text("次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 开始按钮
            Button {
                startCountdown()
            } label: {
                Image(systemName: "play.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - 倒计时视图
    private var countdownView: some View {
        VStack {
            Spacer()
            
            Text("\(countdown)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
                .transition(.scale.combined(with: .opacity))
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: countdown)
    }
    
    // MARK: - 开始倒计时
    private func startCountdown() {
        HapticManager.shared.vibrate(for: .buttonTap)
        countdown = AppConfig.countdownSeconds
        isCountingDown = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
                HapticManager.shared.vibrate(for: .countdownTick)
            } else {
                timer?.invalidate()
                HapticManager.shared.vibrate(for: .countdownEnd)
                
                // 延迟跳转
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    navigateToTraining = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrainingReadyView(action: Action(code: .benchPress), targetReps: 12)
    }
}
