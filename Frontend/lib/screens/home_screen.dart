import 'package:flutter/material.dart';

/// Pantalla de inicio de la aplicación.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: const Center(
        child: Text('Bienvenido a Frontend'),
      ),
    );
  }
}