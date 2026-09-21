package com.xin.server.model;

import java.util.Random;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.MapTable;
import com.xin.server.model.ai.AiManager;
import com.xin.server.model.ai.AiState;
import com.xin.server.model.instance.NpcInstance;
import com.xin.server.template.MapTemplate;
import com.xin.server.thread.ThreadPoolManager;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.ClientManager;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.server.S_Attack;
import com.xin.server.packet.server.S_HpUpdate;
import com.xin.server.packet.server.S_ObjectRemove;
import com.xin.server.types.AttackAnimType;
import com.xin.server.types.NpcType;
import com.xin.server.world.World;

/**
 * 戰鬥判定：命中、傷害、死亡處理。
 * <p>
 * 玩家打怪與怪打玩家<b>共用這裡</b>。分開寫的話兩邊的傷害公式遲早會分岔，
 * 而「玩家打怪 10 點、怪打玩家 30 點」這種不對稱很難從程式碼看出是不是故意的。
 * <p>
 * <b>攻擊距離</b>近戰一律是 Chebyshev 距離 ≤ 1（八方相鄰）。等距地圖上
 * 斜角與正向的視覺距離不同，但格子邏輯一律當成一格 —— 與移動的判定一致。
 */
public final class Combat {

    private static final Logger _log = LoggerFactory.getLogger(Combat.class);

    private static final Random RNG = new Random();

    /** 近戰攻擊距離（格）。 */
    public static final int MELEE_RANGE = 1;

    /** 傷害浮動：實際傷害 = 基礎 × (1 ± VARIANCE)。 */
    private static final double VARIANCE = 0.2;

    private Combat() {
    }

    /** 兩點的 Chebyshev 距離（八方向各算一格）。 */
    public static int distance(int x1, int y1, int x2, int y2) {
        return Math.max(Math.abs(x1 - x2), Math.abs(y1 - y2));
    }

    /** 基礎命中率（雙方命中與閃避相等時）。 */
    private static final int BASE_HIT_RATE = 75;

    /** 命中與閃避每差 1 點，命中率變動幾個百分點。 */
    private static final int HIT_PER_POINT = 3;

    /**
     * 命中率的上下限。
     * <p>
     * <b>永遠留一線</b>：0% 表示某些組合永遠打不中、100% 表示閃避完全沒用，
     * 兩者都會讓玩家覺得數值壞掉。
     */
    private static final int MIN_HIT_RATE = 10;
    private static final int MAX_HIT_RATE = 95;

    /** 判定是否命中。 */
    public static boolean rollHit(int attackerHit, int targetDodge) {
        int rate = BASE_HIT_RATE + (attackerHit - targetDodge) * HIT_PER_POINT;
        rate = Math.max(MIN_HIT_RATE, Math.min(MAX_HIT_RATE, rate));
        return RNG.nextInt(100) < rate;
    }


    /**
     * 防禦的收益係數。防禦等於這個值時，減傷正好 50%。
     */
    private static final int DEFENSE_K = 100;

    /**
     * 套用防禦：<b>百分比減傷</b>，並且至少留 1 點傷害。
     * <p>
     * 減傷 = {@code 防禦 / (防禦 + K)}，遞減收益。不用「直接扣減」是因為
     * 現有資料的兩個數量級差太多 —— 玩家防禦 25、怪物一下打 4 到 7 點，
     * 扣減法會讓玩家完全免疫，而要救回來就得把每一隻怪的傷害都改成
     * 三十幾，等於為了公式去重寫資料。百分比制直接吃現有的數字：
     * 防禦 25 減傷 20%，防禦 0 全額承受。
     * <p>
     * 留下限 1 的理由則相同：防禦再高也只是「打得比較慢」，不會變成
     * 打不動的牆，讓玩家只剩換裝或放棄兩條路。
     */
    public static int applyDefense(int damage, int defense) {
        int d = Math.max(0, defense);
        int reduced = damage * DEFENSE_K / (d + DEFENSE_K);
        return Math.max(1, reduced);
    }

    /** 怪物傷害：base_damage + [0, rand_damage)。 */
    public static int rollNpcDamage(NpcInstance npc) {
        int base = npc.getBaseDamage();
        int rand = Math.max(0, npc.getRandDamage());
        return Math.max(1, base + (rand > 0 ? RNG.nextInt(rand + 1) : 0));
    }

    /** 依攻擊力算一次傷害，最低保證 1 —— 打不動的手感比數字漂亮重要。 */
    public static int rollDamage(int attack) {
        int base = Math.max(1, attack);
        double f = 1.0 + (RNG.nextDouble() * 2 - 1) * VARIANCE;
        return Math.max(1, (int) Math.round(base * f));
    }

    /**
     * 玩家攻擊怪物。
     *
     * @return 造成的傷害；未命中或不可攻擊回 {@code 0}
     */
    public static int playerAttack(Client client, PcInstance pc, NpcInstance target) {
        // 先判命中：沒中就只送動作（damage 0、hit false），血量不動
        // 戰鬥封包只送同一張地圖：別張圖的人收到也只會在自己畫面上找不到這兩個物件
        int mapId = target.getMapId();
        if (!rollHit(pc.getHit(), target.getDodge())) {
            PacketSender.broadcastToMap(mapId, S_Attack.miss(pc.getId(), target.getId()));
            // 沒打中也算出手：被動怪一樣要回頭找你
            target.getHate().add(pc.getId(), 0);
            AiManager.wake(target);
            return 0;
        }

        int damage = applyDefense(rollDamage(pc.getAttack()), target.getDefense());
        int hp = Math.max(0, target.getCurrentHp() - damage);
        target.setCurrentHp(hp);
        // 仇恨 = 累積傷害，第一個打中的人多加最大血量的 1/10
        int firstHitBonus = target.getMaxHp() / 10;
        target.getHate().addDamage(pc.getId(), damage, firstHitBonus);
        target.getDamageLog().addDamage(pc.getId(), damage, firstHitBonus);

        // 攻擊動作與血量分兩包：動作是表現、血量是狀態。
        // 前端可能只想更新血條而不重播動畫（例如中毒持續傷害）。
        // 血量 0 的這一包也是前端播死亡動畫的觸發點，必須在 S_OBJECT_REMOVE 之前送出。
        PacketSender.broadcastToMap(mapId, S_Attack.of(pc.getId(), target.getId(), damage,
                AttackAnimType.DIRECT, 0, 0, 0));
        PacketSender.broadcastToMap(mapId,
                S_HpUpdate.of(target.getId(), hp, target.getMaxHp()));

        if (hp <= 0) {
            onMonsterDeath(client, pc, target);
        } else {
            // 被打就醒來反擊，不必等下一次喚醒巡檢
            AiManager.wake(target);
        }
        return damage;
    }

    /**
     * 怪物攻擊玩家。
     * <p>
     * 血量變動<b>會存檔，但不是當下</b>：只標記 {@link PcInstance#markDirty()}，
     * 由 {@link CharacterSaveTask} 定期寫回，死亡、登出、關服時立即寫回。
     * 以前每挨一下就同步寫一次 DB（而且 {@code CharacterR} 內部還有全域鎖），
     * 怪物一多整個 AI 都會排在 MySQL 後面。
     */
    public static int monsterAttack(NpcInstance attacker, PcInstance target) {
        int mapId = target.getMapId();
        if (!rollHit(attacker.getHit(), target.getDodge())) {
            PacketSender.broadcastToMap(mapId,
                    S_Attack.miss(attacker.getId(), target.getId()));
            return 0;
        }

        // 怪物的傷害用 npc 表的 base_damage / rand_damage，不要另外發明一套 ——
        // 資料已經在 DB 裡，調數值應該改資料而不是改程式。
        int damage = applyDefense(rollNpcDamage(attacker), target.getDefense());
        int hp = Math.max(0, target.getCurrentHp() - damage);
        target.setCurrentHp(hp);
        target.markDirty();

        PacketSender.broadcastToMap(mapId, S_Attack.of(attacker.getId(), target.getId(),
                damage, AttackAnimType.DIRECT, 0, 0, 0));
        PacketSender.broadcastToMap(mapId,
                S_HpUpdate.of(target.getId(), hp, target.getMaxHp()));

        // 隊友的血條要跟著動。S_HP_UPDATE 雖然是廣播，但前端的隊伍欄讀的是
        // S_PARTY 的成員資料，所以這裡要另外刷新一次。
        PartyManager.refresh(target);

        if (hp <= 0) {
            // 這裡在地圖鎖內（AI 執行緒），而死亡處理要存檔、可能換圖：交給一般服務池
            ThreadPoolManager.get().general().execute("player-death:" + target.getName(),
                    () -> onPlayerDeath(target));
        }
        return damage;
    }

    /** 目標是否還能被攻擊（存在、同圖、不在安全區、是怪物、還活著）。 */
    public static boolean isAttackable(PcInstance pc, NpcInstance target) {
        return target != null
                && target.getMapId() == pc.getMapId()
                && !isSafeZone(target.getMapId())
                && NpcType.isAttackable(target.getType())
                && target.getCurrentHp() > 0;
    }

    /** 安全區（map.safe_zone=1）內雙方都不能攻擊；怪物也不會在安全區生成。 */
    public static boolean isSafeZone(int mapId) {
        MapTemplate map = MapTable.get().getMap(mapId);
        return map != null && map._safeZone;
    }

    private static void onMonsterDeath(Client client, PcInstance pc, NpcInstance npc) {
        // 必須經過 World：只從 WorldNpc 移除的話，World 的總表會永遠留著這隻死怪，
        // 之後任何用 objId 查物件的地方都會把牠「找回來」。
        // 順序固定：先停 AI（屍體不能再走一步）→ 移出世界（同時釋放占位格）→ 通知前端。
        // 血量 0 的 S_HP_UPDATE 已經在呼叫端先送出，前端才會播倒地動畫。
        npc.setAiState(AiState.DEAD);
        AiManager.unregister(npc.getId());
        World.get().removeObject(npc);
        PacketSender.broadcastToMap(npc.getMapId(), S_ObjectRemove.of(npc.getId()));

        // 經驗值：暫時用怪物最大血量當基準。真正的經驗表要等 npc 表加欄位，
        // 現在至少讓「打怪會變強」這條迴圈成立。
        // 加經驗會寫 DB，這裡還在地圖鎖內：交給一般服務池，不讓整張圖排在 MySQL 後面。
        final int exp = Math.max(1, npc.getMaxHp() / 2);
        ThreadPoolManager.get().general().execute("kill-reward:" + npc.getName(), () -> {
            UpdateRealm.addExp(pc, exp, client);
            ChallengeManager.recordKill(pc);
        });
        _log.info("怪物死亡 {} 被 {} 擊殺，給予經驗 {}",
                npc.getName(), pc.getName(), exp);

        // 波次生出來的怪不原地重生 —— 否則這一波永遠清不完，波次不會前進。
        // 固定生成點（spawnlist_monster）的怪才需要重生。
        if (!WaveManager.isWaveMonster(npc.getId())) {
            MonsterSpawner.scheduleRespawn(npc);
        }
    }

    private static void onPlayerDeath(PcInstance pc) {
        _log.info("角色死亡 {}", pc.getName());
        // 死亡是關鍵狀態，不等定期存檔：當下寫回，重登才不會「死了又滿血」
        CharacterSaveTask.flush(pc);
        Client client = null;
        for (Client c : ClientManager.getAll()) {
            if (c.hasActiveChar() && c.getActiveChar().getId() == pc.getId()) {
                client = c;
                break;
            }
        }
        // 挑戰中死亡 → 結算並送回洞府；不在挑戰中就只是倒下
        // （洞府本來不該有怪，走到這裡代表是測試或 GM 造成的）
        if (ChallengeManager.isInRun(pc)) {
            ChallengeManager.onDeath(client, pc);
        } else if (client != null) {
            client.sendPacket(com.xin.server.packet.server.S_Chat.system("你已倒下"));
        }
    }
}
