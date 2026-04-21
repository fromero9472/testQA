Feature: CreditProfileClientData

  Background:
    * url 'https://credit-profile-customer-claropay-ar-desa.apps.osen02.claro.amx'
    * def OCP_API   = 'https://api.osen02.claro.amx:6443'
    * def OCP_TOKEN = 'sha256~k0-pa5u7UaJ3amxB1YC3EzV5hkVwWLqKAZ0b3g5IzdU'
    * def NAMESPACE = 'claropay-ar-desa'
    * configure ssl = true

  Scenario: PCP-52117

    # ── Capturar timestamp ANTES del request ───────────────────────
    * def logTs = java.time.Instant.now().toString()
    * karate.log('Log capture desde: ' + logTs)

    # ── Request ────────────────────────────────────────────────────
    Given path '/credit-profile/v1/client/data'
    And header Content-Type = 'application/json'
    And request
    """
    {"isTransaction": false, "claro": {"nim": 1123456789, "cltId": null, "cuit": null, "identificationType": null, "identificationNumber": null, "name": null, "surname": null, "birthdate": null}, "claroPay": {"cuit": null, "documentNumber": null, "uuid": null}}
    """

    # ── Execution ──────────────────────────────────────────────────
    When method POST

    # ── Assertions de respuesta ────────────────────────────────────
    Then status 200
    And match response.message == 'CLIENT_DATA_FOUND_OK'

    # ── Obtener evidencia de logs OCP (opcional) ───────────────────
    # Si no hay acceso al cluster OpenShift (VPN / red interna),
    # esta sección registra un aviso pero NO falla el test.
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
