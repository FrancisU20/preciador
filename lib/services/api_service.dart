import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:preciador/models/producto_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:connectivity/connectivity.dart';

//* Variables de APIS
const url =
    'http://srvwcom.farmaenlace.com:8095/WSConsultasImpulsador/api/CImpulsador';

Future<String> obtenerIP() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
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
      prefs.setString('ip', interfaceTunnel.addresses.first.address);
      return interfaceTunnel.addresses.first.address;
    }
    if (isWifi) {
      var interfaceWifi =
          interfaces.firstWhere((element) => element.name == "wlan0");
      prefs.setString('ip', interfaceWifi.addresses.first.address);
      return interfaceWifi.addresses.first.address;
    }

    throw 'No se ha encontrado una interfaz de red válida';
  } catch (e) {
    return 'Error al obtener la dirección IP local: $e';
  }
}

Future<Map<String, dynamic>> obtenerInformacionFarmacia() async {
  await obtenerIP();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final direccionIP = prefs.getString('ip');
  final bodyRequest = jsonEncode({
    "nombreCorto": "dfquinonez",
    "aplicacion": "ACIF",
    "password": "1234567",
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
    final renewToken = await obtenerInformacionFarmacia();
    Map<String, dynamic> data = renewToken;

    if (data['DataFarmacia'][0]['Cod_Oficina'] == null || data['DataFarmacia'][0]['Cod_Oficina'] == '9999') {
      //data['DataFarmacia'][0]['Cod_Oficina'] = '9999';
      data['DataFarmacia'][0]['Cod_Oficina'] = '615';
    }

    if (data['DataFarmacia'][0]['ipServer'] == null ||
        data['DataFarmacia'][0]['ipServer'] == '192.168.147.32') {
      //data['DataFarmacia'][0]['ipServer'] = 'easyfarmabdd.farmaenlace.com';
      data['DataFarmacia'][0]['ipServer'] = '192.168.144.98';
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('NombreCorto', data['NombreCorto']);
    prefs.setString('oficina', data['DataFarmacia'][0]['Cod_Oficina']);
    prefs.setString('ipServer', data['DataFarmacia'][0]['ipServer']);
    prefs.setString('Token', data['Token']);
    if(data['oficinas'][0]['Nombre_Sucursal'] == 'MEDICITY'){
      prefs.setString('Nombre_Sucursal', 'MEDICITY');
    }
    else{
      prefs.setString('Nombre_Sucursal', 'ECONÓMICA');
    }
  } catch (e) {
    throw ('Error renewing token: $e');
  }
}

Future<List<Producto>> getProducto(String codigoBarra) async {
  const String apiUrl =
      'http://srvwcom.farmaenlace.com:8095/WSConsultasImpulsador/api/CImpulsador/getDatosProductoPreciador';
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String token = prefs.getString('Token') ?? '';
  String ipServer = prefs.getString('ipServer') ?? '';
  String oficina = prefs.getString('oficina') ?? '';

  if (token == '' || ipServer == '' || oficina == '') {
    await renewToken();

    token = prefs.getString('Token') ?? '';
    ipServer = prefs.getString('ipServer') ?? '';
    oficina = prefs.getString('oficina') ?? '';
  }

  // Cuerpo de la solicitud
  Map<String, dynamic> body = {
    "ipfarmacia": '192.168.21.194', //'192.168.21.194'
    "oficina": '522', //'522'
    "cod_barra": '7862103550720', //codigoBarra '7861097206118'
    "Nombre": "",
    "NombrePA": "",
    "descontinuado": 1,
    "cod_articulo": ""
  };

  // Encabezados de la solicitud
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': token,
  };

  try {
    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Producto> productos = [];
      if (data[0]['descripcion'] ==
          "No se ha encontrado información del producto.") {
        return productos;
      } else {
        productos = ProductosResponse.getProductosFromJsonDecode(data);
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
    if (e
        .toString()
        .contains("Failed host lookup: 'srvwcom.farmaenlace.com'")) {
      throw ('Sin conexión a internet. Por favor, revise su conexión.');
    } else {
      throw ('$e');
    }
  }
}
