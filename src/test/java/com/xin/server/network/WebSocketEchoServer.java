package com.xin.server.network;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.*;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;

/** Local-only fixture for the Flutter browser transport tests. No game or DB state. */
public final class WebSocketEchoServer {
    public static void main(String[] args) throws Exception {
        EventLoopGroup boss = new NioEventLoopGroup(1);
        EventLoopGroup worker = new NioEventLoopGroup(1);
        try {
            Channel server = new ServerBootstrap().group(boss, worker)
                    .channel(NioServerSocketChannel.class)
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        protected void initChannel(SocketChannel ch) {
                            ch.pipeline().addLast(new GameProtocolDecoder(65536));
                            ch.pipeline().addLast("game", new SimpleChannelInboundHandler<String>() {
                                protected void channelRead0(ChannelHandlerContext ctx, String text) {
                                    if (text.equals("__close__")) ctx.close();
                                    else ctx.writeAndFlush(text + "\n");
                                }
                            });
                        }
                    }).bind("127.0.0.1", 18081).sync().channel();
            System.out.println("WebSocket echo fixture listening on 127.0.0.1:18081");
            server.closeFuture().sync();
        } finally {
            worker.shutdownGracefully();
            boss.shutdownGracefully();
        }
    }
}
