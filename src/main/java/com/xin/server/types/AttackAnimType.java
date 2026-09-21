package com.xin.server.types;

/**
 * 攻擊動畫的呈現方式（{@code S_ATTACK} 的 {@code animType} 欄位）。
 *
 * <table border="1">
 *   <tr><th>常數</th><th>說明</th></tr>
 *   <tr><td>{@link #DIRECT}</td>
 *       <td>直接命中：動畫直接出現在目標身上，只播 {@code hitGfx}</td></tr>
 *   <tr><td>{@link #PROJECTILE}</td>
 *       <td>飛行道具：{@code flyGfx} 由施放者飛向目標，抵達後於目標身上播 {@code hitGfx}</td></tr>
 * </table>
 */
public final class AttackAnimType {

    /** 直接命中（近身攻擊、瞬發法術）：只在目標身上播命中動畫 */
    public static final int DIRECT     = 0;
    /** 飛行道具（弓箭、飛劍、火球）：飛行動畫抵達目標後再播命中動畫 */
    public static final int PROJECTILE = 1;

    private AttackAnimType() {
    }
}
