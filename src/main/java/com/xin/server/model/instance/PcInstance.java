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
}
