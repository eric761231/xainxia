package com.xin.server.model.ai;

/** NPC 的 AI 狀態。 */
public final class AiState {

    /** 閒置：沒有目標，原地或準備遊走。 */
    public static final int IDLE = 0;
    /** 遊走：在家附近小範圍走動。 */
    public static final int WANDER = 1;
    /** 追擊目標。 */
    public static final int CHASE = 2;
    /** 目標在攻擊距離內。 */
    public static final int ATTACK = 3;
    /** 脫戰回家：途中不理會玩家，到家回滿血。 */
    public static final int RETURN = 4;
    /** 已死亡。 */
    public static final int DEAD = 5;

    private AiState() {
    }

    public static String name(int state) {
        switch (state) {
            case IDLE:   return "閒置";
            case WANDER: return "遊走";
            case CHASE:  return "追擊";
            case ATTACK: return "攻擊";
            case RETURN: return "回家";
            case DEAD:   return "死亡";
            default:     return "未知(" + state + ")";
        }
    }
}
