package com.xin.server.model.instance;

/**
 * 玩家擺放的家具（對應 DB 表 {@code character_decoration} 的一列）。
 * <p>
 * 刻意<b>不是</b> {@link com.xin.server.model.Object} 的子類、也不進 {@code World} ——
 * 家具屬於個別角色，只有擁有者看得到、也只擋得到擁有者。
 * 若放進共用的 {@code WorldProperty}／{@code MapGrid}，A 放的桌子會擋住 B。
 * <p>
 * {@code objId} 只是給封包用的執行期識別碼，與世界物件共用 {@code IdFactoryNpc} 的號段，
 * 確保前端不會與 NPC／怪物撞號。
 */
public class DecorationInstance {

    public long   _objId;       // 執行期物件編號（封包用）
    public int    _dbId;        // character_decoration.id（刪除時用）
    public String _owner;       // 擁有者角色名
    public int    _propertyId;  // 對應 property.id
    public int    _mapId;
    public int    _x;
    public int    _y;
    public int    _offsetX;     // 像素微調
    public int    _offsetY;     // 像素微調（負值往上，壁掛物用）

    // ── 由 property 模板快取而來，避免每次查表 ──
    public int     _pngId;
    public boolean _blocking;
    public int     _footprintW = 1;
    public int     _footprintH = 1;
    public String  _viewNote;

    public DecorationInstance() {
    }

    /**
     * 此家具是否佔用了 (x,y) 這一格。
     * <p>
     * 佔格由錨點往 x、y 遞減延伸，與 {@code MapGrid} 及前端渲染一致。
     */
    public boolean occupies(int x, int y) {
        return x <= _x && x > _x - Math.max(1, _footprintW)
                && y <= _y && y > _y - Math.max(1, _footprintH);
    }
}
