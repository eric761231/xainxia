package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_CharMove;

/**
 * 人物移動。
 * JSON: { "op": "C_MOVE", "data": { "x": 1, "y": 2, "heading": 2 } }
 */
public class C_Move extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_Move.class);

    private final int x;
    private final int y;
    private final int heading;

    public C_Move(String raw) {
        super(raw);
        x = getInt("x", 0);
        y = getInt("y", 0);
        heading = getInt("heading", 0);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_MOVE 失敗：尚未進入遊戲");
            return;
        }

        PcInstance pc = client.getActiveChar();
        pc.setX(x);
        pc.setY(y);
        CharacterR.get().storeCharacter(pc);

        PacketSender.broadcastToVisible(client,
                new S_CharMove(pc.getName(), x, y, heading));
    }
}
