package com.xin.server.model.ai;

import java.util.ArrayDeque;

/**
 * NPC 尋路：只算「下一步」，每走一格重新算一次。
 * <p>
 * 分三段（取自 L1J 的作法，地圖小所以成本可以忽略）：
 * <ul>
 *   <li>距離超過 {@code giveUpRange} → 放棄（回傳 {@code null}），由呼叫端丟掉目標。</li>
 *   <li>距離 ≤ {@link #BFS_RANGE} → 廣度優先搜尋（上限 {@link #BFS_MAX_NODES} 個節點），
 *       只回傳第一步。這一段解掉「卡在 L 形牆角」—— 貪心走法遇到凹牆會一直撞同一面牆。</li>
 *   <li>更遠 → 朝目標方向走一格，被擋就試左右相鄰的兩個方向。</li>
 * </ul>
 * 斜走不切角：兩側任一被擋就不能斜走，與前端玩家的規則一致（否則怪會從牆角縫隙穿過去）。
 * <p>
 * 刻意不依賴 DB／World／地圖單例，只透過 {@link Passable} 問「這格能不能站」，可以單獨驗證。
 */
public final class PathFinder {

    /** 能不能站在這格（呼叫端決定：地形、其他 NPC、玩家）。 */
    @FunctionalInterface
    public interface Passable {
        boolean canStand(int x, int y);
    }

    /** 面向 0..7 對應的位移（與前端 IsoPlayerComponent 同一套編號）。 */
    static final int[][] DIRS = {
        {0, -1}, {1, -1}, {1, 0}, {1, 1}, {0, 1}, {-1, 1}, {-1, 0}, {-1, -1},
    };

    /** 在這個距離內用 BFS。 */
    public static final int BFS_RANGE = 6;
    /** BFS 最多展開的節點數。 */
    public static final int BFS_MAX_NODES = 256;

    private PathFinder() {
    }

    /**
     * 從 (sx,sy) 朝 (tx,ty) 走一步，目標是走到距離 ≤ {@code stopRange} 的位置。
     *
     * @return 下一步 {@code {x, y}}；已在範圍內、超過放棄距離或走不動時回傳 {@code null}
     */
    public static int[] nextStep(int sx, int sy, int tx, int ty, int stopRange, int giveUpRange,
                                 Passable passable) {
        int dist = distance(sx, sy, tx, ty);
        if (dist <= stopRange || dist > giveUpRange) {
            return null;
        }
        if (dist <= BFS_RANGE) {
            int[] step = bfsFirstStep(sx, sy, tx, ty, stopRange, passable);
            if (step != null) {
                return step;
            }
        }
        return greedyStep(sx, sy, tx, ty, passable);
    }

    /** 從 (x,y) 往 (dx,dy) 走一格是否可行（含斜走不切角）。 */
    public static boolean canStep(int x, int y, int dx, int dy, Passable passable) {
        if (!passable.canStand(x + dx, y + dy)) {
            return false;
        }
        if (dx != 0 && dy != 0) {
            return passable.canStand(x + dx, y) && passable.canStand(x, y + dy);
        }
        return true;
    }

    /** 位移方向 → 面向 0..7；(0,0) 回傳 -1。 */
    public static int headingOf(int dx, int dy) {
        int sx = Integer.signum(dx);
        int sy = Integer.signum(dy);
        for (int d = 0; d < DIRS.length; d++) {
            if (DIRS[d][0] == sx && DIRS[d][1] == sy) {
                return d;
            }
        }
        return -1;
    }

    /** 面向 → 位移。 */
    public static int[] delta(int heading) {
        int[] d = DIRS[((heading % 8) + 8) % 8];
        return new int[] {d[0], d[1]};
    }

    /** Chebyshev 距離（八方向各算一格）。 */
    public static int distance(int x1, int y1, int x2, int y2) {
        return Math.max(Math.abs(x1 - x2), Math.abs(y1 - y2));
    }

    private static int[] greedyStep(int sx, int sy, int tx, int ty, Passable passable) {
        int dir = headingOf(tx - sx, ty - sy);
        if (dir < 0) {
            return null;
        }
        int dist = distance(sx, sy, tx, ty);
        int[] offsets = {0, -1, 1};
        for (int off : offsets) {
            int d = (dir + off + 8) % 8;
            int dx = DIRS[d][0];
            int dy = DIRS[d][1];
            if (!canStep(sx, sy, dx, dy, passable)) {
                continue;
            }
            int nd = distance(sx + dx, sy + dy, tx, ty);
            // 正方向必須更近；左右偏一格只要不變遠（沿牆滑過去）
            if (off == 0 ? nd < dist : nd <= dist) {
                return new int[] {sx + dx, sy + dy};
            }
        }
        return null;
    }

    private static int[] bfsFirstStep(int sx, int sy, int tx, int ty, int stopRange, Passable passable) {
        final int r = BFS_RANGE + 2;
        final int size = r * 2 + 1;
        boolean[] seen = new boolean[size * size];
        seen[r * size + r] = true;
        ArrayDeque<int[]> queue = new ArrayDeque<>();
        queue.add(new int[] {sx, sy, -1});
        int nodes = 0;
        while (!queue.isEmpty()) {
            int[] cur = queue.poll();
            if (++nodes > BFS_MAX_NODES) {
                return null;
            }
            for (int d = 0; d < DIRS.length; d++) {
                int nx = cur[0] + DIRS[d][0];
                int ny = cur[1] + DIRS[d][1];
                int lx = nx - sx + r;
                int ly = ny - sy + r;
                if (lx < 0 || ly < 0 || lx >= size || ly >= size) {
                    continue;
                }
                int i = ly * size + lx;
                if (seen[i]) {
                    continue;
                }
                if (!canStep(cur[0], cur[1], DIRS[d][0], DIRS[d][1], passable)) {
                    continue;
                }
                seen[i] = true;
                int firstDir = cur[2] < 0 ? d : cur[2];
                if (distance(nx, ny, tx, ty) <= stopRange) {
                    return new int[] {sx + DIRS[firstDir][0], sy + DIRS[firstDir][1]};
                }
                queue.add(new int[] {nx, ny, firstDir});
            }
        }
        return null;
    }
}
