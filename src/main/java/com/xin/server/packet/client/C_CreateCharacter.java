package com.xin.server.packet.client;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.IdFactory;
import com.xin.server.datatables.lock.CharacterR;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_CharacterAmount;
import com.xin.server.packet.server.S_CharacterList;
import com.xin.server.packet.server.S_CreateCharResult;
import com.xin.server.template.AttributeTemplate;
import com.xin.server.template.CharCreateStatTemplate;
import com.xin.server.template.RealmTemplate;
import com.xin.server.template.AccountTemp;

public class C_CreateCharacter extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_CreateCharacter.class);

    private final String _name;
    private final int _sex;
    private final int _attribute;
    private final int _statsIntel;
    private final int _statsSpirit;
    private final int _statsAgility;
    private final int _statsConstitution;

    public C_CreateCharacter(String raw) {
        super(raw);
        _name = getString("name", "").trim();
        _sex = getInt("sex", 0);
        _attribute = getInt("attribute", -1);
        _statsIntel = getInt("statsIntel", 0);
        _statsSpirit = getInt("statsSpirit", 0);
        _statsAgility = getInt("statsAgility", 0);
        _statsConstitution = getInt("statsConstitution", 0);
    }

    @Override
    public void run(Client client) {
        AccountTemp account = client.getAccount();
        if (account == null) {
            logger.warn("C_CREATE_CHAR 失敗：尚未登入");
            client.sendPacket(S_CreateCharResult.fail(
                    S_CreateCharResult.REASON_NOT_AUTHENTICATED, "尚未登入"));
            return;
        }

        if (!validateName(_name)) {
            logger.warn("C_CREATE_CHAR 失敗：名稱不合法 account={}", account.getAccountName());
            client.sendPacket(S_CreateCharResult.fail(
                    S_CreateCharResult.REASON_INVALID_NAME, "角色名稱需 2~12 字元，僅允許中英文、數字、底線"));
            return;
        }

        if (_sex != 0 && _sex != 1) {
            client.sendPacket(S_CreateCharResult.fail(
                    S_CreateCharResult.REASON_INVALID_SEX, "性別不合法"));
            return;
        }

        if (!AttributeTemplate.isValid(_attribute)) {
            client.sendPacket(S_CreateCharResult.fail(
                    S_CreateCharResult.REASON_INVALID_ATTRIBUTE, "靈根不合法"));
            return;
        }

        if (!CharCreateStatTemplate.validate(_statsIntel, _statsSpirit, _statsAgility, _statsConstitution)) {
            client.sendPacket(S_CreateCharResult.fail(
                    S_CreateCharResult.REASON_INVALID_STATS, "屬性配點無效，請重新分配 8 點"));
            return;
        }

        String accountName = account.getAccountName();
        int maxSlots = account.getCharSlot() > 0 ? account.getCharSlot() : 2;

        PcInstance character = new PcInstance();
        character.setId(IdFactory.get().nextId());
        character.setAccountName(accountName);
        character.setName(_name);
        character.setRealmLevel(1);
        character.setSex(_sex);
        character.setAttribute(_attribute);
        character.setStatsIntel(_statsIntel);
        character.setStatsSpirit(_statsSpirit);
        character.setStatsAgility(_statsAgility);
        character.setConstiution(_statsConstitution);
        character.setMapId(CharCreateStatTemplate.getDefaultMapId());
        character.setX(CharCreateStatTemplate.getDefaultX());
        character.setY(CharCreateStatTemplate.getDefaultY());

        character.recalculateCombatStats();
        character.setRealmStage(RealmTemplate.DEFAULT_STAGE);
        character.setExp(0);
        character.setFaction("");
        character.setLifeJob("");
        character.setLifeJobLevel(0);
        character.setCoreTechnique("");

        switch (CharacterR.get().tryCreateCharacter(accountName, character, maxSlots)) {
            case SLOT_FULL:
                logger.warn("C_CREATE_CHAR 失敗：槽位已滿 account={}", accountName);
                client.sendPacket(S_CreateCharResult.fail(
                        S_CreateCharResult.REASON_SLOT_FULL, "角色槽位已滿"));
                return;
            case NAME_EXISTS:
                logger.warn("C_CREATE_CHAR 失敗：名稱重複 name={}", _name);
                client.sendPacket(S_CreateCharResult.fail(
                        S_CreateCharResult.REASON_NAME_EXISTS, "角色名稱已被使用"));
                return;
            case DB_ERROR:
                logger.warn("C_CREATE_CHAR 失敗：寫入 DB account={} name={}", accountName, _name);
                client.sendPacket(S_CreateCharResult.fail(
                        S_CreateCharResult.REASON_DB_ERROR, "寫入資料庫失敗"));
                return;
            case SUCCESS:
                break;
            default:
                client.sendPacket(S_CreateCharResult.fail(
                        S_CreateCharResult.REASON_DB_ERROR, "寫入資料庫失敗"));
                return;
        }

        List<PcInstance> characters = CharacterR.get().loadByAccount(accountName);
        client.sendPacket(S_CreateCharResult.ok());
        client.sendPacket(new S_CharacterAmount(characters.size(), maxSlots));
        client.sendPacket(S_CharacterList.of(characters));
        logger.info("創角成功 account={} name={} attribute={}",
                accountName, _name, _attribute);
    }

    private boolean validateName(String name) {
        if (name.length() < 2 || name.length() > 12) {
            return false;
        }
        for (int i = 0; i < name.length(); i++) {
            char ch = name.charAt(i);
            if (java.lang.Character.isLetterOrDigit(ch) || ch == '_') {
                continue;
            }
            if (ch >= 0x4E00 && ch <= 0x9FFF) {
                continue;
            }
            return false;
        }
        return true;
    }
}
