package com.xin.server.world;

import java.util.Collection;
import java.util.concurrent.ConcurrentHashMap;

import com.xin.server.datatables.MapCollisionTable;
import com.xin.server.datatables.MapTable;
import com.xin.server.template.MapTemplate;

/** 世界碰撞格索引：每張地圖一份 {@link MapGrid}（對齊 {@link WorldNpc} 的單例形式）。 */
public final class WorldMapGrid {

    private static WorldMapGrid _instance;

    private final ConcurrentHashMap<Integer, MapGrid> _grids = new ConcurrentHashMap<>();

    public static WorldMapGrid get() {
        if (_instance == null) {
            _instance = new WorldMapGrid();
        }
        return _instance;
    }

    /**
     * 取得該地圖的碰撞格；首次取用時依 {@link MapTemplate} 的邊界建立。
     * 地圖不存在於 {@code map} 表時回傳 {@code null}。
     */
    public MapGrid get(int mapId) {
        MapGrid grid = _grids.get(mapId);
        if (grid != null) {
            return grid;
        }
        MapTemplate map = MapTable.get().getMap(mapId);
        if (map == null) {
            return null;
        }
        // 地形碰撞在建 grid 時一次載入 —— computeIfAbsent 保證同一張地圖只跑一次
        return _grids.computeIfAbsent(mapId, k -> {
            MapGrid g = new MapGrid(map);
            MapCollisionTable.get().loadInto(g);
            return g;
        });
    }

    public Collection<MapGrid> getAll() {
        return _grids.values();
    }

    /**
     * 該座標是否可通行；地圖不存在時回傳 {@code false}。
     * 這是移動驗證的單一入口。
     */
    public boolean isWalkable(int mapId, int x, int y) {
        MapGrid grid = get(mapId);
        return grid != null && grid.isWalkable(x, y);
    }

    /** 清空所有地圖的碰撞格（重新佈局用）。 */
    public void clear() {
        _grids.clear();
    }
}
