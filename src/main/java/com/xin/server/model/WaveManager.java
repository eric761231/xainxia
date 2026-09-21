package com.xin.server.model;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.concurrent.atomic.AtomicBoolean;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.MapTable;
import com.xin.server.datatables.NpcTable;
import com.xin.server.datatables.WaveConfigTable;
import com.xin.server.model.instance.NpcInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.ClientManager;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.server.S_MonsterPack;
import com.xin.server.packet.server.S_Wave;
import com.xin.server.template.MapTemplate;
import com.xin.server.template.WaveConfigTemplate;
import com.xin.server.types.NpcType;
import com.xin.server.world.WorldMapGrid;
import com.xin.server.world.WorldNpc;

/**
 * 波次生怪：一波清完就進下一波，每波更多、更遠。
 * <p>
 * 與 {@link MonsterSpawner} 的差別是<b>誰決定生什麼</b>：MonsterSpawner 是
 * 「死掉的那隻原地復活」，波次則是「這一關該出幾隻」。兩者不該同時對同一隻怪
 * 生效，所以波次生出來的怪<b>不排程重生</b>（見 {@link NpcInstance} 的判斷）。
 * <p>
 * <b>只在指定的地圖跑。</b>洞府是玩家的家，本來不該一直冒怪 —— 但目前只有
 * 這張圖有完整的圖磚與碰撞資料，所以先在這裡跑。之後有戰鬥專用地圖就改
 * {@code wave_config.map_id}。
 * <p>
 * <b>目前停用</b>（{@link #ENABLED} = false）：{@code GameServer} 的啟動呼叫與下方的排程註冊都已註解。
 * 停用時 {@link #isWaveMonster} 一律回 false（怪物照常走生成點重生）、{@link #waveMapId} 回 -1
 * （秘境挑戰顯示「尚未開放」），且不會去讀 {@code wave_config}。
 */
public final class WaveManager {

    private static final Logger _log = LoggerFactory.getLogger(WaveManager.class);

    /** 波次管理開關。重新啟用時：改為 true、取消 {@link #start()} 與 {@code GameServer} 中的註解。 */
    public static final boolean ENABLED = false;

    /** 檢查「這一波清完了沒」的間隔。 */
    private static final long CHECK_MS = 1000;

    private static final Random RNG = new Random();
    private static final AtomicBoolean STARTED = new AtomicBoolean(false);

    private static volatile int _wave = 0;
    private static volatile int _breakLeft = 0;

    /**
     * 跑波次的地圖，來自 {@code wave_config}。
     * <p>
     * 一次只跑一張圖 —— 第幾波、剩幾隻這些狀態是單一份的，
     * 兩張圖同時跑會互相覆蓋。
     */
    public static int waveMapId() {
        if (!ENABLED) {
            return -1;
        }
        return WaveConfigTable.get().activeMapId();
    }

    /** 目前地圖的波次設定；沒有啟用的地圖時回 null。 */
    private static WaveConfigTemplate config() {
        int mapId = waveMapId();
        return mapId < 0 ? null : WaveConfigTable.get().getConfig(mapId);
    }

    /** 本波生出來的怪，用來判斷這一波清完了沒。 */
    private static final List<Long> _aliveIds = new ArrayList<>();

    private WaveManager() {
    }

    public static void start() {
        if (!ENABLED) {
            _log.info("波次系統已停用（WaveManager.ENABLED = false）");
            return;
        }
        if (!STARTED.compareAndSet(false, true)) {
            return;
        }
        WaveConfigTemplate cfg = config();
        if (cfg == null) {
            _log.info("波次系統未啟動：wave_config 沒有啟用中的地圖");
            return;
        }
        // 波次排程先註解，不啟用。重新啟用時取消註解（波次生怪屬於 NPC 工作，放 NPC 池）：
        // ThreadPoolManager.get().npc().scheduleWithFixedDelay("wave", CHECK_MS, CHECK_MS, WaveManager::tick);
        _log.info("波次系統已啟動（地圖{}，第一波 {} 隻，每波 +{}，{}種怪）",
                cfg._mapId, cfg._baseCount, cfg._perWave, cfg._npcs.size());
    }

    public static int currentWave() {
        return _wave;
    }

    /**
     * 這隻怪是不是波次生出來的。
     * <p>
     * 波次的怪<b>不能</b>再走 {@link MonsterSpawner} 的原地重生 —— 那會讓
     * 一波清不完（打死一隻、15 秒後又冒出來），波次永遠不會前進。
     */
    public static boolean isWaveMonster(long objId) {
        synchronized (_aliveIds) {
            return _aliveIds.contains(objId);
        }
    }

    /** 本波還活著的數量。 */
    public static int aliveCount() {
        synchronized (_aliveIds) {
            _aliveIds.removeIf(id -> {
                NpcInstance n = WorldNpc.get().get(id);
                return n == null || n.getCurrentHp() <= 0;
            });
            return _aliveIds.size();
        }
    }

    private static void tick() {
        WaveConfigTemplate cfg = config();
        if (cfg == null) {
            return;     // 設定被停用或刪掉了，安靜停手
        }

        // 沒有人在這張圖就整個暫停 —— 不然沒人看的地圖會一直堆怪
        if (playersOnMap() == 0) {
            if (_wave != 0) {
                reset();
            }
            return;
        }

        if (aliveCount() > 0) {
            broadcastState();
            return;
        }

        // 到這裡代表場上沒有本波的怪。三種情況：
        //   1. 還沒開始（_wave == 0）→ 直接開第一波，不用等
        //   2. 剛清完（倒數還沒起算）→ 起算倒數
        //   3. 倒數中 → 減一，歸零就開下一波
        if (_wave == 0) {
            spawnNextWave(cfg);
            return;
        }
        if (_breakLeft <= 0) {
            _breakLeft = cfg._breakSeconds;
            broadcastState();
            return;
        }
        _breakLeft--;
        if (_breakLeft <= 0) {
            spawnNextWave(cfg);
        } else {
            broadcastState();
        }
    }

    private static void spawnNextWave(WaveConfigTemplate cfg) {
        _wave++;
        int count = cfg.countForWave(_wave);
        MapTemplate map = MapTable.get().getMap(cfg._mapId);
        if (map == null) {
            _log.error("波次地圖不存在: {}", cfg._mapId);
            return;
        }

        int made = 0;
        synchronized (_aliveIds) {
            _aliveIds.clear();
            for (int i = 0; i < count; i++) {
                int[] pos = randomWalkable(cfg, map);
                if (pos == null) {
                    continue;   // 找不到空位就少生一隻，不要卡住整波
                }
                // 依權重抽一種已解鎖的怪（min_wave 讓強度階梯自己長出來）
                int npcId = cfg.rollNpcId(_wave, RNG);
                if (npcId == 0) {
                    continue;
                }
                NpcInstance npc = NpcTable.get()
                        .createNpc(npcId, pos[0], pos[1], cfg._mapId);
                if (npc == null) {
                    continue;
                }
                // 越後面的波次越硬。血量隨波次成長，傷害成長慢一點，
                // 否則第 5 波就會一下把玩家秒掉。
                int hp = npc.getMaxHp() + (_wave - 1) * cfg._hpPerWave;
                npc.setMaxHp(hp);
                npc.setCurrentHp(hp);
                npc.setBaseDamage(npc.getBaseDamage() + (_wave - 1) / 2);
                _aliveIds.add(npc.getId());
                made++;
            }
        }

        // 倒數歸零 —— 戰鬥進行中不該顯示「下一波 N」，那是清完之後的事
        _breakLeft = 0;
        PacketSender.broadcastAll(S_MonsterPack.of(cfg._mapId));
        broadcastState();
        _log.info("第 {} 波：生成 {} 隻（預定 {}）", _wave, made, count);
    }

    /**
     * 在某個玩家周圍的環形範圍內找一格可站的位置。
     * <p>
     * 不是整張地圖隨機 —— 那樣生出來的怪多半離玩家太遠，超出 AI 的察覺範圍
     * 就會站在原地不動，這一波永遠清不完（實測踩過：第 1 波卡住 60 秒）。
     * 倖存者玩法本來就該是「怪往你身上湧」。
     */
    private static int[] randomWalkable(WaveConfigTemplate cfg, MapTemplate map) {
        List<PcInstance> players = playersOnMapList();
        if (players.isEmpty()) {
            return null;
        }
        PcInstance anchor = players.get(RNG.nextInt(players.size()));

        for (int attempt = 0; attempt < 60; attempt++) {
            int span = Math.max(1, cfg._spawnMaxDist - cfg._spawnMinDist + 1);
            int dx = (RNG.nextInt(span) + cfg._spawnMinDist) * (RNG.nextBoolean() ? 1 : -1);
            int dy = (RNG.nextInt(span) + cfg._spawnMinDist) * (RNG.nextBoolean() ? 1 : -1);
            int x = anchor.getX() + dx;
            int y = anchor.getY() + dy;
            if (!map.isValidCoord(x, y)) {
                continue;
            }
            if (WorldMapGrid.get().isWalkable(cfg._mapId, x, y)) {
                return new int[] {x, y};
            }
        }
        return null;
    }

    private static List<PcInstance> playersOnMapList() {
        int mapId = waveMapId();
        List<PcInstance> out = new ArrayList<>();
        for (Client c : ClientManager.getAll()) {
            if (c.hasActiveChar() && c.getActiveChar().getMapId() == mapId) {
                out.add(c.getActiveChar());
            }
        }
        return out;
    }

    private static int playersOnMap() {
        return playersOnMapList().size();
    }

    /** 全部玩家下線後歸零，下次進來重新從第一波開始。 */
    private static void reset() {
        synchronized (_aliveIds) {
            for (Long id : _aliveIds) {
                NpcInstance n = WorldNpc.get().get(id);
                if (n != null && NpcType.isAttackable(n.getType())) {
                    WorldNpc.get().remove(id);
                }
            }
            _aliveIds.clear();
        }
        _wave = 0;
        _breakLeft = 0;
        _log.info("波次已重置（地圖{}沒有玩家）", waveMapId());
    }

    private static void broadcastState() {
        PacketSender.broadcastAll(
                S_Wave.of(_wave, aliveCount(), _breakLeft));
    }
}
