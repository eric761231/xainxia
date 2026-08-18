package com.xin.server.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.OnlineUser;
import com.xin.server.datatables.lock.AccountR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.template.AccountTemp;
import com.xin.server.world.World;

/**
 * 帳號登出：更新 DB online_state、清除 OnlineUser 與 Client 綁定。
 */
public final class AccountLogoutService {

    private static final Logger logger = LoggerFactory.getLogger(AccountLogoutService.class);

    private AccountLogoutService() {
    }

    /**
     * @return 是否成功處理（帳號存在且已登出）
     */
    public static boolean logout(Client client) {
        if (client == null) {
            return false;
        }

        PcInstance activeChar = client.getActiveChar();
        if (activeChar != null) {
            World.get().removeObject(activeChar);
        }

        AccountTemp account = client.getAccount();
        if (account == null) {
            logger.warn("登出失敗：Client 尚未綁定帳號");
            return false;
        }

        String accountName = account.getAccountName();
        account.setOnlineState(false);
        account.setServerNo(0);
        account.setServerName("");
        AccountR.get().updateAccount(account);
        OnlineUser.get().remove(accountName);

        client.clearSession();
        logger.info("帳號登出：{}", accountName);
        return true;
    }
}
