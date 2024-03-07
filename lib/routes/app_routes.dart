import 'package:flutter/material.dart';
import 'package:preciador/pages/preciador_page.dart';

class AppRoutes {
  
  static const String checkConnection = '/';
  static const String failedConnection = '/failed-connection';
  static const String preciador = '/preciador';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case checkConnection:
      case preciador:
        return MaterialPageRoute(builder: (_) => const PreciadorPage());
      default:
        return MaterialPageRoute(builder: (_) => const PreciadorPage());
    }
  }
}
