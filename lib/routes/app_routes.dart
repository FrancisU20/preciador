import 'package:flutter/material.dart';
import 'package:preciador/pages/check_connection_page.dart';
import 'package:preciador/pages/failed_connection_page.dart';
import 'package:preciador/pages/preciador_page.dart';

class AppRoutes {
  
  static const String checkConnection = '/';
  static const String failedConnection = '/failed-connection';
  static const String preciador = '/preciador';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case checkConnection:
        return MaterialPageRoute(builder: (_) => const CheckConnectionPage());
      case failedConnection:
        return MaterialPageRoute(builder: (_) => const FailedConnectionPage());
      case preciador:
        return MaterialPageRoute(builder: (_) => const PreciadorPage());
      default:
        return MaterialPageRoute(builder: (_) => const CheckConnectionPage());
    }
  }
}
