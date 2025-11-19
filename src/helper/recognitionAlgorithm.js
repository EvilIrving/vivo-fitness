/**
 * 动作识别算法实现
 * 基于峰值检测法的动作识别
 */

import { getRecognitionParams } from './actionConfig.js'

/**
 * 动作识别状态枚举
 */
const STATE = {
  IDLE: 'idle',               // 静止状态
  MOTION_START: 'motion_start',  // 运动启动
  MOTION_IN_PROGRESS: 'in_progress', // 动作进行中
  PEAK_DETECTED: 'peak_detected',    // 峰值检测
  RETURNING: 'returning',            // 回归基线
}

/**
 * 动作识别器类
 */
class RecognitionAlgorithm {
  constructor() {
    // 当前状态
    this.state = STATE.IDLE
    // 当前动作配置
    this.actionCode = null
    this.params = null
    // 数据缓存
    this.dataBuffer = []
    // 峰值记录
    this.peakValue = 0
    this.peakTime = 0
    // 动作开始时间
    this.motionStartTime = 0
    // 基线值
    this.baselineValue = 0
    // 计数回调
    this.onCountCallback = null
  }

  /**
   * 初始化识别器
   * @param {string} actionCode 动作编号
   * @param {function} onCount 计数回调函数
   */
  init(actionCode, onCount) {
    this.actionCode = actionCode
    this.params = getRecognitionParams(actionCode)
    this.onCountCallback = onCount
    this.reset()
    
    if (!this.params) {
      console.error('未找到动作识别参数:', actionCode)
      return false
    }
    
    console.log('识别器初始化成功:', actionCode, this.params)
    return true
  }

  /**
   * 重置识别器状态
   */
  reset() {
    this.state = STATE.IDLE
    this.dataBuffer = []
    this.peakValue = 0
    this.peakTime = 0
    this.motionStartTime = 0
    this.baselineValue = 0
  }

  /**
   * 处理传感器数据
   * @param {object} fusedData 融合后的传感器数据
   */
  process(fusedData) {
    if (!this.params) {
      return
    }

    // 添加到缓冲区
    this.dataBuffer.push(fusedData)
    
    // 限制缓冲区大小(最近50个数据点)
    if (this.dataBuffer.length > 50) {
      this.dataBuffer.shift()
    }

    // 提取主要监测值
    const value = this._extractPrimaryValue(fusedData)
    const secondaryValue = this._extractSecondaryValue(fusedData)
    const timestamp = fusedData.timestamp

    // 状态机处理
    switch (this.state) {
      case STATE.IDLE:
        this._handleIdleState(value, secondaryValue, timestamp)
        break
      
      case STATE.MOTION_START:
        this._handleMotionStartState(value, secondaryValue, timestamp)
        break
      
      case STATE.MOTION_IN_PROGRESS:
        this._handleInProgressState(value, secondaryValue, timestamp)
        break
      
      case STATE.PEAK_DETECTED:
        this._handlePeakDetectedState(value, secondaryValue, timestamp)
        break
      
      case STATE.RETURNING:
        this._handleReturningState(value, secondaryValue, timestamp)
        break
    }
  }

  /**
   * 提取主要监测轴的值
   * @private
   */
  _extractPrimaryValue(data) {
    const axis = this.params.primaryAxis
    const acc = data.filtered.acc
    const gyro = data.filtered.gyro

    switch (axis) {
      case 'x':
        return Math.abs(acc.x)
      case 'y':
        return Math.abs(acc.y)
      case 'z':
        return Math.abs(acc.z)
      case 'xy_combined':
        return Math.sqrt(acc.x ** 2 + acc.y ** 2)
      case 'gyro_x':
        return Math.abs(gyro.x)
      case 'gyro_y':
        return Math.abs(gyro.y)
      case 'gyro_z':
        return Math.abs(gyro.z)
      default:
        return data.features.accMagnitude
    }
  }

  /**
   * 提取辅助监测轴的值
   * @private
   */
  _extractSecondaryValue(data) {
    if (!this.params.secondaryAxis) {
      return 0
    }

    const axis = this.params.secondaryAxis
    const acc = data.filtered.acc
    const gyro = data.filtered.gyro

    switch (axis) {
      case 'x':
        return Math.abs(acc.x)
      case 'y':
        return Math.abs(acc.y)
      case 'z':
        return Math.abs(acc.z)
      case 'gyro_x':
        return Math.abs(gyro.x)
      case 'gyro_y':
        return Math.abs(gyro.y)
      case 'gyro_z':
        return Math.abs(gyro.z)
      default:
        return 0
    }
  }

  /**
   * 处理静止状态
   * @private
   */
  _handleIdleState(value, secondaryValue, timestamp) {
    // 检测是否超过阈值
    if (value > this.params.peakThreshold * 0.5) {
      // 运动启动
      this.state = STATE.MOTION_START
      this.motionStartTime = timestamp
      this.baselineValue = value
      console.log('动作启动检测')
    }
  }

  /**
   * 处理运动启动状态
   * @private
   */
  _handleMotionStartState(value, secondaryValue, timestamp) {
    // 持续运动检测
    if (value > this.params.peakThreshold * 0.7) {
      this.state = STATE.MOTION_IN_PROGRESS
      console.log('动作进行中')
    } else {
      // 超时无峰值,返回静止
      const elapsed = (timestamp - this.motionStartTime) / 1000
      if (elapsed > this.params.timeWindow.max) {
        this.state = STATE.IDLE
        console.log('运动启动超时,返回静止')
      }
    }
  }

  /**
   * 处理动作进行中状态
   * @private
   */
  _handleInProgressState(value, secondaryValue, timestamp) {
    // 检测峰值
    if (value > this.peakValue) {
      this.peakValue = value
      this.peakTime = timestamp
    }

    // 检测是否达到峰值阈值
    if (this.peakValue >= this.params.peakThreshold) {
      // 检查辅助轴(如果有)
      const secondaryCheck = !this.params.secondaryAxis || 
        secondaryValue >= this.params.gyroThreshold
      
      if (secondaryCheck) {
        this.state = STATE.PEAK_DETECTED
        console.log('峰值检测成功:', this.peakValue)
      }
    }

    // 超时检测
    const elapsed = (timestamp - this.motionStartTime) / 1000
    if (elapsed > this.params.timeWindow.max) {
      this.state = STATE.IDLE
      this.peakValue = 0
      console.log('动作进行超时,返回静止')
    }
  }

  /**
   * 处理峰值检测状态
   * @private
   */
  _handlePeakDetectedState(value, secondaryValue, timestamp) {
    // 检测数值回落
    if (value < this.peakValue * 0.6) {
      this.state = STATE.RETURNING
      console.log('数值开始回落')
    }
  }

  /**
   * 处理回归基线状态
   * @private
   */
  _handleReturningState(value, secondaryValue, timestamp) {
    // 检测是否回归基线附近
    if (value < this.params.peakThreshold * 0.5) {
      // 时间窗口验证
      const duration = (timestamp - this.motionStartTime) / 1000
      
      if (duration >= this.params.timeWindow.min && 
          duration <= this.params.timeWindow.max) {
        // 动作完成!
        this._onActionComplete(duration)
      } else {
        console.log('时间窗口验证失败:', duration, 'Expected:', this.params.timeWindow)
      }
      
      // 重置状态
      this.state = STATE.IDLE
      this.peakValue = 0
      this.motionStartTime = 0
    }
  }

  /**
   * 动作完成回调
   * @private
   */
  _onActionComplete(duration) {
    console.log('动作完成! 耗时:', duration.toFixed(2), '秒')
    
    if (this.onCountCallback) {
      this.onCountCallback({
        duration,
        peakValue: this.peakValue,
        timestamp: Date.now(),
      })
    }
  }

  /**
   * 获取当前状态(用于调试)
   */
  getState() {
    return {
      state: this.state,
      peakValue: this.peakValue,
      bufferSize: this.dataBuffer.length,
    }
  }
}

// 导出单例
export default new RecognitionAlgorithm()
