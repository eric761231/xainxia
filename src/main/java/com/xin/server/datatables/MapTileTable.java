package com.xin.server.datatables;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.xin.server.template.MapTemplate;
import com.xin.server.template.MapTileTemplate;

/**
 * 地圖圖磚資料（讀 {@code resources/maps/<mapId>.json}）。
 * <p>
 * 「哪個座標用哪一張圖」以前是前端資產（{@code assets/maps/0.json}），
 * 但那份 JSON 同時存了地圖邊界，與 DB 的 {@code map.min_x/max_x} 重複 ——
 * DB 改了邊界前端不會跟著變，座標空間就錯開，而且不拋例外，
 * 只表現成「人物站的位置怪怪的」。現在資料只有伺服器這一份。
 * <p>
 * <b>快取策略</b>：首次用到某張地圖時讀檔並常駐，之後直接回傳。
 * 圖磚資料不會在執行期變動，不必每次進圖重讀；要換圖就 {@link #reload()}。
 */
public class MapTileTable {

    private static final Logger _log = LoggerFactory.getLogger(MapTileTable.class);

    /** 資源路徑前綴。 */
    private static final String RESOURCE_DIR = "/maps/";

    private static MapTileTable _instance;

    private final ObjectMapper _mapper = new ObjectMapper();

    /** key = mapId。值為 null 代表「查過了，這張地圖沒有圖磚檔」—— 避免每次重讀。 */
    private final Map<Integer, MapTileTemplate> _cache = new ConcurrentHashMap<>();
    private final Map<Integer, Boolean> _missing = new ConcurrentHashMap<>();

    public static MapTileTable get() {
        if (_instance == null) {
            _instance = new MapTileTable();
        }
        return _instance;
    }

    private MapTileTable() {
    }

    /** 清空快取，下次取用重讀。 */
    public void reload() {
        _cache.clear();
        _missing.clear();
        _log.info("地圖圖磚快取已清空");
    }

    /**
     * 取某張地圖的圖磚資料；沒有對應的 JSON 時回傳 {@code null}。
     * <p>
     * 「沒有」是正常情形 —— 只有需要逐格指定圖磚的地圖才會有檔案，
     * 其餘地圖前端仍用程式產生的地面。
     */
    public MapTileTemplate getMap(int mapId) {
        MapTileTemplate cached = _cache.get(mapId);
        if (cached != null) {
            return cached;
        }
        if (Boolean.TRUE.equals(_missing.get(mapId))) {
            return null;
        }

        MapTileTemplate loaded = load(mapId);
        if (loaded == null) {
            _missing.put(mapId, Boolean.TRUE);
            return null;
        }
        _cache.put(mapId, loaded);
        return loaded;
    }

    private MapTileTemplate load(int mapId) {
        String path = RESOURCE_DIR + mapId + ".json";
        try (InputStream in = MapTileTable.class.getResourceAsStream(path)) {
            if (in == null) {
                _log.info("地圖 {} 無圖磚檔（{}），前端將以程式產生地面", mapId, path);
                return null;
            }
            JsonNode root = _mapper.readTree(
                    new String(in.readAllBytes(), StandardCharsets.UTF_8));

            MapTileTemplate t = new MapTileTemplate();
            t._mapId = root.path("mapId").asInt(mapId);
            t._tileWidth = root.path("tileWidth").asInt(64);
            t._tileHeight = root.path("tileHeight").asInt(32);
            t._walkMin = root.path("walkMin").asInt(0);
            t._walkMax = root.path("walkMax").asInt(0);
            t._tileDir = root.path("tileDir").asText("");

            JsonNode tiles = root.path("tiles");
            tiles.fieldNames().forEachRemaining(key -> {
                try {
                    t._tiles.put(Integer.parseInt(key), tiles.path(key).asText(""));
                } catch (NumberFormatException e) {
                    _log.warn("地圖{}的圖磚編號不是數字：{}", t._mapId, key);
                }
            });

            JsonNode ground = root.path("ground");
            if (!ground.isArray() || ground.isEmpty()) {
                _log.error("地圖 {} 的圖磚檔沒有 ground 資料，略過", mapId);
                return null;
            }
            for (JsonNode cell : ground) {
                // 每一格是 [x, y, 圖磚編號]
                if (!cell.isArray() || cell.size() < 3) {
                    _log.warn("地圖{}有格式不對的 ground 項目，略過：{}", t._mapId, cell);
                    continue;
                }
                t._ground.add(new MapTileTemplate.Cell(
                        cell.get(0).asInt(), cell.get(1).asInt(),
                        cell.get(2).asInt()));
            }

            validate(t);
            _log.info("載入地圖圖磚: 地圖{} {}格 圖磚{}種",
                    mapId, t._ground.size(), t._tiles.size());
            return t;
        } catch (Exception e) {
            _log.error("讀取地圖圖磚失敗 map=" + mapId + " path=" + path, e);
            return null;
        }
    }

    /**
     * 與 DB 的地圖邊界核對，並檢查有沒有指向不存在圖集的 tileId。
     * <p>
     * 不一致時只記警告、不中止啟動 —— 圖磚是表現層，讓伺服器因為它起不來
     * 太超過。但一定要吼出來，否則就退回原本「靜默錯開」的老問題。
     */
    private void validate(MapTileTemplate t) {
        MapTemplate map = MapTable.get().getMap(t._mapId);
        if (map != null && (t._walkMin != map._minX || t._walkMax != map._maxX)) {
            _log.warn("地圖{}的圖磚檔邊界({}..{})與 map 表({}..{})不一致 —— "
                            + "請重產圖磚檔，否則會有格子鋪不到或鋪到界外",
                    t._mapId, t._walkMin, t._walkMax, map._minX, map._maxX);
        }

        int unknown = 0;
        int outside = 0;
        for (MapTileTemplate.Cell c : t._ground) {
            if (!t.isKnownTile(c._tileId)) {
                unknown++;
            }
            if (c._x < t._walkMin || c._x > t._walkMax
                    || c._y < t._walkMin || c._y > t._walkMax) {
                outside++;
            }
        }
        if (unknown > 0) {
            _log.warn("地圖{}有 {} 格的圖磚編號不在 tiles 表裡，前端會畫不出來",
                    t._mapId, unknown);
        }
        if (outside > 0) {
            _log.warn("地圖{}有 {} 格落在可走區之外，前端會忽略", t._mapId, outside);
        }
    }
}
