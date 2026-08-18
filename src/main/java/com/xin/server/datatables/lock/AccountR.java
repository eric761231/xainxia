package com.xin.server.datatables.lock;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import com.xin.server.datatables.sql.AccountTable;
import com.xin.server.datatables.storage.AccountS;
import com.xin.server.template.AccountTemp;

/**
 * 帳號資料表讀寫鎖包裝（對齊天堂 AccountTable + ReentrantLock）
 */
public class AccountR {

    private final Lock _lock;
    private final AccountS _storage;
    private static AccountR _instance;

    private AccountR() {
        this._lock = new ReentrantLock(true);
        this._storage = new AccountTable();
    }

    public static AccountR get() {
        if (_instance == null) {
            _instance = new AccountR();
        }
        return _instance;
    }

    /** 預載入帳號名稱 */
    public void load() {
        _lock.lock();
        try {
            _storage.load();
        } finally {
            _lock.unlock();
        }
    }

    /**
     * 查詢帳號資料是否存在
     *
     * @param login_name 帳號名稱
     */
    public boolean isAccount(String login_name) {
        _lock.lock();
        try {
            return _storage.isAccount(login_name);
        } finally {
            _lock.unlock();
        }
    }

    /**
     * 建立新帳號
     *
     * @param login_name 帳號名稱
     * @param password   帳號密碼
     * @param ip         IP 位址
     * @param host       主機名稱
     */
    public AccountTemp createAccount(String login_name, String password, String ip, String host, int serverId,
            String serverName) {
        _lock.lock();
        try {
            return _storage.createAccount(login_name, password, ip, host, serverId, serverName);
        } finally {
            _lock.unlock();
        }
    }

    /**
     * 查詢帳號資料
     *
     * @param login_name 帳號名稱
     */
    public AccountTemp getAccount(String login_name) {
        _lock.lock();
        try {
            return _storage.getAccount(login_name);
        } finally {
            _lock.unlock();
        }
    }

    /** 更新帳號資料 */
    public void updateAccount(final AccountTemp temp) {
        _lock.lock();
        try {
            _storage.updateAccount(temp);
        } finally {
            _lock.unlock();
        }
    }

    /**
     * 計算該帳號已建立人物數量
     *
     * @param login_name 帳號名稱
     */
    public int getCharacterSize(String login_name) {
        _lock.lock();
        try {
            return _storage.getCharacterSize(login_name);
        } finally {
            _lock.unlock();
        }
    }
}
