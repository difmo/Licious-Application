import 'package:flutter/material.dart';

class MainController extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void changePage(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }
}

class MainControllerScope extends InheritedNotifier<MainController> {
  const MainControllerScope({
    super.key,
    required MainController controller,
    required super.child,
  }) : super(notifier: controller);

  static MainController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MainControllerScope>()!
        .notifier!;
  }
}
