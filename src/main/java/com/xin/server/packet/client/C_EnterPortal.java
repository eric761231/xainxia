package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.xin.server.datatables.MapTable;
import com.xin.server.datatables.MapPortalTable;
import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_MapChange;
import com.xin.server.packet.server.S_MapInfo;
import com.xin.server.template.PortalTemplate;

/**
 * 進入傳送點（換圖）請求。
 * <p>
 * 客戶端 JSON 格式：
 * <pre>
 * { "op": "C_ENTER_PORTAL", "data": { "portalId": 1 } }
 * </pre>
 *
 * 處理流程：
 * <ol>
 *   <li>查詢 {@link MapPortalTable} 確認傳送點存在。</li>
 *   <li>確認傳送點在角色當前地圖上。</li>
 *   <li>確認角色在傳送點的觸發範圍（Chebyshev 距離 &lt;= trigger_range）內。</li>
 *   <li>更新角色地圖與座標，儲存至 DB。</li>
 *   <li>發送 {@link S_MapChange}（新座標）+ {@link S_MapInfo}（新地圖傳送點列表）。</li>
 * </ol>
 */
public class C_EnterPortal extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_EnterPortal.class);

    private final int _portalId;
    /** 玩家踏上傳送點時的當下面向；當傳送點未指定 dest_heading 時沿用此值。 */
    private final int _facing;

    public C_EnterPortal(String raw) {
        super(raw);
        _portalId = getInt("portalId", -1);
        _facing = getInt("facing", 2);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_ENTER_PORTAL 失敗：尚未進入遊戲");
            return;
        }

        PcInstance pc = client.getActiveChar();

        // 查詢傳送點資料
        PortalTemplate portal = MapPortalTable.get().getPortal(_portalId);
        if (portal == null) {
            logger.warn("C_ENTER_PORTAL 失敗：傳送點不存在 portalId={} char={}", _portalId, pc.getName());
            return;
        }

        // 傳送點必須在角色當前地圖上
        if (portal._mapId != pc.getMapId()) {
            logger.warn("C_ENTER_PORTAL 失敗：傳送點不在當前地圖 portalMapId={} charMapId={} char={}",
                    portal._mapId, pc.getMapId(), pc.getName());
            return;
        }

        // 距離驗證：角色必須在觸發範圍內
        if (!portal.isInRange(pc.getX(), pc.getY())) {
            logger.warn("C_ENTER_PORTAL 失敗：距離傳送點太遠 portalId={} portalPos=({},{}) charPos=({},{}) range={} char={}",
                    _portalId, portal._locX, portal._locY, pc.getX(), pc.getY(), portal._triggerRange, pc.getName());
            return;
        }

        // 目標地圖邊界驗證
        if (!MapTable.get().isValidCoord(portal._destMapId, portal._destX, portal._destY)) {
            logger.error("C_ENTER_PORTAL 失敗：目標座標超出地圖邊界 portalId={} dest=({},{},{}) char={}",
                    _portalId, portal._destMapId, portal._destX, portal._destY, pc.getName());
            return;
        }

        // 到達面向：傳送點有指定 dest_heading(>=0) 就用它，否則沿用玩家踏上時的當下面向
        int arrivalFacing = portal._destHeading >= 0 ? portal._destHeading : _facing;

        // 更新角色位置與面向
        int prevMap = pc.getMapId();
        pc.setMapId(portal._destMapId);
        pc.setX(portal._destX);
        pc.setY(portal._destY);
        pc.setHeading(arrivalFacing);
        CharacterR.get().storeCharacter(pc);

        logger.info("傳送成功 char={} {}->{}({},{}) heading={} via portal={}",
                pc.getName(), prevMap, portal._destMapId, portal._destX, portal._destY, arrivalFacing, _portalId);

        // 通知前端切換地圖，並推送新地圖的傳送點列表（小地圖藍色光點）
        client.sendPacket(S_MapChange.of(portal._destMapId, portal._destX, portal._destY, arrivalFacing));
        client.sendPacket(S_MapInfo.of(portal._destMapId));
    }
}
