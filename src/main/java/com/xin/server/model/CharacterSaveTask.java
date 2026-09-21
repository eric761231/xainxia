package com.xin.server.model;

import java.util.concurrent.atomic.AtomicBoolean;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.ClientManager;
import com.xin.server.thread.ThreadPoolManager;

/**
 * 角色定期存檔。
 * <p>
 * 頻繁變動的狀態（移動座標、挨打扣血）只標記 {@link PcInstance#markDirty()}，
 * 由這裡每 {@link #INTERVAL_MS} 毫秒把有變動的角色寫回 DB。以前這些地方都是當下
 * 同步寫 DB：玩家每走一步一次、每挨一下一次，而 {@link CharacterR} 內部還有一把全域鎖 ——
 * 人一多、怪一多，移動與怪物 AI 都會排在 MySQL 後面。
 * <p>
 * <b>取捨</b>：伺服器當機時，最多會遺失最後 {@link #INTERVAL_MS} 毫秒內的座標與血量。
 * 正常結束的路徑都會立即寫回 —— 死亡、登出／斷線（{@code Client.clearSession}）、
 * 關服（{@code ClientManager.shutdownAll}）都呼叫 {@link #flush(PcInstance)}。
 * 換圖、升級、使用道具這類低頻而重要的事件本來就當下存檔，不經過這裡。
 */
public final class CharacterSaveTask {

    private static final Logger _log = LoggerFactory.getLogger(CharacterSaveTask.class);

    /** 定期存檔間隔。 */
    private static final long INTERVAL_MS = 30_000;

    private static final AtomicBoolean STARTED = new AtomicBoolean(false);

    private CharacterSaveTask() {
    }

    /** 啟動定期存檔（一般服務池）。重複呼叫無效。 */
    public static void start() {
        if (!STARTED.compareAndSet(false, true)) {
            return;
        }
        ThreadPoolManager.get().general().scheduleWithFixedDelay(
                "char-save", INTERVAL_MS, INTERVAL_MS, CharacterSaveTask::saveDirty);
        _log.info("角色定期存檔已啟動（每 {} 秒）", INTERVAL_MS / 1000);
    }

    /** 把所有有變動的線上角色寫回 DB。 */
    static void saveDirty() {
        int saved = 0;
        for (Client client : ClientManager.getAll()) {
            PcInstance pc = client.getActiveChar();
            if (pc != null && pc.isDirty()) {
                flush(pc);
                saved++;
            }
        }
        if (saved > 0) {
            _log.debug("定期存檔：{} 名角色", saved);
        }
    }

    /**
     * 立即寫回一名角色。
     * <p>
     * 先清旗標再寫：寫入期間若又有變動，旗標會被重新設起，下一輪還會再存一次，
     * 不會因為競態把新變動漏掉。寫入失敗則把旗標設回，下一輪重試。
     */
    public static void flush(PcInstance pc) {
        if (pc == null) {
            return;
        }
        pc.clearDirty();
        try {
            CharacterR.get().storeCharacter(pc);
        } catch (RuntimeException e) {
            pc.markDirty();
            _log.error("角色存檔失敗：{}，下一輪重試", pc.getName(), e);
        }
    }
}
