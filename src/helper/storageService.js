/**
 * 存储服务封装
 * 提供训练记录的增删改查方法
 */

import { STORAGE_KEYS } from './constants.js'

/**
 * 生成唯一记录ID
 * @returns {string} 格式: rec_YYYYMMDD_XXX
 */
function generateRecordId() {
  const now = new Date()
  const dateStr = now.getFullYear() +
    String(now.getMonth() + 1).padStart(2, '0') +
    String(now.getDate()).padStart(2, '0')
  const randomStr = String(Math.floor(Math.random() * 1000)).padStart(3, '0')
  return `rec_${dateStr}_${randomStr}`
}

/**
 * 格式化日期字符串
 * @param {Date} date 日期对象
 * @returns {string} 格式: YYYY-MM-DD
 */
function formatDate(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

/**
 * 获取所有训练记录
 * @returns {Promise<Array>} 训练记录数组
 */
export function getAllRecords() {
  return new Promise((resolve) => {
    global.storage.get({
      key: STORAGE_KEYS.TRAINING_RECORDS,
      default: '[]',
      success: (data) => {
        try {
          const records = JSON.parse(data)
          resolve(Array.isArray(records) ? records : [])
        } catch (e) {
          console.error('解析训练记录失败:', e)
          resolve([])
        }
      },
      fail: () => {
        resolve([])
      },
    })
  })
}

/**
 * 保存训练记录
 * @param {object} record 训练记录对象
 * @returns {Promise<boolean>} 是否成功
 */
export function saveRecord(record) {
  return new Promise(async (resolve) => {
    try {
      const records = await getAllRecords()
      
      // 生成记录ID
      if (!record.recordId) {
        record.recordId = generateRecordId()
      }
      
      // 添加时间戳
      if (!record.timestamp) {
        record.timestamp = Date.now()
      }
      
      // 添加日期
      if (!record.date) {
        record.date = formatDate(new Date(record.timestamp))
      }
      
      records.push(record)
      
      global.storage.set({
        key: STORAGE_KEYS.TRAINING_RECORDS,
        value: records,
        success: () => {
          console.log('训练记录保存成功:', record.recordId)
          resolve(true)
        },
        fail: (data, code) => {
          console.error('训练记录保存失败:', code, data)
          resolve(false)
        },
      })
    } catch (e) {
      console.error('保存记录异常:', e)
      resolve(false)
    }
  })
}

/**
 * 根据日期查询记录
 * @param {string} date 日期字符串 YYYY-MM-DD
 * @returns {Promise<Array>} 符合条件的记录数组
 */
export function getRecordsByDate(date) {
  return new Promise(async (resolve) => {
    const records = await getAllRecords()
    const filtered = records.filter(record => record.date === date)
    resolve(filtered)
  })
}

/**
 * 根据动作类型查询记录
 * @param {string} actionCode 动作编号
 * @returns {Promise<Array>} 符合条件的记录数组
 */
export function getRecordsByAction(actionCode) {
  return new Promise(async (resolve) => {
    const records = await getAllRecords()
    const filtered = records.filter(record => record.actionCode === actionCode)
    resolve(filtered)
  })
}

/**
 * 获取最近N次训练记录
 * @param {number} count 记录数量
 * @returns {Promise<Array>} 最近的记录数组
 */
export function getRecentRecords(count = 10) {
  return new Promise(async (resolve) => {
    const records = await getAllRecords()
    // 按时间戳降序排序
    const sorted = records.sort((a, b) => b.timestamp - a.timestamp)
    resolve(sorted.slice(0, count))
  })
}

/**
 * 删除训练记录
 * @param {string} recordId 记录ID
 * @returns {Promise<boolean>} 是否成功
 */
export function deleteRecord(recordId) {
  return new Promise(async (resolve) => {
    try {
      const records = await getAllRecords()
      const filtered = records.filter(record => record.recordId !== recordId)
      
      global.storage.set({
        key: STORAGE_KEYS.TRAINING_RECORDS,
        value: filtered,
        success: () => {
          console.log('训练记录删除成功:', recordId)
          resolve(true)
        },
        fail: (data, code) => {
          console.error('训练记录删除失败:', code, data)
          resolve(false)
        },
      })
    } catch (e) {
      console.error('删除记录异常:', e)
      resolve(false)
    }
  })
}

/**
 * 获取当前训练会话
 * @returns {Promise<object|null>} 当前会话数据或null
 */
export function getCurrentSession() {
  return new Promise((resolve) => {
    global.storage.get({
      key: STORAGE_KEYS.CURRENT_SESSION,
      success: (data) => {
        try {
          const session = JSON.parse(data)
          resolve(session)
        } catch (e) {
          resolve(null)
        }
      },
      fail: () => {
        resolve(null)
      },
    })
  })
}

/**
 * 保存当前训练会话
 * @param {object} session 会话数据
 * @returns {Promise<boolean>} 是否成功
 */
export function saveCurrentSession(session) {
  return new Promise((resolve) => {
    global.storage.set({
      key: STORAGE_KEYS.CURRENT_SESSION,
      value: session,
      success: () => {
        resolve(true)
      },
      fail: () => {
        resolve(false)
      },
    })
  })
}

/**
 * 清除当前训练会话
 * @returns {Promise<boolean>} 是否成功
 */
export function clearCurrentSession() {
  return new Promise((resolve) => {
    global.storage.delete({
      key: STORAGE_KEYS.CURRENT_SESSION,
      success: () => {
        resolve(true)
      },
      fail: () => {
        resolve(false)
      },
    })
  })
}

/**
 * 获取用户统计数据
 * @returns {Promise<object>} 统计数据
 */
export function getUserStats() {
  return new Promise((resolve) => {
    global.storage.get({
      key: STORAGE_KEYS.USER_STATS,
      success: (data) => {
        try {
          const stats = JSON.parse(data)
          resolve(stats || {
            totalWorkouts: 0,
            totalReps: 0,
            totalDuration: 0,
            lastWorkoutDate: null,
          })
        } catch (e) {
          resolve({
            totalWorkouts: 0,
            totalReps: 0,
            totalDuration: 0,
            lastWorkoutDate: null,
          })
        }
      },
      fail: () => {
        resolve({
          totalWorkouts: 0,
          totalReps: 0,
          totalDuration: 0,
          lastWorkoutDate: null,
        })
      },
    })
  })
}

/**
 * 更新用户统计数据
 * @param {object} newData 新增的统计数据
 * @returns {Promise<boolean>} 是否成功
 */
export function updateUserStats(newData) {
  return new Promise(async (resolve) => {
    try {
      const stats = await getUserStats()
      
      // 累加数据
      stats.totalWorkouts += 1
      stats.totalReps += newData.totalReps || 0
      stats.totalDuration += newData.duration || 0
      stats.lastWorkoutDate = newData.date || formatDate(new Date())
      
      global.storage.set({
        key: STORAGE_KEYS.USER_STATS,
        value: stats,
        success: () => {
          resolve(true)
        },
        fail: () => {
          resolve(false)
        },
      })
    } catch (e) {
      console.error('更新统计数据异常:', e)
      resolve(false)
    }
  })
}
