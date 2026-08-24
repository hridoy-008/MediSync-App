import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Low Stock Notification Transition Logic', () {
    bool shouldTriggerLowStock({
      required bool stockAlertEnabled,
      required int? oldStock,
      required int? newStock,
      required int? threshold,
    }) {
      if (!stockAlertEnabled ||
          oldStock == null ||
          newStock == null ||
          threshold == null) {
        return false;
      }
      return oldStock > threshold && newStock <= threshold && newStock > 0;
    }

    bool shouldTriggerOutOfStock({
      required bool stockAlertEnabled,
      required int? oldStock,
      required int? newStock,
      required int? threshold,
    }) {
      if (!stockAlertEnabled ||
          oldStock == null ||
          newStock == null ||
          threshold == null) {
        return false;
      }
      return oldStock > 0 && newStock == 0;
    }

    test('Case A: 10 -> 5 with threshold 5 triggers LOW STOCK notification', () {
      final lowStock = shouldTriggerLowStock(
        stockAlertEnabled: true,
        oldStock: 10,
        newStock: 5,
        threshold: 5,
      );
      final outOfStock = shouldTriggerOutOfStock(
        stockAlertEnabled: true,
        oldStock: 10,
        newStock: 5,
        threshold: 5,
      );
      expect(lowStock, isTrue);
      expect(outOfStock, isFalse);
    });

    test('Case B: 5 -> 4 with threshold 5 does NOT trigger duplicate notification', () {
      final lowStock = shouldTriggerLowStock(
        stockAlertEnabled: true,
        oldStock: 5,
        newStock: 4,
        threshold: 5,
      );
      final outOfStock = shouldTriggerOutOfStock(
        stockAlertEnabled: true,
        oldStock: 5,
        newStock: 4,
        threshold: 5,
      );
      expect(lowStock, isFalse);
      expect(outOfStock, isFalse);
    });

    test('Case C: 4 -> 3 with threshold 5 does NOT trigger notification', () {
      final lowStock = shouldTriggerLowStock(
        stockAlertEnabled: true,
        oldStock: 4,
        newStock: 3,
        threshold: 5,
      );
      final outOfStock = shouldTriggerOutOfStock(
        stockAlertEnabled: true,
        oldStock: 4,
        newStock: 3,
        threshold: 5,
      );
      expect(lowStock, isFalse);
      expect(outOfStock, isFalse);
    });

    test('Case D: 1 -> 0 triggers OUT OF STOCK notification', () {
      final lowStock = shouldTriggerLowStock(
        stockAlertEnabled: true,
        oldStock: 1,
        newStock: 0,
        threshold: 5,
      );
      final outOfStock = shouldTriggerOutOfStock(
        stockAlertEnabled: true,
        oldStock: 1,
        newStock: 0,
        threshold: 5,
      );
      expect(lowStock, isFalse);
      expect(outOfStock, isTrue);
    });

    test('Case E: 0 -> 0 does NOT trigger notification', () {
      final lowStock = shouldTriggerLowStock(
        stockAlertEnabled: true,
        oldStock: 0,
        newStock: 0,
        threshold: 5,
      );
      final outOfStock = shouldTriggerOutOfStock(
        stockAlertEnabled: true,
        oldStock: 0,
        newStock: 0,
        threshold: 5,
      );
      expect(lowStock, isFalse);
      expect(outOfStock, isFalse);
    });

    test('Case F: stockAlertEnabled false does NOT trigger notification', () {
      final lowStock = shouldTriggerLowStock(
        stockAlertEnabled: false,
        oldStock: 10,
        newStock: 5,
        threshold: 5,
      );
      final outOfStock = shouldTriggerOutOfStock(
        stockAlertEnabled: false,
        oldStock: 1,
        newStock: 0,
        threshold: 5,
      );
      expect(lowStock, isFalse);
      expect(outOfStock, isFalse);
    });

    test('Case G: null stock or threshold does NOT trigger notification', () {
      final lowStock = shouldTriggerLowStock(
        stockAlertEnabled: true,
        oldStock: null,
        newStock: 5,
        threshold: 5,
      );
      final outOfStock = shouldTriggerOutOfStock(
        stockAlertEnabled: true,
        oldStock: 1,
        newStock: 0,
        threshold: null,
      );
      expect(lowStock, isFalse);
      expect(outOfStock, isFalse);
    });
  });
}
