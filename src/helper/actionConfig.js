/**
 * 动作配置数据
 * 包含预设动作列表和识别参数
 */

import { ACTION_TYPES } from './constants.js'

/**
 * 预设动作列表
 */
export const ACTION_LIST = [
  {
    actionCode: ACTION_TYPES.BENCH_PRESS,
    actionName: '杠铃卧推',
    description: '上下直线推举运动,手臂垂直地面方向运动',
    icon: '/assets/images/bench_press.png',
    sensorFeature: 'Z轴加速度周期性变化,Y轴陀螺仪角速度波动',
    category: '胸部',
  },
  {
    actionCode: ACTION_TYPES.CHEST_FLY,
    actionName: '器械夹胸',
    description: '水平面内双臂向中线夹合运动',
    icon: '/assets/images/chest_fly.png',
    sensorFeature: 'X/Y轴加速度组合变化,Z轴陀螺仪旋转',
    category: '胸部',
  },
  {
    actionCode: ACTION_TYPES.DUMBBELL_CURL,
    actionName: '哑铃弯举',
    description: '前臂垂直面内旋转运动',
    icon: '/assets/images/dumbbell_curl.png',
    sensorFeature: 'Y轴陀螺仪显著角速度变化,X轴加速度周期性',
    category: '手臂',
  },
  {
    actionCode: ACTION_TYPES.SHOULDER_PRESS,
    actionName: '坐姿推肩',
    description: '垂直向上推举运动',
    icon: '/assets/images/shoulder_press.png',
    sensorFeature: 'Z轴加速度主导,Y轴陀螺仪辅助',
    category: '肩部',
  },
  {
    actionCode: ACTION_TYPES.LEG_PRESS,
    actionName: '腿举',
    description: '下肢推蹬运动(手表随手臂自然摆动)',
    icon: '/assets/images/leg_press.png',
    sensorFeature: '低频率X/Y轴加速度波动',
    category: '腿部',
  },
]

/**
 * 动作识别参数配置
 * 每个动作的识别算法参数
 */
export const RECOGNITION_PARAMS = {
  [ACTION_TYPES.BENCH_PRESS]: {
    // 主要监测轴
    primaryAxis: 'z',           // Z轴加速度
    secondaryAxis: 'gyro_y',    // Y轴陀螺仪
    
    // 峰值阈值 (m/s²)
    peakThreshold: 1.5,
    
    // 陀螺仪阈值 (°/s)
    gyroThreshold: 30,
    
    // 时间窗口 (秒)
    timeWindow: {
      min: 0.8,
      max: 2.5,
    },
    
    // 基线范围 (用于判断回归)
    baselineRange: 0.5,
  },
  
  [ACTION_TYPES.CHEST_FLY]: {
    primaryAxis: 'xy_combined',  // X/Y轴组合
    secondaryAxis: 'gyro_z',     // Z轴陀螺仪
    peakThreshold: 1.2,
    gyroThreshold: 45,
    timeWindow: {
      min: 1.0,
      max: 3.0,
    },
    baselineRange: 0.4,
  },
  
  [ACTION_TYPES.DUMBBELL_CURL]: {
    primaryAxis: 'gyro_y',       // Y轴陀螺仪主导
    secondaryAxis: 'x',          // X轴加速度
    peakThreshold: 0.8,
    gyroThreshold: 60,
    timeWindow: {
      min: 0.5,
      max: 2.0,
    },
    baselineRange: 0.3,
  },
  
  [ACTION_TYPES.SHOULDER_PRESS]: {
    primaryAxis: 'z',            // Z轴加速度
    secondaryAxis: 'gyro_y',     // Y轴陀螺仪
    peakThreshold: 1.8,
    gyroThreshold: 35,
    timeWindow: {
      min: 0.8,
      max: 2.5,
    },
    baselineRange: 0.6,
  },
  
  [ACTION_TYPES.LEG_PRESS]: {
    primaryAxis: 'xy_combined',  // X/Y轴组合
    secondaryAxis: null,         // 无辅助轴
    peakThreshold: 0.8,
    gyroThreshold: 0,
    timeWindow: {
      min: 1.5,
      max: 4.0,
    },
    baselineRange: 0.3,
  },
}

/**
 * 根据动作代码获取动作信息
 * @param {string} actionCode 动作编号
 * @returns {object|null} 动作信息对象
 */
export function getActionByCode(actionCode) {
  return ACTION_LIST.find(action => action.actionCode === actionCode) || null
}

/**
 * 根据动作代码获取识别参数
 * @param {string} actionCode 动作编号
 * @returns {object|null} 识别参数对象
 */
export function getRecognitionParams(actionCode) {
  return RECOGNITION_PARAMS[actionCode] || null
}
