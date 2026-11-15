// TypeScript's watch compiler emits the decorator metadata Nest needs for DI.
const ts = require('typescript');
const { spawn } = require('node:child_process');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const formatHost = {
  getCurrentDirectory: () => root,
  getCanonicalFileName: file => file,
  getNewLine: () => ts.sys.newLine,
};
const report = diagnostic => console.error(ts.formatDiagnosticsWithColorAndContext([diagnostic], formatHost));
let server;
let stopping = false;
let restart = Promise.resolve();

function stopServer() {
  const child = server;
  if (!child || child.exitCode !== null || child.signalCode !== null) return Promise.resolve();
  return new Promise(resolve => {
    const timer = setTimeout(() => child.kill('SIGKILL'), 5000);
    child.once('exit', () => { clearTimeout(timer); resolve(); });
    child.kill('SIGTERM');
  });
}

const host = ts.createWatchCompilerHost(
  path.join(root, 'tsconfig.dev.json'), {}, ts.sys,
  ts.createSemanticDiagnosticsBuilderProgram, report,
  diagnostic => console.log(ts.flattenDiagnosticMessageText(diagnostic.messageText, ts.sys.newLine)),
);

host.afterProgramCreate = builder => {
  const program = builder.getProgram();
  const diagnostics = ts.getPreEmitDiagnostics(program);
  diagnostics.forEach(report);
  if (diagnostics.some(d => d.category === ts.DiagnosticCategory.Error)) {
    console.error('Development build failed; waiting for changes.');
    return;
  }
  const result = builder.emit();
  result.diagnostics.forEach(report);
  if (result.emitSkipped || result.diagnostics.some(d => d.category === ts.DiagnosticCategory.Error)) return;
  restart = restart.then(async () => {
    await stopServer();
    if (stopping) return;
    console.log('Starting development API...');
    const child = spawn(process.execPath, ['--enable-source-maps', path.join(root, 'dist/dev/main.js')], {
      cwd: root, env: { ...process.env, SHOWTIME_DEV_BIND_HOST: '127.0.0.1' }, stdio: 'inherit',
    });
    server = child;
    child.on('error', error => console.error('Development API failed to start:', error));
    child.on('exit', (code, signal) => {
      if (server === child) server = undefined;
      if (!stopping && code !== 0 && signal !== 'SIGTERM') console.error(`Development API exited (${signal ?? code}); waiting for changes.`);
    });
  }).catch(error => console.error('Development API restart failed:', error));
};

const watcher = ts.createWatchProgram(host);
for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => {
    if (stopping) return;
    stopping = true;
    watcher.close();
    restart.then(stopServer).finally(() => process.exit(signal === 'SIGINT' ? 130 : 143));
  });
}
