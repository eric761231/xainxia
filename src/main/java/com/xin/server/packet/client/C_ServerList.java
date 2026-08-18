package com.xin.server.packet.client;

import com.xin.server.network.Client;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.ServerOpcodes;
import com.xin.server.packet.server.S_ServerList;
import com.xin.server.OnlineUser;
import com.xin.server.config.ServerConfig;

/**請求伺服器列表（Gate / CONNECTED 狀態）**/
public class C_ServerList extends ClientBasePacket {

	public C_ServerList(String raw) {
		super(raw);
	}

	@Override
	public void run(Client client) {
		// 查列表不需登入，CONNECTED 即可
        if (!client.isConnected()) {
            return;
        }
        int online = OnlineUser.get().size();
        int max = ServerConfig.MAX_ONLINE_USERS;
        S_ServerList list_packet = new S_ServerList(ServerOpcodes.S_SERVER_LIST);
        //
        list_packet.builder().add("dev_local", online, max, S_ServerList.calcStatus(online, max, false));
        //
        list_packet.builder().add("dev_local_2", 85, max, S_ServerList.calcStatus(85, max, false));
        //
        list_packet.builder().add("dev_local_3", max, max, "full");
        //
        list_packet.builder().add("dev_local_4", 0, 0, "maintenance");
        //
        list_packet.builder().build();
        
        client.sendPacket(list_packet);
	}
}
