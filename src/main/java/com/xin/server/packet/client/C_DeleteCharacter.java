package com.xin.server.packet.client;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_CharacterAmount;
import com.xin.server.packet.server.S_CharacterList;
import com.xin.server.packet.server.S_DeleteCharResult;
import com.xin.server.template.AccountTemp;

public class C_DeleteCharacter extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_DeleteCharacter.class);

    private final String _name;

    public C_DeleteCharacter(String raw) {
        super(raw);
        _name = getString("name", "").trim();
    }

    @Override
    public void run(Client client) {
        AccountTemp account = client.getAccount();
        if (account == null) {
            logger.warn("C_DELETE_CHAR 失敗：尚未登入");
            return;
        }

        if (_name.isEmpty()) {
            logger.warn("C_DELETE_CHAR 失敗：未指定角色");
            client.sendPacket(S_DeleteCharResult.fail(
                    S_DeleteCharResult.REASON_NOT_FOUND, "未指定角色名稱"));
            return;
        }

        String accountName = account.getAccountName();
        boolean deleted = CharacterR.get().deleteCharacter(accountName, _name);
        if (!deleted) {
            logger.warn("C_DELETE_CHAR 失敗：角色不存在或非本帳號 account={} name={}", accountName, _name);
            client.sendPacket(S_DeleteCharResult.fail(
                    S_DeleteCharResult.REASON_NOT_FOUND, "角色不存在或無法刪除"));
            return;
        }

        int maxSlots = account.getCharSlot() > 0 ? account.getCharSlot() : 2;
        List<PcInstance> characters = CharacterR.get().loadByAccount(accountName);
        client.sendPacket(S_DeleteCharResult.ok());
        client.sendPacket(new S_CharacterAmount(characters.size(), maxSlots));
        client.sendPacket(S_CharacterList.of(characters));
        logger.info("刪角成功 account={} name={}", accountName, _name);
    }
}
