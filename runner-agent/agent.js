require('dotenv').config();
const express   = require('express');
const cors      = require('cors');
const fs        = require('fs');
const path      = require('path');
const { spawn } = require('child_process');

const app          = express();
const PORT         = process.env.PORT         || 4000;
const AGENT_TOKEN  = process.env.AGENT_TOKEN;
const RUNNER_PATH  = process.env.RUNNER_PATH;
const FEATURES_DIR = process.env.FEATURES_DIR;
const REPORTS_DIR  = process.env.REPORTS_DIR;
const DEFAULT_ENV  = process.env.DEFAULT_ENV  || 'desa';

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
  if (req.path === '/health') return next();
  if (req.headers['x-agent-token'] !== AGENT_TOKEN) {
    return res.status(401).json({ success: false, error: 'Unauthorized' });
  }
  next();
});

// ─── GET /health ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => res.json({
  status:     'OK',
  agent:      'TestQA Runner Agent',
  runnerPath: RUNNER_PATH,
  defaultEnv: DEFAULT_ENV,
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

// ─── POST /run — ejecuta Maven con SSE streaming ──────────────────────────────
// Body: { featurePath?: string, env?: 'desa' | 'prod', baseUrl?: string, properties?: Record<string,string> }
app.post('/run', (req, res) => {
  const { featurePath, baseUrl, properties } = req.body;
  const env = req.body.env || DEFAULT_ENV;

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

  send('info', `🚀 mvn ${args.join(' ')}`);
  send('info', `📁 ${RUNNER_PATH}`);
  send('info', `🌍 Ambiente: ${env}${baseUrl ? ` → ${baseUrl}` : ''}`);
  if (properties && typeof properties === 'object') {
    const propKeys = Object.keys(properties).filter(k => /^[a-zA-Z0-9_.-]+$/.test(String(k || '').trim()));
    if (propKeys.length) send('info', `⚙️ Properties: ${propKeys.join(', ')}`);
  }

  const mvn = spawn('mvn', args, { cwd: RUNNER_PATH, shell: true });

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
        summary = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));
      }
    } catch { /* ignorar si falla la lectura del reporte */ }

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

