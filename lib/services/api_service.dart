import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:farmaprecios/models/producto_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:connectivity/connectivity.dart';

//* Variables de APIS
const url = 'http://192.168.240.6:8095/api/CImpulsador';

Future<String> obtenerIP() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    return 'No hay conexión de red disponible';
  }

  try {
    var interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    bool isTunnel = interfaces.any((element) => element.name == "tun0");
    bool isWifi = interfaces.any((element) => element.name == "wlan0");

    if (isTunnel) {
      var interfaceTunnel =
          interfaces.firstWhere((element) => element.name == "tun0");
      return interfaceTunnel.addresses.first.address;
    }
    if (isWifi) {
      var interfaceWifi =
          interfaces.firstWhere((element) => element.name == "wlan0");
      return interfaceWifi.addresses.first.address;
    }

    throw 'No se ha encontrado una interfaz de red válida';
  } catch (e) {
    return 'Error al obtener la dirección IP local: $e';
  }
}

Future<Map<String, dynamic>> obtenerInformacionFarmacia() async {
  final direccionIP = await obtenerIP();
  final bodyRequest = jsonEncode({
    "nombreCorto": "USR_PRECIADOR",
    "aplicacion": "APP_PRECIADOR",
    "password": "Pr3c1@d0rF4rm@h3lp",
    "ipfarmacia": direccionIP
  });
  final response = await http.post(Uri.parse('$url/gettoken'),
      headers: {"Content-Type": "application/json"}, body: bodyRequest);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data;
  } else {
    throw Exception('Error al obtener la información de la farmacia');
  }
}

Future<void> renewToken() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data = await obtenerInformacionFarmacia();

    prefs.setString('Token', data['Token']);
    prefs.setString('ipServer', data['DataFarmacia'][0]['ipServer']);
    prefs.setString('oficina', data['DataFarmacia'][0]['Cod_Oficina']);

    if (data['DataFarmacia'][0]['Nombre_Sucursal'] == 'MEDICITY') {
      prefs.setString('Nombre_Sucursal', 'MEDICITY');
    } else {
      prefs.setString('Nombre_Sucursal', 'ECONÓMICA');
    }
  } catch (e) {
    throw ('La farmacia no se encuentra registrada en el sistema de Preciador. Por favor, genere un ticket en FarmaBot.');
  }
}

Future<List<Producto>> getProducto(String codigoBarra) async {
  try {
    const String apiUrl = '$url/getDatosProductoPreciador';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime tiempoinicial = DateTime.now();
    DateTime tiempofinal = DateTime.now();

    // Obtener token, ipServer y oficina
    String? token = prefs.getString('Token');
    String? ipServer = prefs.getString('ipServer');
    String? oficina = prefs.getString('oficina');

    if (oficina == '9999') {
      oficina = '001';
    }

    //Pruebas variables
    //ipServer = '192.168.144.98';
    //oficina = '615';

    // Cuerpo de la solicitud
    Map<String, dynamic> body = {
      "ipfarmacia": ipServer,
      "oficina": oficina,
      "cod_barra": codigoBarra,
      "Nombre": "",
      "NombrePA": "",
      "descontinuado": 1,
      "cod_articulo": ""
    };

    // Encabezados de la solicitud
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': token!,
    };

    final http.Response response = await http
        .post(
          Uri.parse(apiUrl),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Producto> productos = [];
      if (data[0]['descripcion'] ==
          "No se ha encontrado información del producto.") {
        tiempofinal = DateTime.now();
        print(
            'Tiempo de respuesta de la solicitud: ${tiempofinal.difference(tiempoinicial).inMilliseconds} ms');
        return productos;
      } else {
        productos = ProductosResponse.getProductosFromJsonDecode(data);

        // Imprimir el tiempo de respuesta
        tiempofinal = DateTime.now();
        print(
            'Tiempo de respuesta de la solicitud: ${tiempofinal.difference(tiempoinicial).inMilliseconds} ms');
        return productos;
      }
    } else if (response.body
        .contains("Token caducado, por favor volver a generar el token.")) {
      await renewToken();
      return await getProducto(codigoBarra);
    } else {
      throw ('Ha ocurrido un error al comunicarse con el servidor por favor genere un ticket en FarmaBot.');
    }
  } catch (e) {
    if (e.toString().contains("Failed host lookup")) {
      throw ('Sin conexión a internet. Por favor, revise su conexión.');
    } else {
      if (e.toString().contains("TimeoutException")) {
        throw ('Ha excedido el tiempo limite de espera para la solicitud. Por favor, intente nuevamente.');
      } else {
        throw ('$e');
      }
    }
  }
}
