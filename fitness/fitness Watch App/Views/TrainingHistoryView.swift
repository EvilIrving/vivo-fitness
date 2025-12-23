//
//  TrainingHistoryView.swift
//  fitness Watch App
//
//  训练历史页 - 展示历史训练记录和统计
//

import SwiftUI

struct TrainingHistoryView: View {
    @State private var records: [TrainingRecord] = []
    @State private var stats: UserStats = .empty
    @State private var isLoading = true
    @State private var selectedRecordId: String?
    @State private var showDeleteAlert = false
    @State private var recordToDelete: TrainingRecord?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 12) {
                Group {
                    if isLoading {
                        loadingView
                    } else if records.isEmpty {
                        emptyView
                    } else {
                        // 统计卡片
                        statsCard
                        
                        // 记录列表
                        recordsList
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("训练历史")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
        }
        .alert("删除记录", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let record = recordToDelete {
                    deleteRecord(record)
                }
            }
        } message: {
            if let record = recordToDelete {
                Text("确定要删除 \(record.actionName) 的训练记录吗？")
            }
        }
        .navigationDestination(item: $selectedRecordId) { recordId in
            TrainingDetailView(recordId: recordId)
        }
    }
    
    // MARK: - 加载中
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .padding()
            Text("加载中...")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(height: 150)
    }
    
    // MARK: - 空状态
    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("暂无训练记录")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("完成训练后会在这里显示")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .frame(height: 180)
    }
    
    // MARK: - 统计卡片
    private var statsCard: some View {
        HStack(spacing: 0) {
            // 训练次数
            VStack(spacing: 4) {
                Text("\(stats.totalWorkouts)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("训练次数")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            // 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 40)
            
            // 总计数
            VStack(spacing: 4) {
                Text("\(stats.totalReps)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("总计数")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 记录列表
    private var recordsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近训练")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            ForEach(records) { record in
                Button {
                    selectedRecordId = record.id
                } label: {
                    RecordRowView(record: record)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        recordToDelete = record
                        showDeleteAlert = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    // MARK: - 加载数据
    private func loadData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            records = StorageService.shared.getRecentRecords(20)
            stats = StorageService.shared.getUserStats()
            isLoading = false
        }
    }
    
    // MARK: - 删除记录
    private func deleteRecord(_ record: TrainingRecord) {
        if StorageService.shared.deleteRecord(record.id) {
            records.removeAll { $0.id == record.id }
            HapticManager.shared.vibrate(for: .buttonTap)
        }
    }
}

// MARK: - 记录行视图
struct RecordRowView: View {
    let record: TrainingRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.actionName)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text(record.date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("·")
                        .foregroundColor(.secondary)
                    Text("\(record.setsCount) 组")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(record.totalReps)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("次")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        TrainingHistoryView()
    }
}
