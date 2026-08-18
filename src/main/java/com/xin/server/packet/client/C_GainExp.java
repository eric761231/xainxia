package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.UpdateRealm;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_LevelUpResult;

/**
 * 獲得經驗值（測試／戰鬥掉落等用途）。
 * JSON: { "op": "C_GAIN_EXP", "data": { "amount": 100 } }
 */
public class C_GainExp extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_GainExp.class);
    private final int amount;

    public C_GainExp(String raw) {
        super(raw);
        amount = getInt("amount", 0);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            client.sendPacket(S_LevelUpResult.fail(
                    S_LevelUpResult.REASON_NOT_IN_GAME, "尚未進入遊戲"));
            return;
        }
        if (amount <= 0) {
            client.sendPacket(S_LevelUpResult.fail(
                    S_LevelUpResult.REASON_INVALID_AMOUNT, "經驗值必須大於 0"));
            return;
        }
        PcInstance pc = client.getActiveChar();
        int levelUps = UpdateRealm.addExp(pc, amount, client);
        logger.info("C_GAIN_EXP char={} amount={} levelUps={}", pc.getName(), amount, levelUps);
    }
}
