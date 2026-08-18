package com.xin.server.datatables.storage;

import java.util.List;
import com.xin.server.model.instance.PcInstance;

/** characters 表持久化（DB 存取 + 名稱索引）。 */
public interface CharacterS {

    void load();

    List<PcInstance> loadByAccount(String accountName);

    PcInstance loadCharacter(String accountName, String charName);

    PcInstance findByName(String accountName, String charName);

    boolean isCharNameTaken(String charName);

    boolean insertCharacter(PcInstance pc);

    void storeCharacter(PcInstance pc);

    int countByAccount(String accountName);

    boolean deleteCharacter(String accountName, String charName);
}
