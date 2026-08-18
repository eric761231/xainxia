package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.xin.server.OnlineUser;
import com.xin.server.config.ServerConfig;
import com.xin.server.datatables.lock.AccountR;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_LoginResult;
import com.xin.server.service.AccountLogoutService;
import com.xin.server.template.AccountTemp;

import io.netty.channel.Channel;

/** 客戶端帳號登入封包 */
public class C_AuthLogin extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_AuthLogin.class);

    private static final String ALLOWED_ACCOUNT_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789";
    private static final String ALLOWED_PASSWORD_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789!_=+-?.#";

    private final String _account;
    private final String _password;

    private final int _serverNo = ServerConfig.SERVER_NO;
    private final String _serverName = ServerConfig.SERVER_NAME;

    public C_AuthLogin(String raw) {
        super(raw);
        _account = getString("account", "").toLowerCase();
        _password = getString("password", "");
    }

    @Override
    public void run(Client client) {
        if (!validateInput(client)) {
            return;
        }

        String ip = client.getIp();
        String host = client.getHost();

        AccountTemp accountData = AccountR.get().getAccount(_account);

        if (accountData == null) {
            if (ServerConfig.AUTO_CREATE_ACCOUNTS) {
                accountData = AccountR.get().createAccount(_account, _password, ip, host, _serverNo, _serverName);
            } else {
                client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_PASS_CHECK));
                return;
            }
        }

        if (accountData == null) {
            logger.warn("帳號建立失敗：{}", _account);
            client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_PASS_CHECK));
            return;
        }

        if (accountData.isBan()) {
            logger.warn("封鎖帳號嘗試登入：{} ip={}", _account, ip);
            client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_ACCOUNT_BAN));
            return;
        }

        if (!accountData.getPassword().equals(_password)) {
            client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_PASS_CHECK));
            return;
        }

        if (OnlineUser.get().isMax()) {
            logger.info("線上人數已達上限");
            client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_MAX_PLAYER));
            return;
        }

        resolveExistingSession(client, _account);

        Client existing = OnlineUser.get().get(_account);
        if (existing != null && existing != client) {
            logger.warn("帳號重複登入：{} ip={}", _account, ip);
            client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_ACCOUNT_IN_USE));
            return;
        }

        if (accountData.getOnlineState()
                && accountData.getServerNo() != 0
                && accountData.getServerNo() != ServerConfig.SERVER_NO) {
            logger.warn("帳號已登入其他伺服器：{} serverNo={}", _account, accountData.getServerNo());
            client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_ACCOUNT_IN_USE));
            return;
        }

        accountData.setIP(ip);
        accountData.setMacAddress(host);

        if (!OnlineUser.get().addClient(accountData, client)) {
            client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_ACCOUNT_IN_USE));
            return;
        }

        AccountR.get().updateAccount(accountData);
        client.sendPacket(S_LoginResult.ok(accountData));
        logger.info("登入成功：account={} ip={}", _account, ip);
    }

    private boolean validateInput(Client client) {
        if (_account.length() < 4 || _account.length() > 12) {
            logger.warn("不合法帳號長度：{} ip={}", _account, client.getIp());
            client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_PASS_CHECK));
            return false;
        }

        for (int i = 0; i < _account.length(); i++) {
            if (!ALLOWED_ACCOUNT_CHARS.contains(String.valueOf(_account.charAt(i)))) {
                logger.warn("不合法帳號字元：{} ip={}", _account, client.getIp());
                client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_PASS_CHECK));
                return false;
            }
        }

        if (_password.length() < 4 || _password.length() > 13) {
            logger.warn("不合法密碼長度：account={} ip={}", _account, client.getIp());
            client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_PASS_CHECK));
            return false;
        }

        for (int i = 0; i < _password.length(); i++) {
            String ch = String.valueOf(_password.charAt(i)).toLowerCase();
            if (!ALLOWED_PASSWORD_CHARS.contains(ch)) {
                logger.warn("不合法密碼字元：account={} ip={}", _account, client.getIp());
                client.sendPacket(S_LoginResult.fail(S_LoginResult.REASON_PASS_CHECK));
                return false;
            }
        }

        return true;
    }

    /**
     * 同一帳號再次登入時，踢掉仍佔線的舊連線，或清理 TCP 已斷但 OnlineUser 未清掉的幽靈紀錄。
     */
    private void resolveExistingSession(Client client, String account) {
        Client existing = OnlineUser.get().get(account);
        if (existing == null || existing == client) {
            return;
        }

        Channel channel = existing.getChannel();
        if (channel == null || !channel.isActive()) {
            logger.info("清理失效連線帳號：{}", account);
            OnlineUser.get().remove(account);
            AccountTemp stale = AccountR.get().getAccount(account);
            if (stale != null && stale.getOnlineState()) {
                stale.setOnlineState(false);
                stale.setServerNo(0);
                stale.setServerName("");
                AccountR.get().updateAccount(stale);
            }
            return;
        }

        logger.info("帳號 {} 重複登入，踢掉舊連線 {} ip={}",
                account, channel.remoteAddress(), client.getIp());
        AccountLogoutService.logout(existing);
        existing.disconnect();
    }
}
