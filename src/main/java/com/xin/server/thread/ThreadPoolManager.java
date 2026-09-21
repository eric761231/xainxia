package com.xin.server.thread;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 全服執行緒的統一入口：三個多執行緒池 + 依名稱建立的專用單一執行緒。
 *
 * <table border="1">
 *   <tr><th>池</th><th>用途</th><th>預設大小</th></tr>
 *   <tr><td>{@link #general()}</td><td>一般服務：存檔、清理、統計等不屬於玩家或 NPC 的工作</td><td>max(2, 核心數/2)</td></tr>
 *   <tr><td>{@link #player()}</td><td>玩家專用：玩家計時（回血、Buff 到期、技能冷卻）等</td><td>max(2, 核心數)</td></tr>
 *   <tr><td>{@link #npc()}</td><td>NPC 專用：怪物 AI、重生、NPC 行為</td><td>max(2, 核心數/2)</td></tr>
 * </table>
 * <p>
 * <b>分池的理由</b>：一個慢任務只會拖累自己那一池。怪物數量暴增讓 AI 變慢時，
 * 玩家的計時與一般服務不受影響，反之亦然。
 * <p>
 * 需要<b>保證先後順序</b>的工作不要丟進多執行緒池，改用 {@link #single(String)}
 * 取得一條專用單一執行緒（同名共用同一條）。
 * <p>
 * 池大小可用 JVM 參數覆寫：{@code -Dxin.pool.general=4 -Dxin.pool.player=8 -Dxin.pool.npc=4}。
 */
public final class ThreadPoolManager {

    private static final Logger _log = LoggerFactory.getLogger(ThreadPoolManager.class);

    /** 關閉時每一池最多等待執行中任務結束的時間。 */
    private static final long SHUTDOWN_AWAIT_MS = 3000;

    private static final class Holder {
        static final ThreadPoolManager INSTANCE = new ThreadPoolManager();
    }

    private final GameExecutor _general;
    private final GameExecutor _player;
    private final GameExecutor _npc;
    private final Map<String, GameExecutor> _singles = new ConcurrentHashMap<>();

    public static ThreadPoolManager get() {
        return Holder.INSTANCE;
    }

    private ThreadPoolManager() {
        int cores = Runtime.getRuntime().availableProcessors();
        _general = GameExecutor.pool("general", size("xin.pool.general", Math.max(2, cores / 2)));
        _player  = GameExecutor.pool("player",  size("xin.pool.player",  Math.max(2, cores)));
        _npc     = GameExecutor.pool("npc",     size("xin.pool.npc",     Math.max(2, cores / 2)));
        _log.info("執行緒池已啟動：一般服務 {} / 玩家 {} / NPC {}（CPU 核心 {}）",
                _general.threadCount(), _player.threadCount(), _npc.threadCount(), cores);
    }

    /** 一般服務執行緒池。 */
    public GameExecutor general() {
        return _general;
    }

    /** 玩家專用執行緒池。 */
    public GameExecutor player() {
        return _player;
    }

    /** NPC 專用執行緒池（含怪物）。 */
    public GameExecutor npc() {
        return _npc;
    }

    /**
     * 取得（必要時建立）一條專用單一執行緒，任務依提交順序逐一執行。
     * 同一個名稱永遠回傳同一條，伺服器關閉時一併停止。
     */
    public GameExecutor single(String name) {
        return _singles.computeIfAbsent(name, n -> {
            _log.info("建立專用單一執行緒：{}", n);
            return GameExecutor.singleThread(n);
        });
    }

    /** 依序停止：專用單一執行緒 → NPC → 玩家 → 一般服務。 */
    public void shutdown() {
        for (GameExecutor single : _singles.values()) {
            single.shutdown(SHUTDOWN_AWAIT_MS);
        }
        _npc.shutdown(SHUTDOWN_AWAIT_MS);
        _player.shutdown(SHUTDOWN_AWAIT_MS);
        _general.shutdown(SHUTDOWN_AWAIT_MS);
        _log.info("執行緒池已停止");
    }

    private static int size(String key, int defaultSize) {
        int value = Integer.getInteger(key, defaultSize);
        if (value < 1) {
            _log.warn("{}={} 無效，改用預設 {}", key, value, defaultSize);
            return defaultSize;
        }
        return value;
    }
}
