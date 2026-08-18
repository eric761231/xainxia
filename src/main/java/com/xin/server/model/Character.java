package com.xin.server.model;

import com.xin.server.template.LevelExpTemplate;

/**
 * 可互動的物件基底
 */
public class Character extends Object {

    private String name;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    private int level = 1;
    
    public int getRealmLevel() {
        return level;
    }

    public void setRealmLevel(int level) {
        this.level = level;
    }

    /** 依目前境界內小等級算出升級所需經驗值上限 */
    public int getExpMax() {
        return LevelExpTemplate.getExpMax(getRealmLevel());
    }

    private int classId;
    
    public int getClassId() {
        return classId;
    }

    public void setClassId(int classId) {
        this.classId = classId;
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
}
