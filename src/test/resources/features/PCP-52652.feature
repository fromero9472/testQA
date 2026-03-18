Feature: Pruebas camino feliz de todos los endpoints de credit-profile-limits
    Background:
        * url 'http://localhost:8080'
        * header Content-Type = 'application/json'

    Scenario: Consulta límites ofrecidos
        Given path '/v1/limits/consult'
        And request {"rangeScore": 8,"antiquityPOS": 7,"clientCategory": "PYME","serviceModel": "PP","clientSubType": "PO"}
        When method post
        Then status 200

    Scenario: Inserta límite ofrecido
        Given path '/v1/limits'
        And request { "antiquitySince": 2, "antiquityUntil": 3, "rangeScore": 8, "offeredLimits": 11111, "dateSince": "2025-10-01T00:00:00.000", "dateUntil": "2025-12-31T17:42:12.000", "clientCategory": "MASIVO", "serviceModel": "POS", "clientSubType": "CO", "createdUser": "EXC1234", "user":"feder" }
        When method post
        Then status 200

    Scenario: Actualiza límite ofrecido
        Given path '/v1/limits'
        And request { "id": 137, "offeredLimits": 35000000, "updatedUser": "EXC1234" }
        When method put
        Then status 200

    Scenario: Elimina límite ofrecido
        Given path '/v1/limits'
        And request { "id": 101, "updatedUser": "EXC1234" }
        When method delete
        Then status 200

    Scenario: Calcula límite disponible para un cliente
        Given path '/v1/limit/credit/profile'
        And request { "clientId": 102, "clientCategory": "PYME", "serviceModel": "PP", "clientSubType": "PO" }
        When method post
        Then status 200

    Scenario: Consulta si un cliente está exceptuado
        Given path '/v1/limits/excepted/consult'
        And request { "clientId": 105, "cuitPay": "20304050607" }
        When method post
        Then status 200

    Scenario: Actualiza cliente exceptuado
        Given path '/v1/limits/excepted'
        And request { "clientId": 105, "cuitPay": "20304050607", "updatedUser": "EXC1234" }
        When method put
        Then status 200

    Scenario: Inserta cliente exceptuado
        Given path '/v1/limits/excepted'
        And request { "clientId": 106, "cuitPay": "20987654321", "createdUser": "EXC1234" }
        When method post
        Then status 200

    Scenario: Elimina cliente exceptuado
        Given path '/v1/limits/excepted'
        And request { "clientId": 106, "cuitPay": "20987654321", "updatedUser": "EXC1234" }
        When method delete
        Then status 200

    Scenario: Consulta límites y consumos de ClaroPay
        Given path '/v1/limits/pay'
        And request { "cuitPay": "20304050607" }
        When method post
        Then status 200

    Scenario: Consulta historial de límites ofrecidos
        Given path '/v1/limits/history'
        And param pageSize = 1
        And param pageNumber = 0
        When method get
        Then status 200

    Scenario: Actualización parcial de límite ofrecido
        Given path '/v1/limits'
        And request { "id": 101, "offeredLimits": 36000000, "updatedUser": "EXC1234" }
        When method patch
        Then status 200

    Scenario: Consulta paginada de límites ofrecidos
        Given path '/v1/limits'
        And param pageSize = 2
        And param pageNumber = 0
        When method get
        Then status 200

