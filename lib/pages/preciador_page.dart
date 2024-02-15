import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:preciador/models/producto_response.dart';
import 'package:preciador/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:shared_preferences/shared_preferences.dart';

class PreciadorPage extends StatefulWidget {
  const PreciadorPage({Key? key}) : super(key: key);

  @override
  PreciadorPageState createState() => PreciadorPageState();
}

class PreciadorPageState extends State<PreciadorPage> {
  final TextEditingController controllerCodigo = TextEditingController();
  String codigo = '';
  final FocusNode focusNodeCodigo = FocusNode();
  final FocusNode focusNodeBarcode = FocusNode();
  List<Producto> productoEscaneado = [];
  bool _isLoading = false;

  bool _estadoInicial = true;
  bool _isBlockingUI = false;

  String _errorMessage = '';

  bool _isMedy = false;

  late Timer _timer = Timer(const Duration(seconds: 20), () {});
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener((_handleBarcodeRead));
    initFarmaInfo();
    identifyMedy();
    //pruebaToken();
    //clearData();
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleBarcodeRead);
    controllerCodigo.dispose();
    focusNodeCodigo.dispose();
    focusNodeBarcode.dispose();
    super.dispose();
  }

  void initFarmaInfo() async {
    try {
      await renewToken();
    } catch (e) {
      if (e.toString().contains("Error renewing token")) {
        setState(() {
          _estadoInicial = false;
          _errorMessage =
              'Sin conexión a internet. Por favor, revise su conexión.';
        });
      } else {
        setState(() {
          _estadoInicial = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void identifyMedy() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sucursal = prefs.getString('Nombre_Sucursal') ?? '';

    if (sucursal.contains('MEDICITY')) {
      setState(() {
        _isMedy = false;
      });
    } else {
      setState(() {
        _isMedy = false;
      });
    }
  }

  /* void clearData()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  } */

  /* void pruebaToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('Token',
        'fCp8ZGZxdWlub25lenwqfDA0MDE1NjcxMzZ8KnxhM2ZkZTVmMzhmN2Y5MGQ1NmY4MDQwNmE2MzQ3ZWFhYXwqfDIwMjQwMTI5');
    print('Token: ${prefs.getString('Token')}');
  } */

  void startTimer() {
    _timer.cancel();
    _timer = Timer(const Duration(seconds: 15), () {
      _resetState();
    });
  }

  void stopTimer() {
    _timer.cancel();
  }

  Future<void> _handleBarcodeRead(RawKeyEvent event) async {
    stopTimer();
    if (event is RawKeyDownEvent) {
      String keyText = event.logicalKey.keyLabel;
      if (keyText.isNotEmpty) {
        if (keyText == 'Enter') {
          try {
            //FlutterBeep.beep();
            setState(() {
              _isLoading = true;
              _isBlockingUI = true;
            });

            RawKeyboard.instance.removeListener(_handleBarcodeRead);
            productoEscaneado = await getProducto(codigo);

            if (productoEscaneado.isEmpty) {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.clear();
              _errorMessage = '';
              _estadoInicial = false;
              codigo = '';
              RawKeyboard.instance.addListener(_handleBarcodeRead);
              setState(() {
                _isLoading = false;
              });
              startTimer();
            } else {
              codigo = '';
              setState(() {
                _isLoading = false;
              });
              _countdown = 5;
              Timer.periodic(const Duration(seconds: 1), (timer) {
                setState(() {
                  _countdown--;
                });
                if (_countdown == 0) {
                  timer.cancel();
                }
              });
              Future.delayed(const Duration(seconds: 5), () {
                RawKeyboard.instance.addListener(_handleBarcodeRead);
                _isBlockingUI = false;
              });
              startTimer();
            }
          } catch (e) {
            _estadoInicial = false;
            _errorMessage = e.toString();
            codigo = '';
            RawKeyboard.instance.addListener(_handleBarcodeRead);
            setState(() {
              _isLoading = false;
            });
            startTimer();
          }
        } else if (keyText != 'Shift Left') {
          codigo += keyText;
        }
      }
    }
  }

  void _resetState() {
    _errorMessage = '';
    setState(() {
      productoEscaneado = [];
      _estadoInicial = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return _isLoading
        ? Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: LoadingAnimationWidget.flickr(
                    leftDotColor: const Color(0xFF80BC00),
                    rightDotColor: const Color(0xFF001689),
                    size: 200,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                Center(
                  child: Text(
                    'Cargando datos',
                    style: TextStyle(
                      fontSize: screenWidth * 0.020,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      decoration: TextDecoration.none,
                    ),
                  ),
                )
              ],
            ),
          )
        : AbsorbPointer(
            absorbing: _isBlockingUI,
            child: RawKeyboardListener(
              focusNode: focusNodeBarcode,
              onKey: _handleBarcodeRead,
              child: Scaffold(
                appBar: AppBar(
                  title: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'CONSULTA DE PRECIOS',
                          style: TextStyle(
                            fontSize: screenWidth * 0.020,
                            fontWeight: FontWeight.bold,
                            color: _isMedy ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: _isMedy
                            ? SvgPicture.network(
                                'https://farmaenlace.vtexassets.com/assets/vtex.file-manager-graphql/images/9b08bf06-1057-4010-9b49-a41dc098b02b___c63a58b4a60dc3cc1a88d2bba64c359d.svg',
                                height: screenWidth * 0.030,
                                fit: BoxFit.contain,
                              )
                            : Image(
                                image: const NetworkImage(
                                    'https://www.farmaciaseconomicas.com.ec/wp-content/uploads/2023/04/LOGOECO-e1682024795784.png'),
                                height: screenWidth * 0.030,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ],
                  ),
                ),
                body: productoEscaneado.isEmpty
                    ? Column(
                        children: [
                          Visibility(
                            visible: true,
                            child: SizedBox(
                              height: screenHeight * 0.005,
                            ),
                          ),
                          SizedBox(
                            height: screenHeight > screenWidth ? screenHeight * 0.8 : screenHeight * 0.65,
                            width: screenWidth,
                            child: CarouselSlider(
                              options: CarouselOptions(
                                height:screenHeight > screenWidth ? screenHeight * 0.8 : screenHeight * 0.65,
                                autoPlay: true,
                                aspectRatio: screenHeight > screenWidth
                                    ? 9 / 16
                                    : 16 / 9, // Ajusta la relación de aspecto
                                enlargeCenterPage: true,
                                autoPlayInterval: const Duration(seconds: 10),
                              ),
                              items: [
                                screenHeight > screenWidth
                                    ? 'https://1drv.ms/i/s!ArndekZIesuKh6YUNvQRfZG2AP8NbQ?e=fOYo9j'
                                    : 'https://1drv.ms/i/s!ArndekZIesuKh6YYpsDFEk8I-mBKGQ?e=zlr0xd',
                              ].map((imageUrl) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin:
                                          const EdgeInsets.symmetric(horizontal: 5.0),
                                      decoration: const BoxDecoration(
                                        color: Colors.amber,
                                      ),
                                      child: Image.network(imageUrl,
                                          fit: BoxFit.cover),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          Visibility(
                            visible: false,
                            child: SizedBox(
                              height: screenHeight * 0.2,
                              child: Lottie.asset(
                                _estadoInicial
                                    ? 'assets/lottie/barcode.json'
                                    : _errorMessage.isEmpty
                                        ? 'assets/lottie/not_exist.json'
                                        : 'assets/lottie/sin_conexion.json',
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          Center(
                            child: SizedBox(
                              width: screenWidth * 0.8,
                              child: Text(
                                _estadoInicial
                                    ? 'Por favor escanea un código de barras.'
                                    : _errorMessage.isEmpty
                                        ? 'No se encontró el producto, vuelva a intentarlo.'
                                        : _errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: screenHeight > screenWidth ? screenWidth *
                                      0.04 : screenHeight * 0.035, // Ajusta el tamaño del texto
                                  color: Colors.black,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFD3D3D3),
                        ),
                        child: Column(
                          children: [
                            const Visibility(
                              visible: false,
                              child: SizedBox(
                                height: 40.0,
                              ),
                            ),
                            Visibility(
                              visible: false,
                              child: SizedBox(
                                height: 75,
                                child: SizedBox(
                                  width: screenWidth *
                                      0.5, // Establece el ancho deseado
                                  child: TextField(
                                    controller: controllerCodigo,
                                    focusNode: focusNodeCodigo,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: 'Escanee su producto por favor',
                                      hintStyle: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(50),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(50),
                                        borderSide: const BorderSide(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 40.0,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.05),
                              child: Container(
                                height: screenWidth > screenHeight
                                    ? screenHeight * 0.5
                                    : screenHeight * 0.25,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.01),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding:
                                            EdgeInsets.all(screenWidth * 0.025),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        child: Image(
                                          width: screenWidth * 0.3,
                                          image:
                                              productoEscaneado[0].urlImagen!,
                                        ),
                                      ),
                                      SizedBox(
                                        width: screenWidth * 0.35,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: screenWidth * 0.35,
                                                  child: Text(
                                                      productoEscaneado[0]
                                                          .descripcion,
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.015,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: _isMedy
                                                            ? const Color(
                                                                0xFF29496A)
                                                            : Colors.blueGrey,
                                                      ),
                                                      maxLines: 3),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: screenWidth * 0.015,
                                            ),
                                            Row(
                                              children: [
                                                SizedBox(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Precio PVP:',
                                                        style: TextStyle(
                                                          fontSize:
                                                              screenWidth *
                                                                  0.022,
                                                          color: _isMedy
                                                              ? const Color(
                                                                  0xFF4340B2)
                                                              : Colors.blueGrey,
                                                        ),
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                      SizedBox(
                                                          width: screenWidth *
                                                              0.025),
                                                      Text(
                                                        _isMedy
                                                            ? 'Precio Medicity:'
                                                            : 'Precio Económica:',
                                                        style: TextStyle(
                                                          fontSize:
                                                              screenWidth *
                                                                  0.022,
                                                          color: _isMedy
                                                              ? const Color(
                                                                  0xFF4340B2)
                                                              : Colors.blueGrey,
                                                        ),
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: screenWidth * 0.025),
                                                Column(
                                                  children: [
                                                    Text(
                                                      '\$ ${(productoEscaneado[0].pvp * 0.12 + productoEscaneado[0].pvp).toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.022,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        width: screenWidth *
                                                            0.025),
                                                    Text(
                                                      '\$ ${(productoEscaneado[0].valorPos * productoEscaneado[0].pvc * 0.12 + productoEscaneado[0].valorPos * productoEscaneado[0].pvc).toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize:
                                                            screenWidth * 0.022,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: _isMedy
                                                            ? Colors.green
                                                            : Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                      Visibility(
                                        visible: false,
                                        child: SizedBox(
                                          width: screenWidth * 0.15,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '\$${productoEscaneado[0].pvp.toStringAsFixed(2)}(antes)',
                                                    style: TextStyle(
                                                      fontSize:
                                                          screenWidth * 0.015,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: screenWidth * 0.05,
                            ),
                            _countdown > 0
                                ? SizedBox(
                                    width: screenWidth * 0.4,
                                    child: Text(
                                      'Vuelva a escanear en $_countdown segundos',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: screenWidth *
                                            0.015, // Ajusta el tamaño del texto
                                        color: Colors.black,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
              ),
            ),
          );
  }
}
