package com.xin.server.model;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.MapTable;
import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.server.S_GameOver;
import com.xin.server.packet.server.S_MapChange;
import com.xin.server.template.MapTemplate;

/**
 * 秘境挑戰：進圖打波次，死了結算後送回洞府，可以再挑戰。
 * <p>
 * <b>為什麼要獨立一張地圖</b>：波次會不斷冒怪，洞府是玩家的家（放家具、
 * 擺設、離線掛著），不該一直有怪。挑戰圖進去就開打、死了就出來，
 * 兩邊的語意完全不同。
 * <p>
 * 這裡也是<b>死亡的唯一出口</b>。在此之前玩家死了只能躺在原地
 * （不能攻擊、怪繼續打、只能重登），等於沒有出路。
 */
public final class ChallengeManager {

    private static final Logger _log = LoggerFactory.getLogger(ChallengeManager.class);

    /**
     * 挑戰地圖 —— 來自 {@code wave_config} 裡啟用中的那一張。
     * <p>
     * 不寫死是因為「哪張圖是秘境」是企劃決定，而且它必須跟波次跑的是<b>同一張</b>：
     * 兩邊各寫一個常數，改了一邊沒改另一邊，就會變成「進得去但不生怪」。
     */
    public static int challengeMapId() {
        return WaveManager.waveMapId();
    }

    /** 死亡或退出後回到的地圖（玩家的洞府）。 */
    public static final int HOME_MAP_ID = 0;

    /** 一次挑戰的紀錄。 */
    private static class Run {
        final long startMs = System.currentTimeMillis();
        int kills;
        int waveReached;
    }

    /** key = 角色 objId。只有正在挑戰中的玩家會在這裡。 */
    private static final Map<Long, Run> _runs = new ConcurrentHashMap<>();

    private ChallengeManager() {
    }

    public static boolean isInRun(PcInstance pc) {
        return pc != null && _runs.containsKey(pc.getId());
    }

    /** 擊殺計數。由 {@link Combat} 在怪物死亡時呼叫。 */
    public static void recordKill(PcInstance pc) {
        Run run = _runs.get(pc.getId());
        if (run != null) {
            run.kills++;
            run.waveReached = Math.max(run.waveReached, WaveManager.currentWave());
        }
    }

    /**
     * 進入挑戰。回傳錯誤訊息；成功回 {@code null}。
     */
    public static String enter(Client client, PcInstance pc) {
        if (isInRun(pc)) {
            return "你已經在挑戰中";
        }
        int mapId = challengeMapId();
        MapTemplate map = mapId < 0 ? null : MapTable.get().getMap(mapId);
        if (map == null) {
            return "挑戰地圖尚未開放";
        }

        // 進場一律回滿血。挑戰的難度應該來自波次，不是「上一場剩多少血」——
        // 帶著殘血進場只會讓玩家先自殺重來，那不是有意義的選擇。
        pc.setCurrentHp(pc.getMaxHp());
        _runs.put(pc.getId(), new Run());
        moveTo(client, pc, mapId, centerOf(map));
        _log.info("進入秘境 char={}", pc.getName());
        return null;
    }

    /** 主動離開（還沒死就退出）。 */
    public static void leave(Client client, PcInstance pc) {
        _runs.remove(pc.getId());
        MapTemplate home = MapTable.get().getMap(HOME_MAP_ID);
        if (home != null) {
            moveTo(client, pc, HOME_MAP_ID, centerOf(home));
        }
    }

    /**
     * 玩家死亡：結算、送回洞府。
     * <p>
     * 回滿血是刻意的 —— 死亡的代價是「這一輪結束」，不是「角色從此殘廢」。
     */
    public static void onDeath(Client client, PcInstance pc) {
        Run run = _runs.remove(pc.getId());
        int wave = run != null ? Math.max(run.waveReached, WaveManager.currentWave()) : 0;
        int kills = run != null ? run.kills : 0;
        int seconds = run != null
                ? (int) ((System.currentTimeMillis() - run.startMs) / 1000) : 0;

        pc.setCurrentHp(pc.getMaxHp());
        MapTemplate home = MapTable.get().getMap(HOME_MAP_ID);
        if (home != null) {
            moveTo(client, pc, HOME_MAP_ID, centerOf(home));
        }
        if (client != null) {
            client.sendPacket(S_GameOver.of(wave, kills, seconds));
        }
        _log.info("挑戰結束 char={} 第{}波 擊殺{} 撐了{}秒",
                pc.getName(), wave, kills, seconds);
    }

    private static int[] centerOf(MapTemplate map) {
        return new int[] {
            (map._minX + map._maxX) / 2,
            (map._minY + map._maxY) / 2,
        };
    }

    private static void moveTo(Client client, PcInstance pc, int mapId, int[] pos) {
        int fromMapId = pc.getMapId();
        pc.setMapId(mapId);
        pc.setX(pos[0]);
        pc.setY(pos[1]);
        CharacterR.get().storeCharacter(pc);
        if (client != null) {
            client.sendPacket(S_MapChange.of(mapId, pos[0], pos[1], pc.getHeading()));
            // 換圖後要重送地圖上的東西，否則前端會停在舊圖的物件狀態
            PacketSender.sendMapObjects(client, mapId);
        }
        // 兩張圖的名單都要更新：新圖的人看到他來，舊圖的人看到他走
        PacketSender.broadcastPcPackForMove(fromMapId, mapId);
    }
}
