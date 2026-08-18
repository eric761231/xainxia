package com.xin.server.config;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 創角數值設定（讀取 {@code config/char_create.ini}）。
 * <p>
 * 涵蓋兩類設定：
 * <ul>
 *   <li>戰鬥基底值：HP/MP/防禦/攻擊/命中/閃避/回復/傀儡/法術/仙藝效率</li>
 *   <li>創角配點規則：四維基底值、自由分配點數、預設出生地圖座標</li>
 * </ul>
 * 若 JSON 檔案缺失或解析失敗，各欄位使用 {@code asInt()} 的備援預設值。
 */
public final class CharCreateConfig {

    private static final Logger LOG = LoggerFactory.getLogger(CharCreateConfig.class);
    private static CharCreateConfig instance;

    // ── 戰鬥基底值 ─────────────────────────────────────────────────────────
    private final int baseHp;
    private final int baseMp;
    private final int baseDefense;
    private final int baseAttack;
    private final int baseHit;
    private final int baseDodge;
    private final int baseHpRegen;
    private final int baseMpRegen;
    private final int basePuppetSlot;
    private final int maxPuppet;
    private final int baseSpellLearnRate;
    private final int baseCraftProficiencyRate;

    // ── 創角配點規則 ───────────────────────────────────────────────────────
    private final int baseStatPerAttr; // 四維素質各別的初始基底值（創角時最低值）
    private final int bonusPool;       // 創角自由分配點數總量
    private final int defaultMapId;    // 創角預設地圖 ID
    private final int defaultX;        // 創角預設 X 座標
    private final int defaultY;        // 創角預設 Y 座標

    public static CharCreateConfig get() {
        if (instance == null) {
            instance = load();
        }
        return instance;
    }

    public static void reload() {
        instance = load();
    }

    private static CharCreateConfig load() {
        Properties p = readIni();
        return new CharCreateConfig(
                getInt(p, "baseHp", 100),
                getInt(p, "baseMp", 50),
                getInt(p, "baseDefense", 5),
                getInt(p, "baseAttack", 5),
                getInt(p, "baseHit", 10),
                getInt(p, "baseDodge", 5),
                getInt(p, "baseHpRegen", 1),
                getInt(p, "baseMpRegen", 1),
                getInt(p, "basePuppetSlot", 0),
                getInt(p, "maxPuppet", 4),
                getInt(p, "baseSpellLearnRate", 100),
                getInt(p, "baseCraftProficiencyRate", 100),
                getInt(p, "baseStatPerAttr", 10),
                getInt(p, "bonusPool", 8),
                getInt(p, "defaultMapId", 0),
                getInt(p, "defaultX", 0),
                getInt(p, "defaultY", 0));
    }

    /** 讀取 {@code config/char_create.ini}：優先 classpath，找不到退外部檔；皆缺回空 Properties（全走預設值）。 */
    private static Properties readIni() {
        Properties props = new Properties();
        try (InputStream in = CharCreateConfig.class.getResourceAsStream("/config/char_create.ini")) {
            if (in != null) {
                props.load(in);
                return props;
            }
        } catch (IOException e) {
            LOG.warn("讀取 classpath char_create.ini 失敗", e);
        }
        Path external = Path.of("config", "char_create.ini");
        if (Files.isRegularFile(external)) {
            try (InputStream in = Files.newInputStream(external)) {
                props.load(in);
                return props;
            } catch (IOException e) {
                LOG.warn("讀取外部 char_create.ini 失敗", e);
            }
        }
        LOG.warn("使用 char_create.ini 預設值");
        return props;
    }

    /** 取整數設定；缺值或格式錯誤時回傳 {@code def}。 */
    private static int getInt(Properties p, String key, int def) {
        String v = p.getProperty(key);
        if (v == null) {
            return def;
        }
        try {
            return Integer.parseInt(v.trim());
        } catch (NumberFormatException e) {
            LOG.warn("char_create.ini 欄位 {} 值 '{}' 非整數，改用預設 {}", key, v, def);
            return def;
        }
    }

    private CharCreateConfig(
            int baseHp, int baseMp, int baseDefense, int baseAttack,
            int baseHit, int baseDodge, int baseHpRegen, int baseMpRegen,
            int basePuppetSlot, int maxPuppet, int baseSpellLearnRate, int baseCraftProficiencyRate,
            int baseStatPerAttr, int bonusPool, int defaultMapId, int defaultX, int defaultY) {
        this.baseHp                  = baseHp;
        this.baseMp                  = baseMp;
        this.baseDefense             = baseDefense;
        this.baseAttack              = baseAttack;
        this.baseHit                 = baseHit;
        this.baseDodge               = baseDodge;
        this.baseHpRegen             = baseHpRegen;
        this.baseMpRegen             = baseMpRegen;
        this.basePuppetSlot          = basePuppetSlot;
        this.maxPuppet               = maxPuppet;
        this.baseSpellLearnRate      = baseSpellLearnRate;
        this.baseCraftProficiencyRate = baseCraftProficiencyRate;
        this.baseStatPerAttr         = baseStatPerAttr;
        this.bonusPool               = bonusPool;
        this.defaultMapId            = defaultMapId;
        this.defaultX                = defaultX;
        this.defaultY                = defaultY;
    }

    // ── getter：戰鬥基底值 ──────────────────────────────────────────────────

    public int getBaseHp() { return baseHp; }
    public int getBaseMp() { return baseMp; }
    public int getBaseDefense() { return baseDefense; }
    public int getBaseAttack() { return baseAttack; }
    public int getBaseHit() { return baseHit; }
    public int getBaseDodge() { return baseDodge; }
    public int getBaseHpRegen() { return baseHpRegen; }
    public int getBaseMpRegen() { return baseMpRegen; }
    public int getBasePuppetSlot() { return basePuppetSlot; }
    public int getMaxPuppet() { return maxPuppet; }
    public int getBaseSpellLearnRate() { return baseSpellLearnRate; }
    public int getBaseCraftProficiencyRate() { return baseCraftProficiencyRate; }

    // ── getter：創角配點規則 ────────────────────────────────────────────────

    /** 四維素質（悟性/神識/敏捷/體魄）的初始基底值，創角時每項最低值。 */
    public int getBaseStatPerAttr() { return baseStatPerAttr; }

    /** 創角自由分配點數總量，玩家可在四維素質間任意分配。 */
    public int getBonusPool() { return bonusPool; }

    /** 新角色的預設出生地圖 ID。 */
    public int getDefaultMapId() { return defaultMapId; }

    /** 新角色的預設出生 X 座標。 */
    public int getDefaultX() { return defaultX; }

    /** 新角色的預設出生 Y 座標。 */
    public int getDefaultY() { return defaultY; }
}
