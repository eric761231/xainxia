package com.xin.server.network;

import java.nio.charset.StandardCharsets;
import java.util.List;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.handler.codec.ByteToMessageDecoder;
import io.netty.handler.codec.LineBasedFrameDecoder;
import io.netty.handler.codec.MessageToMessageCodec;
import io.netty.handler.codec.http.*;
import io.netty.handler.codec.http.websocketx.*;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.codec.string.StringEncoder;

/** Select TCP JSON or HTTP/WebSocket without consuming the initial bytes. */
public final class GameProtocolDecoder extends ByteToMessageDecoder {
    private final int maxFrameLength;

    public GameProtocolDecoder(int maxFrameLength) {
        this.maxFrameLength = maxFrameLength;
    }

    @Override
    protected void decode(ChannelHandlerContext ctx, ByteBuf in, List<Object> out) {
        if (!in.isReadable()) return;
        ChannelPipeline pipeline = ctx.pipeline();
        // JSON packets start with '{' (or whitespace); HTTP methods use uppercase ASCII.
        int first = in.getUnsignedByte(in.readerIndex());
        if (first >= 'A' && first <= 'Z') {
            pipeline.addBefore("game", "http", new HttpServerCodec());
            pipeline.addBefore("game", "httpAggregate", new HttpObjectAggregator(maxFrameLength));
            pipeline.addBefore("game", "httpRoute", new HttpRoute(maxFrameLength));
        } else {
            pipeline.addBefore("game", "lines", new LineBasedFrameDecoder(maxFrameLength));
            pipeline.addBefore("game", "decodeText", new StringDecoder(StandardCharsets.UTF_8));
            pipeline.addBefore("game", "encodeText", new StringEncoder(StandardCharsets.UTF_8));
        }
        // ByteToMessageDecoder forwards its unread cumulation to the new handlers.
        pipeline.remove(this);
    }

    private static final class HttpRoute extends SimpleChannelInboundHandler<FullHttpRequest> {
        private final int maxFrameLength;

        HttpRoute(int maxFrameLength) {
            this.maxFrameLength = maxFrameLength;
        }

        @Override
        protected void channelRead0(ChannelHandlerContext ctx, FullHttpRequest request) {
            if (request.decoderResult().isSuccess() && request.uri().equals("/ws")
                    && request.method().equals(HttpMethod.GET)
                    && "websocket".equalsIgnoreCase(request.headers().get(HttpHeaderNames.UPGRADE))) {
                ChannelPipeline pipeline = ctx.pipeline();
                pipeline.addBefore("game", "websocket",
                        new WebSocketServerProtocolHandler("/ws", null, false, maxFrameLength));
                pipeline.addBefore("game", "websocketAggregate", new WebSocketFrameAggregator(maxFrameLength));
                pipeline.addBefore("game", "websocketText", new TextFrames());
                ctx.fireChannelRead(request.retain());
                pipeline.remove(this);
                return;
            }
            String message = "Xin game server is running. WebSocket endpoint: /ws\n"
                    + "Open the Flutter web application URL to play. This port does not host game assets.\n";
            FullHttpResponse response = new DefaultFullHttpResponse(HttpVersion.HTTP_1_1,
                    request.uri().equals("/") ? HttpResponseStatus.OK : HttpResponseStatus.NOT_FOUND,
                    Unpooled.copiedBuffer(message, StandardCharsets.UTF_8));
            response.headers().set(HttpHeaderNames.CONTENT_TYPE, "text/plain; charset=utf-8");
            response.headers().setInt(HttpHeaderNames.CONTENT_LENGTH, response.content().readableBytes());
            response.headers().set(HttpHeaderNames.CONNECTION, HttpHeaderValues.CLOSE);
            ctx.writeAndFlush(response).addListener(ChannelFutureListener.CLOSE);
        }
    }

    private static final class TextFrames extends MessageToMessageCodec<WebSocketFrame, String> {
        @Override
        protected void encode(ChannelHandlerContext ctx, String text, List<Object> out) {
            out.add(new TextWebSocketFrame(text));
        }

        @Override
        protected void decode(ChannelHandlerContext ctx, WebSocketFrame frame, List<Object> out) {
            if (frame instanceof TextWebSocketFrame text) {
                // Match TCP framing, including several JSON lines in one text frame.
                for (String line : text.text().split("\n")) {
                    if (!line.isBlank()) out.add(line.strip());
                }
            } else if (frame instanceof BinaryWebSocketFrame) {
                ctx.writeAndFlush(new CloseWebSocketFrame(1003, "Text JSON required"))
                        .addListener(ChannelFutureListener.CLOSE);
            }
        }
    }
}
