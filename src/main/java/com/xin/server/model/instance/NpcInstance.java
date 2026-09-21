package com.xin.server.model.instance;

import com.xin.server.model.Character;

/**
 * 地圖 NPC 執行期實例（objId 由 IdFactoryNpc 分配）。
 * 數值由 {@link com.xin.server.datatables.NpcTable} 依 npc 模板套入。
 */
public class NpcInstance extends Character {

    private int npcTemplateId;

    public int getNpcTemplateId() {
        return npcTemplateId;
    }

    public void setNpcTemplateId(int npcTemplateId) {
        this.npcTemplateId = npcTemplateId;
    }

    /** 物件分類，見 {@link com.xin.server.types.NpcType} */
    private int _type;

    public int getType() {
        return _type;
    }

    public void setType(int type) {
        _type = type;
    }

    /**
     * 生成這隻怪的 spawnlist_monster 編號；0＝不是由怪物生成點生的（NPC、波次生的）。
     * <p>
     * 死亡時要靠它回去查那一筆的 {@code respawn_delay}。
     */
    private int _spawnId;

    public int getSpawnId() {
        return _spawnId;
    }

    public void setSpawnId(int spawnId) {
        _spawnId = spawnId;
    }

    private int _gfxid;

    public int getGfxid() {
        return _gfxid;
    }

    public void setGfxid(int gfxid) {
        _gfxid = gfxid;
    }

    private int _defense;

    /** 命中。與 PcInstance 的同名數值放在同一個公式裡比較（見 Combat）。 */
    private int _hit;

    /** 閃避。 */
    private int _dodge;

    public int getHit() {
        return _hit;
    }

    public void setHit(int hit) {
        _hit = hit;
    }

    public int getDodge() {
        return _dodge;
    }

    public void setDodge(int dodge) {
        _dodge = dodge;
    }

    public int getDefense() {
        return _defense;
    }

    public void setDefense(int defense) {
        _defense = defense;
    }

    private int _baseDamage;

    public int getBaseDamage() {
        return _baseDamage;
    }

    public void setBaseDamage(int baseDamage) {
        _baseDamage = baseDamage;
    }

    private int _randDamage;

    public int getRandDamage() {
        return _randDamage;
    }

    public void setRandDamage(int randDamage) {
        _randDamage = randDamage;
    }

    // ── 家與牽引範圍 ─────────────────────────────────────────────
    //
    // 家 = 實際生成的位置。脫戰回家、閒置遊走都以這裡為準；
    // 沒有家的話，被玩家風箏過的怪會一路被拉走，再也回不到原本的區域。

    private int _homeMapId;
    private int _homeX;
    private int _homeY;

    /** 離家最大距離（格）；0＝不限制。 */
    private int _movementDistance;

    public void setHome(int mapId, int x, int y) {
        _homeMapId = mapId;
        _homeX = x;
        _homeY = y;
    }

    public int getHomeMapId() {
        return _homeMapId;
    }

    public int getHomeX() {
        return _homeX;
    }

    public int getHomeY() {
        return _homeY;
    }

    public int getMovementDistance() {
        return _movementDistance;
    }

    public void setMovementDistance(int movementDistance) {
        _movementDistance = Math.max(0, movementDistance);
    }

    /** 與家的 Chebyshev 距離；不在家所在的地圖時回傳 {@link Integer#MAX_VALUE}。 */
    public int distanceFromHome() {
        if (getMapId() != _homeMapId) {
            return Integer.MAX_VALUE;
        }
        return Math.max(Math.abs(getX() - _homeX), Math.abs(getY() - _homeY));
    }

    // ── AI 參數（由模板套入）────────────────────────────────────

    private int _passiSpeed = 800;
    private int _atkSpeed = 1200;
    private boolean _agro = true;
    private int _agroRange = 6;
    private boolean _wander = true;
    private int _ranged = 1;
    private String _idleChat = "";

    public int getPassiSpeed() {
        return _passiSpeed;
    }

    public void setPassiSpeed(int passiSpeed) {
        _passiSpeed = passiSpeed;
    }

    public int getAtkSpeed() {
        return _atkSpeed;
    }

    public void setAtkSpeed(int atkSpeed) {
        _atkSpeed = atkSpeed;
    }

    public boolean isAgro() {
        return _agro;
    }

    public void setAgro(boolean agro) {
        _agro = agro;
    }

    public int getAgroRange() {
        return _agroRange;
    }

    public void setAgroRange(int agroRange) {
        _agroRange = agroRange;
    }

    public boolean isWander() {
        return _wander;
    }

    public void setWander(boolean wander) {
        _wander = wander;
    }

    public int getRanged() {
        return _ranged;
    }

    public void setRanged(int ranged) {
        _ranged = Math.max(1, ranged);
    }

    public String getIdleChat() {
        return _idleChat;
    }

    public void setIdleChat(String idleChat) {
        _idleChat = idleChat != null ? idleChat : "";
    }

    // ── AI 執行期狀態 ──────────────────────────────────────────
    //
    // 只在該地圖的鎖內讀寫（見 com.xin.server.world.MapLocks），所以不需要 volatile。

    /** 目標選擇用的仇恨：脫戰回家時清空。 */
    private final com.xin.server.model.ai.HateList _hate = new com.xin.server.model.ai.HateList();
    /** 傷害紀錄：永不清空，之後分配經驗與掉落用。 */
    private final com.xin.server.model.ai.HateList _damageLog = new com.xin.server.model.ai.HateList();
    private int _aiState = com.xin.server.model.ai.AiState.IDLE;
    private long _nextAttackAt;
    private int _stuckCount;
    private long _lastChatAt;

    public com.xin.server.model.ai.HateList getHate() {
        return _hate;
    }

    public com.xin.server.model.ai.HateList getDamageLog() {
        return _damageLog;
    }

    public int getAiState() {
        return _aiState;
    }

    public void setAiState(int aiState) {
        _aiState = aiState;
    }

    public long getNextAttackAt() {
        return _nextAttackAt;
    }

    public void setNextAttackAt(long nextAttackAt) {
        _nextAttackAt = nextAttackAt;
    }

    public int getStuckCount() {
        return _stuckCount;
    }

    public void setStuckCount(int stuckCount) {
        _stuckCount = stuckCount;
    }

    public long getLastChatAt() {
        return _lastChatAt;
    }

    public void setLastChatAt(long lastChatAt) {
        _lastChatAt = lastChatAt;
    }
}
