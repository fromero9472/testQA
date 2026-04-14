Feature: PCP-49054

  Background:
    * url 'https://credit-profile-claropay-ar-desa.apps.osen02.claro.amx'

  Scenario: Consultar límites de crédito
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
    And match response.message == LIMIT_OFFERED_FOUND_OK
    And match response.code == 200
    And match response.data.offeredLimit == 5000
