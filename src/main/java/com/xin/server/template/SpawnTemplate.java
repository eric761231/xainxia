package com.xin.server.template;

/**
 * 生成點記憶體存放區，三張生成點表共用：
 * {@code spawnlist_scene}（場景物件）、{@code spawnlist_npc}（NPC）、{@code spawnlist_monster}（怪物）。
 * 欄位直接公開（L1J 慣例），由各自的 datatables 類別填入後唯讀使用。
 * 資料來源見 {@code sql/schema_all.sql}。
 */
public class SpawnTemplate {

    /** 一般生成點：在 ±range 內隨機找可走的位置。 */
    public static final int SPAWN_NORMAL = 0;
    /** 首領生成點：固定在中心座標，不散佈。 */
    public static final int SPAWN_BOSS = 1;

    /** 欄位未設定時的預設面向（2 = 東南，與 Object 預設一致）。 */
    public static final int DEFAULT_HEADING = 2;
    /** 欄位未設定時的預設牽引距離（格）。 */
    public static final int DEFAULT_MOVEMENT_DISTANCE = 12;

    public int    _id;     // 資料序號（每張表各自編號）
    public String _zone;   // 地區註解
    public int    _npcId;  // 模板編號：場景物件＝property.id；NPC／怪物＝npc.npc_id
    public String _name;   // 名稱註解
    public int    _count;  // 數量
    public int    _locX;   // 中心X座標
    public int    _locY;   // 中心Y座標
    public int    _range;  // 散佈範圍值
    public int    _mapId;  // 地圖編號
    /** 重生延遲（秒）；0＝不重生。只有 {@code spawnlist_monster} 有這個欄位。 */
    public int    _respawnDelay;
    /** 重生延遲的隨機加值（秒）：實際延遲 = respawn_delay + rand(0..此值)。 */
    public int    _respawnDelayRandom;
    /** 離家最大距離（格）；超過就脫戰回家，0＝不限制。 */
    public int    _movementDistance = DEFAULT_MOVEMENT_DISTANCE;
    /** 初始面向 0..7；-1＝隨機。 */
    public int    _heading = DEFAULT_HEADING;
    /** {@link #SPAWN_NORMAL} 或 {@link #SPAWN_BOSS}。 */
    public int    _spawnType = SPAWN_NORMAL;

    public SpawnTemplate() {
    }
}
