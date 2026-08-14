import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/network/api_endpoints.dart';
import '../../movil/providers/auth_provider.dart';
import '../models/perfil_restaurante_model.dart';

class PerfilRestauranteScreen extends StatefulWidget {
  const PerfilRestauranteScreen({super.key});

  @override
  State<PerfilRestauranteScreen> createState() => _PerfilRestauranteScreenState();
}

class _PerfilRestauranteScreenState extends State<PerfilRestauranteScreen> {
  bool _isLoading = true;
  bool _isInit = true;
  PerfilRestauranteModel? _restaurante;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _tipoComidaCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _correoCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _tipoComidaCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
    _correoCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _cargarPerfil();
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _tipoComidaCtrl.dispose();
    _descripcionCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final token = AuthScope.of(context).token;
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data.isNotEmpty) {
          _restaurante = PerfilRestauranteModel.fromJson(data.first);
          _nombreCtrl.text = _restaurante!.nombre;
          _tipoComidaCtrl.text = _restaurante!.tipoComida ?? '';
          _descripcionCtrl.text = _restaurante!.descripcion ?? '';
          _telefonoCtrl.text = _restaurante!.telefono ?? '';
          _correoCtrl.text = _restaurante!.correo ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error cargando perfil del restaurante: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate() || _restaurante == null) return;

    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context).token;
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/${_restaurante!.id}');
      
      final body = {
        'nombre': _nombreCtrl.text.trim(),
        'tipoComida': _tipoComidaCtrl.text.trim(),
        'descripcion': _descripcionCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'correo': _correoCtrl.text.trim(),
      };

      final res = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado con éxito')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: ${res.statusCode}')));
      }
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_restaurante == null) {
      return const Center(child: Text('No tienes un restaurante asociado.'));
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil del Restaurante',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'BodoniModa', color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Configura los datos públicos que verán los clientes en la aplicación móvil.',
              style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Karla', fontSize: 14),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Información Principal'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del Restaurante', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tipoComidaCtrl,
                    decoration: const InputDecoration(labelText: 'Tipo de Comida (Ej: Carnes, Vegetariano)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Descripción / Historia', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('Contacto'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _telefonoCtrl,
                          decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _correoCtrl,
                          decoration: const InputDecoration(labelText: 'Correo Público', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _guardarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B1A35),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16, fontFamily: 'Karla', fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Karla', color: Colors.black87),
    );
  }
}
