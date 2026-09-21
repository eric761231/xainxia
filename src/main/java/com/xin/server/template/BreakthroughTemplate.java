package com.xin.server.template;

import com.xin.server.datatables.BreakthroughTable;
import com.xin.server.inventory.InventoryManager;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;

/**
 * 境界突破條件查詢門面（資料來自 DB {@code breakthrough_requirement} 表）。
 * <p>
 * 突破所需道具、護體道具、成功機率等數值由 {@link BreakthroughTable} 從 DB 載入，
 * 方便策劃在不重啟伺服器的情況下熱更新突破條件。
 */
public final class BreakthroughTemplate {

    private static final org.slf4j.Logger LOG =
            org.slf4j.LoggerFactory.getLogger(BreakthroughTemplate.class);

    /**
     * 單次突破所需條件（封裝類，對外透過 getter 存取）。
     * 由 {@link BreakthroughTemplate#createRequirement} 建立，
     * 並由 {@link BreakthroughTable} 快取。
     */
    public static final class Requirement {
        private final int   _fromStage;             // 突破前境界（如：鍛體 = 0）
        private final int   _toStage;               // 突破後境界（如：練氣 = 1）
        private final int[] _requiredItemIds;        // 消耗道具編號陣列（空陣列 = 不需要道具）
        private final int[] _protectItemIds;         // 護體道具編號陣列（空陣列 = 無護體選項）
        private final int   _maxRealmLevel;          // 突破前需達到的境界最高等級
        private final int   _baseSuccessRate;        // 基礎成功機率（0～100）
        private final int   _increaseSuccessRate;    // 持有護體道具時的額外成功機率加成（0～100）

        Requirement(int fromStage, int toStage,
                int[] requiredItemIds, int[] protectItemIds,
                int maxRealmLevel, int baseSuccessRate, int increaseSuccessRate) {
            _fromStage            = fromStage;
            _toStage              = toStage;
            _requiredItemIds      = requiredItemIds;
            _protectItemIds       = protectItemIds;
            _maxRealmLevel        = maxRealmLevel;
            _baseSuccessRate      = baseSuccessRate;
            _increaseSuccessRate  = increaseSuccessRate;
        }

        public int getFromStage() {
            return _fromStage;
        }

        public int getToStage() {
            return _toStage;
        }

        /** 突破所需消耗的道具編號陣列；空陣列表示不需要消耗道具。 */
        public int[] getRequiredItemIds() {
            return _requiredItemIds;
        }

        /** 護體道具編號陣列；空陣列表示此境界突破無護體選項。 */
        public int[] getProtectItemIds() {
            return _protectItemIds;
        }

        /** 突破前需達到的境界最高等級（未達此等級不可嘗試突破）。 */
        public int getMaxRealmLevel() {
            return _maxRealmLevel;
        }

        /** 基礎成功機率（0～100）。 */
        public int getBaseSuccessRate() {
            return _baseSuccessRate;
        }

        /** 持有護體道具時的額外成功機率加成（0～100），與基礎機率相加使用。 */
        public int getIncreaseSuccessRate() {
            return _increaseSuccessRate;
        }

        /** 是否有護體道具選項。 */
        public boolean hasProtectItems() {
            return _protectItemIds.length > 0;
        }
    }

    private BreakthroughTemplate() {
    }

    /**
     * 建立一個 {@link Requirement} 實例（供 {@link BreakthroughTable} 呼叫）。
     */
    public static Requirement createRequirement(int fromStage, int toStage,
            int[] requiredItemIds, int[] protectItemIds,
            int maxRealmLevel, int baseSuccessRate, int increaseSuccessRate) {
        return new Requirement(fromStage, toStage,
                requiredItemIds, protectItemIds,
                maxRealmLevel, baseSuccessRate, increaseSuccessRate);
    }

    /**
     * 查詢指定境界（fromStage）的突破需求。
     * 資料由 {@link BreakthroughTable} 從 DB 載入。
     *
     * @param fromStage 目前境界（{@link RealmTemplate} 常數）
     * @return 突破需求；若已是最高境界或 DB 無此境界設定則回傳 {@code null}
     */
    public static Requirement getRequirement(int fromStage) {
        if (!RealmTemplate.hasNextStage(fromStage)) {
            return null;
        }
        return BreakthroughTable.get().getRequirement(fromStage);
    }

    /**
     * 檢查並消耗突破所需道具。
     * <p>
     * <b>先全部檢查、再一次扣除。</b>需要三種丹藥而只有兩種時，如果邊檢查邊扣，
     * 玩家會白白損失前兩種 —— 付了代價卻沒拿到結果，比直接失敗糟糕得多。
     *
     * @param client 用來推送背包變動；離線流程可傳 {@code null}
     * @return 道具齊全並已扣除回 {@code true}；不足則<b>什麼都不扣</b>回 {@code false}
     */
    public static boolean checkAndConsumeItems(Client client, PcInstance pc,
            Requirement req) {
        if (req == null) {
            return false;
        }
        int[] need = req.getRequiredItemIds();
        if (need == null || need.length == 0) {
            return true;
        }

        for (int itemId : need) {
            if (!pc.getInventory().has(itemId, 1)) {
                return false;
            }
        }
        for (int itemId : need) {
            if (!InventoryManager.consume(client, pc, itemId, 1)) {
                // 上面才剛檢查過，走到這裡代表狀態被別的地方改動了
                LOG.error("突破扣道具失敗（檢查時還在）：char={} item={}",
                        pc.getName(), itemId);
                return false;
            }
        }
        return true;
    }

    /** 角色是否持有護體道具（用於計算是否套用護體機率加成）。 */
    public static boolean hasProtectItem(PcInstance pc, Requirement req) {
        if (req == null) {
            return false;
        }
        int[] protect = req.getProtectItemIds();
        if (protect == null) {
            return false;
        }
        for (int itemId : protect) {
            if (pc.getInventory().has(itemId, 1)) {
                return true;
            }
        }
        return false;
    }
}
