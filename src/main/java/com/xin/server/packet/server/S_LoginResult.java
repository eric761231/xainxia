package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.template.AccountTemp;

/**
 * 伺服器登入結果封包
 */
public class S_LoginResult extends ServerBasePacket {

    /** 登入成功 */
    public static final int REASON_LOGIN_OK = 0;

    /** 密碼錯誤 */
    public static final int REASON_PASS_CHECK = 10;

    /** 帳號已在使用中 */
    public static final int REASON_ACCOUNT_IN_USE = 22;

    /** 帳號無法使用（封鎖） */
    public static final int REASON_ACCOUNT_BAN = 93;

    /** 連線人數已滿 */
    public static final int REASON_MAX_PLAYER = 39;

    private S_LoginResult(int reason) {
        super(ServerOpcodes.S_LOGIN_RESULT);
        put("reason", reason);
        put("success", reason == REASON_LOGIN_OK);
    }

    public static S_LoginResult of(int reason) {
        return new S_LoginResult(reason);
    }

    public static S_LoginResult ok(AccountTemp account) {
        S_LoginResult packet = new S_LoginResult(REASON_LOGIN_OK);
        packet.put("account", account.getAccountName());
        packet.put("accessLevel", account.getAccessLevel());
        packet.put("serverNo", account.getServerNo());
        packet.put("serverName", account.getServerName() != null ? account.getServerName() : "");
        return packet;
    }

    public static S_LoginResult fail(int reason) {
        return new S_LoginResult(reason);
    }
}
