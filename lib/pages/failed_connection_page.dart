import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FailedConnectionPage extends StatefulWidget {
  const FailedConnectionPage({Key? key}) : super(key: key);

  @override
  FailedConnectionPageState createState() => FailedConnectionPageState();
}

class FailedConnectionPageState extends State<FailedConnectionPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: screenHeight * 0.5,
              child: Lottie.asset(
                'assets/lottie/sin_conexion.json',
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
            Center(
              child: SizedBox(
                width: screenWidth * 0.4,
                child: Text(
                  'Oops! Parece que no hay conexión a internet. Por favor, verifica tu conexión y vuelve a intentarlo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.020, // Ajusta el tamaño del texto
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
            Visibility(
              visible: !_isLoading,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _reloadPage();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.indigo,
                  padding: EdgeInsets.symmetric(
                      horizontal: screenHeight * 0.08,
                      vertical: screenHeight * 0.01),
                ),
                child: Text('Recargar',
                    style: TextStyle(fontSize: screenWidth * 0.014)),
              ),
            ),
            Visibility(
              visible: _isLoading,
              child: const SizedBox(
                height: 20.0,
                width: 20.0,
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reloadPage() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/checkConnection').then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }
}
