package com.xin.server.gm;

import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;

/**
 * 一個 GM 指令。
 * <p>
 * 實作類別註冊到 {@link GmCommandHandler} 後即可使用，
 * 新增指令不需要新增封包 —— 全部共用 {@code C_GM_COMMAND}。
 */
public interface GmCommand {

    /** 指令名稱（不含前綴），例如 {@code tp}。 */
    String name();

    /** 用法說明，參數錯誤時回饋給玩家。 */
    String usage();

    /** 一句話說明，供 {@code .help} 列表使用。 */
    String description();

    /**
     * 執行指令。
     *
     * @param client 下指令的連線
     * @param pc     下指令的角色
     * @param args   指令名稱之後的參數（依空白切開，可能為空陣列）
     * @return 給玩家的結果訊息
     */
    String execute(Client client, PcInstance pc, String[] args);
}
