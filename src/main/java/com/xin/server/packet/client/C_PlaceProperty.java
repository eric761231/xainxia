package com.xin.server.packet.client;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.IdFactoryNpc;
import com.xin.server.datatables.CharacterDecorationTable;
import com.xin.server.datatables.MapTable;
import com.xin.server.datatables.PropertyTable;
import com.xin.server.model.instance.DecorationInstance;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_Chat;
import com.xin.server.packet.server.S_PropertyPack;
import com.xin.server.template.PropertyTemplate;
import com.xin.server.types.PlacementSurface;
import com.xin.server.world.WorldMapGrid;

/**
 * 放置家具（洞府布置）。
 * JSON: { "op": "C_PLACE_PROPERTY", "data": { "propertyId": 1200, "x": 40, "y": 41 } }
 * <p>
 * 家具屬於個別角色，只有擁有者看得到、也只擋得到擁有者，
 * 因此<b>不進</b>共用的 {@code WorldProperty}／{@code MapGrid}。
 */
public class C_PlaceProperty extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_PlaceProperty.class);

    /** 目前只有修練洞府開放布置。 */
    private static final int DECORATABLE_MAP = 0;

    private final int propertyId;
    private final int x;
    private final int y;

    public C_PlaceProperty(String raw) {
        super(raw);
        propertyId = getInt("propertyId", 0);
        x = getInt("x", 0);
        y = getInt("y", 0);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_PLACE_PROPERTY 失敗：尚未進入遊戲");
            return;
        }
        PcInstance pc = client.getActiveChar();

        String reason = validate(pc);
        if (reason != null) {
            logger.warn("放置家具遭拒（{}）：char={} property={} ({},{})",
                    reason, pc.getName(), propertyId, x, y);
            client.sendPacket(S_Chat.system(reason));
            return;
        }

        PropertyTemplate temp = PropertyTable.get().getTemplate(propertyId);
        DecorationInstance d = new DecorationInstance();
        d._objId      = IdFactoryNpc.get().nextId();
        d._owner      = pc.getName();
        d._propertyId = propertyId;
        d._mapId      = pc.getMapId();
        d._x          = x;
        d._y          = y;
        d._pngId      = temp._pngId;
        d._blocking   = temp._blocking;
        d._footprintW = Math.max(1, temp._footprintW);
        d._footprintH = Math.max(1, temp._footprintH);
        d._viewNote   = temp._viewNote;

        if (CharacterDecorationTable.get().insert(d) == null) {
            client.sendPacket(S_Chat.system("放置失敗（資料庫寫入錯誤）"));
            return;
        }
        pc.addDecoration(d);

        // 單筆推送＝新增一件；前端的 pack 是 upsert 語意
        client.sendPacket(S_PropertyPack.ofDecorations(pc.getMapId(), List.of(d)));
        logger.info("放置家具 char={} {} ({},{}) objId={}",
                pc.getName(), temp._viewNote, x, y, d._objId);
    }

    /** 驗證放置條件；合法回傳 {@code null}，否則回傳給玩家看的原因。 */
    private String validate(PcInstance pc) {
        if (pc.getMapId() != DECORATABLE_MAP) {
            return "只能在自己的洞府布置";
        }
        PropertyTemplate temp = PropertyTable.get().getTemplate(propertyId);
        if (temp == null) {
            return "物件不存在：" + propertyId;
        }
        if (!temp._placeable) {
            return "「" + temp._viewNote + "」不能自行放置";
        }
        if (pc.getDecorations().size() >= PcInstance.MAX_DECORATIONS) {
            return "布置件數已達上限（" + PcInstance.MAX_DECORATIONS + " 件）";
        }
        return validateCells(pc, temp, x, y, 0L);
    }

    /**
     * 逐格檢查以 {@code (x,y)} 為錨點的佔格是否可放置。
     * <p>
     * 放置（{@link C_PlaceProperty}）與搬動（{@link C_MoveProperty}）共用同一套規則 ——
     * 兩邊各寫一份的話遲早會分歧，變成「放得下卻搬不過去」這種難查的問題。
     *
     * @param ignoreObjId 檢查重疊時要排除的裝飾 objId；搬動時傳自己，放置時傳 {@code 0}
     * @return 合法回傳 {@code null}，否則回傳給玩家看的原因
     */
    static String validateCells(PcInstance pc, PropertyTemplate temp,
                                int x, int y, long ignoreObjId) {
        if (MapTable.get().getMap(pc.getMapId()) == null) {
            return "地圖不存在";
        }

        int w = Math.max(1, temp._footprintW);
        int h = Math.max(1, temp._footprintH);
        for (int j = 0; j < h; j++) {
            for (int i = 0; i < w; i++) {
                int tx = x - i;
                int ty = y - j;
                // 先驗邊界，否則越界會被 isWalkable 當成「不可走」，
                // 錯誤訊息變成「只能放在地面上」而非真正的原因
                if (!MapTable.get().isValidCoord(pc.getMapId(), tx, ty)
                        && !WorldMapGrid.get().get(pc.getMapId()).inBounds(tx, ty)) {
                    return "座標超出地圖範圍";
                }
                boolean walkable = WorldMapGrid.get().isWalkable(pc.getMapId(), tx, ty);

                // 放置面規則：地板家具要可走格、壁掛物要不可走格
                if (!PlacementSurface.accepts(temp._placement, walkable)) {
                    return "「" + temp._viewNote + "」只能放在"
                            + PlacementSurface.describe(temp._placement) + "上";
                }
                // 不可與自己既有的家具重疊（搬動時不算自己）
                if (pc.isOccupiedByOwnDecoration(tx, ty, ignoreObjId)) {
                    return "該位置已經有東西了";
                }
                // 不可壓在角色自己身上，否則會把自己困住
                if (temp._blocking && tx == pc.getX() && ty == pc.getY()) {
                    return "不能放在自己站的位置";
                }
            }
        }
        return null;
    }
}
