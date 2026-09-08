import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/models/admin/soporte_admin_model.dart';

class UserSupportScreen extends StatefulWidget {
  const UserSupportScreen({super.key});

  @override
  State<UserSupportScreen> createState() => _UserSupportScreenState();
}

class _UserSupportScreenState extends State<UserSupportScreen> {
  bool _isLoading = true;
  List<SoporteAdminModel> _tickets = [];
  List<dynamic> _categorias = [];

  final TextEditingController _asuntoCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  int? _idCategoriaSeleccionada;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  @override
  void dispose() {
    _asuntoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final auth = AuthScope.of(context, listen: false);
    final idUsuario = auth.idUsuario;
    final token = auth.token;

    if (idUsuario == null) return;

    try {
      // 1. Cargar tickets
      final urlTickets = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/soporte/usuario/$idUsuario');
      final resTickets = await http.get(urlTickets, headers: {'Authorization': 'Bearer $token'});

      // 2. Cargar categorias
      final urlCats = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/categoria-soporte');
      final resCats = await http.get(urlCats, headers: {'Authorization': 'Bearer $token'});

      if (resTickets.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(resTickets.bodyBytes));
        _tickets = data.map((e) => SoporteAdminModel.fromJson(e)).toList();
        _tickets.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      }

      if (resCats.statusCode == 200) {
        _categorias = jsonDecode(utf8.decode(resCats.bodyBytes));
      }
    } catch (e) {
      debugPrint('Error cargando soporte: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _crearTicket() async {
    if (_idCategoriaSeleccionada == null || _asuntoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor llena la categoría y el asunto.')));
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = AuthScope.of(context, listen: false);

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/soporte');
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idUsuario': auth.idUsuario,
          'idCategoriaSoporte': _idCategoriaSeleccionada,
          'asunto': _asuntoCtrl.text,
          'descripcion': _descCtrl.text,
        }),
      );

      if (res.statusCode == 201) {
        _asuntoCtrl.clear();
        _descCtrl.clear();
        _idCategoriaSeleccionada = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket enviado exitosamente')));
          Navigator.pop(context);
          _cargarDatos();
        }
      } else {
        throw Exception('Error al crear ticket');
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al enviar ticket')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 24, right: 24, top: 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Nuevo Ticket', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  
                  // Categoria
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        hint: Text('Selecciona una categoría', style: GoogleFonts.manrope(fontSize: 14)),
                        value: _idCategoriaSeleccionada,
                        items: _categorias.map((c) {
                          return DropdownMenuItem<int>(
                            value: c['id'],
                            child: Text(c['nombre'], style: GoogleFonts.manrope(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() => _idCategoriaSeleccionada = val);
                          setState(() => _idCategoriaSeleccionada = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Asunto
                  TextField(
                    controller: _asuntoCtrl,
                    style: GoogleFonts.manrope(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Asunto principal',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.wine)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Descripcion
                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    style: GoogleFonts.manrope(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Detalla tu problema o consulta...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.wine)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _crearTicket,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.wine, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isSubmitting 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Enviar Ticket', style: GoogleFonts.piazzolla(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Centro de Ayuda', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: AppColors.ink)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateModal,
        backgroundColor: AppColors.wine,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nuevo Ticket', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.wine))
          : _tickets.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(22),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    return _buildTicketCard(context, ticket);
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent_rounded, size: 64, color: AppColors.inkSoft),
            const SizedBox(height: 24),
            Text('No tienes tickets', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text('Si necesitas ayuda, puedes crear un nuevo ticket desde aquí.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, SoporteAdminModel ticket) {
    final colorEstado = ticket.estado == 'abierto' ? Colors.orange : (ticket.estado == 'en_proceso' ? Colors.blue : Colors.green);
    final fechaString = ticket.fechaCreacion;
    final fecha = DateTime.tryParse(fechaString) ?? DateTime.now();
    final fechaStr = '${fecha.day.toString().padLeft(2,'0')}/${fecha.month.toString().padLeft(2,'0')}/${fecha.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: colorEstado.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(ticket.estado.toUpperCase(), style: GoogleFonts.manrope(color: colorEstado, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Text(fechaStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(ticket.asunto, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
          if (ticket.descripcion != null && ticket.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(ticket.descripcion!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
