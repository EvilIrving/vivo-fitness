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


