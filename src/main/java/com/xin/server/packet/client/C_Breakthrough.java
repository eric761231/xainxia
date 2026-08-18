package com.xin.server.packet.client;

import java.util.concurrent.ThreadLocalRandom;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_BreakthroughResult;
import com.xin.server.packet.server.S_CharStatsUpdate;
import com.xin.server.template.BreakthroughTemplate;
import com.xin.server.template.BreakthroughTemplate.Requirement;
import com.xin.server.template.RealmTemplate;

/**
 * 嘗試境界突破。
 */
public class C_Breakthrough extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_Breakthrough.class);

    public C_Breakthrough(String raw) {
        super(raw);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_BREAKTHROUGH 失敗：尚未進入遊戲");
            client.sendPacket(S_BreakthroughResult.fail(
                    S_BreakthroughResult.REASON_NOT_IN_GAME, "尚未進入遊戲"));
            return;
        }

        PcInstance pc = client.getActiveChar();

        // 已達最高境界
        if (!RealmTemplate.hasNextStage(pc.getRealmStage())) {
            client.sendPacket(S_BreakthroughResult.fail(
                    S_BreakthroughResult.REASON_MAX_REALM, "已達最高境界"));
            return;
        }

        Requirement req = BreakthroughTemplate.getRequirement(pc.getRealmStage());
        if (req == null) {
            client.sendPacket(S_BreakthroughResult.fail(
                    S_BreakthroughResult.REASON_MAX_REALM, "尚未開放突破"));
            return;
        }

        // 境界內等級未達突破條件
        if (pc.getRealmLevel() < req.getMaxRealmLevel()) {
            client.sendPacket(S_BreakthroughResult.fail(
                    S_BreakthroughResult.REASON_LEVEL_NOT_READY,
                    "境界小等級尚未達到 " + req.getMaxRealmLevel() + " 層"));
            return;
        }

        // 檢查並消耗突破所需道具
        if (!BreakthroughTemplate.checkAndConsumeItems(pc, req)) {
            client.sendPacket(S_BreakthroughResult.fail(
                    S_BreakthroughResult.REASON_MISSING_ITEM, "缺少突破所需道具"));
            return;
        }

        // 計算實際成功機率（基礎 + 護體加成，上限 100）
        int finalRate = req.getBaseSuccessRate();
        if (req.hasProtectItems() && BreakthroughTemplate.hasProtectItem(pc, req)) {
            finalRate = Math.min(100, finalRate + req.getIncreaseSuccessRate());
        }

        // 整數機率比較：0～99 隨機值 < finalRate 即成功
        boolean success = ThreadLocalRandom.current().nextInt(100) < finalRate;
        if (!success) {
            logger.info("突破失敗 char={} fromStage={} rate={}", pc.getName(), pc.getRealmStage(), finalRate);
            client.sendPacket(S_BreakthroughResult.fail(
                    S_BreakthroughResult.REASON_FAILED, "突破失敗，可再次嘗試"));
            return;
        }

        pc.setRealmStage(req.getToStage());
        pc.setRealmLevel(1);
        pc.recalculateCombatStats();
        CharacterR.get().storeCharacter(pc);

        logger.info("突破成功 char={} newStage={}", pc.getName(), pc.getRealmStage());
        client.sendPacket(S_BreakthroughResult.ok(pc));
        client.sendPacket(S_CharStatsUpdate.of(pc));
    }
}
