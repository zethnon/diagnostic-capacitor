export interface DiagnosticPluginPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
