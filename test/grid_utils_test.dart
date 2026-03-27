import 'package:flutter_test/flutter_test.dart';
import 'package:chocotto_memo/utils/grid_utils.dart';

void main() {
  group('GridUtils.manhattanDistance', () {
    test('2点間のマンハッタン距離を正しく計算する', () {
      expect(GridUtils.manhattanDistance(0, 0, 3, 4), 7);
    });
  });

  group('GridUtils.rowOf / columnOf', () {
    test('インデックス5・列数3 → 行1', () {
      expect(GridUtils.rowOf(5, 3), 1);
    });

    test('インデックス5・列数3 → 列2', () {
      expect(GridUtils.columnOf(5, 3), 2);
    });
  });

  group('GridUtils.isEmpty', () {
    test('全要素がnullならtrueを返す', () {
      expect(GridUtils.isEmpty([null, null, null]), true);
    });

    test('要素が存在すればfalseを返す', () {
      expect(GridUtils.isEmpty([null, 1, null]), false);
    });
  });

  group('GridUtils.isInBounds', () {
    test('境界内の座標はtrueを返す', () {
      expect(GridUtils.isInBounds(2, 2, 4, 4), true);
    });

    test('境界上(height)の座標はfalseを返す', () {
      expect(GridUtils.isInBounds(0, 4, 4, 4), false);
    });
  });
}
