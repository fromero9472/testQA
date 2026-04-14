Feature: PCP-47042

  Background:
    * url 'https://credit-profile-claropay-ar-desa.apps.osen02.claro.amx'

  Scenario: Ingresar con cuitPay válido

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


  Scenario: Ingresar con cuitPay inválido
    # ── Marcar posición de log ANTES del request ────────────────────
    * def logPos = LogReader.getFilePosition()

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

