package com.xin.server.template;

/**
 * NPC 靜態模板記憶體存放區（對應 DB 表 {@code npc}）。
 * 欄位直接公開（L1J 慣例），由 {@link com.xin.server.datatables.NpcTable} 填入後唯讀使用。
 * 資料來源見 {@code sql/npc.sql}。
 */
public class NpcTemplate {

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
    public String _actionList;  // 動作代號列表

    public NpcTemplate() {
    }
}
