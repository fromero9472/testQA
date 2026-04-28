Feature: PCP-56042

  Background:
    * url baseUrl

  Scenario: Validacion Claro - Datos de Claro y ClaroPay en el mismo request
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {
  "claro": {
    "nim": 1123456789,
    "cltId": "16230885",
    "cuit":"20117117110",
    "identificationType":"DNI",
    "identificationNumber":11711711,
    "name": "LUCAS ANDRES",
    "surname": "BUSSO",
    "birthdate": "1997-03-11"
  },
  "claroPay": {
    "cuit": "20117117110",
    "uuid": "asdadsasd"
  }
"transaction": {
    "channelId": 1,
    "caller":  "texto",
    "originId": 1, 
    "isTransaction": false,
  }
}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail == 'No puede enviar datos de Claro y ClaroPay en el mismo request'

  Scenario: Validacion Claro - Campos name, surname y birthdate son null
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"cuit":30,"name":null,"surname":null,"birthdate":null},"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail == 'El campo isTransaction no puede ser null ni vacío'

  Scenario: Validacion Claro - Campos name, surname, birthdate e identificationType son null
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"identificationNumber":null,"name":null,"surname":null,"birthdate":null},"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail == 'El request se encuentra vacío'

  Scenario: Validacion Claro - CUIT con letras o cantidad distinta a 11 dígitos
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"cuit":"abc","transaction":{}},"claroPay":null}
    """
    When method POST
    Then status 500
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST_ERROR'
    And match response.detail == 'Request mal ingresado.'

  Scenario: Validacion Claro - NIM con letras
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"nim":"abc","transaction":{}},"claroPay":null}
    """
    When method POST
    Then status 500
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST_ERROR'
    And match response.detail == 'Request mal ingresado.'

  Scenario: Validacion Claro - birthdate con formato incorrecto
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"birthdate":"dd-mm-yyyy","transaction":{}},"claroPay":null}
    """
    When method POST
    Then status 500
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST_ERROR'
    And match response.detail == 'Request mal ingresado.'

  Scenario: Validacion Claro - Request completamente vacío
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{},"claroPay":{},"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail == 'El request se encuentra vacío'

  Scenario: Validacion Claro - cuit o identificationNumber es requerido
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"name":"test","surname":"test","birthdate":"2023-01-01"},"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail == 'El campo cuit o identificationNumber es requerido'

  Scenario: Validacion ClaroPay - uuid con menos de 36 caracteres
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":null,"claroPay":{"uuid":"shortuuid"},"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail == 'uuid tiene formato invalido'

  Scenario: Validacion ClaroPay - CUIT con letras o cantidad distinta a 11 dígitos
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":null,"claroPay":{"cuit":"abc"},"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail == 'CUIT debe contener solo números y tener 11 dígitos'

  Scenario: Validacion Transaction - channelId y originId son null
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{},"claroPay":null,"transaction":{"isTransaction":true}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail == 'Los campos channelId y originId no pueden ser null'

  Scenario: Validacion Transaction - isTransaction en false
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{},"claroPay":null,"transaction":{"isTransaction":false}}
    """
    When method POST
    Then status 200

  Scenario: Validacion Transaction - isTransaction es null o vacío
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{},"claroPay":null,"transaction":{"isTransaction":null}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail == 'El campo isTransaction no puede ser null ni vacío'

  Scenario: Validacion Transaction - Sin datos en claro y claropay
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":null,"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail == 'Debe ingresar algún dato requerido claro o claroPay'

  Scenario: Validacion Transaction - caller es null o vacío
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{},"claroPay":null,"transaction":{"caller":null}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail == 'El campo caller no puede ser vacío o null'