/**
 * 传感器服务封装
 * 提供传感器订阅、数据采集和预处理功能
 */

import { CONFIG, BUFFER_SIZE, VALIDATION_RANGE, ERROR_CODES } from './constants.js'

/**
 * 传感器数据类
 */
class SensorService {
  constructor() {
    // 加速度数据缓存
    this.accData = []
    // 陀螺仪数据缓存
    this.gyroData = []
    // 数据回调函数
    this.dataCallback = null
    // 是否正在监听
    this.isListening = false
    // 错误回调
    this.errorCallback = null
  }

  /**
   * 启动传感器监听
   * @param {function} onData 数据回调函数
   * @param {function} onError 错误回调函数
   */
  start(onData, onError) {
    if (this.isListening) {
      console.warn('传感器已在监听中')
      return
    }

    this.dataCallback = onData
    this.errorCallback = onError
    this.accData = []
    this.gyroData = []

    // 订阅加速度计
    global.sensor.subscribeAccelerometer({
      callback: (ret) => {
        this._onAccelerometerData(ret)
      },
      fail: (data, code) => {
        console.error('加速度计订阅失败:', code, data)
        this._handleSensorError('加速度计', code, data)
      },
    })

    // 订阅陀螺仪
    global.sensor.subscribeGyroscope({
      callback: (ret) => {
        this._onGyroscopeData(ret)
      },
      fail: (data, code) => {
        console.error('陀螺仪订阅失败:', code, data)
        this._handleSensorError('陀螺仪', code, data)
      },
    })

    this.isListening = true
    console.log('传感器监听已启动')
  }

  /**
   * 暂停传感器监听（保留数据缓存）
   */
  pause() {
    if (!this.isListening) {
      return
    }

    try {
      global.sensor.unsubscribeAccelerometer()
      global.sensor.unsubscribeGyroscope()
      this.isListening = false
      console.log('传感器已暂停（数据保留）')
    } catch (e) {
      console.error('暂停传感器失败:', e)
    }
  }

  /**
   * 恢复传感器监听（继续使用现有缓存）
   */
  resume() {
    if (this.isListening) {
      console.warn('传感器已在监听中')
      return
    }

    if (!this.dataCallback) {
      console.error('无法恢复：缺少回调函数')
      return
    }

    // 订阅加速度计
    global.sensor.subscribeAccelerometer({
      callback: (ret) => {
        this._onAccelerometerData(ret)
      },
      fail: (data, code) => {
        console.error('加速度计订阅失败:', code, data)
        this._handleSensorError('加速度计', code, data)
      },
    })

    // 订阅陀螺仪
    global.sensor.subscribeGyroscope({
      callback: (ret) => {
        this._onGyroscopeData(ret)
      },
      fail: (data, code) => {
        console.error('陀螺仪订阅失败:', code, data)
        this._handleSensorError('陀螺仪', code, data)
      },
    })

    this.isListening = true
    console.log('传感器监听已恢复')
  }

  /**
   * 停止传感器监听（清空数据缓存）
   */
  stop() {
    if (!this.isListening) {
      return
    }

    try {
      global.sensor.unsubscribeAccelerometer()
      global.sensor.unsubscribeGyroscope()
      this.isListening = false
      this.accData = []
      this.gyroData = []
      console.log('传感器监听已停止')
    } catch (e) {
      console.error('停止传感器失败:', e)
    }
  }

  /**
   * 处理加速度计数据
   * @private
   */
  _onAccelerometerData(ret) {
    const timestamp = Date.now()
    
    // 数据验证
    if (!this._validateAccData(ret)) {
      return
    }

    // 添加到缓存
    this.accData.push({
      x: ret.x,
      y: ret.y,
      z: ret.z,
      timestamp,
    })

    // 限制缓存大小
    if (this.accData.length > BUFFER_SIZE.SENSOR_DATA) {
      this.accData.shift()
    }

    // 处理融合数据
    this._processFusedData()
  }

  /**
   * 处理陀螺仪数据
   * @private
   */
  _onGyroscopeData(ret) {
    const timestamp = Date.now()
    
    // 数据验证
    if (!this._validateGyroData(ret)) {
      return
    }

    // 添加到缓存
    this.gyroData.push({
      x: ret.x,
      y: ret.y,
      z: ret.z,
      timestamp,
    })

    // 限制缓存大小
    if (this.gyroData.length > BUFFER_SIZE.SENSOR_DATA) {
      this.gyroData.shift()
    }

    // 处理融合数据
    this._processFusedData()
  }

  /**
   * 验证加速度计数据
   * @private
   */
  _validateAccData(data) {
    if (!data || typeof data !== 'object') {
      return false
    }

    const { x, y, z } = data

    // 检查是否为有效数字
    if (isNaN(x) || isNaN(y) || isNaN(z)) {
      return false
    }

    // 加速度范围检查：±200 m/s² (约±20g)
    const maxAcc = VALIDATION_RANGE.ACCELEROMETER_MAX
    if (Math.abs(x) > maxAcc || Math.abs(y) > maxAcc || Math.abs(z) > maxAcc) {
      return false
    }

    return true
  }

  /**
   * 验证陀螺仪数据
   * @private
   */
  _validateGyroData(data) {
    if (!data || typeof data !== 'object') {
      return false
    }

    const { x, y, z } = data

    // 检查是否为有效数字
    if (isNaN(x) || isNaN(y) || isNaN(z)) {
      return false
    }

    // 陀螺仪范围检查：±2000 °/s
    const maxGyro = VALIDATION_RANGE.GYROSCOPE_MAX
    if (Math.abs(x) > maxGyro || Math.abs(y) > maxGyro || Math.abs(z) > maxGyro) {
      return false
    }

    return true
  }

  /**
   * 处理融合数据并回调
   * @private
   */
  _processFusedData() {
    // 确保两个传感器都有数据
    if (this.accData.length === 0 || this.gyroData.length === 0) {
      return
    }

    // 获取最新数据
    const latestAcc = this.accData[this.accData.length - 1]
    const latestGyro = this.gyroData[this.gyroData.length - 1]

    // 应用滤波
    const filteredAcc = this._applyFilter(this.accData)
    const filteredGyro = this._applyFilter(this.gyroData)

    // 计算加速度向量模长
    const accMagnitude = Math.sqrt(
      filteredAcc.x ** 2 + filteredAcc.y ** 2 + filteredAcc.z ** 2
    )

    // 计算陀螺仪向量模长
    const gyroMagnitude = Math.sqrt(
      filteredGyro.x ** 2 + filteredGyro.y ** 2 + filteredGyro.z ** 2
    )

    // 融合数据
    const fusedData = {
      // 原始数据
      raw: {
        acc: latestAcc,
        gyro: latestGyro,
      },
      // 滤波后的数据
      filtered: {
        acc: filteredAcc,
        gyro: filteredGyro,
      },
      // 特征值
      features: {
        accMagnitude,
        gyroMagnitude,
      },
      timestamp: latestAcc.timestamp,
    }

    // 调用数据回调
    if (this.dataCallback) {
      this.dataCallback(fusedData)
    }
  }

  /**
   * 应用滑动窗口均值滤波
   * @private
   * @param {Array} dataArray 数据数组
   * @returns {object} 滤波后的数据
   */
  _applyFilter(dataArray) {
    const windowSize = Math.min(CONFIG.WINDOW_SIZE, dataArray.length)
    
    if (windowSize === 0) {
      return { x: 0, y: 0, z: 0 }
    }

    // 取最近N个数据点
    const window = dataArray.slice(-windowSize)

    // 计算均值
    const sum = window.reduce(
      (acc, cur) => ({
        x: acc.x + cur.x,
        y: acc.y + cur.y,
        z: acc.z + cur.z,
      }),
      { x: 0, y: 0, z: 0 }
    )

    return {
      x: sum.x / windowSize,
      y: sum.y / windowSize,
      z: sum.z / windowSize,
    }
  }

  /**
   * 处理传感器错误
   * @private
   */
  _handleSensorError(sensorName, code, data) {
    let errorMessage = ''
    
    switch (code) {
      case ERROR_CODES.SENSOR_NOT_SUPPORTED:
        errorMessage = `设备不支持${sensorName}`
        break
      case 201:
        errorMessage = `${sensorName}权限被拒绝`
        break
      case 1000:
        errorMessage = `${sensorName}系统繁忙`
        break
      default:
        errorMessage = `${sensorName}订阅失败 (code: ${code})`
    }
    
    if (this.errorCallback) {
      this.errorCallback({
        message: errorMessage,
        code,
        sensorName,
        data,
      })
    }
  }

  /**
   * 获取原始数据缓存(用于调试)
   */
  getRawData() {
    return {
      acc: this.accData,
      gyro: this.gyroData,
    }
  }

  /**
   * 清空数据缓存
   */
  clearData() {
    this.accData = []
    this.gyroData = []
  }
}

// 导出单例
export default new SensorService()
