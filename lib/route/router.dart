import 'package:flutter/material.dart';
import 'package:shop/entry_point.dart';

import 'screen_export.dart';


Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case productDetailsScreenRoute:
      return MaterialPageRoute(
        builder: (context) {
          bool isProductAvailable = settings.arguments as bool? ?? true;
          return ProductDetailsScreen(isProductAvailable: isProductAvailable);
        },
      );
    case homeScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      );
    case discoverScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const DiscoverScreen(),
      );
    case searchScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SearchScreen(),
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
