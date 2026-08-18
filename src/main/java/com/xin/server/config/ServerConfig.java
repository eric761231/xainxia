package com.xin.server.config;

import com.xin.server.datatables.ConfigTable;
/**
 * 伺�??�基?�設�?
 */
public final class ServerConfig {

    ConfigTable table = ConfigTable.get();

    private static ServerConfig _instance;

    public static ServerConfig get() {
		if (_instance == null) {
			_instance = new ServerConfig();
		}
		return _instance;
	}
	
	public void reload() {
		_instance = new ServerConfig();
	}

    /** 伺�??�編??*/
    public static int SERVER_NO = 1;

    /** ?�大�??�在線人??*/
    public static int MAX_ONLINE_USERS = 500;

    /** 帳�?不�??��??�否?��?建�? */
    public static boolean AUTO_CREATE_ACCOUNTS = true;

    /** 伺�??��?�?**/
    public static String SERVER_NAME = "?��?神�?";

    private ServerConfig() {
    	
    	SERVER_NO = Integer.parseInt(table.getConfigData("server_no", "500"));
    	AUTO_CREATE_ACCOUNTS = Boolean.getBoolean(table.getConfigData("auto_create_accounts", "true"));
    	MAX_ONLINE_USERS = Integer.parseInt(table.getConfigData("max_online_users", "500"));
        // 伺�??��?�?
        SERVER_NAME = table.getConfigData("server_name", "?��?神�?");
    }
}
