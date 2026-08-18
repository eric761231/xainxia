package com.xin.server.network;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class GameServerHandler extends SimpleChannelInboundHandler<String> {

    private static final Logger logger = LoggerFactory.getLogger(GameServerHandler.class);


    // ─────────────────────────────────────────
    // 新連線
    // ─────────────────────────────────────────
    @Override
    public void channelActive(ChannelHandlerContext ctx) {
        Client client = new Client(ctx.channel());
        ClientManager.add(ctx.channel(), client);
    }
    
    // ─────────────────────────────────────────
    // 收到封包
    // ─────────────────────────────────────────
    @Override
    protected void channelRead0(ChannelHandlerContext ctx, String msg) throws Exception {
    	 Client client = ClientManager.get(ctx.channel());
         if (client == null) {
             logger.warn("找不到對應的 GameClient：{}", ctx.channel().remoteAddress());
             return;
         }
         PacketDispatcher.dispatch(client, msg);
    }

    // ─────────────────────────────────────────
    // 斷線
    // ─────────────────────────────────────────
    @Override
    public void channelInactive(ChannelHandlerContext ctx) {
    	ClientManager.remove(ctx.channel());
    }

    // ─────────────────────────────────────────
    // 異常
    // ─────────────────────────────────────────
    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        logger.error("伺服器連線異常", ctx.channel().remoteAddress(), cause);
        ctx.close();
    }
}
