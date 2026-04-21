@ignore
Feature: OCP Evidence Gathering
  # Feature auxiliar: obtiene el pod activo y los logs desde el timestamp indicado.
  # Es llamada desde otros features via karate.call() dentro de un bloque try-catch,
  # por lo que un fallo aquí solo genera un aviso en el feature principal.

  Background:
    # Cuando se llama vía karate.call() con un mapa de args, esos valores tienen prioridad.
    * def OCP_API   = karate.get('OCP_API',   'https://api.osen02.claro.amx:6443')
    * def OCP_TOKEN = karate.get('OCP_TOKEN', 'sha256~k0-pa5u7UaJ3amxB1YC3EzV5hkVwWLqKAZ0b3g5IzdU')
    * def NAMESPACE = karate.get('NAMESPACE', 'claropay-ar-desa')
    * def logTs     = karate.get('logTs',     '1970-01-01T00:00:00Z')

  Scenario: Obtener logs del pod en OpenShift

    * configure ssl = true
    * configure connectTimeout = 5000
    * configure readTimeout = 10000

    # ── Obtener pod del servicio vía OCP API ───────────────────────
    Given url OCP_API + '/api/v1/namespaces/' + NAMESPACE + '/pods'
    And header Authorization = 'Bearer ' + OCP_TOKEN
    And header Accept = 'application/json'
    And param labelSelector = 'app=credit-profile-customer'
    When method GET
    Then status 200

    * def runningPods = karate.filter(response.items, function(p){ return p.status.phase == 'Running' })
    * def podName = runningPods[0].metadata.name
    * karate.log('Pod encontrado: ' + podName)

    # ── Obtener logs del pod desde el timestamp capturado ──────────
    Given url OCP_API + '/api/v1/namespaces/' + NAMESPACE + '/pods/' + podName + '/log'
    And header Authorization = 'Bearer ' + OCP_TOKEN
    And header Accept = 'text/plain'
    And param sinceTime = logTs
    When method GET
    Then status 200

    # Guardamos los logs (pueden estar vacíos si el servicio no generó output nuevo)
    * def logContent = response
    * if (logContent.length == 0) karate.log('WARN: No se generaron logs nuevos desde ' + logTs)
