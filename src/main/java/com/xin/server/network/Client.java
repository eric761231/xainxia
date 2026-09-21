package com.xin.server.network;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.OnlineUser;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.packet.ServerBasePacket;
import com.xin.server.template.AccountTemp;
import com.xin.server.world.World;

import io.netty.channel.*;

/**
 * 客戶端連線處理
 */
public class Client {

	private static final Logger logger = LoggerFactory.getLogger(Client.class);
	
    public enum LoginState {
        CONNECTED,     // 剛建立 TCP 連線，尚未通過帳密驗證。允許：{@code C_AUTH_LOGIN}
        AUTHENTICATED, // 帳密驗證成功，已綁定 {@link accountTemp}。允許：選角相關 C 封包
        IN_GAME        // 已選角進入遊戲，已綁定 {@link PcInstance}。允許：遊戲內 C 封包
    }
    /** Netty 連線通道，與客戶端一對一，生命週期同 TCP 連線 */
    private final Channel channel;
    /** 目前登入狀態，隨 setAccount / setActiveChar / onDisconnect 自動推進或重置 */
    private LoginState state;
    /**
     * 已登入帳號的記憶體實例（對應天堂 {@code L1Account}）。
     * <p>
     * {@code C_AuthLogin} 成功並經 {@link com.xin.server.OnlineUser} 註冊後設定；
     * 斷線時在 {@link #onDisconnect()} 清除。
     */
    private AccountTemp account;
    /**
     * 目前操控中的角色實例（對應天堂 {@code L1PcInstance} / {@code _activeChar}）。
     * <p>
     * {@code C_SelectChar} 成功後設定；斷線時清除，之後可在此觸發存檔。
     */
    private PcInstance activeChar;
    /**
     * 建立新連線會話。
     *
     * @param channel Netty 通道，由 {@link GameServerHandler#channelActive} 傳入
     */
    public Client(Channel channel) {
        this.channel = channel;
        this.state = LoginState.CONNECTED;
    }
    /**
     * 直接將 S 封包寫入 Netty 通道（序列化為 JSON 字串）。
     * <p>
     * 一般業務邏輯建議透過 {@link PacketSender#send(Client, ServerBasePacket)} 發送，
     * 以便統一記錄 log；此方法保留給低階或內部使用。
     *
     * @param packet 伺服器封包，{@link ServerBasePacket#toJson()} 輸出格式：
     *               {@code {"op":"S_XXX","data":{...}}\n}
     */
    public void sendPacket(ServerBasePacket packet) {
    	if (!channel.isActive()) {
        	logger.warn("客戶端已斷線，封包：{}", packet.getOpcode());
            return;
        }
        logger.debug("S包 → [{}] {}",  channel.remoteAddress(), packet.getOpcode());
        channel.writeAndFlush(packet.toJson());
    }

    /**
     * 是否為「剛連線、尚未登入」狀態。
     * <p>
     * 僅在此狀態下應接受 {@code C_AUTH_LOGIN}。
     */
    public boolean isConnected() {
        return state == LoginState.CONNECTED;
    }
    
    /**
     * 是否已完成帳密驗證（含已進入遊戲）。
     * <p>
     * 選角、建角等封包應在此為 {@code true} 時才處理。
     */
    public boolean isAuthenticated() {
        return state == LoginState.AUTHENTICATED || state == LoginState.IN_GAME;
    }
    /**
     * 是否已選角並進入遊戲世界。
     * <p>
     * 移動、攻擊等遊戲內封包應在此為 {@code true} 時才處理。
     */
    public boolean isInGame() {
        return state == LoginState.IN_GAME;
    }
    /**
     * 連線關閉時的清理（由 {@link ClientManager#remove} 呼叫）。
     * <p>
     * 清理項目：
     * <ul>
     *   <li>從 {@link OnlineUser} 移除帳號（避免幽靈在線）</li>
     *   <li>清除 {@code account}、{@code activeChar} 引用</li>
     *   <li>重置狀態為 {@link LoginState#CONNECTED}</li>
     * </ul>
     * 若 {@code activeChar != null}，在此呼叫角色存檔
     */
    public void onDisconnect() {
        clearSession();
    }

    /**
     * 清除帳號／角色綁定，狀態回到 CONNECTED（不關 TCP）。
     */
    public void clearSession() {
        int leftMapId = -1;
        if (activeChar != null) {
            // 登出、斷線、重複登入被踢都會走到這裡：先把還沒寫回的座標與血量存下來。
            // 移動與挨打只標記變動、由定期存檔寫回，少了這一步就會丟掉最後幾十秒。
            com.xin.server.model.CharacterSaveTask.flush(activeChar);
            leftMapId = activeChar.getMapId();
            // 先離隊再移出世界：隊伍是純執行期狀態，不處理的話隊友的
            // 隊伍欄會一直留著一個已經下線的人，而且踢也踢不掉。
            com.xin.server.model.PartyManager.leave(activeChar);
            World.get().removeObject(activeChar);
        }
        account = null;
        activeChar = null;
        state = LoginState.CONNECTED;

        // 清完才重送名單 —— 這時 activeChar 已是 null，重算出來的名單
        // 自然就不含這個人。順序反過來的話他還會留在名單裡。
        if (leftMapId >= 0) {
            PacketSender.broadcastPcPack(leftMapId);
        }
    }
    /**
     * 主動關閉連線（踢人、驗證失敗等）。
     * 關閉後 Netty 會觸發 {@code channelInactive} → {@link #onDisconnect()}。
     */
    public void disconnect() {
        channel.close();
    }
    /**
     * 取得客戶端 IP（不含 port）。
     * <p>
     * 從 {@code channel.remoteAddress()} 解析，例如
     * {@code /192.168.1.100:54321} → {@code 192.168.1.100}。
     * 供登入紀錄、帳號 IP 更新使用；不應信任客戶端封包內自報的 IP。
     */
    public String getIp() {
        if (channel.remoteAddress() == null) {
            return "";
        }
        String address = channel.remoteAddress().toString();
        int index = address.indexOf('/');
        if (index >= 0 && index + 1 < address.length()) {
            int colon = address.indexOf(':', index + 1);
            return colon > index ? address.substring(index + 1, colon) : address.substring(index + 1);
        }
        return address;
    }

    public String getHost() {
        return getIp();
    }
    /** @return Netty 連線通道 */
    public Channel getChannel() {
        return channel;
    }
    /** @return 目前登入狀態 */
    public LoginState getState() {
        return state;
    }
    /**
     * 手動設定登入狀態。
     * <p>
     * 一般應透過 {@link #setAccount} / {@link #setActiveChar} 自動推進，
     * 僅在特殊流程（如登出回選角畫面）才需直接設定。
     */
    public void setState(LoginState state) {
        this.state = state;
    }
    /**
     * @return 已登入帳號實例；未登入時為 {@code null}
     */
    public AccountTemp getAccount() {
        return account;
    }
    /**
     * 綁定登入成功的帳號，並將狀態設為 {@link LoginState#AUTHENTICATED}。
     * <p>
     * 通常由 {@link com.xin.server.OnlineUser#addClient} 呼叫，
     * 對應天堂 {@code client.setAccount(L1Account)}。
     *
     * @param account 從 DB 載入或新建的帳號資料
     */
    public void setAccount(AccountTemp account) {
        this.account = account;
        this.state = LoginState.AUTHENTICATED;
    }
    /**
     * @return 目前操控角色；未選角時為 {@code null}
     */
    public PcInstance getActiveChar() {
        return activeChar;
    }
    /**
     * 綁定選角後的角色，並將狀態設為 {@link LoginState#IN_GAME}。
     * <p>
     * 對應天堂 {@code client.setActiveChar(L1PcInstance)}。
     *
     * @param pc 進入遊戲世界的角色實例
     */
    public void setActiveChar(PcInstance pc) {
        this.activeChar = pc;
        this.state = LoginState.IN_GAME;
    }
    
    /** @return 帳號名稱；未登入時回傳 {@code null} 或空字串 */
    public String getAccountName() {
        return account != null ? account.getAccountName() : null;
    }
    /** 是否已登入帳號（{@code account != null} 的語意化捷徑） */
    public boolean hasAccount() {
        return account != null;
    }
    /** 是否已在遊戲中操控角色（{@code activeChar != null} 的語意化捷徑） */
    public boolean hasActiveChar() {
        return activeChar != null;
    }
    
    /**
     * 除錯用字串，包含遠端位址、狀態、帳號名稱。
     * 不含密碼等敏感資訊。
     */
    @Override
    public String toString() {
        return "Client["
            + channel.remoteAddress()
            + ", state=" + state
            + ", account=" + (account != null ? account.getAccountName() : "null")
            + "]";
    }
    
    /**
     * <h3>C 封包如何使用 Client</h3>
     * <table>
     *   <tr><th>C 封包</th><th>所需狀態</th><th>讀寫 Client 的方式</th></tr>
     *   <tr>
     *     <td>C_AuthLogin</td>
     *     <td>CONNECTED</td>
     *     <td>讀 {@link #getIp()} → 驗證 DB → {@link #setAccount} → 發 S_LoginResult</td>
     *   </tr>
     *   <tr>
     *     <td>C_CharList / C_CreateChar</td>
     *     <td>AUTHENTICATED</td>
     *     <td>讀 {@link #getAccount()} 取得帳號 → 操作角色 DB</td>
     *   </tr>
     *   <tr>
     *     <td>C_SelectChar</td>
     *     <td>AUTHENTICATED</td>
     *     <td>載入角色 → {@link #setActiveChar} → 發 S_EnterGame</td>
     *   </tr>
     *   <tr>
     *     <td>遊戲內封包</td>
     *     <td>IN_GAME</td>
     *     <td>讀 {@link #getActiveChar()} 取得當前角色</td>
     *   </tr>
     * </table>
     */
}
