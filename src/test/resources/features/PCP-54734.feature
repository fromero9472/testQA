Feature: PCP-54734

  Background:
    * url 'https://history-credit-profile-batch-claropay-ar-desa.apps.osen02.claro.amx'
    * def DbUtils = Java.type('utils.DbUtils')

  # ══════════════════════════════════════════════════════════════════
  Scenario: Ejecutar batch y validar transferencia de CREDIT_PROFILE a HISTORY
  # ══════════════════════════════════════════════════════════════════

    # ── Estado DB ANTES ────────────────────────────────────────────
    * def countBefore = DbUtils.scalar("SELECT COUNT(*) FROM CPAY_CREDIT_PROFILE.CREDIT_PROFILE")
    * karate.log('DB ANTES - Total registros en CREDIT_PROFILE: ' + countBefore)

    * def candidate = DbUtils.queryOne("SELECT * FROM CPAY_CREDIT_PROFILE.CREDIT_PROFILE WHERE ROWNUM = 1")
    * karate.log('DB ANTES - Candidato a procesar: ' + candidate)
    * def candidateId = candidate.id

    * def histBefore = DbUtils.queryOne("SELECT * FROM CPAY_CREDIT_PROFILE.HISTORY_CREDIT_PROFILE WHERE ID = " + candidateId)
    * karate.log('DB ANTES - Candidato en HISTORY (debe ser null): ' + histBefore)
    * match histBefore == null

    # ── Request ────────────────────────────────────────────────────
    Given path '/startBatch'
    When method GET
    Then status 200

    # ── Estado DB DESPUÉS ──────────────────────────────────────────
    * def countAfter = DbUtils.scalar("SELECT COUNT(*) FROM CPAY_CREDIT_PROFILE.CREDIT_PROFILE")
    * karate.log('DB DESPUES - Total registros en CREDIT_PROFILE: ' + countAfter)
    * assert countAfter <= countBefore

    * def histAfter = DbUtils.queryOne("SELECT * FROM CPAY_CREDIT_PROFILE.HISTORY_CREDIT_PROFILE WHERE ID = " + candidateId)
    * karate.log('DB DESPUES - Candidato en HISTORY: ' + histAfter)
    * match histAfter.id == candidateId
