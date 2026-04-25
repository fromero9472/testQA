Feature: PCP-49054

  Background:
    * url 'https://credit-profile-claropay-ar-desa.apps.osen02.claro.amx'
    * def KIBANA_URL   = 'http://elkkibana02xpl.claro.amx:5602'
    * def KIBANA_USER  = 'desarrollo_claropay'
    * def KIBANA_PASS  = 'Claro2021'
    * def KIBANA_INDEX = 'logstash-*'
    * def APP_NAME     = 'credit-profile-customer'
    * configure ssl = true

  Scenario: Consultar límites de crédito

    # ── Capturar timestamp ANTES del request ───────────────────────
    * def logTs = java.time.Instant.now().toString()
    * karate.log('Log capture desde: ' + logTs)

    # ── Request ────────────────────────────────────────────────────
    Given path '/credit-profile/v1/limits/consult'
    And header Content-Type = 'application/json'
    And request
    """
    {"rangeScore": 6, "antiquityPOS": 10, "clientCategory": "MASIVO", "serviceModel": "POS", "clientSubType": "P0", "date": "2026-01-29T18:01:10.175Z"}
    """

    # ── Execution ──────────────────────────────────────────────────
    When method POST

    # ── Assertions ────────────────────────────────────────────────
    Then status 200
    And match response.message == 'LIMIT_OFFERED_FOUND_OK'
    And match response.code == 200
    And match response.data.offeredLimit == 5000

    # ── Evidencia de logs via Kibana ───────────────────────────────
    * configure connectTimeout = 8000
    * configure readTimeout    = 15000
    * def safeKibanaEvidence =
      """
      function() {
        try {
          var result = karate.call('classpath:features/kibana-evidence.feature', {
            KIBANA_URL:   KIBANA_URL,
            KIBANA_USER:  KIBANA_USER,
            KIBANA_PASS:  KIBANA_PASS,
            KIBANA_INDEX: KIBANA_INDEX,
            appName:      APP_NAME,
            logTs:        logTs
          });
          return result;
        } catch(e) {
          karate.log('WARN: No se pudo obtener evidencia Kibana.');
          karate.log('WARN: Causa -> ' + e.message);
          karate.log('WARN: Verifique conectividad y credenciales Kibana (' + KIBANA_URL + ')');
          return null;
        }
      }
      """
    * def kibanaEvidence = safeKibanaEvidence()
    * if (kibanaEvidence != null) karate.log('Pod: '                        + kibanaEvidence.podName)
    * if (kibanaEvidence != null) karate.log('======= KIBANA LOG EVIDENCE =======')
    * if (kibanaEvidence != null) karate.log(kibanaEvidence.logContent)
    * if (kibanaEvidence != null) karate.log('===================================')
    * if (kibanaEvidence == null) karate.log('INFO: Evidencia Kibana omitida (sin acceso o sin configurar).')
