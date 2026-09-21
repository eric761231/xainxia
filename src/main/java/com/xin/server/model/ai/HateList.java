package com.xin.server.model.ai;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 仇恨表：誰對這隻怪造成了多少仇恨。
 * <p>
 * 仇恨 = 累積傷害；<b>第一個打中</b>的人另外加一筆獎勵（通常是最大血量的 1/10）；
 * 只是靠近而被發現的人加 0。這樣「先開怪的人扛得住、路過打一下的人搶不走」自然成立。
 * <p>
 * 同分時先加入的優先（LinkedHashMap 保留加入順序），目標才不會在兩人之間來回跳。
 * <p>
 * 不是執行緒安全的 —— 只在該地圖的鎖內使用。刻意不依賴 DB／World／任何單例，
 * 可以單獨驗證。
 */
public final class HateList {

    private final Map<Long, Integer> _hate = new LinkedHashMap<>();
    private boolean _firstHitTaken;

    /** 加仇恨（負值當 0）。objId 為 0 忽略。 */
    public void add(long objId, int hate) {
        if (objId == 0L) {
            return;
        }
        _hate.merge(objId, Math.max(0, hate), Integer::sum);
    }

    /**
     * 依傷害加仇恨；這隻怪第一次被實際打中時，另外加 {@code firstHitBonus}。
     */
    public void addDamage(long objId, int damage, int firstHitBonus) {
        int hate = Math.max(0, damage);
        if (!_firstHitTaken && damage > 0) {
            hate += Math.max(0, firstHitBonus);
            _firstHitTaken = true;
        }
        add(objId, hate);
    }

    /** 仇恨最高者；空表回傳 {@code 0}。 */
    public long top() {
        long best = 0L;
        int bestHate = -1;
        for (Map.Entry<Long, Integer> e : _hate.entrySet()) {
            if (e.getValue() > bestHate) {
                best = e.getKey();
                bestHate = e.getValue();
            }
        }
        return best;
    }

    public int hateOf(long objId) {
        return _hate.getOrDefault(objId, 0);
    }

    public boolean contains(long objId) {
        return _hate.containsKey(objId);
    }

    public void remove(long objId) {
        _hate.remove(objId);
    }

    /** 清空（脫戰回家）；首擊獎勵也重新計算。 */
    public void clear() {
        _hate.clear();
        _firstHitTaken = false;
    }

    public boolean isEmpty() {
        return _hate.isEmpty();
    }

    public int size() {
        return _hate.size();
    }

    /** 唯讀複本，依加入順序。 */
    public Map<Long, Integer> snapshot() {
        return Collections.unmodifiableMap(new LinkedHashMap<>(_hate));
    }
}
