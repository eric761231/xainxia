package com.xin.server.packet.server;

import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 氣泡對話（對應 opcode {@code S_BUBBLE_DIALOG}）。
 * <p>
 * 玩家互動到 {@code actionType=1}（對話）的場景物件時推送，前端於物件頭上顯示氣泡。
 * 對話文字不隨 {@link S_PropertyPack} 預載，一律由本封包單獨送出。
 *
 * <pre>
 * {
 *   "op": "S_BUBBLE_DIALOG",
 *   "data": { "objId": 2000000003, "name": "石碑", "text": "此地乃青雲門禁地" }
 * }
 * </pre>
 */
public class S_BubbleDialog extends ServerBasePacket {

    private S_BubbleDialog(long objId, String name, String text) {
        super(ServerOpcodes.S_BUBBLE_DIALOG);
        // 氣泡要顯示在哪個物件頭上
        put("objId", objId);
        // 對話者名稱（可空值，空字串代表只顯示對話內容而不顯示名稱）
        put("name", name != null ? name : "");
        // 對話內容
        put("text", text != null ? text : "");
    }

    /**
     * 建立氣泡對話封包。
     *
     * @param objId 氣泡所屬的物件編號
     * @param name  對話者名稱，可為 {@code null}（前端不顯示名稱）
     * @param text  對話內容
     */
    public static S_BubbleDialog of(long objId, String name, String text) {
        return new S_BubbleDialog(objId, name, text);
    }
}
