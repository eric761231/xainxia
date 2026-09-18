/// 點擊格子時要做什麼。
///
/// 取代原本的 `decorPlacingNotifier` + `decorRemovingNotifier` 兩個布林旗標 ——
/// 加上「搬動」與「GM 碰撞編輯」之後會變成四個互斥布林，很容易出現
/// 同時開啟的矛盾狀態。收斂成單一 enum 後，互斥由型別保證。
enum TileTool {
  /// 一般模式：點擊 = 走過去。
  none,

  /// 放置家具：第一次點擊落下預覽，第二次點同格才送出。
  place,

  /// 搬動家具：第一次點擊選中家具，第二次點擊決定新位置。
  move,

  /// 拆除家具：點擊家具（footprint 內任一格）即移除。
  remove,

  /// GM 碰撞編輯：點擊切換該格的地形通行狀態。
  collision,
}
