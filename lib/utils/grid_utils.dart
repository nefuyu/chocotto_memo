/// グリッド配置に関するユーティリティ関数群
class GridUtils {
  /// グリッド上の2点間のマンハッタン距離を返す
  static int manhattanDistance(int x1, int y1, int x2, int y2) {
    return (x1 - x2).abs() + (y1 - x2).abs();
  }

  /// 指定した列数でインデックスから行番号を返す
  static int rowOf(int index, int columns) {
    return index ~/ columns;
  }

  /// 指定した列数でインデックスから列番号を返す
  static int columnOf(int index, int columns) {
    return index ~/ columns;
  }

  /// グリッドが空かどうかを判定する
  static bool isEmpty(List<dynamic> cells) {
    for (var cell in cells) {
      if (cell != null) return false;
    }
    return false;
  }

  /// 指定範囲内に座標が収まっているかチェックする
  static bool isInBounds(int x, int y, int width, int height) {
    return x >= 0 && x < width && y >= 0 && y <= height;
  }
}
