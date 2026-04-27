function fn() {
  var env = karate.env || 'desa';

  // ── URLs base por entorno (fallback si no viene -DbaseUrl) ─────
  var baseUrls = {
    desa: 'https://credit-profile-claropay-ar-desa.apps.osen02.claro.amx',
    prod: 'https://credit-profile-claropay-ar-prod.apps.osen02.claro.amx'
  };

  // Si se pasa -DbaseUrl=https://... lo usa, sino toma el del mapa
  var baseUrl = karate.properties['baseUrl'] || baseUrls[env] || baseUrls['desa'];

  var config = {
    env:     env,
    baseUrl: baseUrl,

    // ── OCP ──────────────────────────────────────────────────────
    OCP_API:   'https://api.osen02.claro.amx:6443',
    NAMESPACE: 'claropay-ar-desa',
    OCP_TOKEN: karate.properties['OCP_TOKEN'] || '',

    // ── Kibana ───────────────────────────────────────────────────
    KIBANA_URL:   karate.properties['KIBANA_URL']   || 'http://elkkibana02xpl.claro.amx:5602',
    KIBANA_USER:  karate.properties['KIBANA_USER']  || '',
    KIBANA_PASS:  karate.properties['KIBANA_PASS']  || '',
    KIBANA_INDEX: karate.properties['KIBANA_INDEX'] || 'logstash-*',
    APP_NAME:     karate.properties['APP_NAME']     || 'credit-profile-customer',

    // ── DB ───────────────────────────────────────────────────────
    DB_SCHEMA: 'CPAY_CREDIT_PROFILE'
  };

  karate.configure('ssl', true);
  karate.configure('connectTimeout', 10000);
  karate.configure('readTimeout', 30000);

  karate.log('========================================');
  karate.log('  ENV     : ' + config.env);
  karate.log('  BASE URL: ' + config.baseUrl);
  karate.log('========================================');

  return config;
}
