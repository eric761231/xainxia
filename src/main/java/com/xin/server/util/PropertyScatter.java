package com.xin.server.util;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

import com.xin.server.model.instance.PropertyInstance;
import com.xin.server.template.MapTemplate;
import com.xin.server.template.PropertyTemplate;
import com.xin.server.world.MapGrid;

/**
 * 場景物件的隨機分佈演算法（{@code layout_mode='random'} 的地圖使用）。
 * <p>
 * 單純的均勻亂數會產生「分佈怪異」的結果：物件重疊在同一格、大樹擠成一團、
 * 靠近邊界的區域長不滿、甚至把地圖切出走不進去的死角。本類以四條規則處理：
 * <ol>
 *   <li><b>不重疊</b>：候選位置需通過 {@link MapGrid#canPlace}</li>
 *   <li><b>最小間隔</b>：同一 {@code property.id} 的兩個實例距離需 ≥ {@code min_gap}
 *       （花草設 0 可密集生長，大樹設 3~4 避免擠成一團）</li>
 *   <li><b>重試而非跳過</b>：每個實例最多試 {@link #MAX_ATTEMPTS} 次，
 *       而不是一次失敗就放棄（否則邊界附近永遠長不滿數量）</li>
 *   <li><b>不封死通路</b>：擋路物件放下後該格四鄰若全被擋，視為製造死角並退回重找</li>
 * </ol>
 */
public final class PropertyScatter {

    /** 單一實例的最大嘗試次數；超過即放棄該實例。 */
    public static final int MAX_ATTEMPTS = 30;

    private PropertyScatter() {
    }

    /**
     * 在地圖範圍內為一組同種場景物件挑選合法座標。
     *
     * @param map      地圖設定（提供邊界）
     * @param grid     該地圖的碰撞格（會被讀取以避開既有佔用，但本方法不寫入）
     * @param temp     場景物件模板（提供 footprint 與 min_gap）
     * @param count    要放置的數量
     * @param placed   已放置的同種物件（用於 min_gap 判斷），可為空
     * @return 選定的座標清單，長度可能小於 {@code count}（空間不足時）
     */
    public static List<int[]> scatter(MapTemplate map, MapGrid grid, PropertyTemplate temp,
                                      int count, List<PropertyInstance> placed) {
        List<int[]> result = new ArrayList<>();
        List<int[]> chosen = new ArrayList<>();
        for (PropertyInstance p : placed) {
            chosen.add(new int[] { p.getX(), p.getY() });
        }

        int w = Math.max(1, temp._footprintW);
        int h = Math.max(1, temp._footprintH);

        for (int n = 0; n < count; n++) {
            int[] spot = findSpot(map, grid, temp, w, h, chosen);
            if (spot == null) {
                break;   // 空間已滿，不必再試剩下的
            }
            result.add(spot);
            chosen.add(spot);
        }
        return result;
    }

    /** 為單一實例找一個合法座標；試滿 {@link #MAX_ATTEMPTS} 次仍失敗回傳 {@code null}。 */
    private static int[] findSpot(MapTemplate map, MapGrid grid, PropertyTemplate temp,
                                  int w, int h, List<int[]> chosen) {
        final ThreadLocalRandom rnd = ThreadLocalRandom.current();
        for (int attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
            // footprint 往 x/y 遞減延伸，故錨點下限要往內縮，避免整組佔格越界
            int x = rnd.nextInt(map._minX + w - 1, map._maxX + 1);
            int y = rnd.nextInt(map._minY + h - 1, map._maxY + 1);

            if (!grid.canPlace(x, y, w, h)) {
                continue;
            }
            if (tooClose(x, y, temp._minGap, chosen)) {
                continue;
            }
            if (temp._blocking && wouldSealOff(grid, x, y, w, h)) {
                continue;
            }
            return new int[] { x, y };
        }
        return null;
    }

    /** 與同種已放置物件的 Chebyshev 距離是否小於 {@code minGap}。 */
    private static boolean tooClose(int x, int y, int minGap, List<int[]> chosen) {
        if (minGap <= 0) {
            return false;
        }
        for (int[] c : chosen) {
            int dx = Math.abs(c[0] - x);
            int dy = Math.abs(c[1] - y);
            if (Math.max(dx, dy) < minGap) {
                return true;
            }
        }
        return false;
    }

    /**
     * 放下這個擋路物件後，是否會讓周圍出現走不進去的死角。
     * <p>
     * 檢查佔格四周的每一個相鄰空格：若某個空格在此物件放下後四鄰全被擋住，
     * 就代表製造了一個孤立格，應換位置。
     */
    private static boolean wouldSealOff(MapGrid grid, int x, int y, int w, int h) {
        for (int j = -1; j <= h; j++) {
            for (int i = -1; i <= w; i++) {
                int nx = x - i;
                int ny = y - j;
                if (!grid.inBounds(nx, ny) || grid.isBlocked(nx, ny)) {
                    continue;
                }
                if (isInFootprint(nx, ny, x, y, w, h)) {
                    continue;
                }
                if (!hasWayOut(grid, nx, ny, x, y, w, h)) {
                    return true;
                }
            }
        }
        return false;
    }

    /** 座標是否落在以 (ax,ay) 為錨點的 w×h 佔格內。 */
    private static boolean isInFootprint(int x, int y, int ax, int ay, int w, int h) {
        return x <= ax && x > ax - w && y <= ay && y > ay - h;
    }

    /** 該空格在假設佔格被填滿後，四鄰是否仍有至少一格可通行。 */
    private static boolean hasWayOut(MapGrid grid, int x, int y, int ax, int ay, int w, int h) {
        final int[][] dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } };
        for (int[] d : dirs) {
            int nx = x + d[0];
            int ny = y + d[1];
            if (!grid.inBounds(nx, ny) || grid.isBlocked(nx, ny)) {
                continue;
            }
            if (isInFootprint(nx, ny, ax, ay, w, h)) {
                continue;   // 這格即將被本物件佔掉，不算出口
            }
            return true;
        }
        return false;
    }
}
