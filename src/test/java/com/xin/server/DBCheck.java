package com.xin.server;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import com.xin.util.DatabaseFactory;

public class DBCheck {
    public static void main(String[] args) {
        System.out.println("=== Checking Database Connection ===");
        try {
            Connection conn = DatabaseFactory.getInstance().getConnection();
            System.out.println("Connection successful!");
            DatabaseMetaData metaData = conn.getMetaData();
            ResultSet rs = metaData.getColumns(null, null, "characters", null);
            System.out.println("Columns in 'characters' table:");
            boolean columnsFound = false;
            while (rs.next()) {
                columnsFound = true;
                String tableCat = rs.getString("TABLE_CAT");
                String columnName = rs.getString("COLUMN_NAME");
                String columnType = rs.getString("TYPE_NAME");
                int columnSize = rs.getInt("COLUMN_SIZE");
                System.out.println(" [" + tableCat + "] - " + columnName + " (" + columnType + ", size: " + columnSize + ")");
            }
            if (!columnsFound) {
                System.out.println("Table 'characters' not found or has no columns!");
            }
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
