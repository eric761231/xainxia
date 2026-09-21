package com.xin.server.gm;

import com.xin.server.datatables.MapTable;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.server.S_MapList;

/**
 * {@code .maps} —— 送出全部地圖清單。
 * <p>
 * GM 面板開啟時會自動呼叫，用來畫可傳送的地圖列表。
 * 清單以 {@link S_MapList} 的結構化資料送出，不是文字。
 */
public class GmMaps implements GmCommand {

    @Override
    public String name() {
        return "maps";
    }

    @Override
    public String usage() {
        return ".maps";
    }

    @Override
    public String description() {
        return "列出所有地圖（供 GM 面板傳送清單使用）";
    }

    @Override
    public String execute(Client client, PcInstance pc, String[] args) {
        client.sendPacket(S_MapList.of());
        return "已送出地圖清單（" + MapTable.get().getAll().size() + " 張）";
    }
}
