Feature: PCP-47042

  Background:
    * def KIBANA_URL   = karate.get('KIBANA_URL')
    * def KIBANA_USER  = karate.get('KIBANA_USER')
    * def KIBANA_PASS  = karate.get('KIBANA_PASS')
    * def KIBANA_INDEX = karate.get('KIBANA_INDEX')
    * def APP_NAME     = karate.get('APP_NAME')
    * configure ssl = true

  Scenario: Ingresar con cuitPay válido

    # ── Capturar timestamp ANTES del request ───────────────────────
    * def logTs = java.time.Instant.now().toString()
    * karate.log('Log capture desde: ' + logTs)

    # ── Request ────────────────────────────────────────────────────
    Given path '/credit-profile/v1/limits/pay'
    And header Content-Type = 'application/json'
    And request
    """
    {"cuitPay": 2733224455}
    """

    # ── Execution ──────────────────────────────────────────────────
    When method POST

    # ── Assertions de respuesta ────────────────────────────────────
    Then status 200
    And match response.code == 200
    And match response.message == 'LIMIT_PAY_OK'

    # ── Evidencia de logs via Kibana ───────────────────────────────
    * configure connectTimeout = 8000
    * configure readTimeout    = 15000
    * def safeKibanaEvidence =
      """
      function() {
        try {
          var result = karate.call('classpath:features/kibana-evidence.feature', {
            KIBANA_URL: KIBANA_URL, KIBANA_USER: KIBANA_USER, KIBANA_PASS: KIBANA_PASS,
            KIBANA_INDEX: KIBANA_INDEX, appName: APP_NAME, logTs: logTs
          });
          return result;
        } catch(e) {
          karate.log('WARN: No se pudo obtener evidencia Kibana -> ' + e.message);
          return null;
        }
      }
      """
    * def kibanaEvidence = safeKibanaEvidence()
    * if (kibanaEvidence != null) karate.log('Pod: ' + kibanaEvidence.podName)
    * if (kibanaEvidence != null) karate.log('======= KIBANA LOG EVIDENCE =======')
    * if (kibanaEvidence != null) karate.log(kibanaEvidence.logContent)
    * if (kibanaEvidence != null) karate.log('===================================')
    * if (kibanaEvidence == null) karate.log('INFO: Evidencia Kibana omitida.')


  Scenario: Ingresar con cuitPay inválido

    # ── Capturar timestamp ANTES del request ───────────────────────
    * def logTs = java.time.Instant.now().toString()
    * karate.log('Log capture desde: ' + logTs)

    # ── Request ────────────────────────────────────────────────────
    Given path '/credit-profile/v1/limits/pay'
    And header Content-Type = 'application/json'
    And request
    """
    {"cuitPay": 202001}
    """

    # ── Execution ──────────────────────────────────────────────────
    When method POST

    # ── Assertions de respuesta ────────────────────────────────────
    Then status 400
    And match response.code == 400
    And match response.message == 'LIMIT_PAY_BAD_REQUEST'

    # ── Evidencia de logs via Kibana ───────────────────────────────
    * configure connectTimeout = 8000
    * configure readTimeout    = 15000
    * def safeKibanaEvidence =
      """
      function() {
        try {
          var result = karate.call('classpath:features/kibana-evidence.feature', {
            KIBANA_URL: KIBANA_URL, KIBANA_USER: KIBANA_USER, KIBANA_PASS: KIBANA_PASS,
            KIBANA_INDEX: KIBANA_INDEX, appName: APP_NAME, logTs: logTs
          });
          return result;
        } catch(e) {
          karate.log('WARN: No se pudo obtener evidencia Kibana -> ' + e.message);
          return null;
        }
      }
      """
    * def kibanaEvidence = safeKibanaEvidence()
    * if (kibanaEvidence != null) karate.log('Pod: ' + kibanaEvidence.podName)
    * if (kibanaEvidence != null) karate.log('======= KIBANA LOG EVIDENCE =======')
    * if (kibanaEvidence != null) karate.log(kibanaEvidence.logContent)
    * if (kibanaEvidence != null) karate.log('===================================')
    * if (kibanaEvidence == null) karate.log('INFO: Evidencia Kibana omitida.')
