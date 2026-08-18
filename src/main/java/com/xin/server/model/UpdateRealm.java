package com.xin.server.model;

import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.server.S_CharStatsUpdate;
import com.xin.server.packet.server.S_LevelDownResult;
import com.xin.server.packet.server.S_LevelUpResult;
import com.xin.server.template.RealmTemplate;
import com.xin.server.util.ExpCalculator;

/**
 * 境界升降級與經驗值處理。
 */
public final class UpdateRealm {

    private UpdateRealm() {
    }

    /**
     * 增加經驗值，自動處理連續升級並刷新屬性。
     * 達到境界最高等級後不再升級，多餘經驗值保留（等待境界突破後繼續累積）。
     *
     * @param pc     目標角色
     * @param amount 增加的經驗值（必須 > 0）
     * @param client 目標連線（可為 null，null 時不發送封包）
     * @return 實際升級次數
     */
    public static int addExp(PcInstance pc, int amount, Client client) {
        if (amount <= 0 || pc == null) {
            return 0;
        }
        pc.setExp(pc.getExp() + amount);
        int levelUps = 0;
        while (pc.getRealmLevel() < RealmTemplate.getLevelsPerRealm(pc.getRealmStage())
                && pc.getExp() >= pc.getExpMax()) {
            pc.setExp(pc.getExp() - pc.getExpMax());
            pc.setRealmLevel(pc.getRealmLevel() + 1);
            levelUps++;
            pc.refreshCombatStats();
        }
        CharacterR.get().storeCharacter(pc);
        if (client != null) {
            if (levelUps > 0) {
                client.sendPacket(S_LevelUpResult.ok(pc));
            }
            client.sendPacket(S_CharStatsUpdate.of(pc));
        }
        return levelUps;
    }

    /**
     * 扣除經驗值，自動處理連續降級並刷新屬性。
     * <p>
     * 降級規則：
     * <ul>
     *   <li>exp 扣至負數 → 降一重，並將負值折算回前一重的 expMax 區間內。</li>
     *   <li>已在第 1 重且 exp &lt; 0 → 截底為 0，不跨境界降級。</li>
     * </ul>
     *
     * @param pc     目標角色
     * @param amount 扣除的經驗值（必須 > 0）
     * @param client 目標連線（可為 null，null 時不發送封包）
     * @return 實際降級次數（正數）
     */
    public static int removeExp(PcInstance pc, int amount, Client client) {
        if (amount <= 0 || pc == null) {
            return 0;
        }
        pc.setExp(pc.getExp() - amount);
        int levelDowns = 0;
        while (pc.getExp() < 0 && pc.getRealmLevel() > 1) {
            pc.setRealmLevel(pc.getRealmLevel() - 1);
            pc.setExp(pc.getExp() + ExpCalculator.getExpMax(pc.getRealmLevel()));
            levelDowns++;
            pc.refreshCombatStats();
        }
        if (pc.getExp() < 0) {
            pc.setExp(0);
        }
        CharacterR.get().storeCharacter(pc);
        if (client != null) {
            if (levelDowns > 0) {
                client.sendPacket(S_LevelDownResult.ok(pc));
            }
            client.sendPacket(S_CharStatsUpdate.of(pc));
        }
        return levelDowns;
    }
}
