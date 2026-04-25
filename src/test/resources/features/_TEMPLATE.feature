Feature: {{FEATURE_NAME}}
# Descripción: {{FEATURE_DESCRIPTION}}
# Endpoint:    {{METHOD}} {{BASE_PATH}}
# Autor:       {{AUTHOR}}
# Fecha:       {{DATE}}

  Background:
    * def OCP_API   = 'https://api.osen02.claro.amx:6443'
    * def OCP_TOKEN = '{{OCP_TOKEN}}'
    * def NAMESPACE = '{{NAMESPACE}}'
    * configure ssl = true

  # ══════════════════════════════════════════════════════════════════
  # SCENARIO: Happy Path
  # ══════════════════════════════════════════════════════════════════
  Scenario: {{TICKET_ID}} - {{SCENARIO_DESCRIPTION}}

    # ── Timestamp para evidencia de logs ───────────────────────────
    * def logTs = java.time.Instant.now().toString()
    * karate.log('Log capture desde: ' + logTs)

    # ── [OPCIONAL] Estado DB ANTES del request ─────────────────────
    # * def DbUtils = Java.type('utils.DbUtils')
    # * def dbBefore = DbUtils.queryOne("SELECT {{DB_COLUMNS}} FROM CPAY_CREDIT_PROFILE.{{DB_TABLE}} WHERE {{DB_FILTER}}")
    # * karate.log('DB ANTES: ' + dbBefore)

    # ── Headers ────────────────────────────────────────────────────
    Given path '{{ENDPOINT_PATH}}'
    And header Content-Type = 'application/json'
    # And header Authorization = 'Bearer {{TOKEN}}'   # descomentá si requiere auth

    # ── Request Body ───────────────────────────────────────────────
    And request
    """
    {{REQUEST_BODY}}
    """

    # ── Execution ──────────────────────────────────────────────────
    When method {{HTTP_METHOD}}

    # ── Assertions de respuesta ────────────────────────────────────
    Then status {{EXPECTED_STATUS}}
    And match response.message == '{{EXPECTED_MESSAGE}}'
    # And match response.{{FIELD}} == '{{EXPECTED_VALUE}}'
    # And match response == {message: '{{EXPECTED_MESSAGE}}', data: '#notnull'}

    # ── [OPCIONAL] Estado DB DESPUÉS del request ───────────────────
    # * def dbAfter = DbUtils.queryOne("SELECT {{DB_COLUMNS}} FROM CPAY_CREDIT_PROFILE.{{DB_TABLE}} WHERE {{DB_FILTER}}")
    # * karate.log('DB DESPUES: ' + dbAfter)
    # * match dbAfter.{{DB_COLUMN}} == '{{DB_EXPECTED_VALUE}}'

    # ── [OPCIONAL] Evidencia de logs OCP ──────────────────────────
    # * configure connectTimeout = 5000
    # * configure readTimeout    = 10000
    # * def safeOcpEvidence =
    #   """
    #   function() {
    #     try {
    #       var result = karate.call('classpath:features/ocp-evidence.feature',
    #         { OCP_API: OCP_API, OCP_TOKEN: OCP_TOKEN, NAMESPACE: NAMESPACE, logTs: logTs });
    #       return result;
    #     } catch(e) {
    #       karate.log('WARN: No se pudo obtener evidencia OCP -> ' + e.message);
    #       return null;
    #     }
    #   }
    #   """
    # * def ocpEvidence = safeOcpEvidence()
    # * if (ocpEvidence != null) karate.log('Pod: '     + ocpEvidence.podName)
    # * if (ocpEvidence != null) karate.log(ocpEvidence.logContent)
    # * if (ocpEvidence == null) karate.log('INFO: Evidencia OCP omitida (sin acceso al cluster).')


  # ══════════════════════════════════════════════════════════════════
  # SCENARIO: Error / Validación negativa
  # ══════════════════════════════════════════════════════════════════
  # Scenario: {{TICKET_ID}} - {{SCENARIO_DESCRIPTION_ERROR}}
  #
  #   Given path '{{ENDPOINT_PATH}}'
  #   And header Content-Type = 'application/json'
  #   And request
  #   """
  #   {{REQUEST_BODY_ERROR}}
  #   """
  #   When method {{HTTP_METHOD}}
  #   Then status {{EXPECTED_ERROR_STATUS}}
  #   And match response.message == '{{EXPECTED_ERROR_MESSAGE}}'

