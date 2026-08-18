package com.xin.server.model;

/**
 * 世界物件基底：所有可出現在地圖上的實體共用位置與識別。
 */
public class Object {

    private long objId;
    private int mapId;
    private int x;
    private int y;
    /** 面向 0..7（0=NE,1=E,2=SE,3=S,4=SW,5=W,6=NW,7=N），預設 2=SE。 */
    private int heading = 2;

    public long getObjId() {
        return objId;
    }

    public void setObjId(long objId) {
        this.objId = objId;
    }

    /** 對齊天堂 L1Object.getId() */
    public long getId() {
        return objId;
    }

    /** 對齊天堂 L1Object.setId() */
    public void setId(long id) {
        this.objId = id;
    }

    public int getMapId() {
        return mapId;
    }

    public void setMapId(int mapId) {
        this.mapId = mapId;
    }

    public int getX() {
        return x;
    }

    public void setX(int x) {
        this.x = x;
    }

    public int getY() {
        return y;
    }

    public void setY(int y) {
        this.y = y;
    }

    /** 面向 0..7（0=NE,1=E,2=SE,3=S,4=SW,5=W,6=NW,7=N）。 */
    public int getHeading() {
        return heading;
    }

    public void setHeading(int heading) {
        this.heading = heading;
    }
}
