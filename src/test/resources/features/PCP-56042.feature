Feature: PCP-56042 - Validaciones request POST /v1/credit/profile

  Background:
    * url baseUrl
    * def expectedMessage = 'CREDIT_PROFILE_BAD_REQUEST'
    * def expectedCode = 400
    * def expectedStatus = ''
    * def expectedType = 'PERFILAMIENTO'
    * def expectedSubType = '81'

  Scenario: 1) Validacion Claro - No puede enviar datos de Claro y ClaroPay juntos
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "nim": 1123456789,
        "cltId": "16230885",
        "cuit": 20117117110,
        "identificationType": "DNI",
        "identificationNumber": 11711711,
        "name": "LUCAS ANDRES",
        "surname": "BUSSO",
        "birthdate": "1997-03-11"
      },
      "claroPay": {
        "cuit": 20117117110,
        "uuid": "c6f8b1b4-a354-4155-b425-44ab751632b4"
      },
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 400
    And match response.code == expectedCode
    And match response.message == expectedMessage
    And match response.status == expectedStatus
    And match response.type == expectedType
    And match response.subType == expectedSubType
    And match response.detail == 'No puede enviar datos de Claro y ClaroPay en el mismo request'

  Scenario: 2) Validacion Claro - cuit PF (<30) requiere name, surname y birthdate
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "cuit": 20000000000,
        "name": null,
        "surname": null,
        "birthdate": null
      },
      "claroPay": null,
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": true
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'El flujo requiere que name, surname y birthdate no sean null'

  Scenario: 3) Validacion Claro - flujo por identificationNumber requiere name, surname, birthdate e identificationType
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "identificationNumber": 12345678,
        "identificationType": null,
        "name": null,
        "surname": null,
        "birthdate": null
      },
      "claroPay": null,
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'El flujo requiere que name, surname, birthdate e identificationType no sean null'

  Scenario: 4) Validacion Claro - CUIT invalido (distinto de 11 digitos)
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "cuit": 2011711711
      },
      "claroPay": null,
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'CUIT debe contener solo números y tener 11 dígitos'

  Scenario: 5) Validacion Claro - NIM con letras
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "nim": "abc123"
      },
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'NIM debe contener solo números'

  Scenario: 6) Validacion Claro - birthdate con formato invalido
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "cuit": 20117117110,
        "name": "Juan",
        "surname": "Perez",
        "birthdate": "11-03-1997"
      },
      "claroPay": null,
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'birthdate debe tener formato aaaa-mm-dd'

  Scenario: 7) Validacion General - Request vacío
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {},
      "claroPay": {},
      "transaction": {}
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'El request se encuentra vacío'

  Scenario: 8) Validacion Claro - name/surname/birthdate sin cuit ni identificationNumber (y sin cltId ni nim)
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "name": "test",
        "surname": "test",
        "birthdate": "2023-01-01",
        "cuit": null,
        "identificationNumber": null,
        "cltId": null,
        "nim": null
      },
      "claroPay": null,
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'El campo cuit o identificationNumber es requerido'

  Scenario: 9) Validacion Claro - identificationNumber con letras o caracteres especiales
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "identificationNumber": "12A#45"
      },
      "claroPay": null,
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'El campo identificationNumber debe contener solo números'

  Scenario: 10) Validacion ClaroPay - uuid con formato invalido
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": null,
      "claroPay": {
        "uuid": "short-uuid"
      },
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'uuid tiene formato invalido'

  Scenario: 11) Validacion ClaroPay - CUIT invalido
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": null,
      "claroPay": {
        "cuit": 12345
      },
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'CUIT debe contener solo números y tener 11 dígitos'

  Scenario: 12) Validacion Transaction - isTransaction=true y channelId/originId null
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "cuit": 20117117110
      },
      "claroPay": null,
      "transaction": {
        "channelId": null,
        "caller": "texto",
        "originId": null,
        "isTransaction": true
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'Los campos channelId y originId no pueden ser null'

  Scenario: 13) Validacion Transaction - isTransaction=false y channelId/originId null (default=1)
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "cuit": 20117117110
      },
      "claroPay": null,
      "transaction": {
        "channelId": null,
        "caller": "texto",
        "originId": null,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 200

  Scenario: 14) Validacion Transaction - isTransaction null o vacío
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "cuit": 20117117110
      },
      "claroPay": null,
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": null
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'El campo isTransaction no puede ser null ni vacío'

  Scenario: 15) Validacion Transaction - solo transaction sin datos de claro y claropay
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": null,
      "claroPay": null,
      "transaction": {
        "channelId": 1,
        "caller": "texto",
        "originId": 1,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'Debe ingresar algún dato requerido claro o claroPay'

  Scenario: 16) Validacion Transaction - caller null o vacío
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
      "claro": {
        "cuit": 20117117110
      },
      "claroPay": null,
      "transaction": {
        "channelId": 1,
        "caller": null,
        "originId": 1,
        "isTransaction": false
      }
    }
    """
    When method post
    Then status 400
    And match response.message == expectedMessage
    And match response.detail == 'El campo caller no puede ser vacío o null'
