package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.gm.GmCommandHandler;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_GmResult;

/**
 * GM 指令。
 * JSON: { "op": "C_GM_COMMAND", "data": { "command": "tp 1 40 40" } }
 * <p>
 * {@code command} 為<b>不含前綴</b>的指令原文（前端剝除開頭的 {@code .} 後送出）。
 * 權限不足或未進遊戲一律拒絕，並以 {@link S_GmResult} 回饋原因。
 */
public class C_GmCommand extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_GmCommand.class);

    private final String command;

    public C_GmCommand(String raw) {
        super(raw);
        command = getString("command", "");
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_GM_COMMAND 失敗：尚未進入遊戲");
            return;
        }

        PcInstance pc = client.getActiveChar();
        int level = client.getAccount() != null ? client.getAccount().getAccessLevel() : 0;
        if (level < GmCommandHandler.REQUIRED_ACCESS_LEVEL) {
            logger.warn("GM指令遭拒（權限不足 {}）：char={} cmd={}", level, pc.getName(), command);
            client.sendPacket(S_GmResult.fail("權限不足，需要 access_level ≥ "
                    + GmCommandHandler.REQUIRED_ACCESS_LEVEL));
            return;
        }

        String result = GmCommandHandler.get().execute(client, pc, command);
        client.sendPacket(S_GmResult.ok(result));
    }
}
