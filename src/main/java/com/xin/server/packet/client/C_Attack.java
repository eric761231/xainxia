package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.Combat;
import com.xin.server.model.instance.NpcInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_Chat;
import com.xin.server.world.MapLocks;
import com.xin.server.world.WorldNpc;

/**
 * 攻擊目標。
 * JSON: { "op": "C_ATTACK", "data": { "targetObjId": 2000000001 } }
 * <p>
 * 驗證一律在伺服器做：目標存在、同一張地圖、不在安全區、是可攻擊的類型、還活著、
 * 且在攻擊距離內。前端只負責送出意圖 —— 與移動同樣的分工。
 * <p>
 * 死人不能攻擊：血量 0 的角色送 C_ATTACK 會被擋下，否則倒下之後還能繼續輸出。
 * <p>
 * 整個判定與傷害套用在<b>該地圖的鎖內</b>進行：怪物的 AI 也在改同一隻怪的血量與仇恨。
 */
public class C_Attack extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_Attack.class);

    /**
     * 玩家兩次攻擊的最短間隔（毫秒）。沒有這個限制的話，腳本可以用送封包的速度無限連打。
     * 太早的請求靜默忽略（正常前端一次點擊只送一包）。
     */
    private static final long PC_ATTACK_INTERVAL_MS = 500;

    private final long targetObjId;

    public C_Attack(String raw) {
        super(raw);
        targetObjId = getLong("targetObjId", 0L);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_ATTACK 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();

        if (pc.getCurrentHp() <= 0) {
            client.sendPacket(S_Chat.system("你已倒下，無法攻擊"));
            return;
        }

        long now = System.currentTimeMillis();
        if (now < pc.getNextAttackAt()) {
            return;
        }

        if (Combat.isSafeZone(pc.getMapId())) {
            client.sendPacket(S_Chat.system("此處無法攻擊"));
            return;
        }

        MapLocks.run(pc.getMapId(), () -> {
            NpcInstance target = WorldNpc.get().get(targetObjId);
            if (!Combat.isAttackable(pc, target)) {
                // 靜默拒絕的理由與 C_MOVE 一致：正常前端不會送出這種請求，
                // 會送的是延遲或作弊的客戶端，回訊息也沒有意義。
                logger.warn("C_ATTACK 拒絕（目標不可攻擊）：char={} target={}",
                        pc.getName(), targetObjId);
                return;
            }

            int dist = Combat.distance(pc.getX(), pc.getY(),
                    target.getX(), target.getY());
            if (dist > Combat.MELEE_RANGE) {
                client.sendPacket(S_Chat.system("距離太遠"));
                return;
            }

            pc.setNextAttackAt(now + PC_ATTACK_INTERVAL_MS);
            int damage = Combat.playerAttack(client, pc, target);
            logger.debug("攻擊 char={} target={} damage={}",
                    pc.getName(), target.getName(), damage);
        });
    }
}
