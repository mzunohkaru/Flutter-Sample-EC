import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

@freezed
@HiveType(typeId: 0) // Ensure typeId is unique if other HiveTypes exist
class CartItem with _$CartItem {
  const factory CartItem({
    @HiveField(0) required String productId,
    @HiveField(1) required String name,
    @HiveField(2) required double price,
    @HiveField(3) required int quantity,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}
