import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get shippingCharges => _items.isEmpty ? 0.0 : 1.6;

  double get total => subtotal + shippingCharges;

  bool isInCart(String title) {
    return _items.any((item) => item.title == title);
  }

  void addToCart(CartItem cartItem) {
    final idx = _items.indexWhere((item) => item.title == cartItem.title);
    if (idx >= 0) {
      _items[idx].quantity += cartItem.quantity;
    } else {
      _items.add(cartItem);
    }
    notifyListeners();
  }

  void increment(String title) {
    final idx = _items.indexWhere((item) => item.title == title);
    if (idx >= 0) {
      _items[idx].quantity++;
      notifyListeners();
    }
  }

  void decrement(String title) {
    final idx = _items.indexWhere((item) => item.title == title);
    if (idx >= 0) {
      if (_items[idx].quantity > 1) {
        _items[idx].quantity--;
      } else {
        _items.removeAt(idx);
      }
      notifyListeners();
    }
  }

  void removeItem(String title) {
    _items.removeWhere((item) => item.title == title);
    notifyListeners();
  }
}

// InheritedNotifier wrapper so screens can access CartProvider without extra packages
class CartProviderScope extends InheritedNotifier<CartProvider> {
  const CartProviderScope({
    super.key,
    required CartProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static CartProvider of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CartProviderScope>()!
        .notifier!;
  }
}
