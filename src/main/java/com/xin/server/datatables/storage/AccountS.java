package com.xin.server.datatables.storage;

import com.xin.server.template.AccountTemp;

public interface AccountS {

    /** 預載入帳號名稱 */
    void load();

    /** 建立新帳號 */
    AccountTemp createAccount(final String login_name, final String password, final String ip, final String host,
            final int serverId, final String serverName);

    /** 查詢帳號資料是否存在 */
    boolean isAccount(final String loginName);

    /** 查詢帳號資料 */
    AccountTemp getAccount(final String loginName);

    /** 更新帳號資料 */
    void updateAccount(final AccountTemp account);

    /** 查詢帳號角色數量 */
    int getCharacterSize(final String loginName);
}
