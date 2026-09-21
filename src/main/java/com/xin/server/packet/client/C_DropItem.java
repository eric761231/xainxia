package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.inventory.InventoryManager;
import com.xin.server.model.instance.ItemInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_Chat;

/**
 * 丟棄道具。
 * JSON: { "op": "C_DROP_ITEM", "data": { "objId": 12345, "count": 1 } }
 * <p>
 * 目前是<b>直接銷毀</b>，不會在地上生成可撿的物件 —— 地面道具需要
 * WorldItem 的生成與撿取流程，那是另一件事。
 */
public class C_DropItem extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_DropItem.class);

    private final long objId;
    private final long count;

    public C_DropItem(String raw) {
        super(raw);
        objId = getLong("objId", 0L);
        count = getLong("count", 1L);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_DROP_ITEM 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();

        ItemInstance it = pc.getInventory().getItem(objId);
        if (it == null) {
            client.sendPacket(S_Chat.system("沒有這件道具"));
            return;
        }
        if (it.isEquipped()) {
            client.sendPacket(S_Chat.system("裝備中的物品不能丟棄"));
            return;
        }

        String name = it.getName();
        if (!InventoryManager.discard(client, pc, objId, count)) {
            client.sendPacket(S_Chat.system("丟棄失敗"));
            return;
        }
        client.sendPacket(S_Chat.system("已丟棄「" + name + "」"));
        logger.info("丟棄道具 char={} item={} count={}", pc.getName(), name, count);
    }
}
