package com.xin.server.datatables;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * ??????
 */
public class ConfigTable {

    private final HashMap<String, String> _config = new HashMap<>();
    private static final Logger _log = LoggerFactory.getLogger(ConfigTable.class);

    public static ConfigTable _instance;

    public HashMap<String, String> get_config() {
        return _config;
    }

    public static ConfigTable get() {
        if (_instance == null) {
            _instance = new ConfigTable();
        }
        return _instance;
    }

    public void reload() {
        _config.clear();
        _instance = new ConfigTable();
    }

    public String getConfigData(final String parameter, final String defaultValue) {
        if (_config.containsKey(parameter)) {
            return _config.get(parameter);
        }
        _log.error(parameter + " has no setting in DB !! Use defaultValue= " + defaultValue);
        return defaultValue;
    }

    private ConfigTable() {
        load("_config");
    }

    private void load(final String tableName) {
        final PerformanceTimer timer = new PerformanceTimer();
        Connection cn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            cn = DatabaseFactory.getInstance().getConnection();
            ps = cn.prepareStatement("SELECT * FROM " + tableName);
            rs = ps.executeQuery();
            while (rs.next()) {
                final String parameter = rs.getString("parameter");
                final String value = rs.getString("value");
                if (_config.containsKey(parameter)) {
                    _log.error("[Errer]" + tableName + " has repeated parameter= " + parameter);
                } else {
                    _config.put(parameter, value);
                }
            }
        } catch (final SQLException e) {
            _log.error("error while creating ServerConfig table", e);
        } finally {
            SQLUtil.close(cn);
            SQLUtil.close(ps);
            SQLUtil.close(rs);
        }
        _log.info("載入Config資料量: {} ({}ms)", _config.size(), timer.get());
    }
}
