package utils;

import java.sql.*;
import java.util.*;

/**
 * DbUtils — Utilidad JDBC para validar impacto en base de datos desde Karate.
 *
 * Uso en un .feature:
 *   * def DbUtils = Java.type('utils.DbUtils')
 *   * def rows    = DbUtils.query("SELECT * FROM mi_tabla WHERE id = 123")
 *   * match rows[0].columna == 'valor_esperado'
 *
 * Para ejecutar un UPDATE/INSERT/DELETE sin retorno de filas:
 *   * DbUtils.execute("UPDATE mi_tabla SET estado = 'X' WHERE id = 123")
 *
 * La configuración de conexión se toma de las siguientes propiedades del sistema,
 * o bien de los valores por defecto que podés ajustar aquí abajo:
 *   -Ddb.url=jdbc:postgresql://host:5432/dbname
 *   -Ddb.user=usuario
 *   -Ddb.password=clave
 *
 * Si necesitás múltiples bases de datos podés llamar a los métodos
 * queryWith() / executeWith() pasando los parámetros de conexión explícitamente.
 */
public class DbUtils {

    // ── Configuración por defecto (sobreescribible con -D) ──────────────────
    private static final String DEFAULT_URL  = System.getProperty("db.url",      "");
    private static final String DEFAULT_USER = System.getProperty("db.user",     "");
    private static final String DEFAULT_PASS = System.getProperty("db.password", "");

    // ────────────────────────────────────────────────────────────────────────

    /**
     * Ejecuta un SELECT y devuelve una lista de mapas {columna -> valor}.
     * Llamable directamente desde Karate.
     */
    public static List<Map<String, Object>> query(String sql) throws Exception {
        return queryWith(DEFAULT_URL, DEFAULT_USER, DEFAULT_PASS, sql);
    }

    /**
     * Igual que query() pero con parámetros de conexión explícitos.
     * Útil cuando el test necesita conectarse a múltiples bases.
     */
    public static List<Map<String, Object>> queryWith(String url, String user, String pass, String sql) throws Exception {
        validateConnectionSettings(url, user);
        List<Map<String, Object>> rows = new ArrayList<>();
        try (Connection conn = DriverManager.getConnection(url, user, pass);
             Statement  stmt = conn.createStatement();
             ResultSet  rs   = stmt.executeQuery(sql)) {

            ResultSetMetaData meta = rs.getMetaData();
            int colCount = meta.getColumnCount();

            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                for (int i = 1; i <= colCount; i++) {
                    row.put(meta.getColumnName(i).toLowerCase(), rs.getObject(i));
                }
                rows.add(row);
            }
        }
        return rows;
    }

    /**
     * Ejecuta un INSERT / UPDATE / DELETE y devuelve las filas afectadas.
     * Llamable directamente desde Karate.
     */
    public static int execute(String sql) throws Exception {
        return executeWith(DEFAULT_URL, DEFAULT_USER, DEFAULT_PASS, sql);
    }

    /**
     * Igual que execute() pero con parámetros de conexión explícitos.
     */
    public static int executeWith(String url, String user, String pass, String sql) throws Exception {
        validateConnectionSettings(url, user);
        try (Connection conn = DriverManager.getConnection(url, user, pass);
             Statement  stmt = conn.createStatement()) {
            return stmt.executeUpdate(sql);
        }
    }

    private static void validateConnectionSettings(String url, String user) {
        if (url == null || url.isBlank() || user == null || user.isBlank()) {
            throw new IllegalStateException("DB config faltante. Defini -Ddb.url, -Ddb.user y -Ddb.password para ejecutar validaciones de base.");
        }
    }

    /**
     * Ejecuta un SELECT y devuelve sólo la primera fila (o null si no hay resultados).
     * Conveniente para buscar un registro único.
     */
    public static Map<String, Object> queryOne(String sql) throws Exception {
        List<Map<String, Object>> rows = query(sql);
        return rows.isEmpty() ? null : rows.get(0);
    }

    /**
     * Ejecuta un SELECT y devuelve el valor de la primera columna de la primera fila.
     * Útil para consultas tipo: SELECT COUNT(*) FROM ...
     */
    public static Object scalar(String sql) throws Exception {
        List<Map<String, Object>> rows = query(sql);
        if (rows.isEmpty()) return null;
        Map<String, Object> first = rows.get(0);
        return first.isEmpty() ? null : first.values().iterator().next();
    }
}

