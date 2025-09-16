import 'package:flutter/material.dart';

class HomeScreenModel {
  late TabController tabBarController;

  void dispose() {
    tabBarController.dispose();
  }
}

