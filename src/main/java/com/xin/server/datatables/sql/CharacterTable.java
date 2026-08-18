package com.xin.server.datatables.sql;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.storage.CharacterS;
import com.xin.server.model.instance.PcInstance;
import com.xin.util.DatabaseFactory;
import com.xin.util.PerformanceTimer;
import com.xin.util.SQLUtil;

/**
 * DB table: {@code characters}（角色 SQL 存取與名稱索引）
 */
public class CharacterTable implements CharacterS {

    private static final Logger _log = LoggerFactory.getLogger(CharacterTable.class);

    /** char_name (lower) -> account_name (lower) */
    private final Map<String, String> _charNameIndex = new ConcurrentHashMap<>();

    // 待新增角色編號欄位時再擴充
    private static final String SELECT_COLUMNS =
            "obj_id, account_name, char_name, realm_level, sex, attribute, natal_weapon_id, "
             + "stats_intel, stats_spirit, stats_agility, stats_constitution, "
             + "map_id, loc_x, loc_y, "
             + "current_hp, max_hp, current_mp, max_mp, defense, attack, hit, dodge, "
             + "hp_regen, mp_regen, puppet_max, spell_learn_rate, craft_proficiency_rate, "
             + "exp, realm_stage, "
             + "faction, life_job, life_job_level, core_technique";

    @Override
    public void load() {
        final PerformanceTimer timer = new PerformanceTimer();
        _charNameIndex.clear();

        Connection co = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        int count = 0;
        try {
            co = DatabaseFactory.getInstance().getConnection();
            final String sql = "SELECT char_name, account_name FROM `characters`";
            ps = co.prepareStatement(sql);
            rs = ps.executeQuery();
            while (rs.next()) {
                final String charName = rs.getString("char_name");
                final String accountName = rs.getString("account_name");
                _charNameIndex.put(normalizeCharName(charName), normalizeAccount(accountName));
                count++;
            }
        } catch (final Exception e) {
            _log.error(e.getLocalizedMessage(), e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(co);
        }
        _log.info("載入角色名稱索引: {} ({}ms)", count, timer.get());
    }

    @Override
    public List<PcInstance> loadByAccount(String accountName) {
        final String key = normalizeAccount(accountName);
        Connection co = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        final List<PcInstance> list = new ArrayList<>();
        try {
            co = DatabaseFactory.getInstance().getConnection();
            final String sql = "SELECT " + SELECT_COLUMNS + " FROM `characters` WHERE account_name=? ORDER BY char_name";
            ps = co.prepareStatement(sql);
            ps.setString(1, key);
            rs = ps.executeQuery();
            while (rs.next()) {
                list.add(readRow(rs));
            }
        } catch (final Exception e) {
            _log.error(e.getLocalizedMessage(), e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(co);
        }
        return Collections.unmodifiableList(list);
    }

    @Override
    public PcInstance loadCharacter(String accountName, String charName) {
        return findByName(accountName, charName);
    }

    @Override
    public PcInstance findByName(String accountName, String charName) {
        if (charName == null || charName.isEmpty()) {
            return null;
        }
        Connection co = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            co = DatabaseFactory.getInstance().getConnection();
            final String sql = "SELECT " + SELECT_COLUMNS
                    + " FROM `characters` WHERE account_name=? AND char_name=?";
            ps = co.prepareStatement(sql);
            ps.setString(1, normalizeAccount(accountName));
            ps.setString(2, charName);
            rs = ps.executeQuery();
            if (rs.next()) {
                return readRow(rs);
            }
        } catch (final Exception e) {
            _log.error(e.getLocalizedMessage(), e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(co);
        }
        return null;
    }

    @Override
    public boolean isCharNameTaken(String charName) {
        if (charName == null || charName.isEmpty()) {
            return false;
        }
        if (_charNameIndex.containsKey(normalizeCharName(charName))) {
            return true;
        }
        Connection co = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            co = DatabaseFactory.getInstance().getConnection();
            ps = co.prepareStatement("SELECT 1 FROM `characters` WHERE char_name=? LIMIT 1");
            ps.setString(1, charName);
            rs = ps.executeQuery();
            return rs.next();
        } catch (final Exception e) {
            _log.error(e.getLocalizedMessage(), e);
            return true;
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(co);
        }
    }

    @Override
    public boolean insertCharacter(PcInstance pc) {
        if (pc.getId() <= 0) {
            _log.error("insertCharacter 拒絕：char_id 未設定 name={}", pc.getName());
            return false;
        }
        Connection co = null;
        PreparedStatement ps = null;
        try {
            co = DatabaseFactory.getInstance().getConnection();
            final String sql = "INSERT INTO `characters` (" + SELECT_COLUMNS
                    + ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            ps = co.prepareStatement(sql);
            int i = 1;
            ps.setLong(i++, pc.getId());
            ps.setString(i++, normalizeAccount(pc.getAccountName()));
            ps.setString(i++, pc.getName());
            ps.setInt(i++, pc.getRealmLevel());
            ps.setInt(i++, pc.getSex());
            ps.setInt(i++, pc.getAttribute());
            ps.setInt(i++, pc.getNatalWeaponId());
            ps.setInt(i++, pc.getStatsIntel());
            ps.setInt(i++, pc.getStatsSpirit());
            ps.setInt(i++, pc.getStatsAgility());
            ps.setInt(i++, pc.getStatsConstiution());
            ps.setInt(i++, pc.getMapId());
            ps.setInt(i++, pc.getX());
            ps.setInt(i++, pc.getY());
            ps.setInt(i++, pc.getCurrentHp());
            ps.setInt(i++, pc.getMaxHp());
            ps.setInt(i++, pc.getCurrentMp());
            ps.setInt(i++, pc.getMaxMp());
            ps.setInt(i++, pc.getDefense());
            ps.setInt(i++, pc.getAttack());
            ps.setInt(i++, pc.getHit());
            ps.setInt(i++, pc.getDodge());
            ps.setInt(i++, pc.getHpRegen());
            ps.setInt(i++, pc.getMpRegen());
            ps.setInt(i++, pc.getPuppetMax());
            ps.setInt(i++, pc.getSpellLearnRate());
            ps.setInt(i++, pc.getCraftProficiencyRate());
            ps.setInt(i++, pc.getExp());
            ps.setInt(i++, pc.getRealmStage());
            ps.setString(i++, pc.getFaction());
            ps.setString(i++, pc.getLifeJob());
            ps.setInt(i++, pc.getLifeJobLevel());
            ps.setString(i++, pc.getCoreTechnique());
            ps.executeUpdate();
            pc.setAccountName(normalizeAccount(pc.getAccountName()));
            _charNameIndex.put(normalizeCharName(pc.getName()), normalizeAccount(pc.getAccountName()));
            return true;
        } catch (final SQLException e) {
            if (isDuplicateKey(e)) {
                _log.warn("insertCharacter 名稱重複 name={}", pc.getName());
                return false;
            }
            _log.error(e.getLocalizedMessage(), e);
            return false;
        } catch (final Exception e) {
            _log.error(e.getLocalizedMessage(), e);
            return false;
        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(co);
        }
    }

    @Override
    public void storeCharacter(PcInstance pc) {
        synchronized (pc) {
            Connection co = null;
            PreparedStatement ps = null;
            try {
                co = DatabaseFactory.getInstance().getConnection();
                final String sql = "UPDATE `characters` SET realm_level=?, sex=?, attribute=?, natal_weapon_id=?, "
                        + "stats_intel=?, stats_spirit=?, stats_agility=?, stats_constitution=?, "
                        + "map_id=?, loc_x=?, loc_y=?, "
                        + "current_hp=?, max_hp=?, current_mp=?, max_mp=?, defense=?, attack=?, hit=?, dodge=?, "
                        + "hp_regen=?, mp_regen=?, puppet_max=?, spell_learn_rate=?, craft_proficiency_rate=?, "
                        + "exp=?, realm_stage=?, "
                        + "faction=?, life_job=?, life_job_level=?, core_technique=? "
                        + "WHERE account_name=? AND char_name=?";
                ps = co.prepareStatement(sql);
                int i = 1;
                ps.setInt(i++, pc.getRealmLevel());
                ps.setInt(i++, pc.getSex());
                ps.setInt(i++, pc.getAttribute());
                ps.setInt(i++, pc.getNatalWeaponId());
                ps.setInt(i++, pc.getStatsIntel());
                ps.setInt(i++, pc.getStatsSpirit());
                ps.setInt(i++, pc.getStatsAgility());
                ps.setInt(i++, pc.getStatsConstiution());
                ps.setInt(i++, pc.getMapId());
                ps.setInt(i++, pc.getX());
                ps.setInt(i++, pc.getY());
                ps.setInt(i++, pc.getCurrentHp());
                ps.setInt(i++, pc.getMaxHp());
                ps.setInt(i++, pc.getCurrentMp());
                ps.setInt(i++, pc.getMaxMp());
                ps.setInt(i++, pc.getDefense());
                ps.setInt(i++, pc.getAttack());
                ps.setInt(i++, pc.getHit());
                ps.setInt(i++, pc.getDodge());
                ps.setInt(i++, pc.getHpRegen());
                ps.setInt(i++, pc.getMpRegen());
                ps.setInt(i++, pc.getPuppetMax());
                ps.setInt(i++, pc.getSpellLearnRate());
                ps.setInt(i++, pc.getCraftProficiencyRate());
                ps.setInt(i++, pc.getExp());
                ps.setInt(i++, pc.getRealmStage());
                ps.setString(i++, pc.getFaction());
                ps.setString(i++, pc.getLifeJob());
                ps.setInt(i++, pc.getLifeJobLevel());
                ps.setString(i++, pc.getCoreTechnique());
                ps.setString(i++, normalizeAccount(pc.getAccountName()));
                ps.setString(i++, pc.getName());
                ps.executeUpdate();
            } catch (final Exception e) {
                _log.error(e.getLocalizedMessage(), e);
            } finally {
                SQLUtil.close(ps);
                SQLUtil.close(co);
            }
        }
    }

    @Override
    public int countByAccount(String accountName) {
        Connection co = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            co = DatabaseFactory.getInstance().getConnection();
            ps = co.prepareStatement("SELECT COUNT(*) FROM `characters` WHERE account_name=?");
            ps.setString(1, normalizeAccount(accountName));
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (final Exception e) {
            _log.error(e.getLocalizedMessage(), e);
        } finally {
            SQLUtil.close(rs);
            SQLUtil.close(ps);
            SQLUtil.close(co);
        }
        return 0;
    }

    @Override
    public boolean deleteCharacter(String accountName, String charName) {
        Connection co = null;
        PreparedStatement ps = null;
        try {
            co = DatabaseFactory.getInstance().getConnection();
            ps = co.prepareStatement("DELETE FROM `characters` WHERE account_name=? AND char_name=?");
            ps.setString(1, normalizeAccount(accountName));
            ps.setString(2, charName);
            int rows = ps.executeUpdate();
            if (rows > 0) {
                _charNameIndex.remove(normalizeCharName(charName));
                return true;
            }
            return false;
        } catch (final Exception e) {
            _log.error(e.getLocalizedMessage(), e);
            return false;
        } finally {
            SQLUtil.close(ps);
            SQLUtil.close(co);
        }
    }

    private PcInstance readRow(ResultSet rs) throws Exception {
        final PcInstance pc = new PcInstance();
        pc.setId(rs.getLong("obj_id"));
        pc.setAccountName(rs.getString("account_name"));
        pc.setName(rs.getString("char_name"));
        pc.setRealmLevel(rs.getInt("realm_level"));
        pc.setSex(rs.getInt("sex"));
        pc.setAttribute(rs.getInt("attribute"));
        pc.setNatalWeaponId(rs.getInt("natal_weapon_id"));
        pc.setStatsIntel(rs.getInt("stats_intel"));
        pc.setStatsSpirit(rs.getInt("stats_spirit"));
        pc.setStatsAgility(rs.getInt("stats_agility"));
        pc.setConstiution(rs.getInt("stats_constitution"));
        pc.setMapId(rs.getInt("map_id"));
        pc.setX(rs.getInt("loc_x"));
        pc.setY(rs.getInt("loc_y"));
        pc.setCurrentHp(rs.getInt("current_hp"));
        pc.setMaxHp(rs.getInt("max_hp"));
        pc.setCurrentMp(rs.getInt("current_mp"));
        pc.setMaxMp(rs.getInt("max_mp"));
        pc.setDefense(rs.getInt("defense"));
        pc.setAttack(rs.getInt("attack"));
        pc.setHit(rs.getInt("hit"));
        pc.setDodge(rs.getInt("dodge"));
        pc.setHpRegen(rs.getInt("hp_regen"));
        pc.setMpRegen(rs.getInt("mp_regen"));
        pc.setPuppetMax(rs.getInt("puppet_max"));
        pc.setSpellLearnRate(rs.getInt("spell_learn_rate"));
        pc.setCraftProficiencyRate(rs.getInt("craft_proficiency_rate"));
        pc.setExp(rs.getInt("exp"));
        pc.setRealmStage(rs.getInt("realm_stage")); // 境界階段，見 RealmTemplate
        pc.setFaction(rs.getString("faction")); // 仙門派別
        pc.setLifeJob(rs.getString("life_job"));
        pc.setLifeJobLevel(rs.getInt("life_job_level"));
        pc.setCoreTechnique(rs.getString("core_technique"));
        return pc;
    }

    private String normalizeAccount(String accountName) {
        return accountName == null ? "" : accountName.toLowerCase();
    }

    private String normalizeCharName(String charName) {
        return charName == null ? "" : charName.toLowerCase();
    }

    private boolean isDuplicateKey(SQLException e) {
        // MySQL 1062、SQLState 23000（唯一約束）
        if (e.getErrorCode() == 1062) {
            return true;
        }
        final String sqlState = e.getSQLState();
        return sqlState != null && sqlState.startsWith("23");
    }
}
