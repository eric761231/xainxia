package com.xin.server.types;

/**
 * 聊天頻道。
 * <p>
 * 封包一律傳 int（見 {@code C_CHAT}／{@code S_CHAT} 的 {@code channel} 欄位）。
 *
 * <table border="1">
 *   <tr><th>值</th><th>常數</th><th>說明</th></tr>
 *   <tr><td>0</td><td>{@link #GENERAL}</td>
 *       <td>綜合 —— 僅供前端「全部顯示」的檢視用，<b>不可作為發送頻道</b></td></tr>
 *   <tr><td>1</td><td>{@link #WORLD}</td>  <td>世界（全服廣播）</td></tr>
 *   <tr><td>2</td><td>{@link #PARTY}</td>  <td>隊伍（尚無組隊系統）</td></tr>
 *   <tr><td>3</td><td>{@link #GUILD}</td>  <td>門派（尚無門派系統）</td></tr>
 *   <tr><td>4</td><td>{@link #WHISPER}</td><td>私聊（需指定 target）</td></tr>
 *   <tr><td>5</td><td>{@link #SYSTEM}</td> <td>系統（僅伺服器產生）</td></tr>
 * </table>
 */
public final class ChatChannel {

    /** 綜合：前端檢視用的「全部」，不可發送 */
    public static final int GENERAL = 0;
    /** 世界：全服廣播 */
    public static final int WORLD   = 1;
    /** 隊伍 */
    public static final int PARTY   = 2;
    /** 門派 */
    public static final int GUILD   = 3;
    /** 私聊：需指定接收者名稱 */
    public static final int WHISPER = 4;
    /** 系統：僅由伺服器產生，客戶端不可發送 */
    public static final int SYSTEM  = 5;

    private ChatChannel() {
    }

    /** 客戶端是否允許以此頻道發言。 */
    public static boolean isSendable(int channel) {
        return channel == WORLD || channel == PARTY
                || channel == GUILD || channel == WHISPER;
    }

    /** 頻道顯示名稱（供訊息與 log）。 */
    public static String nameOf(int channel) {
        switch (channel) {
            case GENERAL: return "綜合";
            case WORLD:   return "世界";
            case PARTY:   return "隊伍";
            case GUILD:   return "門派";
            case WHISPER: return "私聊";
            case SYSTEM:  return "系統";
            default:      return "未知";
        }
    }
}
