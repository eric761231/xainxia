package com.xin.server.datatables.lock;

import java.util.List;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;
import com.xin.server.datatables.sql.CharacterTable;
import com.xin.server.datatables.storage.CharacterS;
import com.xin.server.model.instance.PcInstance;

public class CharacterR {

    private final Lock _lock = new ReentrantLock(true);
    private final CharacterS _storage = new CharacterTable();
    private static CharacterR _instance;

    public static CharacterR get() {
        if (_instance == null) {
            _instance = new CharacterR();
        }
        return _instance;
    }

    public void load() {
        _lock.lock();
        try {
            _storage.load();
        } finally {
            _lock.unlock();
        }
    }

    public List<PcInstance> loadByAccount(String accountName) {
        _lock.lock();
        try {
            return _storage.loadByAccount(accountName);
        } finally {
            _lock.unlock();
        }
    }

    public PcInstance loadCharacter(String accountName, String charName) {
        _lock.lock();
        try {
            return _storage.loadCharacter(accountName, charName);
        } finally {
            _lock.unlock();
        }
    }

    public PcInstance findByName(String accountName, String charName) {
        _lock.lock();
        try {
            return _storage.findByName(accountName, charName);
        } finally {
            _lock.unlock();
        }
    }

    public boolean isCharNameTaken(String charName) {
        _lock.lock();
        try {
            return _storage.isCharNameTaken(charName);
        } finally {
            _lock.unlock();
        }
    }

    public boolean insertCharacter(PcInstance pc) {
        _lock.lock();
        try {
            return _storage.insertCharacter(pc);
        } finally {
            _lock.unlock();
        }
    }

    public void storeCharacter(PcInstance pc) {
        _lock.lock();
        try {
            _storage.storeCharacter(pc);
        } finally {
            _lock.unlock();
        }
    }

    public int countByAccount(String accountName) {
        _lock.lock();
        try {
            return _storage.countByAccount(accountName);
        } finally {
            _lock.unlock();
        }
    }

    public boolean deleteCharacter(String accountName, String charName) {
        _lock.lock();
        try {
            return _storage.deleteCharacter(accountName, charName);
        } finally {
            _lock.unlock();
        }
    }

    public enum CreateCharOutcome {
        SUCCESS,
        SLOT_FULL,
        NAME_EXISTS,
        DB_ERROR
    }

    /**
     * 帳號級原子創角：槽位、名稱、寫入在同一把鎖內完成，避免並發雙重通過校驗。
     */
    public CreateCharOutcome tryCreateCharacter(String accountName, PcInstance pc, int maxSlots) {
        _lock.lock();
        try {
            if (_storage.countByAccount(accountName) >= maxSlots) {
                return CreateCharOutcome.SLOT_FULL;
            }
            if (_storage.isCharNameTaken(pc.getName())) {
                return CreateCharOutcome.NAME_EXISTS;
            }
            if (!_storage.insertCharacter(pc)) {
                if (_storage.isCharNameTaken(pc.getName())) {
                    return CreateCharOutcome.NAME_EXISTS;
                }
                return CreateCharOutcome.DB_ERROR;
            }
            return CreateCharOutcome.SUCCESS;
        } finally {
            _lock.unlock();
        }
    }
}
