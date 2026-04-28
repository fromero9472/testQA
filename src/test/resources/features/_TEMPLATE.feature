Feature: {{FEATURE_NAME}}
# DescripciÃ³n: {{FEATURE_DESCRIPTION}}
# Endpoint:    {{METHOD}} {{BASE_PATH}}
# Autor:       {{AUTHOR}}
# Fecha:       {{DATE}}

  Background:
    * def OCP_API   = 'https://api.osen02.claro.amx:6443'
    * def OCP_TOKEN = '{{OCP_TOKEN}}'
    * def NAMESPACE = '{{NAMESPACE}}'
    * url baseUrl
    * configure ssl = true

  # â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  # SCENARIO: Happy Path
  # â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Scenario: {{TICKET_ID}} - {{SCENARIO_DESCRIPTION}}

    # â”€â”€ Timestamp para evidencia de logs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    * def logTs = java.time.Instant.now().toString()
    * karate.log('Log capture desde: ' + logTs)

    # â”€â”€ [OPCIONAL] Estado DB ANTES del request â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    # * def DbUtils = Java.type('utils.DbUtils')
    # * def dbBefore = DbUtils.queryOne("SELECT {{DB_COLUMNS}} FROM CPAY_CREDIT_PROFILE.{{DB_TABLE}} WHERE {{DB_FILTER}}")
    # * karate.log('DB ANTES: ' + dbBefore)

    # â”€â”€ Headers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    Given path '{{ENDPOINT_PATH}}'
    And header Content-Type = 'application/json'
    # And header Authorization = 'Bearer {{TOKEN}}'   # descomentÃ¡ si requiere auth

    # â”€â”€ Request Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    And request
    """
    {{REQUEST_BODY}}
    """

    # â”€â”€ Execution â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    When method {{HTTP_METHOD}}

    # â”€â”€ Assertions de respuesta â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    Then status {{EXPECTED_STATUS}}
    And match response.message == '{{EXPECTED_MESSAGE}}'
    # And match response.{{FIELD}} == '{{EXPECTED_VALUE}}'
    # And match response == {message: '{{EXPECTED_MESSAGE}}', data: '#notnull'}

    # â”€â”€ [OPCIONAL] Estado DB DESPUÃ‰S del request â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    # * def dbAfter = DbUtils.queryOne("SELECT {{DB_COLUMNS}} FROM CPAY_CREDIT_PROFILE.{{DB_TABLE}} WHERE {{DB_FILTER}}")
    # * karate.log('DB DESPUES: ' + dbAfter)
    # * match dbAfter.{{DB_COLUMN}} == '{{DB_EXPECTED_VALUE}}'

    # â”€â”€ [OPCIONAL] Evidencia de logs OCP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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


  # â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  # SCENARIO: Error / ValidaciÃ³n negativa
  # â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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


