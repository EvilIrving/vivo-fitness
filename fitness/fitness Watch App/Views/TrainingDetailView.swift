//
//  TrainingDetailView.swift
//  fitness Watch App
//
//  训练详情页 - 展示单次训练的详细信息
//

import SwiftUI

struct TrainingDetailView: View {
    let recordId: String
    
    @State private var record: TrainingRecord?
    @State private var isLoading = true
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            if isLoading {
                loadingView
            } else if let record = record {
                VStack(spacing: 12) {
                    // 训练概览
                    overviewCard(record)
                    
                    // 组次详情
                    setsDetail(record)
                }
                .padding(.horizontal, 4)
            } else {
                errorView
            }
        }
        .navigationTitle("训练详情")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadRecord()
        }
    }
    
    // MARK: - 加载中
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .frame(height: 150)
    }
    
    // MARK: - 错误视图
    private var errorView: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "exclamationmark.circle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("记录不存在")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("返回") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .frame(height: 180)
    }
    
    // MARK: - 概览卡片
    private func overviewCard(_ record: TrainingRecord) -> some View {
        VStack(spacing: 8) {
            Text(record.actionName)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(record.date)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical, 4)
            
            HStack(spacing: 0) {
                // 总次数
                VStack(spacing: 2) {
                    Text("\(record.totalReps)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("总次数")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // 分隔线
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 36)
                
                // 组数
                VStack(spacing: 2) {
                    Text("\(record.setsCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("组数")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 组次详情
    private func setsDetail(_ record: TrainingRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("组次详情")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            ForEach(record.sets) { set in
                SetDetailRow(set: set)
            }
        }
    }
    
    // MARK: - 加载记录
    private func loadRecord() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            record = StorageService.shared.getRecord(by: recordId)
            isLoading = false
        }
    }
}

// MARK: - 组详情行
struct SetDetailRow: View {
    let set: SetData
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: set.startTime)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("第 \(set.setNumber) 组")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(set.actualReps) / \(set.targetReps)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(set.actualReps >= set.targetReps ? .green : .orange)
                
                if set.setDuration > 0 {
                    Text("用时 \(set.setDuration)s")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
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
        TrainingDetailView(recordId: "test_record")
    }
}
