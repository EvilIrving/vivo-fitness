//
//  HapticManager.swift
//  fitness Watch App
//
//  震动反馈管理器 - 封装 WatchKit 触觉反馈
//

import Foundation
import WatchKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - 短震动
    func shortVibrate() {
        WKInterfaceDevice.current().play(.click)
    }
    
    // MARK: - 长震动（成功）
    func longVibrate() {
        WKInterfaceDevice.current().play(.success)
    }
    
    // MARK: - 开始震动
    func startVibrate() {
        WKInterfaceDevice.current().play(.start)
    }
    
    // MARK: - 停止震动
    func stopVibrate() {
        WKInterfaceDevice.current().play(.stop)
    }
    
    // MARK: - 通知震动
    func notificationVibrate() {
        WKInterfaceDevice.current().play(.notification)
    }
    
    // MARK: - 失败震动
    func failureVibrate() {
        WKInterfaceDevice.current().play(.failure)
    }
    
    // MARK: - 场景震动
    func vibrate(for trigger: VibrationTrigger) {
        switch trigger {
        case .buttonTap:
            shortVibrate()
        case .countdownTick:
            shortVibrate()
        case .countdownEnd:
            longVibrate()
        case .repComplete:
            shortVibrate()
        case .setComplete:
            longVibrate()
        case .pause:
            shortVibrate()
        case .resume:
            shortVibrate()
        case .targetReached:
            longVibrate()
        }
    }
}

// MARK: - 震动触发场景
enum VibrationTrigger {
    case buttonTap          // 按钮点击
    case countdownTick      // 倒计时每秒
    case countdownEnd       // 倒计时结束
    case repComplete        // 单次动作完成
    case setComplete        // 一组完成
    case pause              // 暂停训练
    case resume             // 恢复训练
    case targetReached      // 达到目标
}
