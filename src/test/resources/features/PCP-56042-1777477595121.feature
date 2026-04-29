Feature: PCP-56042

  Background:
    * def _featureBaseUrl = 'http://confluence.claro.amx'
    * url _featureBaseUrl != '' ? _featureBaseUrl : baseUrl

  Scenario: Validacion Claro - Datos de Claro y ClaroPay en el mismo request
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":{},"claroPay":{},"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == No puede enviar datos de Claro y ClaroPay en el mismo request

  Scenario: Validacion Claro - Campos name, surname y birthdate son null
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":{"cuit":12345678901,"name":null,"surname":null,"birthdate":null},"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == El flujo requiere que name, surname y birthdate no sean null

  Scenario: Validacion Claro - Campos name, surname, birthdate e identificationType son null
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":{"identificationNumber":12345678,"name":null,"surname":null,"birthdate":null},"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == El flujo requiere que name, surname, birthdate e identificationType no sean null

  Scenario: Validacion Claro - CUIT con letras o cantidad incorrecta
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":{"cuit":"abc12345678"},"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == CUIT debe contener solo números y tener 11 dígitos

  Scenario: Validacion Claro - NIM con letras
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":{"nim":"abc1234567"},"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == NIM debe contener solo números

  Scenario: Validacion Claro - birthdate con formato incorrecto
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":{"birthdate":"11-03-1997"},"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == birthdate debe tener formato aaaa-mm-dd

  Scenario: Validacion Claro - Request completamente vacío
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":{},"claroPay":{},"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == El request se encuentra vacío

  Scenario: Validacion Claro - cuit o identificationNumber requeridos
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":{"name":"Lucas","surname":"Andres","birthdate":"1997-03-11"},"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == El campo cuit o identificationNumber es requerido

  Scenario: Validacion Claro - identificationNumber con letras
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":{"identificationNumber":"abc12345678"},"claroPay":null,"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == El campo identificationNumber debe contener solo números

  Scenario: Validacion ClaroPay - uuid con menos de 36 caracteres
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":null,"claroPay":{"uuid":"12345"},"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == uuid tiene formato invalido

  Scenario: Validacion ClaroPay - CUIT con letras o cantidad incorrecta
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":null,"claroPay":{"cuit":"abc12345678"},"transaction":{}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == CUIT debe contener solo números y tener 11 dígitos

  Scenario: Validacion Transaction - channelId y originId son null
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":null,"claroPay":null,"transaction":{"isTransaction":true}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == Los campos channelId y originId no pueden ser null

  Scenario: Validacion Transaction - isTransaction false y channelId u originId null
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":null,"claroPay":null,"transaction":{"isTransaction":false}}
    """
    When method POST
    Then status 200

  Scenario: Validacion Transaction - isTransaction null o vacío
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":null,"claroPay":null,"transaction":{"isTransaction":null}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == El campo isTransaction no puede ser null ni vacío

  Scenario: Validacion Transaction - Sin datos en claro y claropay
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":null,"claroPay":null,"transaction":{"isTransaction":true}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == Debe ingresar algún dato requerido claro o claroPay

  Scenario: Validacion Transaction - caller como null o vacío
    Given path '/v1/credit/profile"'
    And header Content-Type = 'application/json'
    And request
    """
{"claro":null,"claroPay":null,"transaction":{"caller":null}}
    """
    When method POST
    Then status 400
    And match response.message == CREDIT_PROFILE_BAD_REQUEST
    And match response.detail == El campo caller no puede ser vacío o null
