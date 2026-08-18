package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_LogoutResult;
import com.xin.server.service.AccountLogoutService;

public class C_AuthLogout extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_AuthLogout.class);

    public C_AuthLogout(String raw) {
        super(raw);
    }

    @Override
    public void run(Client client) {
        if (!client.isAuthenticated()) {
            logger.warn("C_AUTH_LOGOUT 失敗：尚未登入");
            client.sendPacket(S_LogoutResult.fail("尚未登入"));
            return;
        }

        if (AccountLogoutService.logout(client)) {
            client.sendPacket(S_LogoutResult.ok());
        } else {
            client.sendPacket(S_LogoutResult.fail("登出失敗"));
        }
    }
}
