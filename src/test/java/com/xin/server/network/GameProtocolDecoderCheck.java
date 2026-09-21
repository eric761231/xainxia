package com.xin.server.network;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.channel.embedded.EmbeddedChannel;

/** Standalone transport regression check; no database or running game required. */
public final class GameProtocolDecoderCheck {
    private static void check(boolean value, String message) {
        if (!value) throw new AssertionError(message);
    }

    private static EmbeddedChannel channel(List<String> received) {
        EmbeddedChannel ch = new EmbeddedChannel(new GameProtocolDecoder(65536));
        ch.pipeline().addLast("game", new SimpleChannelInboundHandler<String>() {
            protected void channelRead0(ChannelHandlerContext ctx, String message) {
                received.add(message);
            }
        });
        return ch;
    }

    private static ByteBuf bytes(String value) {
        return Unpooled.copiedBuffer(value, StandardCharsets.UTF_8);
    }

    private static String output(EmbeddedChannel ch) {
        StringBuilder text = new StringBuilder();
        ByteBuf buf;
        while ((buf = ch.readOutbound()) != null) {
            text.append(buf.toString(StandardCharsets.UTF_8));
            buf.release();
        }
        return text.toString();
    }

    private static ByteBuf frame(int opcode, boolean fin, String text) {
        byte[] payload = text.getBytes(StandardCharsets.UTF_8);
        ByteBuf buf = Unpooled.buffer();
        buf.writeByte((fin ? 128 : 0) | opcode);
        if (payload.length < 126) buf.writeByte(128 | payload.length);
        else buf.writeByte(128 | 126).writeShort(payload.length);
        byte[] mask = {11, 22, 33, 44};
        buf.writeBytes(mask);
        for (int i = 0; i < payload.length; i++) buf.writeByte(payload[i] ^ mask[i % 4]);
        return buf;
    }

    public static void main(String[] args) {
        List<String> received = new ArrayList<>();
        EmbeddedChannel tcp = channel(received);
        byte[] packet = "{\"op\":\"中文\"}\n{\"op\":2}\n".getBytes(StandardCharsets.UTF_8);
        for (byte b : packet) tcp.writeInbound(Unpooled.wrappedBuffer(new byte[] {b}));
        check(received.equals(List.of("{\"op\":\"中文\"}", "{\"op\":2}")), "TCP split UTF-8 / coalesced packets");
        tcp.writeOutbound("{\"ok\":true}\n");
        check(output(tcp).equals("{\"ok\":true}\n"), "TCP response");
        tcp.finishAndReleaseAll();

        received.clear();
        EmbeddedChannel http = channel(received);
        http.writeInbound(bytes("G"));
        http.writeInbound(bytes("ET / HTTP/1.1\r\nHost: localhost\r\n\r\n"));
        String response = output(http);
        check(response.contains("200 OK") && response.contains("/ws"), "HTTP guidance");
        check(received.isEmpty(), "HTTP must not reach JSON dispatcher");
        http.finishAndReleaseAll();

        EmbeddedChannel ws = channel(received);
        ws.writeInbound(bytes("GET /ws HTTP/1.1\r\nHost: localhost:8080\r\n"
                + "Upgrade: websocket\r\nConnection: Upgrade\r\n"
                + "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"));
        check(output(ws).contains("101 Switching Protocols"), "WebSocket handshake");
        ws.writeInbound(frame(1, false, "{\"op\":"));
        ws.writeInbound(frame(0, true, "\"中文\"}\n{\"op\":2}\n"));
        check(received.equals(List.of("{\"op\":\"中文\"}", "{\"op\":2}")), "fragmented WebSocket JSON");
        ws.writeOutbound("{\"ok\":true}\n");
        ByteBuf reply = ws.readOutbound();
        check(reply.readUnsignedByte() == 129, "server sends text frame");
        int length = reply.readUnsignedByte();
        check(reply.readCharSequence(length, StandardCharsets.UTF_8).toString().equals("{\"ok\":true}\n"), "WebSocket reply content");
        reply.release();
        ws.writeInbound(frame(9, true, "ping"));
        ByteBuf pong = ws.readOutbound();
        check(pong.readUnsignedByte() == 138, "ping/pong");
        pong.release();
        ws.writeInbound(frame(2, true, "binary"));
        ByteBuf close = ws.readOutbound();
        check(close.readUnsignedByte() == 136, "binary rejected with close frame");
        close.release();
        ws.finishAndReleaseAll();
        System.out.println("PASS: TCP, UTF-8, HTTP, WebSocket handshake, fragmentation, replies, ping/pong, binary rejection");
    }
}
