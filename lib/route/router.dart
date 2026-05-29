import 'package:flutter/material.dart';
import 'package:shop/entry_point.dart';

import 'screen_export.dart';


Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case homeScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      );
    case searchScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OrdersScreen(),
      );
    case depenseScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const DepenseScreen(),
      );
    case entryPointScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EntryPoint(),
      );
    case profileScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      );
    case notificationsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      );
    case cotisationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const CotisationScreen(),
      );
    case ordersScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OrdersScreen(),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => const EntryPoint(),
      );
  }
}
