package com.xin.server;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;





import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.config.CharCreateConfig;
import com.xin.server.config.ServerConfig;
import com.xin.server.datatables.lock.AccountR;
import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.datatables.BreakthroughTable;
import com.xin.server.datatables.ItemTable;
import com.xin.server.datatables.LevelExpTable;
import com.xin.server.datatables.MapPortalTable;
import com.xin.server.datatables.MapTable;
import com.xin.server.datatables.MonsterSpawnTable;
import com.xin.server.datatables.NpcSpawnTable;
import com.xin.server.datatables.NpcTable;
import com.xin.server.datatables.PropertyTable;
import com.xin.server.datatables.RealmTable;
import com.xin.server.datatables.SceneSpawnTable;
import com.xin.server.datatables.StatGrowthBonusTable;
import com.xin.server.gm.GmCommandHandler;
import com.xin.server.network.GameServerHandler;
import com.xin.server.network.GameProtocolDecoder;
import com.xin.server.thread.ThreadPoolManager;
import com.xin.util.DatabaseFactory;

public class GameServer {

    private static final Logger logger = LoggerFactory.getLogger(GameServer.class);

    /** 單一封包（一行）的長度上限；超過即斷開，避免惡意超長輸入吃光記憶體。 */
    private static final int MAX_FRAME_LENGTH = 65536;
    private final int port;

    public GameServer(int port) {
        this.port = port;
    }

    public void start() throws Exception {
        DatabaseFactory dbFactory = DatabaseFactory.getInstance();

        // 伺服器關閉（Ctrl+C／IDE 停止／System.exit）時，先通知線上客戶端關閉遊戲視窗。
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            logger.info("偵測到伺服器關閉，通知線上玩家並存檔...");
            com.xin.server.network.ClientManager.shutdownAll();
        }, "server-shutdown-hook"));

        EventLoopGroup bossGroup = new NioEventLoopGroup(1);
        EventLoopGroup workerGroup = new NioEventLoopGroup();

        try {
            ServerBootstrap bootstrap = new ServerBootstrap();
            bootstrap.group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .option(ChannelOption.SO_BACKLOG, 128)
                    .childOption(ChannelOption.SO_KEEPALIVE, true)
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) throws Exception {
                            ch.pipeline().addLast(new GameProtocolDecoder(MAX_FRAME_LENGTH));
                            ch.pipeline().addLast("game", new GameServerHandler());
                        }
                    });
            // 啟動順序：設定 → 執行緒池 → 創角設定 → 策劃表 → 物件生成 → ID 序列 → 帳號/角色索引 → 道具模板
            ServerConfig.get();
            ThreadPoolManager.get();       // 一般服務／玩家／NPC 三個池，後面的排程都靠它
            CharCreateConfig.get();
            StatGrowthBonusTable.get();
            MapTable.get();
            MapPortalTable.get();
            NpcTable.get();
            PropertyTable.get();
            // 生成點分三張表，需在 NpcTable / PropertyTable 都載入後才能生成
            SceneSpawnTable.get().spawnAll();     // 場景物件 spawnlist_scene
            NpcSpawnTable.get().spawnAll();       // NPC      spawnlist_npc
            MonsterSpawnTable.get().spawnAll();   // 怪物     spawnlist_monster

            // NPC AI：每隻 NPC 自己排程，玩家靠近才醒來（見 model/ai）。要在生怪之後啟動。
            com.xin.server.model.ai.AiManager.start();
            // 怪物波次管理：先註解、不啟用（見 WaveManager.ENABLED）
            // com.xin.server.model.WaveManager.start();
            RealmTable.get();
            BreakthroughTable.get();
            LevelExpTable.get();
            IdFactory.get().load();
            IdFactoryNpc.get();
            AccountR.get().load();
            CharacterR.get().load();
            // 移動、挨打只標記變動，由這裡每 30 秒寫回（見 CharacterSaveTask）
            com.xin.server.model.CharacterSaveTask.start();
            ItemTable.get();
            GmCommandHandler.get();
            logger.info("正在啟動遊戲伺服器，監聽端口: {} ...", port);
            ChannelFuture future = bootstrap.bind(port).sync();
            logger.info("遊戲伺服器已啟動，正在等待玩家連線...");

            future.channel().closeFuture().sync();
        } finally {
            workerGroup.shutdownGracefully();
            bossGroup.shutdownGracefully();
            ThreadPoolManager.get().shutdown();   // 停掉 AI、重生等排程，再寫回資料
            IdFactory.get().save();   // 將當前最大 ID 寫回 id_sequence 表
            dbFactory.shutdown();
            logger.info("遊戲伺服器已安全關閉");
        }
    }

    public static void main(String[] args) throws Exception {
        int port = 8080;
        if (args.length > 0) {
            try {
                port = Integer.parseInt(args[0]);
            } catch (NumberFormatException e) {
                logger.warn("未偵測到有效端口參數，使用預設端口 8080");
            }
        }
        new GameServer(port).start();
    }
}
