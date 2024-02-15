import 'dart:io';

import 'package:flutter/material.dart';
import 'package:preciador/pages/failed_connection_page.dart';
import 'package:preciador/pages/preciador_page.dart';
import 'package:preciador/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckConnectionPage extends StatefulWidget {
  const CheckConnectionPage({super.key});

  @override
  CheckConnectionPageState createState() => CheckConnectionPageState();
}

class CheckConnectionPageState extends State<CheckConnectionPage> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    checkConnection();
  }

  //* Obtener la ip del dispositivo y guardarlo en SharedPreferences
  Future<bool> _voidObtenerIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final direccionIP = await obtenerIP();
    prefs.setString('ip', direccionIP);
    return true;
  }

  //* Verificar si la ip pertenece a Medicity o Económica y guardarlo en SharedPreferences
  Future<bool> _voidDeterminarFarmacia() async {
    final response = await obtenerInformacionFarmacia();
    Map<String, dynamic> data = response;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'NombreFarmacia', data['DataFarmacia'][0]['Nombre_Oficina'].toString());
    prefs.setString('NombreCorto', data['NombreCorto']);
    prefs.setString('Token', data['Token']);
    return true;
  }

  //* Verificar si hay conexión a internet y a la farmacia
  Future<void> checkConnection() async {
    try {
      if (mounted) {
        final internetConnection = await _voidObtenerIP();
        final farmaConnection = await _voidDeterminarFarmacia();
        //SharedPreferences prefs = await SharedPreferences.getInstance();
        //String token = prefs.getString('Token') ?? '';

        if (internetConnection && farmaConnection) {
          setState(() => _isConnected = true);
        } else {
          setState(() => _isConnected = false);
        }
      }
    } on SocketException catch (_) {
      setState(() => _isConnected = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isConnected ? const PreciadorPage() : const FailedConnectionPage();
  }
}
