package com.xin.server.packet.client;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.CharacterDecorationTable;
import com.xin.server.datatables.PropertyTable;
import com.xin.server.model.instance.DecorationInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_Chat;
import com.xin.server.packet.server.S_PropertyPack;
import com.xin.server.template.PropertyTemplate;

/**
 * 搬動已放置的家具。
 * JSON: { "op": "C_MOVE_PROPERTY", "data": { "objId": 2000000002, "x": 40, "y": 41 } }
 * <p>
 * 不送 {@code S_ObjectRemove} 再重放 —— 前端的 {@code S_PROPERTY_PACK} 是 upsert 語意，
 * 同一個 objId 會就地重繪並重建碰撞，一包就夠了。
 */
public class C_MoveProperty extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_MoveProperty.class);

    private final long objId;
    private final int x;
    private final int y;

    public C_MoveProperty(String raw) {
        super(raw);
        objId = getLong("objId", 0L);
        x = getInt("x", 0);
        y = getInt("y", 0);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_MOVE_PROPERTY 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();

        // findDecoration 只找得到自己的東西，越權搬動在此就擋掉
        DecorationInstance d = pc.findDecoration(objId);
        if (d == null) {
            client.sendPacket(S_Chat.system("那不是你的東西"));
            return;
        }

        PropertyTemplate temp = PropertyTable.get().getTemplate(d._propertyId);
        if (temp == null) {
            client.sendPacket(S_Chat.system("物件不存在：" + d._propertyId));
            return;
        }

        // 排除自己，否則往旁邊移一格會撞到自己原本的佔格
        String reason = C_PlaceProperty.validateCells(pc, temp, x, y, objId);
        if (reason != null) {
            logger.warn("搬動家具遭拒（{}）：char={} objId={} ({},{})",
                    reason, pc.getName(), objId, x, y);
            client.sendPacket(S_Chat.system(reason));
            return;
        }

        if (!CharacterDecorationTable.get().updatePosition(d._dbId, pc.getName(), x, y)) {
            client.sendPacket(S_Chat.system("搬動失敗（資料庫錯誤）"));
            return;
        }

        int fromX = d._x;
        int fromY = d._y;
        d._x = x;
        d._y = y;

        client.sendPacket(S_PropertyPack.ofDecorations(pc.getMapId(), List.of(d)));
        logger.info("搬動家具 char={} {} ({},{}) → ({},{}) objId={}",
                pc.getName(), temp._viewNote, fromX, fromY, x, y, objId);
    }
}
