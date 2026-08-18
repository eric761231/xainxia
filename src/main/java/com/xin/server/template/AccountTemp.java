package com.xin.server.template;

import java.sql.Timestamp;

/**
 * 帳號連線記憶體物件（登入後存於 {@link com.xin.server.network.Client}）。
 * <p>
 * 儲存帳號的執行時狀態（IP、MAC、連線狀態、權限等），
 * 由 {@link com.xin.server.datatables.sql.AccountTable} 從 DB 查詢後填入。
 */
public class AccountTemp {

    private String _accountName;   // 帳號名稱
    private String _password;      // 帳號密碼（雜湊）
    private Timestamp _createTime; // 帳號建立時間
    private String _IP;            // 連線 IP 位址
    private String _macAddress;    // 連線 MAC 位址
    private int _serverNo;         // 伺服器編號
    private String _serverName;    // 伺服器名稱
    private boolean _onlineState;  // 帳號連線狀態
    private int _accessLevel;      // 帳號權限等級（0=一般玩家，100=GM）
    private boolean _isBan;        // 是否被封鎖
    private int _charSlot;         // 帳號角色槽位上限

    public String getAccountName() { 
    	return _accountName; 
    }
    public void setAccountName(String v) { 
    	_accountName = v; 
    }

    public String getPassword() { 
    	return _password; 
    }
    public void setPassword(String v) { 
    	_password = v; 
    }

    public Timestamp getCreateTime() { 
    	return _createTime; 
    }
    public void setCreateTime(Timestamp v) { 
    	_createTime = v; 
    }

    public String getIP() {
    	return _IP; 
    }
    public void setIP(String v) { 
    	_IP = v; 
    }

    public String getMacAddress() { 
    	return _macAddress; 
    }
    public void setMacAddress(String v) { 
    	_macAddress = v; 
    }

    public int getServerNo() { 
    	return _serverNo; 
    }
    public void setServerNo(int v) { 
    	_serverNo = v; 
    }

    public String getServerName() { 
    	return _serverName; 
    }
    public void setServerName(String v) { 
    	_serverName = v; 
    }

    public boolean getOnlineState() { 
    	return _onlineState; 
    }
    public void setOnlineState(boolean v) { 
    	_onlineState = v; 
    }

    public int getAccessLevel() { return 
    		_accessLevel; 
    }
    public void setAccessLevel(int v) { 
    	_accessLevel = v; 
    }

    public boolean isBan() { 
    	return _isBan; 
    }
    public void setBan(boolean v) { 
    	_isBan = v; 
    }

    public int getCharSlot() { 
    	return _charSlot; 
    }
    
    public void setCharSlot(int v) { 
    	_charSlot = v; 
    }
}
