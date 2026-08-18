package com.xin.server.datatables.sql;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.datatables.storage.AccountS;
import com.xin.server.template.AccountTemp;
import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * DB table: {@code accounts}（帳號資料表）
 */
public class AccountTable implements AccountS {

    private static final Logger _log = LoggerFactory.getLogger(AccountTable.class);

    /** 已註冊帳號名稱快取（login_name lower） */
    private final Map<String, String> _loginNameList = new HashMap<>();

    @Override
    public void load() {
        final PerformanceTimer timer = new PerformanceTimer();
        Connection co = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            co = DatabaseFactory.getInstance().getConnection();
            final String sqlstr = "SELECT * FROM `accounts`";
            ps = co.prepareStatement(sqlstr);
            rs = ps.executeQuery();

            while (rs.next()) {
                final String login_name = rs.getString("login_name").toLowerCase();
                _loginNameList.put(login_name, login_name);
            }

        } catch (final Exception e) {
            _log.error(e.getLocalizedMessage(), e);

        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(co);
            SQLUtil.close(rs);
        }
        _log.info("載入已註冊帳號名稱索引: {} ({}ms)", _loginNameList.size(), timer.get());
    }

    @Override
    public AccountTemp createAccount(final String login_name, final String password, final String ip, final String host,
            final int serverId, final String serverName) {
        Connection co = null;
        PreparedStatement ps = null;
        try {
            final AccountTemp value = new AccountTemp();

            value.setAccountName(login_name);
            value.setPassword(password);
            value.setIP(ip);
            value.setMacAddress(host);
            Timestamp now = new Timestamp(System.currentTimeMillis());
            value.setCreateTime(now);
            value.setServerNo(serverId);
            value.setServerName(serverName);
            value.setOnlineState(true);
            value.setAccessLevel(0);
            value.setBan(false);
            value.setCharSlot(2);

            co = DatabaseFactory.getInstance().getConnection();
            final String sqlstr = "INSERT INTO `accounts` (`login_name`, `password`, `ip`, `macAddress`, `createTime`, `server_no`, `server_name`, `online_state`, `access_level`, `isBan`, `char_slot`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            ps = co.prepareStatement(sqlstr);

            ps.setString(1, value.getAccountName());
            ps.setString(2, value.getPassword());
            ps.setString(3, value.getIP());
            ps.setString(4, value.getMacAddress());
            ps.setTimestamp(5, value.getCreateTime());
            ps.setInt(6, value.getServerNo());
            ps.setString(7, value.getServerName());
            ps.setBoolean(8, value.getOnlineState());
            ps.setInt(9, value.getAccessLevel());
            ps.setBoolean(10, value.isBan());
            ps.setInt(11, value.getCharSlot());
            ps.execute();
            _loginNameList.put(login_name.toLowerCase(), login_name.toLowerCase());
            _log.info("帳號 {} 已建立", login_name);
            return value;
        } catch (final Exception e) {
            _log.error(e.getLocalizedMessage(), e);
        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(co);
        }
        return null;
    }

    public boolean isAccount(final String loginName) {
        return _loginNameList.containsKey(loginName.toLowerCase());
    }

    public AccountTemp getAccount(final String loginName) {
        Connection co = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            co = DatabaseFactory.getInstance().getConnection();
            final String sqlstr = "SELECT * FROM `accounts` WHERE `login_name` = ?";
            ps = co.prepareStatement(sqlstr);
            ps.setString(1, loginName);
            rs = ps.executeQuery();
            if (rs.next()) {
                AccountTemp temp = new AccountTemp();
                temp.setAccountName(rs.getString("login_name"));
                temp.setPassword(rs.getString("password"));
                temp.setIP(rs.getString("ip"));
                temp.setMacAddress(rs.getString("macAddress"));
                temp.setServerNo(rs.getInt("server_no"));
                temp.setServerName(rs.getString("server_name"));
                temp.setOnlineState(rs.getBoolean("online_state"));
                temp.setAccessLevel(rs.getInt("access_level"));
                temp.setBan(rs.getBoolean("isBan"));
                temp.setCharSlot(rs.getInt("char_slot"));
                return temp;
            }
        } catch (final Exception e) {
            _log.error(e.getLocalizedMessage(), e);
        } finally {
            SQLUtil.close(co, ps, rs);
        }
        return null;
    }

    public void updateAccount(final AccountTemp value) {
        Connection con = null;
        PreparedStatement ps = null;
        int i = 1;
        try {
            con = DatabaseFactory.getInstance().getConnection();
            final String sqlstr = "UPDATE `accounts` SET `password`=?,`ip`=?,`server_no`=?,`server_name`=?,`online_state`=?,`access_level`=?,`isBan`=?,`char_slot`=? WHERE `login_name`=?";
            ps = con.prepareStatement(sqlstr);
            ps.setString(i++, value.getPassword());
            ps.setString(i++, value.getIP());
            ps.setInt(i++, value.getServerNo());
            ps.setString(i++, value.getServerName());
            ps.setBoolean(i++, value.getOnlineState());
            ps.setInt(i++, value.getAccessLevel());
            ps.setBoolean(i++, value.isBan());
            ps.setInt(i++, value.getCharSlot());
            ps.setString(i++, value.getAccountName());
            ps.executeUpdate();

        } catch (final Exception e) {
            _log.error(e.getLocalizedMessage(), e);

        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(con);
        }
    }

    public int getCharacterSize(final String loginName) {
        return CharacterR.get().countByAccount(loginName);
    }

}
