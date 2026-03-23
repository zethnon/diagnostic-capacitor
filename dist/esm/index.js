import { registerPlugin } from '@capacitor/core';
const DiagnosticPlugin = registerPlugin('DiagnosticPlugin', {
    web: () => import('./web').then(m => new m.DiagnosticPluginWeb()),
});
export * from './definitions';
export { DiagnosticPlugin };
//# sourceMappingURL=index.js.map