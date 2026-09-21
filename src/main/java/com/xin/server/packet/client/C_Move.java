package com.xin.server.packet.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.datatables.MapTable;
import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.PacketSender;
import com.xin.server.packet.ClientBasePacket;
import com.xin.server.packet.server.S_CharMove;
import com.xin.server.world.WorldMapGrid;

/**
 * 人物移動。
 * JSON: { "op": "C_MOVE", "data": { "x": 1, "y": 2, "heading": 2 } }
 * <p>
 * 伺服器為權威：座標需通過地圖邊界、碰撞格與步距三項驗證才會採用。
 * 任一項不過就<b>不更新座標、也不回任何封包</b>（靜默拒絕）。
 * <p>
 * 前端有自己的碰撞判定，不可通行的移動不會被送出；因此會被拒絕的請求
 * 只可能來自異常或作弊的客戶端，沒有必要為它們回送修正而讓正常玩家承受
 * 延遲時的位置彈跳。
 */
public class C_Move extends ClientBasePacket {

    private static final Logger logger = LoggerFactory.getLogger(C_Move.class);

    /** 單次移動允許的最大格距（Chebyshev）；超過視為瞬移。 */
    private static final int MAX_STEP = 1;

    private final int x;
    private final int y;
    private final int heading;

    public C_Move(String raw) {
        super(raw);
        x = getInt("x", 0);
        y = getInt("y", 0);
        heading = getInt("heading", 0);
    }

    @Override
    public void run(Client client) {
        if (!client.hasActiveChar()) {
            logger.warn("C_MOVE 失敗：尚未進入遊戲");
            return;
        }

        PcInstance pc = client.getActiveChar();
        String reason = validate(pc);
        if (reason != null) {
            // 靜默拒絕：不更新座標、不回任何封包。
            //
            // 客戶端本身已有碰撞判定，不可通行的移動根本不會送出；會走到這裡
            // 就代表是異常或作弊的客戶端。此時回送修正封包只會讓正常玩家在
            // 網路延遲時被拉來拉去，對作弊者又毫無作用（它本來就不理會伺服器）。
            // 伺服器「不更新座標」本身就完成了權威判定。
            logger.warn("C_MOVE 拒絕（{}）：{} 由 ({},{}) 移往 ({},{})",
                    reason, pc.getName(), pc.getX(), pc.getY(), x, y);
            return;
        }

        pc.setX(x);
        pc.setY(y);
        pc.setHeading(heading);
        // 不每一步都寫 DB（每 400ms 一次）：標記後由 CharacterSaveTask 定期寫回，
        // 登出、斷線、關服時會立即寫回，正常離線不會丟座標。
        pc.markDirty();

        PacketSender.broadcastToVisible(client,
                new S_CharMove(pc.getName(), x, y, heading));
    }

    /** 驗證目標座標；合法回傳 {@code null}，否則回傳拒絕原因（供 log）。 */
    private String validate(PcInstance pc) {
        if (MapTable.get().getMap(pc.getMapId()) == null) {
            return "地圖不存在";
        }
        if (!MapTable.get().isValidCoord(pc.getMapId(), x, y)) {
            return "超出地圖邊界";
        }
        if (!WorldMapGrid.get().isWalkable(pc.getMapId(), x, y)) {
            return "目標格被阻擋";
        }
        // 玩家自己擺的家具只擋得到自己 —— 不在共用碰撞格裡，需另外問
        if (pc.isBlockedByOwnDecoration(x, y)) {
            return "目標格被自己的家具擋住";
        }
        int step = Math.max(Math.abs(x - pc.getX()), Math.abs(y - pc.getY()));
        if (step > MAX_STEP) {
            return "步距過大 " + step;
        }
        return null;
    }
}
