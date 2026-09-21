package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.types.AttackAnimType;

/**
 * 攻擊演出（對應 opcode {@code S_ATTACK}）。
 * <p>
 * 只負責「演出」與「傷害數字」：誰打誰、掉多少血、播哪些動畫。
 * 攻擊者與目標一律以 {@code objId} 識別，玩家、NPC、怪物都適用。
 * <p>
 * <b>血量不在本封包內</b> —— 血條由 {@link S_HpUpdate} 獨立更新，
 * 因為血量會因非攻擊原因（治療、自然回復、buff）而改變；
 * 目標死亡則由 {@link S_ObjectRemove} 表達。
 * <p>
 * 動畫依 {@code animType}（見 {@link AttackAnimType}）分兩種演法：
 * <ul>
 *   <li>{@code 0}=直接命中：只在目標身上播 {@code hitGfx}（近身攻擊、瞬發法術）</li>
 *   <li>{@code 1}=飛行道具：{@code flyGfx} 由施放者飛向目標，抵達後才播 {@code hitGfx}
 *       （弓箭、飛劍、火球）</li>
 * </ul>
 * 三個動畫編號皆可為 {@code 0} 表示不播該段。
 *
 * <pre>
 * {
 *   "op": "S_ATTACK",
 *   "data": {
 *     "attackerObjId": 2000000001, "targetObjId": 1000000005, "damage": 37,
 *     "animType": 1, "castGfx": 120, "flyGfx": 121, "hitGfx": 122
 *   }
 * }
 * </pre>
 */
public class S_Attack extends ServerBasePacket {

    private S_Attack(long attackerObjId, long targetObjId, int damage,
                     int animType, int castGfx, int flyGfx, int hitGfx) {
        super(ServerOpcodes.S_ATTACK);
        put("attackerObjId", attackerObjId);
        put("targetObjId",   targetObjId);
        put("damage",        damage);
        put("animType",      animType);
        put("castGfx",       castGfx);
        put("flyGfx",        flyGfx);
        put("hitGfx",        hitGfx);
        // 明確標示是否命中。不用「damage == 0」判斷 —— 傷害有下限 1，
        // 但將來若加入「完全格擋」之類的機制，0 傷害與未命中就不是同一回事了。
        put("hit",           damage > 0);
    }

    /**
     * 建立攻擊演出封包。
     *
     * @param attackerObjId 攻擊者物件編號
     * @param targetObjId   目標物件編號
     * @param damage        造成的傷害（前端跳的傷害數字）
     * @param animType      動畫呈現方式，見 {@link AttackAnimType}
     * @param castGfx       施放者身上的動畫編號（0=無）
     * @param flyGfx        飛行中的動畫編號（{@code animType=1} 才用，0=無）
     * @param hitGfx        命中時目標身上的動畫編號（0=無）
     */
    /** 未命中：只播動作，不扣血。 */
    public static S_Attack miss(long attackerObjId, long targetObjId) {
        return new S_Attack(attackerObjId, targetObjId, 0,
                AttackAnimType.DIRECT, 0, 0, 0);
    }

    public static S_Attack of(long attackerObjId, long targetObjId, int damage,
                              int animType, int castGfx, int flyGfx, int hitGfx) {
        return new S_Attack(attackerObjId, targetObjId, damage,
                animType, castGfx, flyGfx, hitGfx);
    }

    /**
     * 建立直接命中（{@link AttackAnimType#DIRECT}）的攻擊演出封包，
     * 只在目標身上播一段命中動畫。
     */
    public static S_Attack direct(long attackerObjId, long targetObjId, int damage, int hitGfx) {
        return new S_Attack(attackerObjId, targetObjId, damage,
                AttackAnimType.DIRECT, 0, 0, hitGfx);
    }
}
