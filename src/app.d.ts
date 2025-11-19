/// <reference types="@blueos" />
type Router = typeof import('@blueos.app.appmanager.router');
type Prompt = typeof import('@blueos.window.prompt');
type Sensor = typeof import('@blueos.hardware.sensor.sensor');
type Vibrator = typeof import('@blueos.hardware.vibrator.vibrator');
type Storage = typeof import('@blueos.storage.storage');

declare const global: {
  router: Router;
  prompt: Prompt;
  sensor: Sensor;
  vibrator: Vibrator;
  storage: Storage;
}

declare const Promise: typeof Promise