package com.xin.server.gm;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;

/**
 * GM 指令的解析與分發。
 * <p>
 * 所有指令共用 {@code C_GM_COMMAND} 一個封包，新增指令只需實作 {@link GmCommand}
 * 並在 {@link #register()} 掛上，不必動封包或前端。
 * <p>
 * 權限：帳號的 {@code access_level} 需 ≥ {@link #REQUIRED_ACCESS_LEVEL}。
 */
public class GmCommandHandler {

    private static final Logger _log = LoggerFactory.getLogger(GmCommandHandler.class);

    /** 執行 GM 指令所需的最低權限等級。 */
    public static final int REQUIRED_ACCESS_LEVEL = 100;

    /** 指令前綴，前端送出前已剝除，此處僅供說明訊息使用。 */
    public static final String PREFIX = ".";

    private static GmCommandHandler _instance;

    /** key = 指令名稱（小寫） */
    private final Map<String, GmCommand> _commands = new LinkedHashMap<>();

    public static GmCommandHandler get() {
        if (_instance == null) {
            _instance = new GmCommandHandler();
        }
        return _instance;
    }

    private GmCommandHandler() {
        register();
        _log.info("載入GM指令系統: " + _commands.size() + "個指令 " + _commands.keySet());
    }

    /** 註冊指令；新增 GM 指令就加在這裡。 */
    private void register() {
        add(new GmTeleport());
        add(new GmMaps());
        add(new GmCollision());
        add(new GmAi());
    }

    private void add(GmCommand cmd) {
        _commands.put(cmd.name().toLowerCase(), cmd);
    }

    /**
     * 解析並執行一行指令。
     *
     * @param raw 不含前綴的指令原文，例如 {@code "tp 1 40 40"}
     * @return 要回饋給玩家的訊息
     */
    public String execute(Client client, PcInstance pc, String raw) {
        if (raw == null || raw.isBlank()) {
            return "指令是空的";
        }
        String[] parts = raw.trim().split("\s+");
        String name = parts[0].toLowerCase();
        String[] args = Arrays.copyOfRange(parts, 1, parts.length);

        if ("help".equals(name)) {
            return helpText();
        }

        GmCommand cmd = _commands.get(name);
        if (cmd == null) {
            return "未知指令：" + name + "（用 " + PREFIX + "help 看可用指令）";
        }

        try {
            String result = cmd.execute(client, pc, args);
            _log.info("GM指令 char={} cmd={} args={} -> {}",
                    pc.getName(), name, Arrays.toString(args), result);
            return result;
        } catch (RuntimeException e) {
            _log.error("GM指令執行失敗 char=" + pc.getName() + " cmd=" + raw, e);
            return "指令執行失敗：" + e.getMessage();
        }
    }

    /** 可用指令一覽。 */
    public String helpText() {
        List<String> lines = new ArrayList<>();
        lines.add("可用 GM 指令：");
        for (GmCommand c : _commands.values()) {
            lines.add("  " + PREFIX + c.usage() + " － " + c.description());
        }
        lines.add("  " + PREFIX + "help － 顯示本說明");
        return String.join("\n", lines);
    }
}
