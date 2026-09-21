package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.CharacterDecorationTable;
import com.xin.server.model.instance.DecorationInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_Chat;
import com.xin.server.packet.server.S_ObjectRemove;

/**
 * 移除家具（洞府布置）。
 * JSON: { "op": "C_REMOVE_PROPERTY", "data": { "objId": 2000000005 } }
 * <p>
 * 只能移除<b>自己的</b>裝飾：{@code findDecoration} 只查得到自己身上的清單，
 * DB 刪除時也再比對一次 {@code char_name}，兩層都擋。
 */
public class C_RemoveProperty extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_RemoveProperty.class);

    private final long objId;

    public C_RemoveProperty(String raw) {
        super(raw);
        objId = getLong("objId", 0);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_REMOVE_PROPERTY 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();

        DecorationInstance d = pc.findDecoration(objId);
        if (d == null) {
            logger.warn("移除家具遭拒（非本人所有或不存在）：char={} objId={}",
                    pc.getName(), objId);
            client.sendPacket(S_Chat.system("那不是你的東西"));
            return;
        }

        if (!CharacterDecorationTable.get().delete(d._dbId, pc.getName())) {
            client.sendPacket(S_Chat.system("移除失敗（資料庫錯誤）"));
            return;
        }
        pc.removeDecoration(d);
        client.sendPacket(S_ObjectRemove.of(d._objId));
        logger.info("移除家具 char={} {} objId={}", pc.getName(), d._viewNote, objId);
    }
}
