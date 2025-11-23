// ==================== 存储键常量 ====================
export const STORAGE_KEYS = {
  TRAINING_RECORDS: 'training_records', // 训练记录数组
  CURRENT_SESSION: 'current_session',   // 当前训练会话
  ACTION_CONFIG: 'action_config',       // 动作配置参数
  USER_STATS: 'user_stats',             // 用户统计数据
}

// ==================== 动作类型常量 ====================
export const ACTION_TYPES = {
  BENCH_PRESS: 'ACT_001',    // 杠铃卧推
  CHEST_FLY: 'ACT_002',      // 器械夹胸
  DUMBBELL_CURL: 'ACT_003',  // 哑铃弯举
  SHOULDER_PRESS: 'ACT_004', // 坐姿推肩
  LEG_PRESS: 'ACT_005',      // 腿举
}

// ==================== 错误码常量 ====================
export const ERROR_CODES = {
  SENSOR_NOT_SUPPORTED: 1000,    // 设备不支持传感器
  STORAGE_FULL: 302,             // 存储空间不足
  INVALID_DATA: 9001,            // 无效数据
  TRAINING_INTERRUPTED: 9002,    // 训练中断
}

// ==================== 配置常量 ====================
export const CONFIG = {
  // 传感器采样频率
  SENSOR_INTERVAL: 'ui',        // 60ms/次
  
  // 滑动窗口大小
  WINDOW_SIZE: 5,
  
  // 默认目标次数
  DEFAULT_TARGET_REPS: 12,
  
  // 震动模式
  VIBRATE_MODE: {
    SHORT: 'short',
    LONG: 'long',
  },
  
  // Toast持续时间
  TOAST_DURATION: {
    SHORT: 0,
    LONG: 1,
  },
}

// ==================== 缓冲区大小常量 ====================
export const BUFFER_SIZE = {
  SENSOR_DATA: 100,           // 传感器数据缓冲区大小
  RECOGNITION_DATA: 50,       // 识别算法数据缓冲区大小
}

// ==================== 阈值系数常量 ====================
export const THRESHOLD_RATIOS = {
  MOTION_START: 0.5,          // 运动启动阈值系数
  MOTION_CONTINUE: 0.7,       // 运动持续阈值系数
  PEAK_DETECTED: 0.6,         // 峰值检测回落系数
  RETURNING: 0.5,             // 回归基线系数
}

// ==================== 延迟时间常量（毫秒）====================
export const DELAY_MS = {
  PAGE_TRANSITION: 500,       // 页面跳转延迟
  SENSOR_START: 1000,         // 传感器启动延迟
  SET_COMPLETE: 1500,         // 组完成提示延迟
  TOAST_DISPLAY: 500,         // Toast显示后延迟
}

// ==================== 数据验证范围 ====================
export const VALIDATION_RANGE = {
  ACCELEROMETER_MAX: 200,     // 加速度最大值 (m/s²)
  GYROSCOPE_MAX: 2000,        // 陀螺仪最大值 (°/s)
}


