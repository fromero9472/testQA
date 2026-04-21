Feature: CreditProfileCustomer

  Background:
    * url 'https://credit-profile-customer-claropay-ar-desa.apps.osen02.claro.amx'

  # ══════════════════════════════════════════════════════════════════
  Scenario: Validar Request Válido Con CltId
  # ══════════════════════════════════════════════════════════════════
    # ── Request ────────────────────────────────────────────────────
    Given path '/v1/client/data'
    And header Content-Type = 'application/json'
    And request
    """
    {"isTransaction": false, "claro": {"nim": "1123456789", "cltId": null, "cuit": null, "identificationType": null, "identificationNumber": null, "name": null, "surname": null, "birthdate": null}, "claroPay": {"cuit": null, "documentNumber": null, "uuid": null}}
    """

    # ── Execution ──────────────────────────────────────────────────
    When method POST

    # ── Assertions ────────────────────────────────────────────────
    Then status 200
    And match response.responseStatus == 'validación exitosa'

