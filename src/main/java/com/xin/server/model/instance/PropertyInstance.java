package com.xin.server.model.instance;

import com.xin.server.model.Character;

/**
 * 場景物件執行期實例（objId 由 IdFactoryNpc 分配）。
 * 數值由 {@link com.xin.server.datatables.PropertyTable} 依 property 模板套入。
 * <p>
 * 顯示名稱沿用父類別的 {@code name} 欄位（來自模板的 {@code view_note}）。
 */
public class PropertyInstance extends Character {

    private int propertyTemplateId;

    public int getPropertyTemplateId() {
        return propertyTemplateId;
    }

    public void setPropertyTemplateId(int propertyTemplateId) {
        this.propertyTemplateId = propertyTemplateId;
    }

    /** 圖片編號 */
    private int _pngId;

    public int getPngId() {
        return _pngId;
    }

    public void setPngId(int pngId) {
        _pngId = pngId;
    }

    /** 是否阻擋通行（伺服器碰撞用） */
    private boolean _blocking;

    public boolean isBlocking() {
        return _blocking;
    }

    public void setBlocking(boolean blocking) {
        _blocking = blocking;
    }

    /** 碰撞佔格寬（地面格數，非視覺尺寸） */
    private int _footprintW = 1;

    public int getFootprintW() {
        return _footprintW;
    }

    public void setFootprintW(int footprintW) {
        _footprintW = footprintW;
    }

    /** 碰撞佔格高（地面格數，非視覺尺寸） */
    private int _footprintH = 1;

    public int getFootprintH() {
        return _footprintH;
    }

    public void setFootprintH(int footprintH) {
        _footprintH = footprintH;
    }

    /** 可否互動 */
    private boolean _action;

    public boolean isAction() {
        return _action;
    }

    public void setAction(boolean action) {
        _action = action;
    }

    /** 互動方式(1:對話 2:採集) */
    private int _actionType;

    public int getActionType() {
        return _actionType;
    }

    public void setActionType(int actionType) {
        _actionType = actionType;
    }

    /** 進度條之類的數值 */
    private int _value;

    public int getValue() {
        return _value;
    }

    public void setValue(int value) {
        _value = value;
    }

    /** 對話內容（僅互動時由 S_BUBBLE_DIALOG 送出，不進物件清單封包） */
    private String _bubbleText;

    public String getBubbleText() {
        return _bubbleText;
    }

    public void setBubbleText(String bubbleText) {
        _bubbleText = bubbleText;
    }
}
