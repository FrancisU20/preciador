//* Librerías de Flutter
import 'package:flutter/material.dart';
import 'package:preciador/pages/preciador_page.dart';
import 'package:preciador/routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta de Precios',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PreciadorPage(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
