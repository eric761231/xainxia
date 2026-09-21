package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.ClientManager;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_Chat;
import com.xin.server.types.ChatChannel;

/**
 * 聊天發言。
 * JSON: { "op": "C_CHAT", "data": { "channel": 1, "text": "哈囉", "target": "" } }
 * <p>
 * {@code channel} 見 {@link ChatChannel}；{@code target} 僅 {@link ChatChannel#WHISPER} 使用。
 * <p>
 * 隊伍與門派目前<b>沒有後端系統</b>（無組隊、無門派資料表），
 * 送這兩個頻道會收到系統訊息說明尚未實作 —— 不假裝送出成功。
 */
public class C_Chat extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_Chat.class);

    /** 單則訊息長度上限。 */
    private static final int MAX_LENGTH = 200;

    private final int channel;
    private final String text;
    private final String target;

    public C_Chat(String raw) {
        super(raw);
        channel = getInt("channel", ChatChannel.WORLD);
        text = getString("text", "").trim();
        target = getString("target", "").trim();
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_CHAT 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();

        if (text.isEmpty()) {
            return;   // 空訊息直接忽略，不必回饋
        }
        if (text.length() > MAX_LENGTH) {
            client.sendPacket(S_Chat.system("訊息過長（上限 " + MAX_LENGTH + " 字）"));
            return;
        }
        if (!ChatChannel.isSendable(channel)) {
            logger.warn("C_CHAT 拒絕：不可發送的頻道 {} char={}", channel, pc.getName());
            client.sendPacket(S_Chat.system("無法在「" + ChatChannel.nameOf(channel) + "」頻道發言"));
            return;
        }

        switch (channel) {
            case ChatChannel.WORLD:
                PacketSender.broadcastAll(S_Chat.of(ChatChannel.WORLD, pc.getName(), text));
                break;

            case ChatChannel.WHISPER:
                whisper(client, pc);
                break;

            case ChatChannel.PARTY:
            case ChatChannel.GUILD:
                client.sendPacket(S_Chat.system(
                        "「" + ChatChannel.nameOf(channel) + "」頻道尚未實作"));
                break;

            default:
                break;
        }
    }

    /** 私聊：發送者與接收者各送一份，否則自己看不到自己說了什麼。 */
    private void whisper(Client client, PcInstance pc) {
        if (target.isEmpty()) {
            client.sendPacket(S_Chat.system("私聊需要指定對象"));
            return;
        }
        if (target.equals(pc.getName())) {
            client.sendPacket(S_Chat.system("不能私聊自己"));
            return;
        }

        Client targetClient = null;
        for (Client c : ClientManager.getAll()) {
            if (c.hasActiveChar() && target.equals(c.getActiveChar().getName())) {
                targetClient = c;
                break;
            }
        }
        if (targetClient == null) {
            client.sendPacket(S_Chat.system("找不到玩家：" + target));
            return;
        }

        S_Chat packet = S_Chat.of(ChatChannel.WHISPER, pc.getName(), text);
        targetClient.sendPacket(packet);
        client.sendPacket(packet);
    }
}
