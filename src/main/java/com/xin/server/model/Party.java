package com.xin.server.model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

import com.xin.server.model.instance.PcInstance;

/**
 * 一支隊伍。
 * <p>
 * 成員存 {@link PcInstance} 參考而不是名字 —— 名字要再查一次 World，
 * 而且角色下線後名字還在、參考卻能立刻發現對象已經不在了。
 * <p>
 * 用 {@link CopyOnWriteArrayList}：讀（廣播、算人數）遠多於寫（加入退出），
 * 而且廣播時常常要一邊迭代一邊移除離線的成員。
 */
public class Party {

    /** 隊伍人數上限。 */
    public static final int MAX_MEMBERS = 5;

    private final long _id;
    private final List<PcInstance> _members = new CopyOnWriteArrayList<>();
    private volatile PcInstance _leader;

    public Party(long id, PcInstance leader) {
        _id = id;
        _leader = leader;
        _members.add(leader);
    }

    public long getId() {
        return _id;
    }

    public PcInstance getLeader() {
        return _leader;
    }

    public List<PcInstance> getMembers() {
        return Collections.unmodifiableList(new ArrayList<>(_members));
    }

    public int size() {
        return _members.size();
    }

    public boolean isFull() {
        return _members.size() >= MAX_MEMBERS;
    }

    public boolean isLeader(PcInstance pc) {
        return _leader != null && pc != null && _leader.getId() == pc.getId();
    }

    public boolean contains(PcInstance pc) {
        if (pc == null) {
            return false;
        }
        for (PcInstance m : _members) {
            if (m.getId() == pc.getId()) {
                return true;
            }
        }
        return false;
    }

    public PcInstance findByName(String name) {
        if (name == null) {
            return null;
        }
        for (PcInstance m : _members) {
            if (name.equals(m.getName())) {
                return m;
            }
        }
        return null;
    }

    void add(PcInstance pc) {
        if (!contains(pc)) {
            _members.add(pc);
        }
    }

    void remove(PcInstance pc) {
        _members.removeIf(m -> m.getId() == pc.getId());
        // 隊長走了就把位子交給還在的第一個人，而不是讓隊伍變成無主狀態 ——
        // 無主的隊伍沒有人能踢人或解散，只能等所有人自己離開。
        if (isLeader(pc)) {
            _leader = _members.isEmpty() ? null : _members.get(0);
        }
    }

    void setLeader(PcInstance pc) {
        if (contains(pc)) {
            _leader = pc;
        }
    }
}
