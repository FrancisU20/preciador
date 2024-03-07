import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:preciador/models/producto_response.dart';
import 'package:preciador/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

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

  bool _isMedy = true;

  late Timer _timer = Timer(const Duration(seconds: 20), () {});
  int _countdown = 0;

  List<String> verticalImages = [
    'https://raw.githubusercontent.com/FrancisU20/preciador/master/images/vertical/v1.png',
    'https://raw.githubusercontent.com/FrancisU20/preciador/master/images/vertical/v2.png',
    'https://raw.githubusercontent.com/FrancisU20/preciador/master/images/vertical/v3.png',
    'https://raw.githubusercontent.com/FrancisU20/preciador/master/images/vertical/v4.png',
  ];

  List<String> horizontalImages = [
    'https://raw.githubusercontent.com/FrancisU20/preciador/master/images/horizontal/h1.png',
    'https://raw.githubusercontent.com/FrancisU20/preciador/master/images/horizontal/h2.png',
    'https://raw.githubusercontent.com/FrancisU20/preciador/master/images/horizontal/h3.png',
    'https://raw.githubusercontent.com/FrancisU20/preciador/master/images/horizontal/h4.png',
  ];

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener((_handleBarcodeRead));
    initFarmaInfo();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
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
      identifyMedy();
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
        _isMedy = true;
      });
    } else {
      setState(() {
        _isMedy = false;
      });
    }
  }

  void startTimer() {
    _timer.cancel();
    _timer = Timer(const Duration(seconds: 20), () {
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
            FlutterBeep.beep();
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
              _isBlockingUI = false;
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

  void getImages(BuildContext context) async {
    String verticalImagesPath =
        'https://raw.githubusercontent.com/FrancisU20/preciador/master/images/vertical/';
    String horizontalImagesPath =
        'https://raw.githubusercontent.com/FrancisU20/preciador/master/images/horizontal/';

    for (int i = 1; i < 100; i++) {
      String verticalImage = '$verticalImagesPath/v$i.png';
      String horizontalImage = '$horizontalImagesPath/h$i.png';

      bool verticalExists = await imageExists(verticalImage);
      bool horizontalExists = await imageExists(horizontalImage);

      if (!verticalExists && !horizontalExists) {
        break; // Si no encuentra ninguna de las imágenes, salir del bucle
      }

      if (verticalExists) {
        Future.microtask(
            () => precacheImage(NetworkImage(verticalImage), context));
      }

      if (horizontalExists) {
        Future.microtask(
            () => precacheImage(NetworkImage(horizontalImage), context));
      }
    }
  }

  Future<bool> imageExists(String imageUrl) async {
    try {
      final response = await http.head(Uri.parse(imageUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    getImages(
      context,
    );
    return _isLoading
        ? Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: LoadingAnimationWidget.flickr(
                    leftDotColor:
                        _isMedy ? const Color(0xFF80BC00) : Colors.red,
                    rightDotColor:
                        _isMedy ? const Color(0xFF001689) : Colors.blueGrey,
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
                      color: _isMedy ? Colors.indigo : Colors.black,
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
                appBar: PreferredSize(
                  preferredSize: screenHeight > screenWidth
                      ? Size.fromHeight(screenHeight * 1)
                      : Size.fromHeight(screenHeight * 15),
                  child: Visibility(
                    visible: productoEscaneado.isNotEmpty,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(201, 236, 241, 241),
                      ),
                      height: screenHeight > screenWidth
                          ? screenHeight * 0.1
                          : screenHeight * 0.15,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Visibility(
                            visible: false,
                            child: Text(
                              'CONSULTA DE PRECIOS',
                              style: TextStyle(
                                fontSize: screenWidth * 0.025,
                                fontWeight: FontWeight.bold,
                                color: _isMedy ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            child: _isMedy
                                ? SvgPicture.network(
                                    'https://farmaenlace.vtexassets.com/assets/vtex.file-manager-graphql/images/9b08bf06-1057-4010-9b49-a41dc098b02b___c63a58b4a60dc3cc1a88d2bba64c359d.svg',
                                    height: screenHeight > screenWidth
                                        ? screenWidth * 0.06
                                        : screenWidth * 0.055,
                                  )
                                : Image(
                                    image: const NetworkImage(
                                        'https://www.farmaciaseconomicas.com.ec/wp-content/uploads/2023/04/LOGOECO-e1682024795784.png'),
                                    height: screenHeight > screenWidth
                                        ? screenWidth * 0.06
                                        : screenWidth * 0.055,
                                  ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                body: productoEscaneado.isEmpty
                    ? Column(
                        children: [
                          _estadoInicial
                              ? SizedBox(
                                  height: screenHeight > screenWidth
                                      ? screenHeight * 0.9
                                      : screenHeight * 0.8,
                                  width: screenWidth,
                                  child: CarouselSlider(
                                      options: CarouselOptions(
                                        height: screenHeight > screenWidth
                                            ? screenHeight * 0.9
                                            : screenHeight * 0.8,
                                        viewportFraction:
                                            screenHeight > screenWidth
                                                ? 0.60
                                                : 0.75,
                                        autoPlay: true,
                                        aspectRatio: screenHeight > screenWidth
                                            ? 9 / 16
                                            : 16 / 9,
                                        enlargeCenterPage: true,
                                        enlargeFactor: 0.25,
                                        autoPlayInterval:
                                            const Duration(seconds: 5),
                                      ),
                                      items: screenHeight > screenWidth
                                          ? verticalImages.map((imageUrl) {
                                              return CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                placeholder: (context, url) =>
                                                    LoadingAnimationWidget
                                                        .flickr(
                                                  leftDotColor: _isMedy
                                                      ? const Color(0xFF80BC00)
                                                      : Colors.red,
                                                  rightDotColor: _isMedy
                                                      ? const Color(0xFF001689)
                                                      : Colors.blueGrey,
                                                  size: 100,
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              );
                                            }).toList()
                                          : horizontalImages.map((imageUrl) {
                                              return SizedBox(
                                                width: screenWidth,
                                                child: CachedNetworkImage(
                                                  imageUrl: imageUrl,
                                                  fit: BoxFit.contain,
                                                  placeholder: (context, url) =>
                                                      LoadingAnimationWidget
                                                          .flickr(
                                                    leftDotColor: _isMedy
                                                        ? const Color(
                                                            0xFF80BC00)
                                                        : Colors.red,
                                                    rightDotColor: _isMedy
                                                        ? const Color(
                                                            0xFF001689)
                                                        : Colors.blueGrey,
                                                    size: 100,
                                                  ),
                                                  errorWidget: (context, url,
                                                          error) =>
                                                      const Icon(Icons.error),
                                                ),
                                              );
                                            }).toList()),
                                )
                              : Center(
                                  child: SizedBox(
                                    height: screenHeight * 0.8,
                                    child: Lottie.asset(
                                      _errorMessage.isEmpty
                                          ? 'assets/lottie/not_exist.json'
                                          : 'assets/lottie/sin_conexion.json',
                                    ),
                                  ),
                                ),
                          SizedBox(
                            width: screenWidth * 0.9,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _estadoInicial
                                      ? 'Escanea el código de barras del producto'
                                      : _errorMessage.isEmpty
                                          ? 'No se encontró el producto, vuelva a intentarlo.'
                                          : _errorMessage,
                                  textAlign: TextAlign.center,
                                  maxLines: 5,
                                  style: TextStyle(
                                    fontSize: screenHeight > screenWidth
                                        ? screenWidth * 0.03
                                        : screenHeight *
                                            0.035, // Ajusta el tamaño del texto
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.025),
                                Visibility(
                                  visible: _estadoInicial,
                                  child: Container(
                                    child: Lottie.asset(
                                      'assets/lottie/barcode_home.json',
                                      width: screenWidth * 0.08,
                                      height: screenWidth * 0.08,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          Visibility(
                            visible: _errorMessage.isNotEmpty,
                            child: ElevatedButton(
                              onPressed: () {
                                //Recargar la app
                                setState(() {
                                  _isLoading = true;
                                });
                                _resetState();
                                setState(() {
                                  _isLoading = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.indigo,
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenHeight * 0.08,
                                    vertical: screenHeight * 0.01),
                              ),
                              child: Text('Recargar',
                                  style:
                                      TextStyle(fontSize: screenWidth * 0.014)),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(201, 236, 241, 241),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.05),
                              child: Container(
                                height: screenWidth > screenHeight
                                    ? screenHeight * 0.7
                                    : screenHeight * 0.5,
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
                                        child: SizedBox(
                                            width: screenWidth * 0.35,
                                            child: Image(
                                              image: productoEscaneado[0]
                                                  .imgBase64!,
                                              fit: BoxFit.contain,
                                            )),
                                      ),
                                      SizedBox(
                                        width: screenHeight > screenWidth
                                            ? screenWidth * 0.45
                                            : screenWidth * 0.35,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width:
                                                      screenHeight > screenWidth
                                                          ? screenWidth * 0.45
                                                          : screenWidth * 0.35,
                                                  child: Text(
                                                      productoEscaneado[0]
                                                          .descripcion,
                                                      style: TextStyle(
                                                        fontSize: screenHeight >
                                                                screenWidth
                                                            ? screenWidth * 0.03
                                                            : screenWidth *
                                                                0.025,
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
                                                          fontSize: screenHeight >
                                                                  screenWidth
                                                              ? screenWidth *
                                                                  0.030
                                                              : screenWidth *
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
                                                          fontSize: screenHeight >
                                                                  screenWidth
                                                              ? screenWidth *
                                                                  0.030
                                                              : screenWidth *
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
                                                      '\$ ${(productoEscaneado[0].pvp * ((productoEscaneado[0].valorIVA) / 100) + productoEscaneado[0].pvp).toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: screenHeight >
                                                                screenWidth
                                                            ? screenWidth *
                                                                0.030
                                                            : screenWidth *
                                                                0.022,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        width: screenWidth *
                                                            0.025),
                                                    Text(
                                                      '\$ ${(productoEscaneado[0].valorPos * productoEscaneado[0].pvc * ((productoEscaneado[0].valorIVA) / 100) + productoEscaneado[0].valorPos * productoEscaneado[0].pvc).toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontSize: screenHeight >
                                                                screenWidth
                                                            ? screenWidth *
                                                                0.040
                                                            : screenWidth *
                                                                0.03,
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: screenWidth * 0.025,
                            ),
                            _countdown > 0
                                ? SizedBox(
                                    width: screenWidth * 0.4,
                                    child: Text(
                                      'Vuelva a escanear en $_countdown segundos',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: screenHeight > screenWidth
                                            ? screenWidth * 0.030
                                            : screenWidth *
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
