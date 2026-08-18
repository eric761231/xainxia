package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_EnterGame;
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

        World.get().storeObject(pc);
        client.setActiveChar(pc);
        client.sendPacket(new S_EnterGame(pc.getId(), pc.getName(), pc.getMapId(), pc.getX(), pc.getY()));
        // 推送當前地圖資訊（傳送點列表供前端小地圖顯示藍色光點）
        client.sendPacket(S_MapInfo.of(pc.getMapId()));
        logger.info("玩家進入遊戲 account={} char={} objId={}",
                account.getAccountName(), _name, pc.getId());
    }
}
