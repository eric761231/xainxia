package com.xin.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class SQLUtil {

    /** 关闭 */
    public static void close(Statement stmt) {
        if (stmt != null) {
            try {
                stmt.close();
            } catch (final SQLException e) {
                e.printStackTrace();
            }
        }
    }

    /** 关闭 */
    public static void close(PreparedStatement stmt) {
        if (stmt != null) {
            try {
                stmt.close();
            } catch (final SQLException e) {
                e.printStackTrace();
            }
        }
    }

    /** 关闭 */
    public static void close(ResultSet rs) {
        if (rs != null) {
            try {
                rs.close();
            } catch (final SQLException e) {
                e.printStackTrace();
            }
        }
    }

    /** 关闭 */
    public static void close(Connection con) {
        if (con != null) {
            try {
                con.close();
            } catch (final SQLException e) {
                e.printStackTrace();
            }
        }
    }

    /** 关闭 */
    public static void close(Connection con, PreparedStatement stmt, ResultSet rs) {
        SQLUtil.close(rs);
        SQLUtil.close(stmt);
        SQLUtil.close(con);
    }

    /** 关闭 */
    public static void close(Connection con, Statement stmt, ResultSet rs) {
        SQLUtil.close(rs);
        SQLUtil.close(stmt);
        SQLUtil.close(con);
    }
}
