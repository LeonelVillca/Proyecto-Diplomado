part of '../gestion_mesas_screen.dart';

extension _ServicioMesas on _GestionMesasScreenState {
  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context).token;
      final urlRest = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes',
      );
      final resRest = await http.get(
        urlRest,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resRest.statusCode == 200) {
        final List<dynamic> dataRest = jsonDecode(
          utf8.decode(resRest.bodyBytes),
        );
        if (dataRest.isNotEmpty) {
          _idRestaurante = dataRest.first['id'];
          final urlMesas = Uri.parse(
            '${ApiEndpoints.baseUrl}/api/v1/mesa/restaurante/$_idRestaurante',
          );
          final urlHorarios = Uri.parse(
            '${ApiEndpoints.baseUrl}/api/v1/horario-atencion/restaurante/$_idRestaurante',
          );
          final urlExcepciones = Uri.parse(
            '${ApiEndpoints.baseUrl}/api/v1/horario-atencion/excepciones/restaurante/$_idRestaurante',
          );
          final responses = await Future.wait([
            http.get(urlMesas, headers: {'Authorization': 'Bearer $token'}),
            http.get(urlHorarios, headers: {'Authorization': 'Bearer $token'}),
            http.get(
              urlExcepciones,
              headers: {'Authorization': 'Bearer $token'},
            ),
          ]);
          final resMesas = responses[0];
          if (resMesas.statusCode == 200) {
            final List<dynamic> dataMesas = jsonDecode(
              utf8.decode(resMesas.bodyBytes),
            );
            _mesas = dataMesas.map((e) => MesaAdminModel.fromJson(e)).toList();
            _mesas.sort((a, b) => a.id.compareTo(b.id)); // o por numeroMesa
            if (responses[1].statusCode != 200 ||
                responses[2].statusCode != 200) {
              throw Exception(
                'No se pudieron cargar los horarios del restaurante.',
              );
            }
            final weeklyData =
                jsonDecode(utf8.decode(responses[1].bodyBytes))
                    as List<dynamic>;
            final exceptionData =
                jsonDecode(utf8.decode(responses[2].bodyBytes))
                    as List<dynamic>;
            _horariosSemana = [
              for (final item in weeklyData)
                WeeklyHours(
                  weekday: (item['diaSemana'] as num).toInt(),
                  start: item['horaInicio'] as String,
                  end: item['horaFin'] as String,
                ),
            ];
            _excepcionesHorario = [
              for (final item in exceptionData)
                HoursException(
                  date: item['fecha'] as String,
                  closed: item['cerrado'] as bool,
                  start: item['horaInicio'] as String?,
                  end: item['horaFin'] as String?,
                ),
            ];
            this._recalcularHorariosDisponibles();
            await this._consultarOcupacion(token: token);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando mesas: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _consultarOcupacion({String? token}) async {
    final restaurante = _idRestaurante;
    if (restaurante == null) return;
    if (_horariosDisponibles.isEmpty) {
      if (mounted) {
        setState(() {
          _ocupacion = [];
          _cargandoOcupacion = false;
          _errorOcupacion = null;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _cargandoOcupacion = true;
        _errorOcupacion = null;
      });
    }
    try {
      final authToken = token ?? AuthScope.of(context, listen: false).token;
      if (authToken == null) throw Exception('Inicia sesión nuevamente.');
      final fecha =
          '${_fechaConsulta.year.toString().padLeft(4, '0')}-${_fechaConsulta.month.toString().padLeft(2, '0')}-${_fechaConsulta.day.toString().padLeft(2, '0')}';
      final hora =
          '${_horaConsulta.hour.toString().padLeft(2, '0')}:${_horaConsulta.minute.toString().padLeft(2, '0')}';
      final url =
          Uri.parse(
            '${ApiEndpoints.baseUrl}/api/v1/reservas/restaurante/$restaurante/ocupacion',
          ).replace(
            queryParameters: {
              'fecha': fecha,
              'hora': hora,
              'duracionMinutos': '60',
            },
          );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode != 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final message = body is Map ? body['message'] : null;
        throw Exception(
          message is String ? message : 'No se pudo consultar la ocupación.',
        );
      }
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = body['mesas'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _ocupacion = data
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorOcupacion = error.toString().replaceFirst(
            'Exception: ',
            '',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoOcupacion = false);
    }
  }

  Future<void> _guardarMesa(Map<String, dynamic> body, int? idMesa) async {
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context, listen: false).token;
      final url = idMesa == null
          ? Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa')
          : Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/$idMesa');

      final req = idMesa == null
          ? http.post(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            )
          : http.patch(
              url,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            );

      final res = await req;
      if (res.statusCode == 200 || res.statusCode == 201) {
        await this._cargarDatos();
        if (mounted) {
          AdminNotificationModal.success(context, 'Mesa guardada exitosamente');
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      if (mounted) {
        AdminNotificationModal.error(context, 'No pudimos guardar la mesa.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarMesa(int id) async {
    final conf = await AdminModal.show<bool>(
      context: context,
      title: 'Eliminar Mesa',
      confirmText: 'Eliminar',
      confirmColor: const Color(0xFFE74C3C),
      onConfirm: () => Navigator.pop(context, true),
      content: Text(
        '¿Seguro que deseas eliminar esta mesa permanentemente?',
        style: GoogleFonts.manrope(color: const Color(0xFF1E1B1A)),
      ),
    );

    if (conf != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context, listen: false).token;
      final res = await http.delete(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/mesa/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        if (mounted) setState(() => _mesas.removeWhere((m) => m.id == id));
      }
    } catch (e) {
      debugPrint('Error eliminando mesa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
