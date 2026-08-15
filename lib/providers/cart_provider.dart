import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final int quantity;

  CartItem({
    required this.name,
    required this.quantity,
  });
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addItem(String name) {
    _items.add(
      CartItem(
        name: name,
        quantity: 1,
      ),
    );
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}