Feature: PCP-47042

  Background:
    * def KIBANA_URL   = karate.get('KIBANA_URL')
    * def KIBANA_USER  = karate.get('KIBANA_USER')
    * def KIBANA_PASS  = karate.get('KIBANA_PASS')
    * def KIBANA_INDEX = karate.get('KIBANA_INDEX')
    * def APP_NAME     = karate.get('APP_NAME')
    * url baseUrl
    * configure ssl = true

  Scenario: Ingresar con cuitPay vÃ¡lido

    # â”€â”€ Capturar timestamp ANTES del request â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    * def logTs = java.time.Instant.now().toString()
    * karate.log('Log capture desde: ' + logTs)

    # â”€â”€ Request â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    Given path '/credit-profile/v1/limits/pay'
    And header Content-Type = 'application/json'
    And request
    """
    {"cuitPay": 2733224455}
    """

    # â”€â”€ Execution â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    When method POST

    # â”€â”€ Assertions de respuesta â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    Then status 200
    And match response.code == 200
    And match response.message == 'LIMIT_PAY_OK'

    # â”€â”€ Evidencia de logs via Kibana â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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


  Scenario: Ingresar con cuitPay invÃ¡lido

    # â”€â”€ Capturar timestamp ANTES del request â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    * def logTs = java.time.Instant.now().toString()
    * karate.log('Log capture desde: ' + logTs)

    # â”€â”€ Request â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    Given path '/credit-profile/v1/limits/pay'
    And header Content-Type = 'application/json'
    And request
    """
    {"cuitPay": 202001}
    """

    # â”€â”€ Execution â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    When method POST

    # â”€â”€ Assertions de respuesta â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    Then status 400
    And match response.code == 400
    And match response.message == 'LIMIT_PAY_BAD_REQUEST'

    # â”€â”€ Evidencia de logs via Kibana â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

