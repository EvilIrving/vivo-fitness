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
    
    @State private var countdown: Int = AppConfig.countdownSeconds
    @State private var isCountingDown = true
    @State private var navigateToTraining = false
    @State private var timer: Timer?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            countdownView
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToTraining) {
            TrainingActiveView(action: action, targetReps: targetReps, currentSet: 1)
        }
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
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
        HapticManager.shared.vibrate(for: .countdownTick)
        
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
