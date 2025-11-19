/**
 * 将常用的 Feature API 挂载到 global 下,方便项目使用
 * 如果需要增加全局变量,请同步更新 app.d.ts,可用于代码提示、错误检测
 */
import router from '@blueos.app.appmanager.router'
import prompt from '@blueos.window.prompt'
import sensor from '@blueos.hardware.sensor.sensor'
import vibrator from '@blueos.hardware.vibrator.vibrator'
import storage from '@blueos.storage.storage'

global.router = router
global.prompt = prompt
global.sensor = sensor
global.vibrator = vibrator
global.storage = storage
