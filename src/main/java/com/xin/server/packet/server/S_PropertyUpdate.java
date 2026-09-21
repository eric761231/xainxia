package com.xin.server.packet.server;

import com.xin.server.model.instance.PropertyInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.packet.ServerOpcodes;

/**
 * 場景物件狀態變化（對應 opcode {@code S_PROPERTY_UPDATE}）。
 * <p>
 * 場景物件被互動後推送，例如藥草被採了一次、礦石被挖了一段進度。
 * 只帶會變動的欄位：{@code value}（進度條之類的數值）與 {@code action}
 * （是否還能互動；採空後設為 {@code false}）。
 * 圖片、名稱等靜態設定不重送，前端沿用 {@code S_PROPERTY_PACK} 收到的資料。
 * <p>
 * 物件若是直接消失（藥草被採光、礦石挖盡），改送 {@link S_ObjectRemove}。
 *
 * <pre>
 * {
 *   "op": "S_PROPERTY_UPDATE",
 *   "data": { "objId": 2000000003, "value": 2, "action": true }
 * }
 * </pre>
 */
public class S_PropertyUpdate extends ServerBasePacket {

    private S_PropertyUpdate(long objId, int value, boolean action) {
        super(ServerOpcodes.S_PROPERTY_UPDATE);
        put("objId", objId);
        put("value", value);
        put("action", action);
    }

    /**
     * 建立場景物件狀態變化封包。
     *
     * @param objId  場景物件編號
     * @param value  變化後的數值（進度條之類的）
     * @param action 變化後是否仍可互動
     */
    public static S_PropertyUpdate of(long objId, int value, boolean action) {
        return new S_PropertyUpdate(objId, value, action);
    }

    /** 依實例當前狀態建立封包。 */
    public static S_PropertyUpdate of(PropertyInstance property) {
        return new S_PropertyUpdate(property.getId(), property.getValue(), property.isAction());
    }
}
