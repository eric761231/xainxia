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
import com.xin.server.template.AccountTemp;

public class C_CharList extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_CharList.class);

    public C_CharList(String raw) {
        super(raw);
    }

    @Override
    public void run(Client client) {
        AccountTemp account = client.getAccount();
        if (account == null) {
            logger.warn("C_CHAR_LIST 失敗：尚未登入");
            return;
        }

        String accountName = account.getAccountName();
        List<PcInstance> characters = CharacterR.get().loadByAccount(accountName);
        int count = characters.size();
        int maxSlots = account.getCharSlot() > 0 ? account.getCharSlot() : 2;

        client.sendPacket(new S_CharacterAmount(count, maxSlots));
        client.sendPacket(S_CharacterList.of(characters));
        logger.info("角色列表 account={} count={}/{}", accountName, count, maxSlots);
    }
}
