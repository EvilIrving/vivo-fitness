//
//  ActionListView.swift
//  fitness Watch App
//
//  动作列表页 - 应用入口，展示可选动作
//

import SwiftUI

struct ActionListView: View {
    @State private var selectedAction: Action?
    @State private var showHistory = false
    
    private let actions = Action.allActions
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    // 标题区
                    headerView
                    
                    // 动作列表
                    ForEach(actions) { action in
                        NavigationLink(value: action) {
                            ActionRowView(action: action)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // 历史入口
                    historyButton
                }
                .padding(.horizontal, 4)
            }
            .navigationDestination(for: Action.self) { action in
                RepsSettingView(action: action)
            }
            .navigationDestination(isPresented: $showHistory) {
                TrainingHistoryView()
            }
        }
    }
    
    // MARK: - 标题区
    private var headerView: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .foregroundColor(.blue)
            Text("健身计数")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 历史按钮
    private var historyButton: some View {
        Button {
            HapticManager.shared.vibrate(for: .buttonTap)
            showHistory = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.body)
                Text("历史")
                    .font(.footnote)
            }
            .foregroundColor(.gray)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 动作行视图
struct ActionRowView: View {
    let action: Action
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(action.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(action.category)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
    }
}

#Preview {
    ActionListView()
}
