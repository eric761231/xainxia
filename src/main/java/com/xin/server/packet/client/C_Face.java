package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_CharFace;

/**
 * 人物轉向（不移動）。
 * JSON: { "op": "C_FACE", "data": { "heading": 2 } }
 */
public class C_Face extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_Face.class);

    private final int heading;

    public C_Face(String raw) {
        super(raw);
        heading = getInt("heading", 0);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_FACE 失敗：尚未進入遊戲");
            return;
        }

        PcInstance pc = client.getActiveChar();
        PacketSender.broadcastToVisible(client,
                new S_CharFace(pc.getName(), heading));
    }
}
