package com.xin.server.network;

import io.netty.channel.Channel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.CharacterSaveTask;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.packet.server.S_ServerShutdown;
import com.xin.server.packet.server.S_SystemMessage;
import com.xin.server.service.AccountLogoutService;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

/**
 * 連線統一管理
 */
public class ClientManager {

    private static final Logger logger = LoggerFactory.getLogger(ClientManager.class);

    private static final ConcurrentHashMap<String, Client> clients = new ConcurrentHashMap<>();

    public static void add(Channel channel, Client client) {
        clients.put(channel.id().asShortText(), client);
        logger.info("新連線：{} 線上人數：{}", channel.remoteAddress(), clients.size());
    }

    public static void remove(Channel channel) {
        Client client = clients.remove(channel.id().asShortText());
        if (client != null) {
            if (client.hasAccount()) {
                AccountLogoutService.logout(client);
            } else {
                client.onDisconnect();
            }
            logger.info("斷線：{} 線上人數：{}", channel.remoteAddress(), clients.size());
        }
    }

    public static Client get(Channel channel) {
        return clients.get(channel.id().asShortText());
    }

    public static Collection<Client> getAll() {
        return clients.values();
    }

    public static int getOnlineCount() {
        return clients.size();
    }

    public static void shutdownAll() {
        logger.info("伺服器關閉中，線上人數：{}", clients.size());

        if (clients.isEmpty()) {
            return;
        }

        PacketSender.broadcastAll(new S_SystemMessage("伺服器即將關閉，資料儲存中..."));
        // 通知客戶端關閉遊戲視窗（連線關閉封包）。
        PacketSender.broadcastAll(S_ServerShutdown.of("伺服器已關閉"));

        int threadCount = Math.min(clients.size(), 10);
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);

        List<Future<?>> futures = new ArrayList<>();

        for (Client client : clients.values()) {
            futures.add(executor.submit(() -> {
                try {
                    // 以前這裡只寫 log、沒有真的存檔；移動與挨打改為定期存檔後，
                    // 關服時不寫回就會丟掉最後一輪的座標與血量。
                    PcInstance pc = client.getActiveChar();
                    if (pc != null) {
                        CharacterSaveTask.flush(pc);
                        logger.info("已儲存角色：{}", pc.getName());
                    }
                } catch (Exception e) {
                    logger.error("角色儲存失敗：{}", client, e);
                }
            }));
        }

        for (Future<?> f : futures) {
            try {
                f.get();
            } catch (Exception e) {
                logger.error("等待執行緒異常", e);
            }
        }

        executor.shutdown();

        // 讓 S_ServerShutdown / S_SystemMessage 有時間送達客戶端，再關閉連線。
        try {
            Thread.sleep(300);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        for (Client client : clients.values()) {
            client.disconnect();
        }

        clients.clear();
        logger.info("所有玩家資料儲存完成");
    }
}
