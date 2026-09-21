package com.xin.server.gm;

import java.util.Map;

import com.xin.server.model.ai.AiManager;
import com.xin.server.model.ai.AiState;
import com.xin.server.model.instance.NpcInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.thread.GameExecutor;
import com.xin.server.thread.ThreadPoolManager;
import com.xin.server.world.MapGrid;
import com.xin.server.world.MapLocks;
import com.xin.server.world.WorldMapGrid;
import com.xin.server.world.WorldNpc;

/**
 * {@code .ai} —— 觀察與操作 NPC AI。沒有測試框架，這是檢查 AI 狀態最直接的方式。
 * <ul>
 *   <li>{@code .ai} / {@code .ai stat}：醒著的 AI 數、所在地圖 NPC 數、NPC 執行緒池負載</li>
 *   <li>{@code .ai <objId>}：這隻 NPC 的狀態、目標、仇恨表、離家距離、攻擊冷卻</li>
 *   <li>{@code .ai grid}：以自己為中心印出格子（{@code M}=生物 {@code #}=擋路 {@code @}=自己）</li>
 *   <li>{@code .ai wake} / {@code .ai sleep}：叫醒／休眠目前地圖的所有 NPC</li>
 * </ul>
 */
public class GmAi implements GmCommand {

    private static final int GRID_RADIUS = 10;

    @Override
    public String name() {
        return "ai";
    }

    @Override
    public String usage() {
        return ".ai [stat|grid|wake|sleep|<objId>]";
    }

    @Override
    public String description() {
        return "查看與操作 NPC AI";
    }

    @Override
    public String execute(Client client, PcInstance pc, String[] args) {
        String sub = args.length == 0 ? "stat" : args[0].toLowerCase();
        int mapId = pc.getMapId();
        switch (sub) {
            case "stat": {
                GameExecutor npcPool = ThreadPoolManager.get().npc();
                return "醒著的 AI：" + AiManager.activeCount()
                        + "｜本圖 NPC：" + WorldNpc.get().getNpcsByMap(mapId).size()
                        + "｜NPC 執行緒池 執行中 " + npcPool.activeCount() + " / 排隊 " + npcPool.queuedCount();
            }
            case "grid": {
                MapGrid grid = WorldMapGrid.get().get(mapId);
                if (grid == null) {
                    return "地圖 " + mapId + " 沒有格子資料";
                }
                return MapLocks.call(mapId, () -> grid.dumpArea(pc.getX(), pc.getY(), GRID_RADIUS));
            }
            case "wake":
                return "已叫醒 " + AiManager.wakeMap(mapId) + " 隻";
            case "sleep":
                return "已休眠 " + AiManager.sleepMap(mapId) + " 隻";
            default:
                return describe(sub);
        }
    }

    private String describe(String arg) {
        long objId;
        try {
            objId = Long.parseLong(arg);
        } catch (NumberFormatException e) {
            return "用法：" + usage();
        }
        NpcInstance npc = WorldNpc.get().get(objId);
        if (npc == null) {
            return "找不到 NPC " + objId;
        }
        return MapLocks.call(npc.getMapId(), () -> {
            long now = System.currentTimeMillis();
            StringBuilder sb = new StringBuilder();
            sb.append(npc.getName()).append('（').append(objId).append('）')
              .append(" 狀態=").append(AiState.name(npc.getAiState()))
              .append(AiManager.isRunning(objId) ? "（醒著）" : "（休眠）")
              .append("\n位置=(").append(npc.getX()).append(',').append(npc.getY()).append(')')
              .append(" 家=(").append(npc.getHomeX()).append(',').append(npc.getHomeY()).append(')')
              .append(" 離家=").append(npc.distanceFromHome()).append('/').append(npc.getMovementDistance())
              .append("\n血量=").append(npc.getCurrentHp()).append('/').append(npc.getMaxHp())
              .append(" 走速=").append(npc.getPassiSpeed()).append("ms 攻速=").append(npc.getAtkSpeed())
              .append("ms 距離=").append(npc.getRanged())
              .append(" 下次攻擊=").append(Math.max(0, npc.getNextAttackAt() - now)).append("ms")
              .append("\n仇恨：");
            Map<Long, Integer> hate = npc.getHate().snapshot();
            if (hate.isEmpty()) {
                sb.append("（無）");
            }
            for (Map.Entry<Long, Integer> e : hate.entrySet()) {
                sb.append(e.getKey()).append('=').append(e.getValue()).append(' ');
            }
            return sb.toString();
        });
    }
}
