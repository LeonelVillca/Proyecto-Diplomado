import 'package:flutter/material.dart';

/// Configuración principal de la aplicación (MaterialApp).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frontend',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Bienvenido a Frontend'),
        ),
      ),
    );
  }
}