package com.xin.server.model.instance;

import com.xin.server.inventory.Inventory;
import com.xin.server.model.Character;
import com.xin.server.util.CombatStatCalculator;
import com.xin.server.template.NatalWeaponTemplate;
import com.xin.server.template.RealmTemplate;

/**
 * 玩家在世界中的執行期實例。
 */
public class PcInstance extends Character {

    private final Inventory inventory = new Inventory();

    public Inventory getInventory() {
        return inventory;
    }

    /** 靈根 attribute：0=金 … 6=雷 */
    private int _attribute;

    public int getAttribute() {
        return _attribute;
    }

    public void setAttribute(int attribute) {
        _attribute = attribute;
    }

    /** 本命攻擊法寶武器類型 */
    private int _natalWeaponId;

    public int getNatalWeaponId() {
        return _natalWeaponId;
    }

    public void setNatalWeaponId(int natalWeaponId) {
        _natalWeaponId = natalWeaponId;
    }

    /**性別**/
	private int _sex;
	
	public int getSex() {
		return _sex;
	}
	
	public void setSex(int sex) {
		_sex = sex; 
	}
	
	// 角色名稱
	private String _name;

	/** 角色名稱 **/
	public String getName() {
		return _name;
	}
	/** 設置角色名稱 **/
	public void setName(String name) {
		_name = name;
	}
	
	/**身體數值點數*/
	private int _stats_point;
	
	public int getStats() {
		return _stats_point;
	}
	
	public void setStatsPoint(int stats_point) {
		_stats_point = stats_point;
	}
	
	/**悟性（stats_intel）**/
	private int _stats_intelligence;
	
	public int getStatsIntel() {
		return _stats_intelligence;
	}
	
	public void setStatsIntel(int stats_intelligence) {
		_stats_intelligence = stats_intelligence;
	}
	
	/**神識（stats_spirit）**/
	private int _stats_spirit;
	
	public int getStatsSpirit() {
		return _stats_spirit;
	}
	
	public void setStatsSpirit(int stats_spirit) {
		_stats_spirit = stats_spirit;
	}
	
	/**敏捷**/
	private int _stats_agility;
	
	public int getStatsAgility() {
		return _stats_agility;
	}
	
	public void setStatsAgility(int stats_agility) {
		_stats_agility = stats_agility;
	}
	
	/**體魄**/
	private int _stats_constiution;
	
	public int getStatsConstiution() {
		return _stats_constiution;
	}
	
	public void setConstiution(int stats_constiution) {
		_stats_constiution = stats_constiution;
	}
	
	private int _baseHp;
	
	public int getBaseHp() {
		return _baseHp;
	}
	
	public void setBaseHp(int baseHp) {
		_baseHp = baseHp;
	}
	
	private int _maxHp;
	
	public int getMaxHp() {
		return _maxHp;
	}
	
	public void setMaxHp(int maxHp) {
		_maxHp = maxHp;
	}
	
	private int _currentHp;
	
	public int getCurrentHp() {
		return _currentHp;
	}
	
	public void setCurrentHp(int currentHp) {
		_currentHp = currentHp;
	}
	
	private int _baseMp;
	
	public int getBaseMp() {
		return _baseMp;
	}
	
	public void setBaseMp(int baseMp) {
		_baseMp = baseMp;
	}
	
	private int _maxMp;
	
	public int getMaxMp() {
		return _maxMp;
	}
	
	public void setMaxMp(int maxMp) {
		_maxMp = maxMp;
	}
	
	private int _currentMp;
	
	public int getCurrentMp() {
		return _currentMp;
	}
	
	public void setCurrentMp(int currentMp) {
		_currentMp = currentMp;
	}
	
	private String accountName;
	
	public String getAccountName() {
        return accountName;
    }

    public void setAccountName(String accountName) {
        this.accountName = accountName;
    }
	
    private int _studyMagicSpeed; // 領悟法術速度
    
    public int get_studyMagicSpeed() {
    	return _studyMagicSpeed;
    }
    
    public void set_studyMagicSpeed(int studyMagicSpeed) {
        _studyMagicSpeed = studyMagicSpeed;
    }
    
    private int _studyMagicTime; // 領悟法術需要時間

    public int get_studyMagicTime() {
    	return _studyMagicTime;
    }

    public void set_studyMagicTime(int studyMagicTime) {
    	_studyMagicTime = studyMagicTime;
    }

    /** 防禦力 */
    private int _defense;

    public int getDefense() {
        return _defense;
    }

    public void setDefense(int defense) {
        _defense = defense;
    }

    /** 經驗值 */
    private int _exp;

    public int getExp() {
        return _exp;
    }

    public void setExp(int exp) {
        _exp = exp;
    }

    /** 境界階段（見 RealmTemplate） */
    private int _realmStage;

    public int getRealmStage() {
        return _realmStage;
    }

    public void setRealmStage(int realmStage) {
        _realmStage = realmStage;
    }

    /** 所屬勢力 */
    private String _faction = "";

    public String getFaction() {
        return _faction;
    }

    public void setFaction(String faction) {
        _faction = faction;
    }

    /** 生活職業 */
    private String _lifeJob = "";

    public String getLifeJob() {
        return _lifeJob;
    }

    public void setLifeJob(String lifeJob) {
        _lifeJob = lifeJob;
    }

    /** 生活職業等級 */
    private int _lifeJobLevel;

    public int getLifeJobLevel() {
        return _lifeJobLevel;
    }

    public void setLifeJobLevel(int lifeJobLevel) {
        _lifeJobLevel = lifeJobLevel;
    }

    /** 核心功法 */
    private String _coreTechnique = "";

    public String getCoreTechnique() {
        return _coreTechnique;
    }

    public void setCoreTechnique(String coreTechnique) {
        _coreTechnique = coreTechnique;
    }

    /** 境界名稱（依 {@link #getRealmStage()} 查 {@link RealmTemplate}） */
    public String getRealmName() {
        return RealmTemplate.getName(getRealmStage());
    }

    /** 本命武器名稱（依 {@link #getNatalWeaponId()} 查 {@link NatalWeaponTemplate}） */
    public String getNatalWeaponName() {
        return NatalWeaponTemplate.getName(getNatalWeaponId());
    }

    /** 依四大素質、境界獎勵重新計算並套用全部戰鬥屬性（創角、突破：HP/MP 填滿） */
    public void recalculateCombatStats() {
        CombatStatCalculator.apply(this, true);
    }

    /** 升級時重算屬性，保留並按比例增加 HP/MP */
    /**
     * 下一次可以攻擊的時間（毫秒）。沒有這個限制的話，腳本可以用送封包的速度無限連打。
     * 只有這個角色自己的封包執行緒會讀寫。
     */
    private long _nextAttackAt;

    public long getNextAttackAt() {
        return _nextAttackAt;
    }

    public void setNextAttackAt(long nextAttackAt) {
        _nextAttackAt = nextAttackAt;
    }

    /**
     * 是否有尚未寫回 DB 的變動（移動、扣血等高頻狀態）。
     * 由 {@link com.xin.server.model.CharacterSaveTask} 定期寫回並清除。
     * volatile：封包執行緒、NPC 執行緒與存檔執行緒都會讀寫它。
     */
    private volatile boolean _dirty;

    /** 標記有變動，等定期存檔寫回。 */
    public void markDirty() {
        _dirty = true;
    }

    public boolean isDirty() {
        return _dirty;
    }

    public void clearDirty() {
        _dirty = false;
    }

    public void refreshCombatStats() {
        CombatStatCalculator.apply(this, false);
    }

    /** 攻擊力 */
    private int _attack;

    public int getAttack() { return _attack; }
    public void setAttack(int attack) { _attack = attack; }

    /** 命中 */
    private int _hit;

    public int getHit() { return _hit; }
    public void setHit(int hit) { _hit = hit; }

    /** 閃避 */
    private int _dodge;

    public int getDodge() { return _dodge; }
    public void setDodge(int dodge) { _dodge = dodge; }

    /** 回血速度 */
    private int _hpRegen;

    public int getHpRegen() { return _hpRegen; }
    public void setHpRegen(int hpRegen) { _hpRegen = hpRegen; }

    /** 回魔速度 */
    private int _mpRegen;

    public int getMpRegen() { return _mpRegen; }
    public void setMpRegen(int mpRegen) { _mpRegen = mpRegen; }

    /** 傀儡／寵物上限（神識決定，最高 4） */
    private int _puppetMax;

    public int getPuppetMax() { return _puppetMax; }
    public void setPuppetMax(int puppetMax) { _puppetMax = puppetMax; }

    /** 法術領悟效率（%，悟性加成） */
    private int _spellLearnRate = 100;

    public int getSpellLearnRate() { return _spellLearnRate; }
    public void setSpellLearnRate(int spellLearnRate) { _spellLearnRate = spellLearnRate; }

    /** 仙藝熟練度加成（%，悟性加成） */
    private int _craftProficiencyRate = 100;

    public int getCraftProficiencyRate() { return _craftProficiencyRate; }
    public void setCraftProficiencyRate(int craftProficiencyRate) { _craftProficiencyRate = craftProficiencyRate; }

    // ──────────────────────────────────────────────────────────────
    // 洞府裝飾（玩家自己擺的家具）
    //
    // 刻意掛在角色身上而非 World：每人只看得到自己的裝飾，
    // 碰撞也必須是每人一份 —— 否則 A 放的桌子會擋住站在同一張地圖的 B。
    // ──────────────────────────────────────────────────────────────

    /** 單一角色的裝飾件數上限。 */
    public static final int MAX_DECORATIONS = 50;

    private final java.util.List<DecorationInstance> _decorations =
            new java.util.ArrayList<>();

    public java.util.List<DecorationInstance> getDecorations() {
        return _decorations;
    }

    /** 換圖／進圖時重載該地圖的裝飾。 */
    public void setDecorations(java.util.List<DecorationInstance> list) {
        _decorations.clear();
        if (list != null) {
            _decorations.addAll(list);
        }
    }

    public void addDecoration(DecorationInstance d) {
        _decorations.add(d);
    }

    /** 依執行期物件編號取得裝飾；查無回傳 {@code null}。 */
    public DecorationInstance findDecoration(long objId) {
        for (DecorationInstance d : _decorations) {
            if (d._objId == objId) {
                return d;
            }
        }
        return null;
    }

    public boolean removeDecoration(DecorationInstance d) {
        return _decorations.remove(d);
    }

    /**
     * 該格是否被<b>自己的</b>裝飾擋住。
     * <p>
     * 只計入 {@code blocking} 的家具；純裝飾（地毯、掛畫）不擋路。
     * 移動驗證除了共用的 {@code MapGrid} 之外還要再問這一條。
     */
    public boolean isBlockedByOwnDecoration(int x, int y) {
        for (DecorationInstance d : _decorations) {
            if (d._blocking && d._mapId == getMapId() && d.occupies(x, y)) {
                return true;
            }
        }
        return false;
    }

    /** 該格是否已被自己的任何裝飾佔用（不論擋不擋路），供放置時避免重疊。 */
    public boolean isOccupiedByOwnDecoration(int x, int y) {
        return isOccupiedByOwnDecoration(x, y, 0L);
    }

    /**
     * 同上，但排除指定的一件裝飾。
     * <p>
     * 搬動家具時必須排除「正在搬的那一件」，否則往旁邊移一格會撞到自己
     * 原本的佔格而永遠被拒。放置時傳 {@code 0} 即為不排除任何東西。
     */
    public boolean isOccupiedByOwnDecoration(int x, int y, long ignoreObjId) {
        for (DecorationInstance d : _decorations) {
            if (d._objId == ignoreObjId) {
                continue;
            }
            if (d._mapId == getMapId() && d.occupies(x, y)) {
                return true;
            }
        }
        return false;
    }
}
