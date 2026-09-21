package com.xin.server.template;

/**
 * NPC 靜態模板記憶體存放區（對應 DB 表 {@code npc}）。
 * 欄位直接公開（L1J 慣例），由 {@link com.xin.server.datatables.NpcTable} 填入後唯讀使用。
 * 資料來源見 {@code sql/schema_all.sql}。
 */
public class NpcTemplate {

    /** 走一格的預設毫秒數。 */
    public static final int DEFAULT_PASSI_SPEED = 800;
    /** 攻擊一次的預設毫秒數。 */
    public static final int DEFAULT_ATK_SPEED = 1200;
    /** 主動察覺範圍預設（格）。 */
    public static final int DEFAULT_AGRO_RANGE = 6;
    /**
     * 速度下限（毫秒）。前端走一格的插值最快也要 0.4 秒左右，
     * 伺服器走得比這快的話畫面會一直瞬移追趕。
     */
    public static final int MIN_SPEED = 400;

    public int    _id;          // 資料序號
    public int    _npcId;       // npc編號
    public String _name;        // 名稱註解
    public String _typeName;    // npc類型分類代號（DB 原字串：monster/npc/shop/gather/scenery）
    public int    _type;        // 由 _typeName 轉出的 NpcType 常數
    public int    _gfxid;       // 外型編號
    public int    _maxHp;       // 最大體力
    public int    _maxMp;       // 最大法力
    public int    _defense;     // 防禦力
    public int    _baseDamage;  // 基礎傷害
    public int    _randDamage;  // 浮動傷害
    public int    _hit;         // 命中
    public int    _dodge;       // 閃避
    public String _actionList;  // 動作代號列表

    // ── AI 參數 ──
    public int     _passiSpeed = DEFAULT_PASSI_SPEED; // 走一格的毫秒數
    public int     _atkSpeed   = DEFAULT_ATK_SPEED;   // 攻擊一次的毫秒數
    public boolean _agro       = true;                // 是否主動攻擊
    public int     _agroRange  = DEFAULT_AGRO_RANGE;  // 主動察覺範圍（格）
    public boolean _wander     = true;                // 閒置時是否遊走
    public int     _ranged     = 1;                   // 普攻距離（格）
    public String  _idleChat   = "";                  // NPC 閒置時說的話，以 | 分隔

    public NpcTemplate() {
    }
}
