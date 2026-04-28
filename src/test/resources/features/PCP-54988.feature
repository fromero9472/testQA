Feature: PCP-54988

  Background:
    * url baseUrl

  Scenario: Validacion Claro - Datos de Claro y ClaroPay en el mismo request
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{},"claroPay":{},"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'No puede enviar datos de Claro y ClaroPay en el mismo request'

  Scenario: Validacion Claro - Campos name, surname y birthdate en null
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"cuit":"12345678901","identificationNumber":12345678,"transaction":{}},"claroPay":null}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'El flujo requiere que name, surname y birthdate no sean null'

  Scenario: Validacion Claro - Campos name, surname, birthdate e identificationType en null
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"identificationNumber":12345678,"transaction":{}},"claroPay":null}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'El flujo requiere que name, surname, birthdate e identificationType no sean null'

  Scenario: Validacion Claro - CUIT con letras o cantidad distinta a 11 digitos
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"cuit":"abc12345678","transaction":{}},"claroPay":null}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'CUIT debe contener solo numeros'

  Scenario: Validacion Claro - NIM con letras
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"nim":"abc1234567","transaction":{}},"claroPay":null}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'NIM debe contener solo numeros'

  Scenario: Validacion Claro - birthdate con formato incorrecto
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"birthdate":"11-03-1997","transaction":{}},"claroPay":null}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'birthdate debe tener formato aaaa-mm-dd'

  Scenario: Validacion Claro - request completamente vacio
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{},"claroPay":{},"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'El request se encuentra vacio'

  Scenario: Validacion Claro - cuit o identificationNumber requeridos
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"name":"Lucas","surname":"Andres","birthdate":"1997-03-11","transaction":{}},"claroPay":null}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'El campo cuit o identificationNumber es requerido'

  Scenario: Validacion Claro - identificationNumber con letras o caracteres especiales
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{"identificationNumber":"abc12345678","transaction":{}},"claroPay":null}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'El campo identificationNumber debe contener solo numeros'

  Scenario: Validacion ClaroPay - uuid con menos de 36 caracteres
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":null,"claroPay":{"uuid":"12345"},"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'uuid tiene formato invalido'

  Scenario: Validacion ClaroPay - CUIT con letras o cantidad distinta a 11 digitos
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":null,"claroPay":{"cuit":"abc12345678"},"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'CUIT debe contener solo numeros'

  Scenario: Validacion Transaction - channelId y originId en null
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{},"claroPay":{},"transaction":{"isTransaction":true}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'Los campos channelId y originId no pueden ser null'

  Scenario: Validacion Transaction - isTransaction en false
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{},"claroPay":{},"transaction":{"isTransaction":false}}
    """
    When method POST
    Then status 200

  Scenario: Validacion Transaction - isTransaction null o vacio
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{},"claroPay":{},"transaction":{"isTransaction":null}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'El campo isTransaction no puede ser null ni vacio'

  Scenario: Validacion Transaction - request sin datos en claro y claropay
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":null,"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'Debe ingresar algun dato requerido claro o claroPay'

  Scenario: Validacion Transaction - caller vacio o null
    Given path '/v1/credit/profile'
    And header Content-Type = 'application/json'
    And request
    """
    {"claro":{},"claroPay":{},"transaction":{"caller":null}}
    """
    When method POST
    Then status 400
    And match response.message == 'CREDIT_PROFILE_BAD_REQUEST'
    And match response.detail contains 'El campo caller no puede ser vacio o null'

  Scenario: Validacion de Request Claro
    Given path '/v1/credit/profile'
    When method POST
    Then status 200

