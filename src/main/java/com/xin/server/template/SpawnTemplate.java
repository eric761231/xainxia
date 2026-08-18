package com.xin.server.template;

/**
 * NPC 生成點記憶體存放區（對應 DB 表 {@code spawnlist}）。
 * 欄位直接公開（L1J 慣例），由 {@link com.xin.server.datatables.SpawnTable} 填入後唯讀使用。
 * 資料來源見 {@code sql/spawnlist.sql}。
 */
public class SpawnTemplate {

    public int    _id;     // 資料序號
    public String _zone;   // 地區註解
    public int    _npcId;  // npc編號
    public String _name;   // npc名稱
    public int    _count;  // npc數量
    public int    _locX;   // 出生X座標
    public int    _locY;   // 出生Y座標
    public int    _range;  // 出生範圍值
    public int    _mapId;  // 地圖編號

    public SpawnTemplate() {
    }
}
