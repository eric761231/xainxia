package com.xin.server.thread;

import java.util.concurrent.Future;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 一組具名的執行緒：可以是<b>單一執行緒</b>或<b>多執行緒池</b>，同一套 API。
 * <ul>
 *   <li>{@link #singleThread(String)}：只有一條執行緒，任務<b>依提交順序逐一執行</b>。
 *       適合必須保證先後順序的工作（例如存檔佇列、同一份狀態的連續更新）。</li>
 *   <li>{@link #pool(String, int)}：多條執行緒，任務<b>可以並行</b>，彼此不能依賴執行順序。</li>
 * </ul>
 * 支援立即執行、延遲一次、固定頻率與固定間隔重複執行。
 * <p>
 * <b>每個任務的例外都會被記錄並吞掉。</b>週期性任務只要拋出一次例外就會被
 * {@code ScheduledExecutorService} 永久停掉而且不會有任何通知（症狀是「怪物突然不再重生」），
 * 所以所有提交進來的任務都先包一層記錄例外的外殼。
 */
public final class GameExecutor {

    private static final Logger _log = LoggerFactory.getLogger(GameExecutor.class);

    private final String _name;
    private final ScheduledThreadPoolExecutor _exec;

    private GameExecutor(String name, int threads) {
        _name = name;
        _exec = new ScheduledThreadPoolExecutor(threads, new NamedThreadFactory(name));
        // 取消的延遲任務立刻移出佇列，避免大量取消（例如怪物重生被取消）堆積在記憶體
        _exec.setRemoveOnCancelPolicy(true);
        // 關閉時不再執行還在排隊的延遲任務（重生、AI 之類）
        _exec.setExecuteExistingDelayedTasksAfterShutdownPolicy(false);
        _exec.setContinueExistingPeriodicTasksAfterShutdownPolicy(false);
    }

    /** 單一執行緒：任務依提交順序逐一執行。 */
    public static GameExecutor singleThread(String name) {
        return new GameExecutor(name, 1);
    }

    /** 多執行緒池：任務可並行執行，彼此不可依賴先後順序。 */
    public static GameExecutor pool(String name, int threads) {
        return new GameExecutor(name, Math.max(1, threads));
    }

    public String name() {
        return _name;
    }

    public int threadCount() {
        return _exec.getCorePoolSize();
    }

    public boolean isSingleThread() {
        return _exec.getCorePoolSize() == 1;
    }

    /** 正在執行中的任務數。 */
    public int activeCount() {
        return _exec.getActiveCount();
    }

    /** 排隊中（含尚未到時間的延遲／週期任務）的任務數。 */
    public int queuedCount() {
        return _exec.getQueue().size();
    }

    /**
     * 立即執行一次。
     *
     * @return 伺服器關閉中無法接受任務時回傳 {@code null}
     */
    public Future<?> execute(String taskName, Runnable task) {
        try {
            return _exec.submit(safe(taskName, task));
        } catch (RejectedExecutionException e) {
            rejected(taskName);
            return null;
        }
    }

    /**
     * 延遲 {@code delayMs} 毫秒後執行一次。
     *
     * @return 伺服器關閉中無法接受任務時回傳 {@code null}
     */
    public ScheduledFuture<?> schedule(String taskName, long delayMs, Runnable task) {
        try {
            return _exec.schedule(safe(taskName, task), Math.max(0, delayMs), TimeUnit.MILLISECONDS);
        } catch (RejectedExecutionException e) {
            rejected(taskName);
            return null;
        }
    }

    /**
     * 固定頻率重複執行：每 {@code periodMs} 起跑一次，不論上一次花多久。
     * 上一次超時時下一次會緊接著執行（同一個任務不會重疊執行）。
     *
     * @return 伺服器關閉中無法接受任務時回傳 {@code null}
     */
    public ScheduledFuture<?> scheduleAtFixedRate(String taskName, long initialDelayMs, long periodMs, Runnable task) {
        try {
            return _exec.scheduleAtFixedRate(safe(taskName, task),
                    Math.max(0, initialDelayMs), periodMs, TimeUnit.MILLISECONDS);
        } catch (RejectedExecutionException e) {
            rejected(taskName);
            return null;
        }
    }

    /**
     * 固定間隔重複執行：上一次結束後再等 {@code delayMs} 才執行下一次。
     * 遊戲迴圈（AI、回血）通常用這個，慢的一次不會讓後面擠在一起。
     *
     * @return 伺服器關閉中無法接受任務時回傳 {@code null}
     */
    public ScheduledFuture<?> scheduleWithFixedDelay(String taskName, long initialDelayMs, long delayMs, Runnable task) {
        try {
            return _exec.scheduleWithFixedDelay(safe(taskName, task),
                    Math.max(0, initialDelayMs), delayMs, TimeUnit.MILLISECONDS);
        } catch (RejectedExecutionException e) {
            rejected(taskName);
            return null;
        }
    }

    /** 停止接受新任務，最多等 {@code awaitMs} 讓執行中的任務結束，逾時強制中斷。 */
    public void shutdown(long awaitMs) {
        _exec.shutdown();
        try {
            if (!_exec.awaitTermination(awaitMs, TimeUnit.MILLISECONDS)) {
                _exec.shutdownNow();
            }
        } catch (InterruptedException e) {
            _exec.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }

    public boolean isShutdown() {
        return _exec.isShutdown();
    }

    private Runnable safe(String taskName, Runnable task) {
        return () -> {
            try {
                task.run();
            } catch (Throwable t) {
                // 不重新拋出：拋了週期任務就永久停掉，而且沒有人會知道
                _log.error("[{}] 任務「{}」發生例外，本次略過", _name, taskName, t);
            }
        };
    }

    private void rejected(String taskName) {
        _log.debug("[{}] 已關閉，不再接受任務「{}」", _name, taskName);
    }

    /** 執行緒命名為「池名-編號」，方便在 thread dump 與記錄中辨認。 */
    private static final class NamedThreadFactory implements ThreadFactory {
        private final String _prefix;
        private final AtomicInteger _seq = new AtomicInteger(1);

        NamedThreadFactory(String prefix) {
            _prefix = prefix;
        }

        @Override
        public Thread newThread(Runnable r) {
            Thread t = new Thread(r, _prefix + "-" + _seq.getAndIncrement());
            t.setDaemon(true);   // 不要擋住 JVM 關閉
            t.setUncaughtExceptionHandler((thread, e) ->
                    _log.error("執行緒 {} 發生未處理例外", thread.getName(), e));
            return t;
        }
    }
}
