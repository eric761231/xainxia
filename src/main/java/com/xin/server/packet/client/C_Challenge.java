package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.ChallengeManager;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_Chat;

/**
 * 秘境挑戰的進出。
 * JSON: { "op": "C_CHALLENGE", "data": { "action": "enter" } }
 * <p>
 * 動作：{@code enter} 進入挑戰、{@code leave} 主動退出。
 * 死亡造成的退出由伺服器自己處理（見 {@link ChallengeManager#onDeath}），
 * 不需要前端送封包。
 */
public class C_Challenge extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_Challenge.class);

    private final String action;

    public C_Challenge(String raw) {
        super(raw);
        action = getString("action", "").trim().toLowerCase();
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_CHALLENGE 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();

        switch (action) {
            case "enter":
                String error = ChallengeManager.enter(client, pc);
                if (error != null) {
                    client.sendPacket(S_Chat.system(error));
                } else {
                    client.sendPacket(S_Chat.system("進入秘境，準備迎敵"));
                }
                break;

            case "leave":
                ChallengeManager.leave(client, pc);
                client.sendPacket(S_Chat.system("已離開秘境"));
                break;

            default:
                logger.warn("C_CHALLENGE 未知動作：{}", action);
        }
    }
}
