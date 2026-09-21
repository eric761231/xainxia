package com.xin.server.model;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.xin.server.model.instance.PcInstance;
import com.xin.server.network.Client;
import com.xin.server.network.ClientManager;
import com.xin.server.packet.server.S_Chat;
import com.xin.server.packet.server.S_Party;
import com.xin.server.packet.server.S_PartyInvite;

/**
 * 隊伍的建立、加入、退出。
 * <p>
 * 隊伍是<b>純執行期</b>的狀態，不進資料庫 —— 下線就離隊，重登要重新組。
 * 這是這類遊戲的通例，也省掉「隊伍存在但成員全下線」的孤兒資料。
 * <p>
 * 任何變動都會對<b>全隊</b>重送一次 {@link S_Party}。隊伍最多 5 人，
 * 整包重送遠比設計增量封包單純，也不會有「某個成員的畫面沒更新到」的狀況。
 */
public final class PartyManager {

    private static final Logger _log = LoggerFactory.getLogger(PartyManager.class);

    private static final AtomicLong _nextId = new AtomicLong(1);

    /** key = 角色 objId。一個角色同時只能在一支隊伍。 */
    private static final Map<Long, Party> _byMember = new ConcurrentHashMap<>();

    /** key = 被邀請者 objId，value = 邀請者 objId。單一待處理邀請，後來的覆蓋先前的。 */
    private static final Map<Long, Long> _pendingInvites = new ConcurrentHashMap<>();

    private PartyManager() {
    }

    public static Party partyOf(PcInstance pc) {
        return pc == null ? null : _byMember.get(pc.getId());
    }

    // ── 邀請 ────────────────────────────────────────────────────────────

    /** 送出邀請。回傳給邀請者看的錯誤訊息；成功回 {@code null}。 */
    public static String invite(PcInstance inviter, PcInstance target) {
        if (target == null) {
            return "找不到該玩家";
        }
        if (target.getId() == inviter.getId()) {
            return "不能邀請自己";
        }
        if (partyOf(target) != null) {
            return target.getName() + " 已經在隊伍中";
        }
        Party party = partyOf(inviter);
        if (party != null) {
            if (!party.isLeader(inviter)) {
                return "只有隊長可以邀請";
            }
            if (party.isFull()) {
                return "隊伍已滿（上限 " + Party.MAX_MEMBERS + " 人）";
            }
        }

        _pendingInvites.put(target.getId(), inviter.getId());
        Client tc = clientOf(target);
        if (tc == null) {
            _pendingInvites.remove(target.getId());
            return target.getName() + " 不在線上";
        }
        tc.sendPacket(S_PartyInvite.of(inviter.getId(), inviter.getName()));
        return null;
    }

    /** 接受邀請。回傳錯誤訊息；成功回 {@code null}。 */
    public static String accept(PcInstance pc) {
        Long inviterId = _pendingInvites.remove(pc.getId());
        if (inviterId == null) {
            return "沒有待處理的組隊邀請";
        }
        if (partyOf(pc) != null) {
            return "你已經在隊伍中";
        }
        PcInstance inviter = findOnlineById(inviterId);
        if (inviter == null) {
            return "邀請者已離線";
        }

        Party party = partyOf(inviter);
        if (party == null) {
            // 邀請者原本沒隊伍：這一刻才真正成立一支隊伍，邀請者當隊長
            party = new Party(_nextId.getAndIncrement(), inviter);
            _byMember.put(inviter.getId(), party);
        }
        if (party.isFull()) {
            return "隊伍已滿";
        }
        party.add(pc);
        _byMember.put(pc.getId(), party);
        _log.info("組隊 {} 加入 {} 的隊伍（{}人）",
                pc.getName(), party.getLeader().getName(), party.size());
        broadcast(party, pc.getName() + " 加入隊伍");
        return null;
    }

    public static void decline(PcInstance pc) {
        Long inviterId = _pendingInvites.remove(pc.getId());
        if (inviterId == null) {
            return;
        }
        PcInstance inviter = findOnlineById(inviterId);
        Client ic = clientOf(inviter);
        if (ic != null) {
            ic.sendPacket(S_Chat.system(pc.getName() + " 婉拒了組隊邀請"));
        }
    }

    // ── 離隊 ────────────────────────────────────────────────────────────

    /** 主動離隊，或下線時呼叫。 */
    public static void leave(PcInstance pc) {
        Party party = partyOf(pc);
        if (party == null) {
            return;
        }
        _byMember.remove(pc.getId());
        party.remove(pc);

        // 一個人的隊伍沒有意義，直接解散 —— 否則會留下一堆單人隊伍，
        // 而且那個人再被邀請時還要先處理「你已經在隊伍中」。
        if (party.size() <= 1) {
            for (PcInstance m : party.getMembers()) {
                _byMember.remove(m.getId());
                sendTo(m, S_Party.empty());
                sendTo(m, S_Chat.system("隊伍已解散"));
            }
            _log.info("隊伍解散（{} 離開後不足 2 人）", pc.getName());
        } else {
            broadcast(party, pc.getName() + " 離開了隊伍");
        }
        sendTo(pc, S_Party.empty());
    }

    /** 隊長踢人。回傳錯誤訊息；成功回 {@code null}。 */
    public static String kick(PcInstance leader, String targetName) {
        Party party = partyOf(leader);
        if (party == null) {
            return "你不在隊伍中";
        }
        if (!party.isLeader(leader)) {
            return "只有隊長可以驅逐隊員";
        }
        PcInstance target = party.findByName(targetName);
        if (target == null) {
            return "隊伍中沒有 " + targetName;
        }
        if (target.getId() == leader.getId()) {
            return "不能驅逐自己";
        }
        sendTo(target, S_Chat.system("你被移出了隊伍"));
        leave(target);
        return null;
    }

    /** 委任隊長。回傳錯誤訊息；成功回 {@code null}。 */
    public static String promote(PcInstance leader, String targetName) {
        Party party = partyOf(leader);
        if (party == null) {
            return "你不在隊伍中";
        }
        if (!party.isLeader(leader)) {
            return "只有隊長可以委任";
        }
        PcInstance target = party.findByName(targetName);
        if (target == null) {
            return "隊伍中沒有 " + targetName;
        }
        party.setLeader(target);
        broadcast(party, target.getName() + " 成為隊長");
        return null;
    }

    // ── 廣播 ────────────────────────────────────────────────────────────

    /** 對全隊重送隊伍狀態，並附一則系統訊息。 */
    public static void broadcast(Party party, String message) {
        for (PcInstance m : party.getMembers()) {
            sendTo(m, S_Party.of(party));
            if (message != null) {
                sendTo(m, S_Chat.system(message));
            }
        }
    }

    /** 只重送狀態（血量變化等，不需要訊息）。 */
    public static void refresh(PcInstance pc) {
        Party party = partyOf(pc);
        if (party != null) {
            broadcast(party, null);
        }
    }

    private static void sendTo(PcInstance pc, com.xin.server.packet.ServerBasePacket packet) {
        Client c = clientOf(pc);
        if (c != null) {
            c.sendPacket(packet);
        }
    }

    private static Client clientOf(PcInstance pc) {
        if (pc == null) {
            return null;
        }
        for (Client c : ClientManager.getAll()) {
            if (c.hasActiveChar() && c.getActiveChar().getId() == pc.getId()) {
                return c;
            }
        }
        return null;
    }

    private static PcInstance findOnlineById(long objId) {
        for (Client c : ClientManager.getAll()) {
            if (c.hasActiveChar() && c.getActiveChar().getId() == objId) {
                return c.getActiveChar();
            }
        }
        return null;
    }
}
