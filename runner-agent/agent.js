require('dotenv').config();
const express   = require('express');
const cors      = require('cors');
const fs        = require('fs');
const path      = require('path');
const { spawn } = require('child_process');
const { parseAllJunitFiles } = require('./karateJunitParser');

const app          = express();
const PORT         = process.env.PORT         || 4000;
const AGENT_TOKEN  = process.env.AGENT_TOKEN;
const RUNNER_PATH  = process.env.RUNNER_PATH;
const FEATURES_DIR = process.env.FEATURES_DIR;
const REPORTS_DIR  = process.env.REPORTS_DIR;
const DEFAULT_ENV  = process.env.DEFAULT_ENV  || 'desa';
const RUNNER_JAVA_HOME = process.env.RUNNER_JAVA_HOME || process.env.JAVA_HOME || '';
const RUNNER_MAVEN_HOME = process.env.RUNNER_MAVEN_HOME || process.env.MAVEN_HOME || '';
const MAVEN_CMD = process.env.MAVEN_CMD || 'mvn';
const EVIDENCE_DIR = REPORTS_DIR ? path.join(REPORTS_DIR, 'evidence') : path.join(process.cwd(), 'evidence');

function buildRunnerEnv() {
  const env = { ...process.env };

  const prependPaths = [];
  if (RUNNER_JAVA_HOME) {
    env.JAVA_HOME = RUNNER_JAVA_HOME;
    prependPaths.push(path.join(RUNNER_JAVA_HOME, 'bin'));
  }
  if (RUNNER_MAVEN_HOME) {
    env.MAVEN_HOME = RUNNER_MAVEN_HOME;
    prependPaths.push(path.join(RUNNER_MAVEN_HOME, 'bin'));
  }
  if (prependPaths.length) {
    env.PATH = `${prependPaths.join(path.delimiter)}${path.delimiter}${env.PATH || ''}`;
  }
  return env;
}

function ensureEvidenceDir() {
  if (!fs.existsSync(EVIDENCE_DIR)) {
    fs.mkdirSync(EVIDENCE_DIR, { recursive: true });
  }
}

function toScenarioFromJunit(testcase, index) {
  return {
    id: `scenario-${index + 1}`,
    index: index + 1,
    name: testcase.name || 'Unknown',
    status: (testcase.status || 'UNKNOWN').toUpperCase(),
    durationMs: testcase.durationMs || 0,
    tags: [],
    featureFile: testcase.classname || 'Sin datos',
    line: null,
    steps: [],
    http: {
      method: testcase.http?.method || null,
      url: testcase.http?.url || null,
      expectedStatus: testcase.http?.expectedStatus ?? null,
      actualStatus: testcase.http?.actualStatus ?? null,
      headers: testcase.http?.headers || {},
      requestBody: testcase.http?.requestBody ?? null,
      responseBody: testcase.http?.responseBody ?? null,
    },
    assertions: Array.isArray(testcase.assertions) ? testcase.assertions : [],
    testData: {},
    logs: Array.isArray(testcase.logs) ? testcase.logs : [],
    db: testcase.db || { query: null, result: null },
    error: testcase.error ? {
      message: testcase.error.message || 'Test failed',
      stack: testcase.error.stack || '',
    } : null,
  };
}

function mapKarateReport(rawKarateJson, ctx = {}) {
  const scenariosPassed = Number(rawKarateJson?.scenariosPassed || 0);
  const scenariosFailed = Number(rawKarateJson?.scenariosFailed || rawKarateJson?.scenariosfailed || 0);
  const scenariosSkipped = Number(rawKarateJson?.scenariosSkipped || 0);
  const total = scenariosPassed + scenariosFailed + scenariosSkipped;
  const durationMs = Math.round(Number(rawKarateJson?.elapsedTime || 0) * 1000);
  const finishedAt = new Date().toISOString();
  const startedAt = ctx.startedAt || finishedAt;
  const executionId = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

  return {
    executionId,
    featureName: ctx.featureName || rawKarateJson?.featureName || 'Sin datos',
    environment: rawKarateJson?.env || ctx.environment || DEFAULT_ENV,
    baseUrl: ctx.baseUrl || process.env.DEFAULT_BASE_URL || 'Sin datos',
    status: scenariosFailed > 0 ? 'FAILED' : 'PASSED',
    startedAt,
    finishedAt,
    durationMs,
    summary: {
      total,
      passed: scenariosPassed,
      failed: scenariosFailed,
      skipped: scenariosSkipped,
      error: 0,
      successRate: total > 0 ? Math.round((scenariosPassed / total) * 100) : 0,
    },
    scenarios: [],
  };
}

function saveExecutionEvidence(report) {
  ensureEvidenceDir();
  fs.writeFileSync(path.join(EVIDENCE_DIR, `${report.executionId}.json`), JSON.stringify(report, null, 2), 'utf8');
  fs.writeFileSync(path.join(EVIDENCE_DIR, 'latest.json'), JSON.stringify(report, null, 2), 'utf8');
}

function scenarioToHtml(s) {
  const requestBody = s.http?.requestBody == null ? 'Sin datos' : JSON.stringify(s.http.requestBody, null, 2);
  const responseBody = s.http?.responseBody == null ? 'Sin datos' : JSON.stringify(s.http.responseBody, null, 2);
  const errorText = s.error?.message || 'Sin datos';
  const stackText = s.error?.stack || 'Sin datos';
  return `
    <details class="scenario">
      <summary><b>#${s.index}</b> ${s.name} <span class="badge ${String(s.status || 'UNKNOWN').toLowerCase()}">${s.status}</span></summary>
      <div class="grid">
        <div><b>Duracion:</b> ${s.durationMs}ms</div>
        <div><b>Metodo:</b> ${s.http?.method || 'Sin datos'}</div>
        <div><b>URL:</b> ${s.http?.url || 'Sin datos'}</div>
        <div><b>Status esperado:</b> ${s.http?.expectedStatus ?? 'Sin datos'}</div>
        <div><b>Status obtenido:</b> ${s.http?.actualStatus ?? 'Sin datos'}</div>
      </div>
      <h4>Request</h4><pre>${requestBody}</pre>
      <h4>Response</h4><pre>${responseBody}</pre>
      <h4>Error</h4><pre>${errorText}</pre>
      <h4>Stack</h4><pre>${stackText}</pre>
    </details>
  `;
}

function buildHtmlReport(report) {
  const scenariosHtml = (report.scenarios || []).map(scenarioToHtml).join('\n');
  return `<!doctype html>
<html><head><meta charset="utf-8"><title>Reporte ${report.executionId}</title>
<style>
body{background:#0b1220;color:#dbe3f4;font-family:Segoe UI,Arial,sans-serif;padding:24px}
.cards{display:grid;grid-template-columns:repeat(5,minmax(120px,1fr));gap:10px}
.card{background:#121b2f;border:1px solid #26324a;border-radius:8px;padding:12px}
.scenario{background:#121b2f;border:1px solid #26324a;border-radius:8px;padding:8px;margin:8px 0}
.badge{padding:2px 8px;border-radius:999px}
.passed{background:#143d28}.failed{background:#4a1d1d}.skipped{background:#3f3f3f}.error{background:#4b2b14}
pre{background:#0f1729;border:1px solid #22304a;padding:8px;border-radius:6px;white-space:pre-wrap}
.grid{display:grid;grid-template-columns:repeat(2,minmax(160px,1fr));gap:8px;margin:8px 0}
</style></head><body>
<h1>Reporte de Ejecucion</h1>
<div class="cards">
<div class="card"><b>Feature</b><div>${report.featureName}</div></div>
<div class="card"><b>Estado</b><div>${report.status}</div></div>
<div class="card"><b>Total</b><div>${report.summary.total}</div></div>
<div class="card"><b>Passed</b><div>${report.summary.passed}</div></div>
<div class="card"><b>Failed</b><div>${report.summary.failed}</div></div>
</div>
<h2>Escenarios</h2>
${scenariosHtml || '<p>Sin datos</p>'}
</body></html>`;
}

// ─── Validar config al arrancar ───────────────────────────────────────────────
if (!RUNNER_PATH || !FEATURES_DIR) {
  console.error('\n❌  Falta RUNNER_PATH o FEATURES_DIR en .env\n');
  process.exit(1);
}
if (!AGENT_TOKEN) {
  console.error('\n❌  Falta AGENT_TOKEN en .env\n');
  process.exit(1);
}
if (!fs.existsSync(FEATURES_DIR)) {
  console.warn(`\n⚠️   FEATURES_DIR no existe: ${FEATURES_DIR}\n`);
}

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(cors({ origin: (process.env.ALLOWED_ORIGINS || '').split(',') }));
app.use(express.json());

// ─── Auth por token (header x-agent-token) ────────────────────────────────────
app.use((req, res, next) => {
  console.log(`[Auth] Recibida petición para: ${req.path}`);
  const receivedToken = req.headers['x-agent-token'];
  console.log(`[Auth] Token recibido: ${receivedToken ? 'sí' : 'no'}`);

  if (req.path === '/health') return next();
  if (receivedToken !== AGENT_TOKEN) {
    console.error('[Auth] ❌ Token inválido o ausente. Rechazando petición.');
    return res.status(401).json({ success: false, error: 'Unauthorized' });
  }
  console.log('[Auth] ✅ Token válido. Petición autorizada.');
  next();
});

// ─── GET /health ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => res.json({
  status:     'OK',
  agent:      'TestQA Runner Agent',
  runnerPath: RUNNER_PATH,
  defaultEnv: DEFAULT_ENV,
  javaHome:   RUNNER_JAVA_HOME || null,
  mavenHome:  RUNNER_MAVEN_HOME || null,
  mavenCmd:   MAVEN_CMD,
}));

// ─── GET /features — lista todos los .feature ─────────────────────────────────
app.get('/features', (_req, res) => {
  try {
    const walk = (dir) => {
      let out = [];
      if (!fs.existsSync(dir)) return out;
      for (const file of fs.readdirSync(dir)) {
        const full = path.join(dir, file);
        if (fs.statSync(full).isDirectory()) {
          out = out.concat(walk(full));
        } else if (file.endsWith('.feature')) {
          out.push({
            name:         file,
            relativePath: path.relative(FEATURES_DIR, full).replace(/\\/g, '/'),
            size:         fs.statSync(full).size,
            modified:     fs.statSync(full).mtime,
          });
        }
      }
      return out;
    };
    res.json({ success: true, features: walk(FEATURES_DIR) });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── GET /features/content?path= — contenido de un .feature ──────────────────
app.get('/features/content', (req, res) => {
  try {
    const full = path.normalize(path.join(FEATURES_DIR, req.query.path || ''));
    if (!full.startsWith(path.normalize(FEATURES_DIR))) {
      return res.status(403).json({ success: false, error: 'Acceso denegado' });
    }
    res.json({ success: true, content: fs.readFileSync(full, 'utf8') });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── Helper: validar que el path esté dentro de FEATURES_DIR ─────────────────
const safeFeaturePath = (rel) => {
  const full = path.normalize(path.join(FEATURES_DIR, rel || ''));
  if (!full.startsWith(path.normalize(FEATURES_DIR))) throw new Error('Acceso denegado');
  return full;
};

// ─── POST /features/save — guarda contenido editado en un .feature ────────────
// Body: { path: 'PCP-47042.feature', content: '...' }
app.post('/features/save', (req, res) => {
  try {
    const { path: relPath, content } = req.body;
    if (!relPath || content === undefined) return res.status(400).json({ success: false, error: 'Faltan path y content' });
    const full = safeFeaturePath(relPath);
    if (!fs.existsSync(full)) return res.status(404).json({ success: false, error: 'Archivo no encontrado' });
    fs.writeFileSync(full, content, 'utf8');
    res.json({ success: true, size: fs.statSync(full).size, modified: fs.statSync(full).mtime });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── POST /features/rename — renombra un .feature en disco ───────────────────
// Body: { oldPath: 'PCP-47042.feature', newName: 'PCP-47042-v2' }
app.post('/features/rename', (req, res) => {
  try {
    const { oldPath, newName } = req.body;
    if (!oldPath || !newName) return res.status(400).json({ success: false, error: 'Faltan oldPath y newName' });

    const safeName = newName.replace(/[^a-zA-Z0-9_\-]/g, '_').replace(/\.feature$/, '');
    const oldFull  = safeFeaturePath(oldPath);
    const newFull  = path.join(path.dirname(oldFull), `${safeName}.feature`);

    if (!fs.existsSync(oldFull)) return res.status(404).json({ success: false, error: 'Archivo no encontrado' });
    if (fs.existsSync(newFull))  return res.status(409).json({ success: false, error: 'Ya existe un archivo con ese nombre' });

    fs.renameSync(oldFull, newFull);
    res.json({
      success: true,
      feature: {
        name:         `${safeName}.feature`,
        relativePath: path.relative(FEATURES_DIR, newFull).replace(/\\/g, '/'),
        size:         fs.statSync(newFull).size,
        modified:     fs.statSync(newFull).mtime,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── POST /features/create — crea un nuevo .feature ──────────────────────────
// Body: { name: 'MiFeature', content?: string }
app.post('/features/create', (req, res) => {
  try {
    const { name, content } = req.body;
    if (!name) return res.status(400).json({ success: false, error: 'Falta el nombre' });

    const safeName = name.replace(/[^a-zA-Z0-9_\-]/g, '_').replace(/\.feature$/, '');
    const full     = path.join(FEATURES_DIR, `${safeName}.feature`);

    if (fs.existsSync(full)) return res.status(409).json({ success: false, error: 'Ya existe un archivo con ese nombre' });

    const defaultContent = content || `Feature: ${safeName}\n\n  # Escenarios generados por QATestUI\n\n  Scenario: Ejemplo\n    Given url baseUrl\n    When method GET\n    Then status 200\n`;
    fs.writeFileSync(full, defaultContent, 'utf8');

    res.json({
      success: true,
      feature: {
        name:         `${safeName}.feature`,
        relativePath: path.relative(FEATURES_DIR, full).replace(/\\/g, '/'),
        size:         fs.statSync(full).size,
        modified:     fs.statSync(full).mtime,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── POST /features/import — importa un .feature desde contenido ──────────────
// Body: { name: 'MiFeature.feature', content: '...' }
app.post('/features/import', (req, res) => {
  try {
    const { name, content } = req.body;
    if (!name || !content) return res.status(400).json({ success: false, error: 'Faltan name y content' });

    const safeName = name.replace(/[^a-zA-Z0-9_\-]/g, '_').replace(/\.feature$/, '');
    let   full     = path.join(FEATURES_DIR, `${safeName}.feature`);

    // Si ya existe, agregar sufijo numérico
    let counter = 1;
    while (fs.existsSync(full)) {
      full = path.join(FEATURES_DIR, `${safeName}_${counter++}.feature`);
    }

    fs.writeFileSync(full, content, 'utf8');
    const finalName = path.basename(full);
    res.json({
      success: true,
      feature: {
        name:         finalName,
        relativePath: path.relative(FEATURES_DIR, full).replace(/\\/g, '/'),
        size:         fs.statSync(full).size,
        modified:     fs.statSync(full).mtime,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── DELETE /features — elimina un .feature del disco ─────────────────────────
// Body: { path: 'PCP-47042.feature' }
app.delete('/features', (req, res) => {
  try {
    const { path: relPath } = req.body;
    if (!relPath) return res.status(400).json({ success: false, error: 'Falta el path' });

    const full = safeFeaturePath(relPath);
    if (!fs.existsSync(full)) return res.status(404).json({ success: false, error: 'Archivo no encontrado' });

    fs.unlinkSync(full);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── GET /report — ultimo reporte Karate (karate-summary-json.txt) ────────────
app.get('/report', (_req, res) => {
  try {
    const summaryPath = path.join(REPORTS_DIR, 'karate-summary-json.txt');
    if (!fs.existsSync(summaryPath)) {
      return res.json({ success: false, error: 'No hay reportes todavía. Ejecutá un feature primero.' });
    }
    const summary = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));
    res.json({ success: true, summary });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/reports/latest', (_req, res) => {
  try {
    const latestPath = path.join(EVIDENCE_DIR, 'latest.json');
    if (!fs.existsSync(latestPath)) return res.status(404).json({ success: false, error: 'No hay reportes' });
    res.json({ success: true, report: JSON.parse(fs.readFileSync(latestPath, 'utf8')) });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/reports/:executionId', (req, res) => {
  try {
    const filePath = path.join(EVIDENCE_DIR, `${req.params.executionId}.json`);
    if (!fs.existsSync(filePath)) return res.status(404).json({ success: false, error: 'Reporte no encontrado' });
    res.json({ success: true, report: JSON.parse(fs.readFileSync(filePath, 'utf8')) });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/reports/:executionId/scenarios/:scenarioId', (req, res) => {
  try {
    const filePath = path.join(EVIDENCE_DIR, `${req.params.executionId}.json`);
    if (!fs.existsSync(filePath)) return res.status(404).json({ success: false, error: 'Reporte no encontrado' });
    const report = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const scenario = (report.scenarios || []).find((s) => String(s.id) === String(req.params.scenarioId));
    if (!scenario) return res.status(404).json({ success: false, error: 'Escenario no encontrado' });
    res.json({ success: true, scenario });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/reports/:executionId/download/json', (req, res) => {
  try {
    const filePath = path.join(EVIDENCE_DIR, `${req.params.executionId}.json`);
    if (!fs.existsSync(filePath)) return res.status(404).json({ success: false, error: 'Reporte no encontrado' });
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename=\"report-${req.params.executionId}.json\"`);
    res.send(fs.readFileSync(filePath, 'utf8'));
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/reports/:executionId/download/html', (req, res) => {
  try {
    const filePath = path.join(EVIDENCE_DIR, `${req.params.executionId}.json`);
    if (!fs.existsSync(filePath)) return res.status(404).json({ success: false, error: 'Reporte no encontrado' });
    const report = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename=\"report-${req.params.executionId}.html\"`);
    res.send(buildHtmlReport(report));
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── POST /run — ejecuta Maven con SSE streaming ──────────────────────────────
// Body: { featurePath?: string, env?: 'desa' | 'prod', baseUrl?: string, properties?: Record<string,string> }
app.post('/run', (req, res) => {
  const { featurePath, baseUrl, properties } = req.body;
  const env = req.body.env || DEFAULT_ENV;
  const startedAt = new Date().toISOString();

  res.setHeader('Content-Type',  'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection',    'keep-alive');
  res.flushHeaders();

  const send = (type, data) =>
    res.write(`data: ${JSON.stringify({ type, data })}\n\n`);

  const args = ['test', '-Dtest=KarateRunner', `-Dkarate.env=${env}`];
  if (baseUrl) args.push(`-DbaseUrl=${baseUrl}`);
  if (properties && typeof properties === 'object' && !Array.isArray(properties)) {
    Object.entries(properties).forEach(([key, value]) => {
      const safeKey = String(key || '').trim();
      if (!safeKey) return;
      if (!/^[a-zA-Z0-9_.-]+$/.test(safeKey)) return;
      if (value === undefined || value === null || String(value).trim() === '') return;
      args.push(`-D${safeKey}=${String(value)}`);
    });
  }
  if (featurePath) args.push(`-Dkarate.options=classpath:features/${featurePath}`);

  send('info', `🚀 ${MAVEN_CMD} ${args.join(' ')}`);
  send('info', `📁 ${RUNNER_PATH}`);
  send('info', `🌍 Ambiente: ${env}${baseUrl ? ` → ${baseUrl}` : ''}`);
  if (RUNNER_JAVA_HOME) send('info', `☕ JAVA_HOME: ${RUNNER_JAVA_HOME}`);
  if (RUNNER_MAVEN_HOME) send('info', `🧰 MAVEN_HOME: ${RUNNER_MAVEN_HOME}`);
  if (properties && typeof properties === 'object') {
    const propKeys = Object.keys(properties).filter(k => /^[a-zA-Z0-9_.-]+$/.test(String(k || '').trim()));
    if (propKeys.length) send('info', `⚙️ Properties: ${propKeys.join(', ')}`);
  }

  const mvn = spawn(MAVEN_CMD, args, {
    cwd: RUNNER_PATH,
    shell: true,
    env: buildRunnerEnv(),
  });

  const pipe = (type) => (chunk) =>
    chunk.toString().split('\n')
      .filter(l => l.trim())
      .forEach(l => {
        // Clasificar lineas importantes de Maven/Karate
        const line = l.trim();
        const t = line.includes('BUILD FAILURE') || line.includes('FAILED') || line.includes('ERROR')
          ? 'error'
          : line.includes('BUILD SUCCESS') || line.includes('Tests run:') || line.includes('passed')
          ? 'success'
          : type;
        send(t, line);
      });

  mvn.stdout.on('data', pipe('log'));
  mvn.stderr.on('data', pipe('error'));

  mvn.on('close', (code) => {
    // Leer el reporte generado
    let summary = null;
    try {
      const summaryPath = path.join(REPORTS_DIR, 'karate-summary-json.txt');
      if (fs.existsSync(summaryPath)) {
        const rawKarateJson = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));

        // DEBUG: Log de lo que Karate envía
        send('log', `📊 Karate JSON keys: ${Object.keys(rawKarateJson).join(', ')}`);
        send('log', `📊 ¿Tiene scenarios?: ${rawKarateJson.scenarios ? 'SÍ (' + rawKarateJson.scenarios.length + ')' : 'NO'}`);

        // MAPEAR formato Karate al formato QATestUI esperado
        summary = mapKarateReport(rawKarateJson, {
          startedAt,
          environment: env,
          baseUrl,
          featureName: featurePath || 'all-features',
        });

        send('log', `✅ Estructura mapeada: status=${summary.status}, total=${summary.summary.total}`);

        // FASE 2: Enriquecer con datos del JUnit XML
        try {
          const junitDir = path.join(RUNNER_PATH, 'target', 'surefire-reports');
          send('log', `📁 Buscando JUnit XML en: ${junitDir}`);
          send('log', `📁 ¿Existe el directorio?: ${fs.existsSync(junitDir)}`);

          if (fs.existsSync(junitDir)) {
            const files = fs.readdirSync(junitDir);
            send('log', `📁 Archivos en surefire-reports: ${files.join(', ')}`);
          }

          const junitTestcases = parseAllJunitFiles(junitDir);

          send('log', `📊 JUnit testcases encontrados: ${junitTestcases.length}`);
          if (junitTestcases.length > 0) {
            send('log', `✅ Primer testcase: ${junitTestcases[0].name}`);
            summary.scenarios = junitTestcases.map((tc, i) => toScenarioFromJunit(tc, i));
            send('log', `✅ Scenarios mapeados: ${summary.scenarios.length}`);
          } else {
            send('log', `⚠️ No se encontraron testcases en el XML`);
          }
        } catch (enrichErr) {
          console.warn('⚠️ No se pudo enriquecer con JUnit XML:', enrichErr.message);
          send('log', `⚠️ Error en enrichment: ${enrichErr.message}`);
          send('log', `⚠️ Stack: ${enrichErr.stack}`);
        }
      }
      if (summary) saveExecutionEvidence(summary);
    } catch (err) {
      send('log', `⚠️ Error al leer reporte: ${err.message}`);
    }

    send('done', {
      exitCode: code,
      success:  code === 0,
      message:  code === 0 ? '✅ Tests finalizados correctamente' : `❌ Tests fallaron (exit code ${code})`,
      summary,
    });
    res.end();
  });

  mvn.on('error', (err) => {
    send('error', `No se pudo iniciar Maven: ${err.message}`);
    send('done', {
      exitCode: 1, success: false,
      message: '❌ Maven no encontrado. ¿Está en el PATH del sistema?',
    });
    res.end();
  });
});

// ─── Start ────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🤖  TestQA Runner Agent → http://localhost:${PORT}`);
  console.log(`    Runner : ${RUNNER_PATH}`);
  console.log(`    Env    : ${DEFAULT_ENV}\n`);
});

