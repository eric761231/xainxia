package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.PacketSender;
import com.xin.server.config.CharCreateConfig;
import com.xin.server.datatables.MapTable;
import com.xin.server.template.MapTemplate;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.inventory.InventoryManager;
import com.xin.server.packet.server.S_EnterGame;
import com.xin.server.packet.server.S_Inventory;
import com.xin.server.packet.server.S_MapInfo;
import com.xin.server.template.AccountTemp;
import com.xin.server.world.World;

public class C_SelectCharacter extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_SelectCharacter.class);

    private final String _name;

    public C_SelectCharacter(String raw) {
        super(raw);
        _name = getString("name", "").trim();
    }

    @Override
    public void run(Client client) {
        AccountTemp account = client.getAccount();
        if (account == null) {
            logger.warn("C_SELECT_CHAR 失敗：尚未登入");
            return;
        }

        if (_name.isEmpty()) {
            logger.warn("C_SELECT_CHAR 失敗：未指定角色");
            return;
        }

        PcInstance pc = CharacterR.get().loadCharacter(account.getAccountName(), _name);
        if (pc == null) {
            logger.warn("C_SELECT_CHAR 失敗：角色不存在 account={} name={}", account.getAccountName(), _name);
            return;
        }

        if (pc.getId() <= 0) {
            logger.warn("C_SELECT_CHAR 失敗：角色缺少 obj_id name={}", _name);
            return;
        }

        rescueIfOutOfBounds(pc);

        World.get().storeObject(pc);
        // 死著進遊戲的話什麼都不能做（攻擊被擋、被怪繼續打），等於角色報廢。
        // 復活流程（回城扣經驗、S_GAME_OVER 等）還沒定案，先用最單純的policy：
        // 進遊戲時若已倒下就回滿血。要改成別的規則只要動這一段。
        if (pc.getCurrentHp() <= 0) {
            pc.setCurrentHp(pc.getMaxHp());
            CharacterR.get().storeCharacter(pc);
            logger.info("角色 {} 上線時已倒下，回復滿血", pc.getName());
        }

        client.setActiveChar(pc);

        // 背包要在 S_ENTER_GAME 之後、地圖物件之前送：前端收到 enterGame 才會
        // 建立世界，太早送會沒有東西接。
        InventoryManager.loadInto(pc);
        client.sendPacket(new S_EnterGame(pc.getId(), pc.getName(), pc.getMapId(), pc.getX(), pc.getY()));
        client.sendPacket(S_Inventory.of(pc));
        // 推送當前地圖資訊（傳送點列表供前端小地圖顯示藍色光點）
        client.sendPacket(S_MapInfo.of(pc.getMapId()));
        // 進圖時把地圖上的物件一併推過去，客戶端才畫得出 NPC／怪物／場景物件
        PacketSender.sendMapObjects(client, pc.getMapId());
        // 圖上原本的人也要知道有人進來了
        PacketSender.broadcastPcPack(pc.getMapId());
        logger.info("玩家進入遊戲 account={} char={} objId={}",
                account.getAccountName(), _name, pc.getId());
    }

    /**
     * 進圖前把落在地圖外的角色拉回合法位置。
     * <p>
     * 沒有這道防呆，角色一旦位於邊界外就<b>永久卡死</b>：{@code C_Move} 會判定
     * 目標「超出地圖邊界」或與現在位置「步距過大」而全部拒絕，並把角色拉回
     * 那個非法座標，玩家再也走不出來。
     * <p>
     * 會發生的原因包括：地圖邊界被調小、創角設定變更、GM 手動改座標。
     */
    private static void rescueIfOutOfBounds(PcInstance pc) {
        MapTemplate map = MapTable.get().getMap(pc.getMapId());
        if (map == null) {
            logger.warn("角色所在地圖不存在，移回出生點: char={} mapId={}", pc.getName(), pc.getMapId());
            map = MapTable.get().getMap(CharCreateConfig.get().getDefaultMapId());
            if (map == null) {
                return;
            }
            pc.setMapId(map._mapId);
        }
        if (map.isValidCoord(pc.getX(), pc.getY())) {
            return;
        }
        int oldX = pc.getX();
        int oldY = pc.getY();
        pc.setX(clamp(oldX, map._minX, map._maxX));
        pc.setY(clamp(oldY, map._minY, map._maxY));
        CharacterR.get().storeCharacter(pc);
        logger.warn("角色座標超出地圖範圍，已拉回: char={} ({},{}) -> ({},{}) [map {} 範圍 {}..{}]",
                pc.getName(), oldX, oldY, pc.getX(), pc.getY(),
                map._mapId, map._minX, map._maxX);
    }

    private static int clamp(int v, int min, int max) {
        return v < min ? min : (v > max ? max : v);
    }
}
