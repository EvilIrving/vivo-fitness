//
//  MotionManager.swift
//  fitness Watch App
//
//  传感器数据管理器 - 处理加速度计和陀螺仪数据采集与滤波
//

import Foundation
import CoreMotion

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private var accBuffer: [SensorReading] = []
    private var gyroBuffer: [SensorReading] = []
    
    @Published var isMonitoring = false
    @Published var latestFusedData: FusedSensorData?
    
    var onDataUpdate: ((FusedSensorData) -> Void)?
    
    private let updateInterval: TimeInterval = 0.02  // 50 Hz
    
    init() {
        // 配置更新间隔
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.gyroUpdateInterval = updateInterval
        motionManager.deviceMotionUpdateInterval = updateInterval
    }
    
    // MARK: - 启动传感器监测
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        accBuffer.removeAll()
        gyroBuffer.removeAll()
        
        // 使用 DeviceMotion 获取融合数据（更准确）
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let self = self, let motion = motion else { return }
                self.processDeviceMotion(motion)
            }
            isMonitoring = true
        } else {
            // 降级：分别获取加速度和陀螺仪
            startSeparateSensors()
        }
    }
    
    // MARK: - 停止传感器监测
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        isMonitoring = false
    }
    
    // MARK: - 处理设备运动数据
    private func processDeviceMotion(_ motion: CMDeviceMotion) {
        let timestamp = motion.timestamp
        
        // 获取用户加速度（排除重力）
        let userAcc = motion.userAcceleration
        let accReading = SensorReading(
            x: userAcc.x * 9.8,  // 转换为 m/s²
            y: userAcc.y * 9.8,
            z: userAcc.z * 9.8,
            timestamp: timestamp
        )
        
        // 获取旋转速率
        let rotationRate = motion.rotationRate
        let gyroReading = SensorReading(
            x: rotationRate.x * 180 / .pi,  // 转换为度/秒
            y: rotationRate.y * 180 / .pi,
            z: rotationRate.z * 180 / .pi,
            timestamp: timestamp
        )
        
        // 验证数据有效性
        guard validateAccelerometerData(accReading),
              validateGyroscopeData(gyroReading) else {
            return
        }
        
        // 添加到缓冲区
        addToBuffer(acc: accReading, gyro: gyroReading)
        
        // 应用滤波并创建融合数据
        let filteredAcc = applyMovingAverageFilter(buffer: accBuffer, windowSize: AppConfig.windowSize)
        let filteredGyro = applyMovingAverageFilter(buffer: gyroBuffer, windowSize: AppConfig.windowSize)
        
        let fusedData = FusedSensorData(
            rawAcc: accReading,
            rawGyro: gyroReading,
            filteredAcc: filteredAcc,
            filteredGyro: filteredGyro,
            timestamp: timestamp
        )
        
        DispatchQueue.main.async {
            self.latestFusedData = fusedData
            self.onDataUpdate?(fusedData)
        }
    }
    
    // MARK: - 分别启动传感器（降级方案）
    private func startSeparateSensors() {
        var latestAcc: SensorReading?
        var latestGyro: SensorReading?
        
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let data = data else { return }
                latestAcc = SensorReading(
                    x: data.acceleration.x * 9.8,
                    y: data.acceleration.y * 9.8,
                    z: data.acceleration.z * 9.8,
                    timestamp: data.timestamp
                )
                self?.tryFuseData(acc: latestAcc, gyro: latestGyro)
            }
        }
        
        if motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
                guard let data = data else { return }
                latestGyro = SensorReading(
                    x: data.rotationRate.x * 180 / .pi,
                    y: data.rotationRate.y * 180 / .pi,
                    z: data.rotationRate.z * 180 / .pi,
                    timestamp: data.timestamp
                )
                self?.tryFuseData(acc: latestAcc, gyro: latestGyro)
            }
        }
        
        isMonitoring = true
    }
    
    private func tryFuseData(acc: SensorReading?, gyro: SensorReading?) {
        guard let acc = acc, let gyro = gyro else { return }
        
        guard validateAccelerometerData(acc), validateGyroscopeData(gyro) else { return }
        
        addToBuffer(acc: acc, gyro: gyro)
        
        let filteredAcc = applyMovingAverageFilter(buffer: accBuffer, windowSize: AppConfig.windowSize)
        let filteredGyro = applyMovingAverageFilter(buffer: gyroBuffer, windowSize: AppConfig.windowSize)
        
        let fusedData = FusedSensorData(
            rawAcc: acc,
            rawGyro: gyro,
            filteredAcc: filteredAcc,
            filteredGyro: filteredGyro,
            timestamp: acc.timestamp
        )
        
        DispatchQueue.main.async {
            self.latestFusedData = fusedData
            self.onDataUpdate?(fusedData)
        }
    }
    
    // MARK: - 缓冲区管理
    private func addToBuffer(acc: SensorReading, gyro: SensorReading) {
        accBuffer.append(acc)
        gyroBuffer.append(gyro)
        
        if accBuffer.count > AppConfig.sensorBufferSize {
            accBuffer.removeFirst()
        }
        if gyroBuffer.count > AppConfig.sensorBufferSize {
            gyroBuffer.removeFirst()
        }
    }
    
    // MARK: - 滑动窗口均值滤波
    private func applyMovingAverageFilter(buffer: [SensorReading], windowSize: Int) -> SensorReading {
        guard !buffer.isEmpty else {
            return .zero
        }
        
        let actualWindowSize = min(windowSize, buffer.count)
        let window = buffer.suffix(actualWindowSize)
        
        var sumX = 0.0
        var sumY = 0.0
        var sumZ = 0.0
        
        for reading in window {
            sumX += reading.x
            sumY += reading.y
            sumZ += reading.z
        }
        
        let count = Double(actualWindowSize)
        return SensorReading(
            x: sumX / count,
            y: sumY / count,
            z: sumZ / count,
            timestamp: buffer.last?.timestamp ?? 0
        )
    }
    
    // MARK: - 数据验证
    private func validateAccelerometerData(_ data: SensorReading) -> Bool {
        guard !data.x.isNaN, !data.y.isNaN, !data.z.isNaN else {
            return false
        }
        
        let maxAcc = ValidationRange.accelerometerMax
        guard abs(data.x) <= maxAcc,
              abs(data.y) <= maxAcc,
              abs(data.z) <= maxAcc else {
            return false
        }
        
        return true
    }
    
    private func validateGyroscopeData(_ data: SensorReading) -> Bool {
        guard !data.x.isNaN, !data.y.isNaN, !data.z.isNaN else {
            return false
        }
        
        let maxGyro = ValidationRange.gyroscopeMax
        guard abs(data.x) <= maxGyro,
              abs(data.y) <= maxGyro,
              abs(data.z) <= maxGyro else {
            return false
        }
        
        return true
    }
}
