/**
 * Parser de JUnit XML de Karate
 *
 * Lee los archivos XML generados por Karate en target/surefire-reports/
 * y extrae información detallada para enriquecer el reporte JSON
 */

const fs = require('fs');
const path = require('path');

/**
 * Parsea archivos JUnit XML simples de Karate
 * @param {string} junitXmlPath - Ruta al archivo Test-*.xml
 * @returns {Array} Array con detalles extraídos
 */
function parseJUnitXml(junitXmlPath) {
  try {
    if (!fs.existsSync(junitXmlPath)) {
      return [];
    }

    const content = fs.readFileSync(junitXmlPath, 'utf8');
    const testcases = extractTestcases(content);
    return testcases;
  } catch (err) {
    console.warn(`⚠️ Error al parsear ${junitXmlPath}:`, err.message);
    return [];
  }
}

/**
 * Extrae testcases del XML usando regex (sin depender de xml parser externo)
 */
function extractTestcases(xmlContent) {
  const testcases = [];
  const testcaseRegex = /<testcase\b([^>]*?)(?:\/>|>([\s\S]*?)<\/testcase>)/g;

  let match;
  while ((match = testcaseRegex.exec(xmlContent)) !== null) {
    const attrs = match[1] || '';
    const content = match[2] || '';
    const name = getXmlAttr(attrs, 'name') || 'Unknown';
    const classname = getXmlAttr(attrs, 'classname') || '';
    const time = getXmlAttr(attrs, 'time') || '0';

    const testcase = {
      name,
      classname,
      durationMs: Math.round(parseFloat(time) * 1000) || 0,
      status: 'PASSED',
      error: null,
      properties: {},
    };

    const systemOut = extractSystemOut(content);
    testcase.logs = systemOut ? systemOut.split(/\r?\n/).filter(Boolean) : [];

    // Extraer propiedades
    const propRegex = /<property\s+name="([^"]*?)"\s+value="([^"]*?)"\s*\/?>/g;
    let propMatch;
    while ((propMatch = propRegex.exec(content)) !== null) {
      const [, propName, propValue] = propMatch;
      testcase.properties[propName] = propValue;
    }

    // Verificar si hay failure o error
    if (content.includes('<failure') || content.includes('<error')) {
      testcase.status = 'FAILED';
      const failureMatch = /<failure[^>]*>([\s\S]*?)<\/failure>/.exec(content);
      const errorMatch = /<error[^>]*>([\s\S]*?)<\/error>/.exec(content);

      const errorContent = failureMatch?.[1] || errorMatch?.[1] || '';
      testcase.error = {
        message: 'Test failed',
        stack: errorContent.trim(),
      };
    }

    // Extraer información HTTP de propiedades
    testcase.http = {
      method: testcase.properties['http.method'] || null,
      url: testcase.properties['http.url'] || null,
      expectedStatus: testcase.properties['http.expectedStatus']
        ? parseInt(testcase.properties['http.expectedStatus'])
        : null,
      actualStatus: testcase.properties['http.actualStatus']
        ? parseInt(testcase.properties['http.actualStatus'])
        : null,
      headers: tryParseJson(testcase.properties['http.headers'] || '{}'),
      requestBody: tryParseJson(testcase.properties['http.requestBody'] || 'null'),
      responseBody: tryParseJson(testcase.properties['http.responseBody'] || 'null'),
    };

    // Assertions
    testcase.assertions = extractAssertions(systemOut, testcase.properties);

    // Enriquecer HTTP desde logs cuando no viene en properties
    const httpFromLogs = extractHttpFromLogs(systemOut);
    testcase.http = {
      ...testcase.http,
      method: testcase.http.method || httpFromLogs.method || null,
      url: testcase.http.url || httpFromLogs.url || null,
      expectedStatus: testcase.http.expectedStatus ?? httpFromLogs.expectedStatus ?? null,
      actualStatus: testcase.http.actualStatus ?? httpFromLogs.actualStatus ?? null,
      requestBody: testcase.http.requestBody ?? httpFromLogs.requestBody ?? null,
      responseBody: testcase.http.responseBody ?? httpFromLogs.responseBody ?? null,
    };

    // Evidencia DB (si aparece en logs)
    testcase.db = extractDbEvidence(systemOut);

    testcases.push(testcase);
  }

  return testcases;
}

function extractSystemOut(content) {
  const match = /<system-out><!\[CDATA\[([\s\S]*?)\]\]><\/system-out>/.exec(content || '');
  return match ? match[1] : '';
}

function extractAssertions(systemOut, properties = {}) {
  if (properties['assertions']) {
    try { return JSON.parse(properties['assertions']); } catch {}
  }
  const logs = (systemOut || '').split(/\r?\n/);
  const assertions = [];
  for (const line of logs) {
    const txt = line.trim();
    if (/^\d+\s+>\s+(?:Then|And)\s+match\s+/i.test(txt) || /All members matched/i.test(txt) || /did not match/i.test(txt)) {
      assertions.push(txt);
    }
  }
  return assertions;
}

function extractHttpFromLogs(systemOut) {
  const out = {
    method: null,
    url: null,
    expectedStatus: null,
    actualStatus: null,
    requestBody: null,
    responseBody: null,
  };
  if (!systemOut) return out;

  const allRequests = [...systemOut.matchAll(/\n\d+\s+>\s+([A-Z]+)\s+(https?:\/\/[^\s]+)/gi)]
    .map((m) => ({ method: m[1], url: m[2] }));
  const businessRequest = pickBusinessRequest(allRequests, systemOut);
  if (businessRequest) {
    out.method = businessRequest.method;
    out.url = businessRequest.url;
  }

  const actualStatus = /\n\d+\s+<\s+(\d{3})\b/.exec(systemOut);
  if (actualStatus) out.actualStatus = parseInt(actualStatus[1], 10);

  const expectedStatus = /Then status (\d{3})/i.exec(systemOut);
  if (expectedStatus) out.expectedStatus = parseInt(expectedStatus[1], 10);

  const reqBodyMatch = /request:[\s\S]*?\n(?:\d+\s+>\s+.*\n)+([\{\[][\s\S]*?[\}\]])\s*(?:\n|$)/i.exec(systemOut);
  if (reqBodyMatch) out.requestBody = tryParseJson(reqBodyMatch[1].trim()) ?? reqBodyMatch[1].trim();

  const responseBlock = /response time in milliseconds:[\s\S]*?\n\d+\s+<\s+\d{3}(?:[\s\S]*?\n)([\{\[][\s\S]*?[\}\]])/i.exec(systemOut);
  if (responseBlock) out.responseBody = tryParseJson(responseBlock[1].trim()) ?? responseBlock[1].trim();

  return out;
}

function pickBusinessRequest(requests = [], systemOut = '') {
  if (!requests.length) return null;
  if (requests.length === 1) return requests[0];

  const baseUrlMatch = /BASE URL:\s*(https?:\/\/[^\s]+)/i.exec(systemOut || '');
  const baseUrl = baseUrlMatch ? baseUrlMatch[1].toLowerCase() : null;

  const nonInfra = requests.filter((r) => {
    const url = String(r.url || '').toLowerCase();
    return !(
      url.includes('kibana') ||
      url.includes('/elasticsearch') ||
      url.includes('logstash-') ||
      url.includes(':5601') ||
      url.includes(':5602')
    );
  });

  if (baseUrl) {
    const byBaseUrl = nonInfra.find((r) => String(r.url || '').toLowerCase().startsWith(baseUrl));
    if (byBaseUrl) return byBaseUrl;
  }

  if (nonInfra.length) return nonInfra[0];
  return requests[0];
}

function extractDbEvidence(systemOut) {
  if (!systemOut) return { query: null, result: null };
  const lines = systemOut.split(/\r?\n/);
  let query = null;
  let result = null;
  for (const line of lines) {
    const txt = line.trim();
    if (!query && /(select|update|insert|delete)\s+.+\s+(from|into)\s+/i.test(txt)) query = txt;
    if (!result && /(rows?|resultado|result)\s*[:=]/i.test(txt)) result = txt;
  }
  return { query, result };
}

function getXmlAttr(attrText, attrName) {
  const regex = new RegExp(`${attrName}="([^"]*)"`);
  const match = regex.exec(attrText || '');
  return match ? match[1] : '';
}

/**
 * Helper para parsear JSON de forma segura
 */
function tryParseJson(str) {
  if (!str || str === 'null') return null;
  try {
    return JSON.parse(str);
  } catch {
    return null;
  }
}

/**
 * Busca y parsea todos los archivos JUnit XML en un directorio
 */
function parseAllJunitFiles(reportsDir) {
  try {
    if (!fs.existsSync(reportsDir)) {
      return [];
    }

    const files = fs.readdirSync(reportsDir);
    const xmlFiles = files.filter(f => f.startsWith('TEST-') && f.endsWith('.xml'));

    let allTestcases = [];
    for (const file of xmlFiles) {
      const filePath = path.join(reportsDir, file);
      const testcases = parseJUnitXml(filePath);
      allTestcases = allTestcases.concat(testcases);
    }

    return dedupeAndRankTestcases(allTestcases);
  } catch (err) {
    console.warn('⚠️ Error al leer archivos JUnit:', err.message);
    return [];
  }
}

function dedupeAndRankTestcases(testcases = []) {
  const byName = new Map();
  for (const tc of testcases) {
    const key = String(tc.name || '').trim().toLowerCase() || `__idx_${Math.random()}`;
    const prev = byName.get(key);
    if (!prev || testcaseScore(tc) > testcaseScore(prev)) {
      byName.set(key, tc);
    }
  }
  return Array.from(byName.values());
}

function testcaseScore(tc) {
  let score = 0;
  const url = String(tc?.http?.url || '').toLowerCase();
  const hasBusinessUrl = url && !(
    url.includes('kibana') ||
    url.includes('/elasticsearch') ||
    url.includes('logstash-') ||
    url.includes(':5601') ||
    url.includes(':5602')
  );
  if (hasBusinessUrl) score += 100;
  if (tc?.http?.method) score += 10;
  if (tc?.http?.actualStatus != null) score += 10;
  if (tc?.http?.expectedStatus != null) score += 5;
  if (tc?.http?.requestBody != null) score += 5;
  if (tc?.http?.responseBody != null) score += 5;
  if (Array.isArray(tc?.assertions) && tc.assertions.length) score += 3;
  if (Array.isArray(tc?.logs) && tc.logs.length) score += 2;
  return score;
}

/**
 * Enriquece un scenario con datos del JUnit XML
 * @param {Object} scenario - Escenario del JSON
 * @param {Array} junitTestcases - Testcases parseados del XML
 * @param {number} index - Índice del scenario
 * @returns {Object} Scenario enriquecido
 */
function enrichScenarioWithJunit(scenario, junitTestcases, index) {
  // Buscar testcase que coincida por nombre o índice
  const matching = junitTestcases.find(tc => {
    const tcName = (tc.name || '').toLowerCase();
    const scenarioName = (scenario.name || '').toLowerCase();
    return tcName.includes(scenarioName) || scenarioName.includes(tcName);
  });

  if (matching) {
    return {
      ...scenario,
      // Preservar datos que ya existen, enriquecer con XML
      status: matching.status,
      http: {
        ...scenario.http,
        ...matching.http,
      },
      assertions: matching.assertions.length > 0 ? matching.assertions : scenario.assertions,
      error: matching.error || scenario.error,
      durationMs: matching.durationMs || scenario.durationMs,
    };
  }

  return scenario;
}

module.exports = {
  parseJUnitXml,
  parseAllJunitFiles,
  extractTestcases,
  enrichScenarioWithJunit,
};

