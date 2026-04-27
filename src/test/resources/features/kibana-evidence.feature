@ignore
Feature: Kibana Evidence Gathering
  # Feature auxiliar: consulta Elasticsearch via el proxy de Kibana (:5602/elasticsearch)
  # para obtener logs del servicio desde el timestamp indicado.
  # Es llamada desde otros features via karate.call() dentro de un bloque try-catch.

  Background:
    * def KIBANA_URL   = karate.get('KIBANA_URL')
    * def KIBANA_USER  = karate.get('KIBANA_USER')
    * def KIBANA_PASS  = karate.get('KIBANA_PASS')
    * def KIBANA_INDEX = karate.get('KIBANA_INDEX')
    * def logTs        = karate.get('logTs',        '1970-01-01T00:00:00Z')
    * def appName      = karate.get('appName', karate.get('APP_NAME'))

  Scenario: Obtener logs desde Kibana/Elasticsearch

    * configure ssl             = true
    * configure connectTimeout  = 8000
    * configure readTimeout     = 15000

    # ── Credenciales en Base64 para Basic Auth ─────────────────────
    * def Base64 = Java.type('java.util.Base64')
    * def encoded = Base64.getEncoder().encodeToString((KIBANA_USER + ':' + KIBANA_PASS).getBytes('UTF-8'))
    * def authHeader = 'Basic ' + encoded

    # ── Query DSL: logs del app desde logTs hasta ahora ────────────
    * def searchBody =
      """
      {
        "size": 50,
        "sort": [{ "@timestamp": { "order": "asc" } }],
        "query": {
          "bool": {
            "must": [
              { "wildcard": { "kubernetes.labels.app": { "value": "*#(appName)*" } } },
              {
                "range": {
                  "@timestamp": {
                    "gte": "#(logTs)",
                    "lte": "now"
                  }
                }
              }
            ]
          }
        },
        "_source": ["@timestamp", "message", "log", "kubernetes.pod.name", "level", "severity"]
      }
      """

    # ── POST al proxy Elasticsearch de Kibana ─────────────────────
    Given url KIBANA_URL + '/elasticsearch/' + KIBANA_INDEX + '/_search'
    And header Authorization = authHeader
    And header Content-Type  = 'application/json'
    And header kbn-xsrf      = 'reporting'
    And request searchBody
    When method POST
    Then status 200

    # ── Procesar resultados ────────────────────────────────────────
    * def hits      = response.hits.hits
    * def totalHits = response.hits.total.value
    * karate.log('Kibana: ' + totalHits + ' log(s) encontrados para "' + appName + '" desde ' + logTs)

    # ── Formatear logs como texto plano ───────────────────────────
    * def buildLogLines =
      """
      function(hits) {
        if (!hits || hits.length === 0) return '(sin logs nuevos desde timestamp capturado)';
        var lines = [];
        for (var i = 0; i < hits.length; i++) {
          var src = hits[i]._source;
          var ts  = src['@timestamp'] || '';
          var msg = src['message'] || src['log'] || '';
          var pod = (src['kubernetes'] && src['kubernetes']['pod'] && src['kubernetes']['pod']['name'])
                    ? src['kubernetes']['pod']['name']
                    : 'pod-desconocido';
          lines.push('[' + ts + '] [' + pod + '] ' + msg);
        }
        return lines.join('\n');
      }
      """
    * def logContent = buildLogLines(hits)
    * def getPodName =
      """
      function(hits) {
        if (hits.length > 0 && hits[0]._source['kubernetes'] && hits[0]._source['kubernetes']['pod']) {
          return hits[0]._source['kubernetes']['pod']['name'];
        }
        return 'unknown';
      }
      """
    * def podName = getPodName(hits)
