package com.xin.server.inventory;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.IdFactory;
import com.xin.server.datatables.CharacterItemTable;
import com.xin.server.datatables.ItemTable;
import com.xin.server.model.instance.ItemInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.server.S_ItemRemove;
import com.xin.server.packet.server.S_ItemUpdate;
import com.xin.server.template.ItemTemplate;

/**
 * 背包的增刪改：記憶體、資料庫、通知前端三件事一起做完。
 * <p>
 * <b>為什麼要有這一層</b>：加一件道具需要「找可疊加的那疊或建新的 → 寫 DB →
 * 推封包」三步，缺任何一步都會產生難查的症狀 —— 只改記憶體則重登消失、
 * 只寫 DB 則畫面不動、忘了疊加規則則同一種藥水佔滿背包。
 * 集中在這裡，呼叫端就不必記得這些。
 */
public final class InventoryManager {

    private static final Logger _log = LoggerFactory.getLogger(InventoryManager.class);

    private InventoryManager() {
    }

    /** 選角時把 DB 的道具灌進背包。 */
    public static void loadInto(PcInstance pc) {
        Inventory inv = pc.getInventory();
        inv.clearItems();
        List<ItemInstance> items = CharacterItemTable.get().load(pc.getId());
        for (ItemInstance it : items) {
            inv.storeItem(it);
        }
        _log.info("載入角色道具: {} 共{}件", pc.getName(), items.size());
    }

    /**
     * 給予道具。可疊加的併入既有那疊，否則建立新的一筆。
     *
     * @return 實際受影響的道具實例；失敗（模板不存在）回 {@code null}
     */
    public static ItemInstance addItem(Client client, PcInstance pc,
                                       int itemId, long count) {
        if (count <= 0) {
            return null;
        }
        ItemTemplate temp = ItemTable.get().getTemplate(itemId);
        if (temp == null) {
            _log.warn("給予道具失敗：不存在的 item_id={}", itemId);
            return null;
        }

        Inventory inv = pc.getInventory();
        ItemInstance stack = inv.findStackable(itemId, count);
        if (stack != null) {
            stack.setCount(stack.getCount() + count);
            CharacterItemTable.get().update(stack);
            notifyUpdate(client, stack);
            return stack;
        }

        ItemInstance it = new ItemInstance();
        it.setId(IdFactory.get().nextId());
        it.setItem(temp);
        it.setCount(count);
        it.setCharObjId(pc.getId());
        inv.storeItem(it);
        if (!CharacterItemTable.get().insert(it)) {
            // DB 寫失敗就把記憶體也還原，否則會出現「看得到但重登消失」
            inv.deleteItem(it.getId());
            return null;
        }
        notifyUpdate(client, it);
        return it;
    }

    /**
     * 扣除道具。數量不足時<b>不扣任何東西</b>並回傳 false。
     * <p>
     * 部分扣除會讓玩家付了代價卻沒拿到結果，比直接失敗糟糕得多。
     */
    public static boolean consume(Client client, PcInstance pc,
                                  int itemId, long count) {
        Inventory inv = pc.getInventory();
        List<Long> removed = inv.consume(itemId, count);
        if (removed == null) {
            return false;
        }

        // 被刪光的整筆刪 DB，還有剩的更新數量
        for (Long objId : removed) {
            CharacterItemTable.get().delete(objId, pc.getId());
            if (client != null) {
                client.sendPacket(S_ItemRemove.of(objId));
            }
        }
        for (ItemInstance it : inv.getItems()) {
            if (it.getItemId() == itemId) {
                CharacterItemTable.get().update(it);
                notifyUpdate(client, it);
            }
        }
        return true;
    }

    /**
     * 丟棄／刪除指定的一筆道具（整筆或部分數量）。
     *
     * @return 是否真的動到東西
     */
    public static boolean discard(Client client, PcInstance pc,
                                  long objId, long count) {
        Inventory inv = pc.getInventory();
        ItemInstance it = inv.getItem(objId);
        if (it == null || count <= 0) {
            return false;
        }
        long take = Math.min(count, it.getCount());
        it.setCount(it.getCount() - take);

        if (it.getCount() <= 0) {
            inv.deleteItem(objId);
            CharacterItemTable.get().delete(objId, pc.getId());
            if (client != null) {
                client.sendPacket(S_ItemRemove.of(objId));
            }
        } else {
            CharacterItemTable.get().update(it);
            notifyUpdate(client, it);
        }
        return true;
    }

    private static void notifyUpdate(Client client, ItemInstance it) {
        if (client != null) {
            client.sendPacket(S_ItemUpdate.of(it));
        }
    }
}
