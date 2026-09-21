package com.xin.server.world;

import java.util.ArrayList;
import java.util.List;

import com.xin.server.model.instance.PropertyInstance;
import com.xin.server.template.MapTemplate;

/**
 * 單一地圖的碰撞格與佔用索引。
 * <p>
 * 解決兩個問題：
 * <ul>
 *   <li><b>碰撞</b>：哪些格子被擋住不能走（{@link #isWalkable(int, int)}）</li>
 *   <li><b>佔用查詢</b>：某格上是哪個物件（{@link #occupantAt(int, int)}）——
 *       在此之前只能對 {@code WorldProperty} 做 O(n) 全世界線性掃描</li>
 * </ul>
 * <p>
 * 座標為地圖的絕對格座標（目前所有地圖都是 1..20），內部以
 * {@code minX/minY} 為原點位移成 0-based 陣列索引。
 * <p>
 * <b>佔格展開方向與前端一致</b>：由錨點格往 x、y 遞減延伸
 * （見前端 {@code iso_map_component.dart} 的 {@code tx = obj.x - i}）。
 * 兩邊不一致的話，同一棵樹在前後端會擋住不同的格子。
 */
public class MapGrid {

    private final int _mapId;
    private final int _minX;
    private final int _minY;
    private final int _width;
    private final int _height;

    /**
     * [y][x]，true = 被場景物件擋住。
     * <p>
     * 與 {@link #_terrain} <b>刻意分開</b>：物件會被移除（{@link #remove}），
     * 地形不會。混在同一個陣列的話，拆掉一棵樹會把它腳下的懸崖一併變成可走。
     */
    private final boolean[][] _blocked;
    /** [y][x]，true = 地形本身不可通行（牆、水、懸崖），由 {@code map_collision} 載入 */
    private final boolean[][] _terrain;
    /** [y][x]，該格上的物件 objId；0 = 空 */
    private final long[][] _occupant;
    /**
     * [y][x]，站在這格的生物（NPC／怪物）objId；0 = 沒有。
     * <p>
     * 與場景物件的 {@link #_occupant} 分開：生物每走一步都要更新，場景物件的
     * {@link #remove} 是整張圖掃描，混在一起會互相覆蓋。寫入點只有
     * {@code World.storeObject/removeObject} 與 AI 的移動，並由 AiManager 定期重建自我修正。
     */
    private final long[][] _mover;

    public MapGrid(MapTemplate map) {
        _mapId  = map._mapId;
        _minX   = map._minX;
        _minY   = map._minY;
        _width  = map._maxX - map._minX + 1;
        _height = map._maxY - map._minY + 1;
        _blocked  = new boolean[_height][_width];
        _terrain  = new boolean[_height][_width];
        _occupant = new long[_height][_width];
        _mover    = new long[_height][_width];
    }

    public int getMapId() {
        return _mapId;
    }

    public int getWidth() {
        return _width;
    }

    public int getHeight() {
        return _height;
    }

    /** 絕對座標是否落在地圖範圍內。 */
    public boolean inBounds(int x, int y) {
        int ix = x - _minX;
        int iy = y - _minY;
        return ix >= 0 && ix < _width && iy >= 0 && iy < _height;
    }

    /** 該格是否被擋住（地形或物件任一即擋）；越界視為擋住。 */
    public boolean isBlocked(int x, int y) {
        if (!inBounds(x, y)) {
            return true;
        }
        int ix = x - _minX;
        int iy = y - _minY;
        return _terrain[iy][ix] || _blocked[iy][ix];
    }

    /** 該格的地形是否不可通行（不含場景物件）。 */
    public boolean isTerrainBlocked(int x, int y) {
        if (!inBounds(x, y)) {
            return true;
        }
        return _terrain[y - _minY][x - _minX];
    }

    /** 設定單格地形碰撞（GM 編輯與開機載入共用）。越界靜默忽略。 */
    public void setTerrainBlocked(int x, int y, boolean blocked) {
        if (!inBounds(x, y)) {
            return;
        }
        _terrain[y - _minY][x - _minX] = blocked;
    }

    /** 目前所有地形阻擋格，每筆為 {@code {x, y}} 絕對座標。供推送給前端。 */
    public List<int[]> getTerrainBlockedCells() {
        List<int[]> cells = new ArrayList<>();
        for (int j = 0; j < _height; j++) {
            for (int i = 0; i < _width; i++) {
                if (_terrain[j][i]) {
                    cells.add(new int[] { i + _minX, j + _minY });
                }
            }
        }
        return cells;
    }

    /** 該格是否可通行（未越界且未被擋）。 */
    public boolean isWalkable(int x, int y) {
        return !isBlocked(x, y);
    }

    /** 該格上的物件 objId；空格或越界回傳 {@code 0}。 */
    public long occupantAt(int x, int y) {
        if (!inBounds(x, y)) {
            return 0L;
        }
        return _occupant[y - _minY][x - _minX];
    }

    /**
     * 以 (x,y) 為錨點的 {@code w×h} 佔格是否全部可放置
     * （皆在範圍內、皆未被佔用）。
     */
    public boolean canPlace(int x, int y, int w, int h) {
        for (int j = 0; j < h; j++) {
            for (int i = 0; i < w; i++) {
                int tx = x - i;
                int ty = y - j;
                if (!inBounds(tx, ty)) {
                    return false;
                }
                if (_occupant[ty - _minY][tx - _minX] != 0L) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * 把場景物件寫入格子：佔用一律登記，{@code blocking} 者額外標記為不可通行。
     * 呼叫前應先以 {@link #canPlace} 確認。
     */
    public void place(PropertyInstance property) {
        int w = Math.max(1, property.getFootprintW());
        int h = Math.max(1, property.getFootprintH());
        for (int j = 0; j < h; j++) {
            for (int i = 0; i < w; i++) {
                int tx = property.getX() - i;
                int ty = property.getY() - j;
                if (!inBounds(tx, ty)) {
                    continue;
                }
                _occupant[ty - _minY][tx - _minX] = property.getId();
                if (property.isBlocking()) {
                    _blocked[ty - _minY][tx - _minX] = true;
                }
            }
        }
    }

    /** 移除某物件佔用的所有格子（採集耗盡、GM 移除）。 */
    public void remove(long objId) {
        for (int j = 0; j < _height; j++) {
            for (int i = 0; i < _width; i++) {
                if (_occupant[j][i] == objId) {
                    _occupant[j][i] = 0L;
                    _blocked[j][i] = false;
                }
            }
        }
    }

    /**
     * 該格的四鄰是否至少有一格可通行。
     * 用於分佈演算法避免製造走不進去的死角。
     */
    public boolean hasWalkableNeighbour(int x, int y) {
        return isWalkable(x + 1, y) || isWalkable(x - 1, y)
                || isWalkable(x, y + 1) || isWalkable(x, y - 1);
    }

    // ── 生物占位 ─────────────────────────────────────────────────

    /** 站在該格的生物 objId；沒有或越界回傳 {@code 0}。 */
    public long moverAt(int x, int y) {
        if (!inBounds(x, y)) {
            return 0L;
        }
        return _mover[y - _minY][x - _minX];
    }

    /** 可以走、而且沒有別的生物站著。 */
    public boolean isFree(int x, int y) {
        return isWalkable(x, y) && moverAt(x, y) == 0L;
    }

    /** 生物站上這格。越界靜默忽略。 */
    public void enterMover(long objId, int x, int y) {
        if (inBounds(x, y)) {
            _mover[y - _minY][x - _minX] = objId;
        }
    }

    /** 生物離開這格；只清掉自己，不會把後來站上去的別人清掉。 */
    public void leaveMover(long objId, int x, int y) {
        if (inBounds(x, y) && _mover[y - _minY][x - _minX] == objId) {
            _mover[y - _minY][x - _minX] = 0L;
        }
    }

    public void moveMover(long objId, int fromX, int fromY, int toX, int toY) {
        leaveMover(objId, fromX, fromY);
        enterMover(objId, toX, toY);
    }

    /** 清空生物占位（重建前使用），回傳清掉的格數。 */
    public int clearMovers() {
        int count = 0;
        for (int j = 0; j < _height; j++) {
            for (int i = 0; i < _width; i++) {
                if (_mover[j][i] != 0L) {
                    _mover[j][i] = 0L;
                    count++;
                }
            }
        }
        return count;
    }

    /**
     * 以 (cx,cy) 為中心印出 ±radius 的區域：{@code #}=擋路 {@code o}=可穿越物件
     * {@code M}=生物 {@code .}=空。大地圖整張印出來太長，GM 指令用這個。
     */
    public String dumpArea(int cx, int cy, int radius) {
        StringBuilder sb = new StringBuilder();
        sb.append("MapGrid mapId=").append(_mapId).append(" 中心(").append(cx).append(',').append(cy)
          .append(") ±").append(radius).append('\n');
        for (int y = cy - radius; y <= cy + radius; y++) {
            for (int x = cx - radius; x <= cx + radius; x++) {
                if (!inBounds(x, y)) {
                    sb.append(' ');
                } else if (x == cx && y == cy) {
                    sb.append('@');
                } else if (moverAt(x, y) != 0L) {
                    sb.append('M');
                } else if (isBlocked(x, y)) {
                    sb.append('#');
                } else if (occupantAt(x, y) != 0L) {
                    sb.append('o');
                } else {
                    sb.append('.');
                }
            }
            sb.append('\n');
        }
        return sb.toString();
    }

    /** 以 ASCII 印出佔用圖，供人工檢查分佈是否合理（{@code #}=擋路 {@code o}=可穿越物件 {@code .}=空）。 */
    public String dump() {
        StringBuilder sb = new StringBuilder();
        sb.append("MapGrid mapId=").append(_mapId)
          .append(' ').append(_width).append('x').append(_height).append('\n');
        for (int j = 0; j < _height; j++) {
            for (int i = 0; i < _width; i++) {
                sb.append(_blocked[j][i] ? '#' : (_occupant[j][i] != 0L ? 'o' : '.'));
            }
            sb.append('\n');
        }
        return sb.toString();
    }
}
