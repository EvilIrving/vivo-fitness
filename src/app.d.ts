/// <reference types="@blueos" />
type Router = typeof import('@blueos.app.appmanager.router');
type Prompt = typeof import('@blueos.window.prompt');

declare const global: {
  router: Router;
  prompt: Prompt;
}

declare const Promise: typeof Promise