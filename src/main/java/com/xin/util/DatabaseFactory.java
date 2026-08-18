package com.xin.util;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

// 資料庫工廠類別
public class DatabaseFactory {

    private static DatabaseFactory instance;
    private static final Logger logger = LoggerFactory.getLogger(DatabaseFactory.class);
    
    private HikariDataSource dataSource;

    public static synchronized DatabaseFactory getInstance() {
        if (instance == null) {
            instance = new DatabaseFactory();
        }
        return instance;
    }

    public DatabaseFactory() {
        try (InputStream input = getClass().getClassLoader().getResourceAsStream("database.properties")) {
            Properties prop = new Properties();
            if (input == null) {
                logger.error("找不到 database.properties 設定檔！");
                return;
            }
            // 讀取設定檔
            prop.load(input);

            // 配置 HikariCP
            HikariConfig config = new HikariConfig();
            config.setDriverClassName(prop.getProperty("db.driverClassName"));
            config.setJdbcUrl(prop.getProperty("db.url"));
            config.setUsername(prop.getProperty("db.username"));
            config.setPassword(prop.getProperty("db.password"));

            // 連接池設定
            config.setMaximumPoolSize(Integer.parseInt(prop.getProperty("hikari.maximumPoolSize", "10")));
            config.setMinimumIdle(Integer.parseInt(prop.getProperty("hikari.minimumIdle", "2")));
            config.setIdleTimeout(Long.parseLong(prop.getProperty("hikari.idleTimeout", "30000")));
            config.setConnectionTimeout(Long.parseLong(prop.getProperty("hikari.connectionTimeout", "10000")));
            config.setMaxLifetime(Long.parseLong(prop.getProperty("hikari.maxLifetime", "600000")));

            // 初始化資料來源
            dataSource = new HikariDataSource(config);
            logger.info("資料庫連線池 (HikariCP) 初始化成功，目標資料庫: {}", prop.getProperty("db.url"));

        } catch (Exception e) {
            logger.error("初始化資料庫連線池時發生異常", e);
        }
    }

    // 取得資料庫連線
    public Connection getConnection() throws SQLException {
        if (dataSource == null) {
            throw new SQLException("資料來源未成功初始化！");
        }
        return dataSource.getConnection();
    }

    // 關閉連線池
    public void shutdown() {
        if (dataSource != null && !dataSource.isClosed()) {
            dataSource.close();
            logger.info("資料庫連線池已關閉。");
        }
    }
}