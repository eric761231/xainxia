package com.xin.server;

import java.util.Collection;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.config.ServerConfig;
import com.xin.server.network.Client;
import com.xin.server.template.AccountTemp;

/**
 * 線上帳號管理
 */
public class OnlineUser {

    private static final Logger logger = LoggerFactory.getLogger(OnlineUser.class);

    private static OnlineUser instance;

    private final Map<String, Client> clientList = new ConcurrentHashMap<>();

    public static OnlineUser get() {
        if (instance == null) {
            instance = new OnlineUser();
        }
        return instance;
    }

    /**
     * 註冊已登入帳號
     */
    public boolean addClient(AccountTemp account, Client client) {
        String accountName = account.getAccountName().toLowerCase();
        Client existing = clientList.get(accountName);
        if (existing != null) {
            logger.warn("帳號重複登入：{}", accountName);
            return false;
        }

        account.setOnlineState(true);
        account.setServerNo(ServerConfig.SERVER_NO);
        client.setAccount(account);
        clientList.put(accountName, client);
        logger.info("帳號登入：{}，目前線上帳號：{}", accountName, clientList.size());
        return true;
    }

    public Client get(String accountName) {
        return clientList.get(accountName.toLowerCase());
    }

    public boolean isOnline(String accountName) {
        return clientList.containsKey(accountName.toLowerCase());
    }

    public boolean isMax() {
        return clientList.size() >= ServerConfig.MAX_ONLINE_USERS;
    }

    public int size() {
        return clientList.size();
    }

    public Collection<Client> all() {
        return clientList.values();
    }

    /**
     * 從線上表移除（記憶體）；DB 離線狀態由 {@link com.xin.server.service.AccountLogoutService} 寫入。
     */
    public void remove(String accountName) {
        if (accountName == null) {
            return;
        }
        Client removed = clientList.remove(accountName.toLowerCase());
        if (removed != null) {
            logger.info("帳號離線：{}，目前線上帳號：{}", accountName.toLowerCase(), clientList.size());
        }
    }
}
