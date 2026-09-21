package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 收到組隊邀請（對應 opcode {@code S_PARTY_INVITE}）。
 * <p>
 * 前端應該跳出可接受／拒絕的提示。邀請是<b>單一待處理</b>的：
 * 後來的邀請會覆蓋先前的，避免累積一堆過期邀請。
 */
public class S_PartyInvite extends ServerBasePacket {

    private S_PartyInvite(long inviterObjId, String inviterName) {
        super(ServerOpcodes.S_PARTY_INVITE);
        put("inviterObjId", inviterObjId);
        put("inviterName", inviterName);
    }

    public static S_PartyInvite of(long inviterObjId, String inviterName) {
        return new S_PartyInvite(inviterObjId, inviterName);
    }
}
