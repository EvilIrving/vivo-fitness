//
//  RepsSettingView.swift
//  fitness Watch App
//
//  次数设置页 - 设置目标次数
//

import SwiftUI

struct RepsSettingView: View {
    let action: Action
    
    @State private var targetReps: Int = AppConfig.defaultTargetReps
    @State private var navigateToTraining = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 动作名称
            Text(action.name)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            Spacer()
            
            // 目标次数显示
            VStack(spacing: 4) {
                Text("\(targetReps)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("目标次数")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 控制按钮
            HStack(spacing: 16) {
                // 减少按钮
                Button {
                    if targetReps > AppConfig.minTargetReps {
                        targetReps -= 1
                        HapticManager.shared.vibrate(for: .buttonTap)
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // 确认按钮
                Button {
                    HapticManager.shared.vibrate(for: .buttonTap)
                    navigateToTraining = true
                } label: {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // 增加按钮
                Button {
                    if targetReps < AppConfig.maxTargetReps {
                        targetReps += 1
                        HapticManager.shared.vibrate(for: .buttonTap)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 16)
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $navigateToTraining) {
            TrainingReadyView(action: action, targetReps: targetReps)
        }
        // 支持 Digital Crown 调整次数
        .focusable()
        .digitalCrownRotation(
            Binding(
                get: { Double(targetReps) },
                set: { targetReps = Int($0) }
            ),
            from: Double(AppConfig.minTargetReps),
            through: Double(AppConfig.maxTargetReps),
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
    }
}

#Preview {
    NavigationStack {
        RepsSettingView(action: Action(code: .barbellBenchPress))
    }
}
