package com.xin.server.template;

import java.util.ArrayList;
import java.util.List;

/**
 * 一張地圖的波次設定（{@code wave_config} 一列 + 它的 {@code wave_npc}）。
 * <p>
 * 波次刻意<b>不放 spawnlist_monster</b>：生成點的語意是「這個座標會冒出什麼」，
 * 波次的語意是「這一關怎麼打」—— 沒有固定座標（繞著玩家生）、數量隨波次成長、
 * 清完才進下一波。兩種語意混在同一張表裡，任何一邊都會變得難懂。
 */
public class WaveConfigTemplate {

    /** 波次可以抽到的一種怪。 */
    public static class Entry {
        public int _npcId;
        public int _weight;
        public int _minWave;

        public Entry(int npcId, int weight, int minWave) {
            _npcId = npcId;
            _weight = Math.max(1, weight);
            _minWave = Math.max(1, minWave);
        }
    }

    public int _mapId;
    public boolean _enabled;
    public int _baseCount;
    public int _perWave;
    public int _maxCount;
    public int _breakSeconds;
    public int _spawnMinDist;
    public int _spawnMaxDist;
    public int _hpPerWave;
    public String _note;

    public final List<Entry> _npcs = new ArrayList<>();

    /** 這一波該生幾隻。 */
    public int countForWave(int wave) {
        return Math.min(_maxCount, _baseCount + (wave - 1) * _perWave);
    }

    /**
     * 依權重抽一種怪；只從「已經解鎖」的挑。
     * <p>
     * 沒有任何一種解鎖時回 0（呼叫端略過這一隻）—— 這代表資料設錯了
     * （所有 min_wave 都大於 1），不該讓它變成例外炸掉整個排程。
     */
    public int rollNpcId(int wave, java.util.Random rng) {
        int total = 0;
        for (Entry e : _npcs) {
            if (wave >= e._minWave) {
                total += e._weight;
            }
        }
        if (total <= 0) {
            return 0;
        }
        int pick = rng.nextInt(total);
        for (Entry e : _npcs) {
            if (wave < e._minWave) {
                continue;
            }
            pick -= e._weight;
            if (pick < 0) {
                return e._npcId;
            }
        }
        return 0;
    }
}
