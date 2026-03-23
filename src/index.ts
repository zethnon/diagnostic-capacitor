import { registerPlugin } from '@capacitor/core';
import type { DiagnosticPlugin } from './definitions';

const DiagnosticPlugin = registerPlugin<DiagnosticPlugin>('DiagnosticPlugin', {
  web: () => import('./web').then(m => new m.DiagnosticPluginWeb()),
});

export * from './definitions';
export { DiagnosticPlugin };