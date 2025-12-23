//
//  StorageService.swift
//  fitness Watch App
//
//  数据存储服务 - 管理训练记录的持久化
//

import Foundation

class StorageService {
    static let shared = StorageService()
    
    private let recordsKey = "training_records"
    private let statsKey = "user_stats"
    
    private init() {}
    
    // MARK: - 保存训练记录
    func saveRecord(_ record: TrainingRecord) -> Bool {
        var records = getAllRecords()
        records.append(record)
        
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: recordsKey)
            
            // 更新统计
            updateStats(with: record)
            return true
        } catch {
            print("[StorageService] 保存失败: \(error)")
            return false
        }
    }
    
    // MARK: - 获取所有记录
    func getAllRecords() -> [TrainingRecord] {
        guard let data = UserDefaults.standard.data(forKey: recordsKey) else {
            return []
        }
        
        do {
            let records = try JSONDecoder().decode([TrainingRecord].self, from: data)
            return records
        } catch {
            print("[StorageService] 解码失败: \(error)")
            return []
        }
    }
    
    // MARK: - 按日期查询
    func getRecordsByDate(_ dateString: String) -> [TrainingRecord] {
        return getAllRecords().filter { $0.date == dateString }
    }
    
    // MARK: - 按动作类型查询
    func getRecordsByAction(_ actionCode: String) -> [TrainingRecord] {
        return getAllRecords().filter { $0.actionCode == actionCode }
    }
    
    // MARK: - 获取最近N条记录
    func getRecentRecords(_ count: Int) -> [TrainingRecord] {
        let records = getAllRecords()
        let sorted = records.sorted { $0.timestamp > $1.timestamp }
        return Array(sorted.prefix(count))
    }
    
    // MARK: - 删除记录
    func deleteRecord(_ recordId: String) -> Bool {
        var records = getAllRecords()
        let originalCount = records.count
        records.removeAll { $0.id == recordId }
        
        guard records.count != originalCount else { return false }
        
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: recordsKey)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - 获取记录详情
    func getRecord(by id: String) -> TrainingRecord? {
        return getAllRecords().first { $0.id == id }
    }
    
    // MARK: - 用户统计
    func getUserStats() -> UserStats {
        guard let data = UserDefaults.standard.data(forKey: statsKey) else {
            return .empty
        }
        
        do {
            return try JSONDecoder().decode(UserStats.self, from: data)
        } catch {
            return .empty
        }
    }
    
    private func updateStats(with record: TrainingRecord) {
        var stats = getUserStats()
        stats.totalWorkouts += 1
        stats.totalReps += record.totalReps
        stats.totalDuration += record.duration
        stats.lastWorkoutDate = record.date
        
        do {
            let data = try JSONEncoder().encode(stats)
            UserDefaults.standard.set(data, forKey: statsKey)
        } catch {
            print("[StorageService] 统计更新失败: \(error)")
        }
    }
    
    // MARK: - 清除所有数据（仅用于调试）
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: recordsKey)
        UserDefaults.standard.removeObject(forKey: statsKey)
    }
}
