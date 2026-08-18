package com.xin.util;

import java.util.concurrent.TimeUnit;

/**
 * 效能計時器，用於計算程式碼執行時間
 */
public class PerformanceTimer {

    private long startTime; // 開始時間
    private long stopTime; // 停止時間

    /**
     * 初始化計時器並開始計時
     */
    public PerformanceTimer() {
        this.startTime = System.nanoTime();
    }

    /**
     * 停止計時並回傳執行時間 (毫秒)
     * 
     * @return 執行時間 (毫秒)
     */
    public long get() {
        this.stopTime = System.nanoTime();
        return TimeUnit.NANOSECONDS.toMillis(this.stopTime - this.startTime);
    }

    /**
     * 重置計時器 (重新開始計時)
     */
    public void reset() {
        this.startTime = System.nanoTime();
        this.stopTime = 0;
    }

    /**
     * 直接取得當前已經過的時間 (毫秒)
     * 
     * @return 已經過的時間 (毫秒)
     */
    public long getElapsed() {
        return TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - this.startTime);
    }
}
