//
//  SetCompleteView.swift
//  fitness Watch App
//
//  组完成页 - 展示本组完成情况，选择继续或结束
//

import SwiftUI

struct SetCompleteView: View {
    let action: Action
    let targetReps: Int
    let actualReps: Int
    let currentSet: Int
    @ObservedObject var session: TrainingSession
    
    @State private var navigateToNextSet = false
    @State private var navigateToHome = false
    @State private var showToast = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 完成标识
            completeBadge
            
            Spacer()
            
            // 结果显示
            resultView
            
            Spacer()
            
            // 操作按钮
            actionsView
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToNextSet) {
            TrainingReadyView(action: action, targetReps: targetReps)
                .onAppear {
                    session.nextSet()
                }
        }
        .overlay {
            if showToast {
                toastView
            }
        }
        .onChange(of: navigateToHome) { _, newValue in
            if newValue {
                // 返回到根视图（这里使用 dismiss 链）
                // 在实际实现中可能需要使用 NavigationPath
            }
        }
    }
    
    // MARK: - 完成标识
    private var completeBadge: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
            
            Text(action.name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("第 \(currentSet) 组")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.top, 12)
    }
    
    // MARK: - 结果显示
    private var resultView: some View {
        VStack(spacing: 4) {
            Text("\(actualReps)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.green)
            
            Text("━━")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
            
            Text("\(targetReps)")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 操作按钮
    private var actionsView: some View {
        HStack(spacing: 32) {
            // 继续按钮
            VStack(spacing: 4) {
                Button {
                    HapticManager.shared.vibrate(for: .buttonTap)
                    navigateToNextSet = true
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                
                Text("继续")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 结束按钮
            VStack(spacing: 4) {
                Button {
                    finishTraining()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                
                Text("结束")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Toast 视图
    private var toastView: some View {
        VStack {
            Spacer()
            Text("训练记录已保存")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
                .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - 结束训练
    private func finishTraining() {
        HapticManager.shared.vibrate(for: .buttonTap)
        
        // 保存记录
        let record = session.toRecord()
        let success = StorageService.shared.saveRecord(record)
        
        if success {
            // 显示 Toast
            withAnimation {
                showToast = true
            }
            
            // 延迟返回首页
            DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.toastDisplayDelay) {
                // 通过多次 dismiss 返回首页
                // 在更复杂的实现中应使用 NavigationPath
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SetCompleteView(
            action: Action(code: .barbellBenchPress),
            targetReps: 12,
            actualReps: 12,
            currentSet: 1,
            session: TrainingSession(action: Action(code: .barbellBenchPress))
        )
    }
}
