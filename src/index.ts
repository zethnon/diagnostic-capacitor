import { registerPlugin } from '@capacitor/core';

import type { DiagnosticPluginPlugin } from './definitions';

const DiagnosticPlugin = registerPlugin<DiagnosticPluginPlugin>('DiagnosticPlugin', {
  web: () => import('./web').then((m) => new m.DiagnosticPluginWeb()),
});

export * from './definitions';
export { DiagnosticPlugin };
