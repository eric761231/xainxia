package com.xin.server.datatables;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.PropertyInstance;
import com.xin.server.template.MapTemplate;
import com.xin.server.template.PropertyTemplate;
import com.xin.server.template.SpawnTemplate;
import com.xin.server.types.MapLayoutMode;
import com.xin.server.util.PropertyScatter;
import com.xin.server.world.MapGrid;
import com.xin.server.world.WorldMapGrid;
import com.xin.server.world.WorldProperty;
import com.xin.util.PerformanceTimer;

/**
 * 場景物件生成點（DB 表 {@code spawnlist_scene}）。
 * <p>
 * 每筆描述某地圖上一組場景物件（{@code property} 模板）的中心座標、數量與散佈範圍；
 * 放置方式依地圖的 {@code layout_mode} 決定（見 {@link #spawnAll()}）。
 * NPC 與怪物分別在 {@link NpcSpawnTable} 與 {@link MonsterSpawnTable}。
 */
public class SceneSpawnTable {

    private static final Logger _log = LoggerFactory.getLogger(SceneSpawnTable.class);

    static final String TABLE = "spawnlist_scene";

    private static SceneSpawnTable _instance;

    /** key = id */
    private final Map<Integer, SpawnTemplate> _byId = new HashMap<>();
    /** key = mapid */
    private final Map<Integer, List<SpawnTemplate>> _byMap = new HashMap<>();

    public static SceneSpawnTable get() {
        if (_instance == null) {
            _instance = new SceneSpawnTable();
        }
        return _instance;
    }

    /** 重新從 DB 載入（GM 熱更新用；不會移除已生成的物件）。 */
    public static void reload() {
        _instance = new SceneSpawnTable();
    }

    private SceneSpawnTable() {
        PerformanceTimer timer = new PerformanceTimer();
        for (SpawnTemplate s : SpawnTableSupport.load(TABLE, "property_id", false)) {
            _byId.put(s._id, s);
            _byMap.computeIfAbsent(s._mapId, k -> new ArrayList<>()).add(s);
        }
        _log.info("載入場景物件生成點: " + _byId.size() + "筆 (" + timer.get() + "ms)");
    }

    /**
     * 依地圖的 layout_mode 生成所有場景物件。必須在 {@link PropertyTable} 載入後呼叫。
     * <ul>
     *   <li>random：以 {@link PropertyScatter} 在全地圖合理散佈</li>
     *   <li>static／player：依中心 ±range 放置，亂數種子固定，每次啟動位置相同</li>
     * </ul>
     */
    public void spawnAll() {
        PerformanceTimer timer = new PerformanceTimer();
        int made = 0;
        int skipped = 0;
        for (Map.Entry<Integer, List<SpawnTemplate>> entry : _byMap.entrySet()) {
            int mapId = entry.getKey();
            MapTemplate map = MapTable.get().getMap(mapId);
            if (map == null) {
                _log.error("場景物件生成點指向不存在的地圖: mapId={}", mapId);
                skipped += entry.getValue().size();
                continue;
            }
            boolean random = map._layoutMode == MapLayoutMode.RANDOM;
            if (map._layoutMode == MapLayoutMode.PLAYER) {
                _log.info("地圖 {} 為玩家佈置模式，第二階段實作，本次先依 {} 固定放置", mapId, TABLE);
            }
            for (SpawnTemplate s : entry.getValue()) {
                int n = random ? spawnScattered(map, s) : spawnFixed(s);
                made += n;
                skipped += s._count - n;
            }
        }
        _log.info("生成場景物件 " + made + "個"
                + (skipped > 0 ? " / 跳過 " + skipped + "個" : "")
                + " (" + timer.get() + "ms)");
    }

    /**
     * 依中心 ±range 放置（static／player 模式）。
     * <p>
     * 亂數以「生成點 id + 第幾個實例」為種子，同一筆設定每次啟動都長在同一處 ——
     * static 的語意就是固定。{@code range} 仍然有效，只是散得可重現。
     */
    private int spawnFixed(SpawnTemplate s) {
        PropertyTemplate temp = PropertyTable.get().getTemplate(s._npcId);
        if (temp == null) {
            _log.warn("找不到場景物件模板: " + s._npcId);
            return 0;
        }
        MapGrid grid = WorldMapGrid.get().get(s._mapId);
        int w = Math.max(1, temp._footprintW);
        int h = Math.max(1, temp._footprintH);

        int made = 0;
        for (int i = 0; i < s._count; i++) {
            Random seeded = new Random(s._id * 1000L + i);
            // range 有值時在範圍內重試，避免兩個實例疊在同一格
            int attempts = s._range > 0 ? PropertyScatter.MAX_ATTEMPTS : 1;
            for (int a = 0; a < attempts; a++) {
                int x = SpawnTableSupport.seededCoord(seeded, s._locX, s._range);
                int y = SpawnTableSupport.seededCoord(seeded, s._locY, s._range);
                if (!MapTable.get().isValidCoord(s._mapId, x, y)) {
                    continue;
                }
                if (grid != null && !grid.canPlace(x, y, w, h)) {
                    continue;
                }
                if (PropertyTable.get().createProperty(temp._id, x, y, s._mapId) != null) {
                    made++;
                }
                break;
            }
        }
        return made;
    }

    /** 以 {@link PropertyScatter} 在全地圖範圍合理散佈（random 模式）。 */
    private int spawnScattered(MapTemplate map, SpawnTemplate s) {
        PropertyTemplate temp = PropertyTable.get().getTemplate(s._npcId);
        if (temp == null) {
            _log.warn("找不到場景物件模板: " + s._npcId);
            return 0;
        }
        MapGrid grid = WorldMapGrid.get().get(map._mapId);
        if (grid == null) {
            return 0;
        }
        List<PropertyInstance> sameKind = new ArrayList<>();
        for (PropertyInstance p : WorldProperty.get().getPropertiesByMap(map._mapId)) {
            if (p.getPropertyTemplateId() == temp._id) {
                sameKind.add(p);
            }
        }
        int made = 0;
        for (int[] spot : PropertyScatter.scatter(map, grid, temp, s._count, sameKind)) {
            if (PropertyTable.get().createProperty(temp._id, spot[0], spot[1], map._mapId) != null) {
                made++;
            }
        }
        return made;
    }

    public SpawnTemplate getSpawn(int id) {
        return _byId.get(id);
    }

    public List<SpawnTemplate> getSpawnsByMap(int mapId) {
        List<SpawnTemplate> list = _byMap.get(mapId);
        return list != null ? list : Collections.<SpawnTemplate>emptyList();
    }

    public Collection<SpawnTemplate> getAll() {
        return _byId.values();
    }
}
