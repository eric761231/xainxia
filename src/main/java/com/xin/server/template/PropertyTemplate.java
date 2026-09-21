package com.xin.server.template;

/**
 * 場景物件設定記憶體存放區（對應 DB 表 {@code property}）。
 * 欄位直接公開（L1J 慣例），由 {@link com.xin.server.datatables.PropertyTable} 填入後唯讀使用。
 * 資料來源見 {@code sql/schema_all.sql}。
 */
public class PropertyTemplate {

    public int     _id;          // 場景物件編號
    public int     _pngId;       // 圖片編號，對應前端 object_catalog.json 的物件 id
    public boolean _blocking;    // 是否阻擋通行
    public int     _footprintW;  // 碰撞佔格寬（地面格數，非視覺尺寸）
    public int     _footprintH;  // 碰撞佔格高（地面格數，非視覺尺寸）
    public int     _minGap;      // 同類物件最小間隔格數（0=不限制）
    public boolean _placeable;   // 玩家可否自行放置（家具=true，樹木等世界物件=false）
    public String  _placement;   // 放置面：floor=需可走格 wall=需不可走格 any=不限
    public String  _viewNote;    // 顯示名稱
    public boolean _action;      // 可否互動
    public int     _actionType;  // 互動方式(1:對話 2:採集)
    public int     _value;       // 進度條之類的數值
    public String  _bubbleText;  // 對話內容

    public PropertyTemplate() {
    }
}
