package com.xin.server.packet.server;

import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * NPC 對話視窗（對應 opcode {@code S_DIALOG}）。
 * <p>
 * 回應 {@code C_INTERACT}，前端開啟對話視窗。{@code options} 為可選的回覆分支，
 * 空清單代表單純顯示一句話。
 * <p>
 * 與 {@link S_BubbleDialog} 的分工：本封包是**有選項的對話視窗**（NPC／商店），
 * 氣泡對話則是物件頭上的一句話（場景物件），兩者 UI 不同。
 * 對話對象一律以 {@code objId} 識別（不用模板編號，否則同張圖的同名 NPC 會撞在一起）。
 *
 * <pre>
 * {
 *   "op": "S_DIALOG",
 *   "data": {
 *     "objId": 2000000002, "name": "藥童", "text": "客倌要買點什麼？",
 *     "options": [ { "id": 1, "text": "我要買藥" }, { "id": 2, "text": "沒事" } ]
 *   }
 * }
 * </pre>
 */
public class S_Dialog extends ServerBasePacket {

    private S_Dialog(long objId, String name, String text, List<Map.Entry<Integer, String>> options) {
        super(ServerOpcodes.S_DIALOG);
        put("objId", objId);
        put("name",  name != null ? name : "");
        put("text",  text != null ? text : "");

        ArrayNode arr = newArray();
        if (options != null) {
            for (Map.Entry<Integer, String> option : options) {
                ObjectNode node = newObject();
                node.put("id",   option.getKey());
                node.put("text", option.getValue());
                arr.add(node);
            }
        }
        putArray("options", arr);
    }

    /**
     * 建立含回覆分支的對話封包。
     *
     * @param objId   對話對象的物件編號
     * @param name    對話對象顯示名稱
     * @param text    對話內容
     * @param options 回覆分支（key=選項編號、value=選項文字）；可為 {@code null} 或空
     */
    public static S_Dialog of(long objId, String name, String text,
                              List<Map.Entry<Integer, String>> options) {
        return new S_Dialog(objId, name, text, options);
    }

    /** 建立無回覆分支的對話封包（只顯示一句話）。 */
    public static S_Dialog of(long objId, String name, String text) {
        return new S_Dialog(objId, name, text, null);
    }
}
