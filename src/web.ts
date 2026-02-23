import { WebPlugin } from '@capacitor/core';

import type { DiagnosticPluginPlugin } from './definitions';

export class DiagnosticPluginWeb extends WebPlugin implements DiagnosticPluginPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
