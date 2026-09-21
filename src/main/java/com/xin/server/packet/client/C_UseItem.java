package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.inventory.InventoryManager;
import com.xin.server.model.instance.ItemInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_Chat;
import com.xin.server.packet.server.S_HpUpdate;
import com.xin.server.template.ItemTemplate;

/**
 * 使用道具。
 * JSON: { "op": "C_USE_ITEM", "data": { "objId": 12345 } }
 * <p>
 * <b>效果目前只實作了治癒藥水</b>。其餘可使用的道具（突破丹藥）由突破流程
 * 自己消耗，不從背包點擊觸發；真正的通用道具效果表要等技能／狀態系統就緒。
 * 這裡對沒有實作效果的道具<b>不扣除</b> —— 扣了卻沒效果比不能用更糟。
 */
public class C_UseItem extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_UseItem.class);

    /** 治癒藥水（item.item_id = 40010）。 */
    private static final int HEAL_POTION = 40010;
    private static final int HEAL_AMOUNT = 50;

    private final long objId;

    public C_UseItem(String raw) {
        super(raw);
        objId = getLong("objId", 0L);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_USE_ITEM 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();

        ItemInstance it = pc.getInventory().getItem(objId);
        if (it == null) {
            client.sendPacket(S_Chat.system("沒有這件道具"));
            return;
        }
        ItemTemplate temp = it.getItem();
        if (temp == null || temp.getUseType() != 1) {
            client.sendPacket(S_Chat.system("「" + it.getName() + "」不能使用"));
            return;
        }

        if (it.getItemId() != HEAL_POTION) {
            // 有 use_type=1 但還沒有效果的道具（例如突破丹藥）
            client.sendPacket(S_Chat.system("「" + it.getName() + "」的效果尚未開放"));
            return;
        }

        int before = pc.getCurrentHp();
        int healed = Math.min(HEAL_AMOUNT, pc.getMaxHp() - before);
        if (healed <= 0) {
            client.sendPacket(S_Chat.system("氣血已滿"));
            return;
        }

        // 先扣道具再給效果：扣除失敗就什麼都沒發生，不會有「喝了沒扣」的漏洞
        if (!InventoryManager.consume(client, pc, it.getItemId(), 1)) {
            client.sendPacket(S_Chat.system("道具不足"));
            return;
        }
        pc.setCurrentHp(before + healed);
        // 一定要存檔：血量改了不寫回 DB，登出重進就退回喝藥前的數字，
        // 玩家等於白喝。C_Move 改座標後也是同樣的作法。
        CharacterR.get().storeCharacter(pc);
        client.sendPacket(S_HpUpdate.of(pc.getId(), pc.getCurrentHp(), pc.getMaxHp()));
        client.sendPacket(S_Chat.system("使用「" + temp.getName() + "」，恢復 "
                + healed + " 點氣血"));
        logger.info("使用道具 char={} item={} hp {}→{}",
                pc.getName(), temp.getName(), before, pc.getCurrentHp());
    }
}
