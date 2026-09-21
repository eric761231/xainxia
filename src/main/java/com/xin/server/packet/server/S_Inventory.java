package com.xin.server.packet.server;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.model.instance.ItemInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.template.ItemTemplate;

/**
 * 整份背包（對應 opcode {@code S_INVENTORY}）。
 * <p>
 * 選角進遊戲時送一次。之後的變動走 {@link S_ItemUpdate}／{@link S_ItemRemove}
 * 的增量封包，不重送整份 —— 背包會越來越大，每撿一件就整包重送並不划算。
 * <p>
 * 每一件都附上模板欄位（名稱、類型、可否使用…），前端因此<b>不需要一份
 * item 表的副本</b>。道具定義只存在伺服器，前端改版不必跟著更新。
 */
public class S_Inventory extends ServerBasePacket {

    private S_Inventory(PcInstance pc) {
        super(ServerOpcodes.S_INVENTORY);
        ArrayNode arr = newArray();
        for (ItemInstance it : pc.getInventory().getItems()) {
            arr.add(describe(it));
        }
        putArray("items", arr);
        put("size", pc.getInventory().getSize());
    }

    /**
     * 一件道具的完整描述。{@link S_ItemUpdate} 也用同一組欄位 ——
     * 兩邊格式一致，前端只需要一條解析路徑。
     */
    static void fill(ObjectNode n, ItemInstance it) {
        n.put("objId", it.getId());
        n.put("itemId", it.getItemId());
        n.put("count", it.getCount());
        n.put("enchantLevel", it.getEnchantLevel());
        n.put("equipped", it.isEquipped());
        n.put("identified", it.isIdentified());

        ItemTemplate t = it.getItem();
        n.put("name", t != null ? t.getName() : "");
        n.put("itemType", t != null ? t.getItemType() : 0);
        n.put("stackable", t != null && t.isStackable());
        n.put("usable", t != null && t.getUseType() == 1);
        n.put("weaponType", t != null ? t.getWeaponType() : 0);
        n.put("armorType", t != null ? t.getArmorType() : 0);
    }

    private ObjectNode describe(ItemInstance it) {
        ObjectNode n = newObject();
        fill(n, it);
        return n;
    }

    public static S_Inventory of(PcInstance pc) {
        return new S_Inventory(pc);
    }
}
