package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.PartyManager;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_Chat;
import com.xin.server.world.World;

/**
 * 隊伍操作。一個封包承載所有動作，用 {@code action} 分派。
 * JSON: { "op": "C_PARTY", "data": { "action": "invite", "target": "月蒼海" } }
 * <p>
 * 六個動作各開一個 opcode 也可以，但它們的驗證與回饋方式完全一樣
 * （查隊伍 → 檢查權限 → 回錯誤訊息或廣播），合成一個封包少五份重複的樣板。
 * <p>
 * 動作：{@code invite} / {@code accept} / {@code decline} /
 * {@code leave} / {@code kick} / {@code promote}
 */
public class C_Party extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_Party.class);

    private final String action;
    private final String target;

    public C_Party(String raw) {
        super(raw);
        action = getString("action", "").trim().toLowerCase();
        target = getString("target", "").trim();
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_PARTY 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();
        String error = null;

        switch (action) {
            case "invite":
                error = PartyManager.invite(pc, World.get().findPc(target));
                if (error == null) {
                    client.sendPacket(S_Chat.system("已向 " + target + " 送出組隊邀請"));
                }
                break;

            case "accept":
                error = PartyManager.accept(pc);
                break;

            case "decline":
                PartyManager.decline(pc);
                break;

            case "leave":
                PartyManager.leave(pc);
                break;

            case "kick":
                error = PartyManager.kick(pc, target);
                break;

            case "promote":
                error = PartyManager.promote(pc, target);
                break;

            default:
                logger.warn("C_PARTY 未知動作：{}", action);
                return;
        }

        if (error != null) {
            client.sendPacket(S_Chat.system(error));
        }
        logger.debug("C_PARTY char={} action={} target={} error={}",
                pc.getName(), action, target, error);
    }
}
