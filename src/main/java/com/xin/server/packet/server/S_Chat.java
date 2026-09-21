package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.types.ChatChannel;

/**
 * 聊天訊息（對應 opcode {@code S_CHAT}）。
 * <p>
 * {@code channel} 見 {@link ChatChannel}。系統訊息的 {@code sender} 為空字串。
 *
 * <pre>
 * {
 *   "op": "S_CHAT",
 *   "data": { "channel": 1, "sender": "蒼海", "text": "有人打副本嗎" }
 * }
 * </pre>
 */
public class S_Chat extends ServerBasePacket {

    private S_Chat(int channel, String sender, String text) {
        super(ServerOpcodes.S_CHAT);
        put("channel", channel);
        put("sender", sender != null ? sender : "");
        put("text", text != null ? text : "");
    }

    /**
     * 建立一般聊天訊息。
     *
     * @param channel 頻道，見 {@link ChatChannel}
     * @param sender  發話者角色名
     * @param text    訊息內容
     */
    public static S_Chat of(int channel, String sender, String text) {
        return new S_Chat(channel, sender, text);
    }

    /** 建立系統訊息（無發話者）。 */
    public static S_Chat system(String text) {
        return new S_Chat(ChatChannel.SYSTEM, "", text);
    }
}
