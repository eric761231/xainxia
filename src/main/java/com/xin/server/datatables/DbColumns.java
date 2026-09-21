package com.xin.server.datatables;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * 讀資料表時容忍「後來才加的欄位」還不存在。
 * <p>
 * 資料庫升級是手動執行 migration 的；某一欄還沒加就讓整張表載入失敗的話，
 * 症狀會是「地圖上什麼都沒有」，跟 SQL 看起來毫無關係。改成缺欄位時用預設值
 * 並警告，半套升級只會退化，不會讓世界清空。
 */
final class DbColumns {

    private DbColumns() {
    }

    /** 結果集實際有的欄位名稱（小寫）。 */
    static Set<String> of(ResultSet rs) throws SQLException {
        ResultSetMetaData meta = rs.getMetaData();
        Set<String> out = new HashSet<>();
        for (int i = 1; i <= meta.getColumnCount(); i++) {
            out.add(meta.getColumnLabel(i).toLowerCase(Locale.ROOT));
        }
        return out;
    }

    /** 欄位存在就讀，不存在回傳預設值。 */
    static int intOr(ResultSet rs, Set<String> columns, String name, int def) throws SQLException {
        return columns.contains(name) ? rs.getInt(name) : def;
    }

    /** 字串欄位：存在就讀（null 轉空字串），不存在回傳預設值。 */
    static String stringOr(ResultSet rs, Set<String> columns, String name, String def) throws SQLException {
        if (!columns.contains(name)) {
            return def;
        }
        String v = rs.getString(name);
        return v != null ? v : "";
    }

    /** 列出 {@code wanted} 之中不存在的欄位，供警告用。 */
    static List<String> missing(Set<String> columns, String... wanted) {
        List<String> out = new ArrayList<>();
        for (String c : wanted) {
            if (!columns.contains(c)) {
                out.add(c);
            }
        }
        return out;
    }
}
