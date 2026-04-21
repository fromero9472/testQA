Feature: PCP-47042

  Background:
    * url 'https://credit-profile-claropay-ar-desa.apps.osen02.claro.amx'
    * def OCP_API   = 'https://api.osen02.claro.amx:6443'
    * def OCP_TOKEN = 'sha256~k0-pa5u7UaJ3amxB1YC3EzV5hkVwWLqKAZ0b3g5IzdU'
    * def NAMESPACE = 'claropay-ar-desa'
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

    # ── Obtener evidencia de logs OCP (opcional) ───────────────────
    * configure connectTimeout = 5000
    * configure readTimeout = 10000
    * def safeOcpEvidence =
      """
      function() {
        try {
          var result = karate.call('classpath:features/ocp-evidence.feature',
            { OCP_API: OCP_API, OCP_TOKEN: OCP_TOKEN, NAMESPACE: NAMESPACE, logTs: logTs });
          return result;
        } catch(e) {
          karate.log('WARN: No se pudo obtener evidencia OCP.');
          karate.log('WARN: Causa -> ' + e.message);
          karate.log('WARN: Verifique conectividad VPN / red al cluster OpenShift (' + OCP_API + ')');
          return null;
        }
      }
      """
    * def ocpEvidence = safeOcpEvidence()
    * if (ocpEvidence != null) karate.log('Pod encontrado: ' + ocpEvidence.podName)
    * if (ocpEvidence != null) karate.log('======= LOG EVIDENCE =======')
    * if (ocpEvidence != null) karate.log(ocpEvidence.logContent)
    * if (ocpEvidence != null) karate.log('============================')
    * if (ocpEvidence == null) karate.log('INFO: Evidencia OCP omitida (sin acceso al cluster).')


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

    # ── Obtener evidencia de logs OCP (opcional) ───────────────────
    * configure connectTimeout = 5000
    * configure readTimeout = 10000
    * def safeOcpEvidence =
      """
      function() {
        try {
          var result = karate.call('classpath:features/ocp-evidence.feature',
            { OCP_API: OCP_API, OCP_TOKEN: OCP_TOKEN, NAMESPACE: NAMESPACE, logTs: logTs });
          return result;
        } catch(e) {
          karate.log('WARN: No se pudo obtener evidencia OCP.');
          karate.log('WARN: Causa -> ' + e.message);
          karate.log('WARN: Verifique conectividad VPN / red al cluster OpenShift (' + OCP_API + ')');
          return null;
        }
      }
      """
    * def ocpEvidence = safeOcpEvidence()
    * if (ocpEvidence != null) karate.log('Pod encontrado: ' + ocpEvidence.podName)
    * if (ocpEvidence != null) karate.log('======= LOG EVIDENCE =======')
    * if (ocpEvidence != null) karate.log(ocpEvidence.logContent)
    * if (ocpEvidence != null) karate.log('============================')
    * if (ocpEvidence == null) karate.log('INFO: Evidencia OCP omitida (sin acceso al cluster).')
