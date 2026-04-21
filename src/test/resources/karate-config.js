function fn() {
  var config = {
    // ── Entorno activo ─────────────────────────────────────────────
    env: karate.env || 'desa',

    // ── URLs base por entorno ──────────────────────────────────────
    baseUrl: {
      desa: 'https://credit-profile-claropay-ar-desa.apps.osen02.claro.amx',
      prod: 'https://credit-profile-claropay-ar-prod.apps.osen02.claro.amx'
    }['desa'],

    // ── OCP ────────────────────────────────────────────────────────
    OCP_API:   'https://api.osen02.claro.amx:6443',
    NAMESPACE: 'claropay-ar-desa',

    // ── DB ─────────────────────────────────────────────────────────
    DB_SCHEMA: 'CPAY_CREDIT_PROFILE'
  };

  karate.configure('ssl', true);
  karate.configure('connectTimeout', 10000);
  karate.configure('readTimeout', 30000);

  // ── Loguear entorno activo al inicio ──────────────────────────
  karate.log('========================================');
  karate.log('  ENV   : ' + config.env);
  karate.log('  BASE  : ' + config.baseUrl);
  karate.log('========================================');

  return config;
}

