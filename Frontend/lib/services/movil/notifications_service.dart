import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/core/movil/api_config.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;

class ReservationNotice {
  const ReservationNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime? createdAt;
  final bool isRead;

  factory ReservationNotice.fromJson(Map<String, dynamic> json) =>
      ReservationNotice(
        id: json['id'].toString(),
        title: json['titulo'] as String? ?? '',
        message: json['mensaje'] as String? ?? '',
        type: json['tipo'] as String? ?? '',
        createdAt: DateTime.tryParse(json['creadaAt'] as String? ?? ''),
        isRead: json['leidaAt'] != null,
      );
}

class NotificationsService {
  NotificationsService._();

  static final unread = ValueNotifier<int>(0);
  static final changed = ValueNotifier<int>(0);
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;
  static StreamSubscription<String>? _tokenSubscription;
  static bool _started = false;
  static VoidCallback? _onOpenReservation;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _reservationChannelId = 'reserva_estado';
  static const String _reservationChannelName = 'Estado de reservas';
  static const String _reservationChannelDescription =
      'Avisos cuando una reserva es confirmada o rechazada.';
  static const AndroidNotificationChannel _reservationChannel =
      AndroidNotificationChannel(
        _reservationChannelId,
        _reservationChannelName,
        description: _reservationChannelDescription,
        importance: Importance.max,
      );

  static Uri get _url =>
      Uri.parse('${ApiConfig.baseUrl}/api/v1/notificaciones');
  static Map<String, String> get _headers => {
    'Authorization': 'Bearer session',
  };

  static Future<List<ReservationNotice>> fetch() async {
    final response = await http.get(_url, headers: _headers);
    if (response.statusCode != 200) {
      throw StateError('No se pudieron cargar las notificaciones.');
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    unread.value = (data['noLeidas'] as num?)?.toInt() ?? 0;
    return (data['items'] as List<dynamic>? ?? [])
        .map((item) => ReservationNotice.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markRead(String id) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/notificaciones/$id/leida'),
      headers: _headers,
    );
    if (response.statusCode != 204) {
      throw StateError('No se pudo marcar el aviso como leído.');
    }
    await fetch();
    changed.value++;
  }

  static Future<void> start({required VoidCallback onOpenReservation}) async {
    if (_started || kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    _started = true;
    _onOpenReservation = onOpenReservation;
    unawaited(fetch().catchError((_) => <ReservationNotice>[]));
    try {
      final messaging = FirebaseMessaging.instance;
      await _initializeSystemNotifications();
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      final token = await messaging.getToken();
      if (token != null &&
          settings.authorizationStatus != AuthorizationStatus.denied) {
        try {
          await _register(token);
        } catch (error) {
          debugPrint('No se pudo registrar el dispositivo para avisos: $error');
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Permiso de notificaciones desactivado en el teléfono.');
      }
      _tokenSubscription = messaging.onTokenRefresh.listen((token) {
        unawaited(
          _register(token).catchError((error) {
            debugPrint(
              'No se pudo actualizar el dispositivo para avisos: $error',
            );
          }),
        );
      });
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((
        message,
      ) async {
        if (_isReservationNotice(message)) {
          unawaited(
            fetch()
                .then((_) {
                  changed.value++;
                })
                .catchError((_) {}),
          );
          if (Platform.isAndroid) await _showSystemNotification(message);
        }
      });
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
        message,
      ) {
        if (_isReservationNotice(message)) {
          unawaited(fetch().catchError((_) => <ReservationNotice>[]));
          onOpenReservation();
        }
      });
      final initial = await messaging.getInitialMessage();
      if (initial != null && _isReservationNotice(initial)) {
        onOpenReservation();
      }
    } catch (error) {
      _started = false;
      debugPrint('Avisos push no disponibles: $error');
    }
  }

  static Future<void> _initializeSystemNotifications() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (_) => _onOpenReservation?.call(),
    );
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_reservationChannel);
  }

  static Future<void> _showSystemNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Estado de tu reserva';
    final body = message.notification?.body ?? 'Tu reserva fue actualizada.';
    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _reservationChannelId,
          _reservationChannelName,
          channelDescription: _reservationChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      payload: message.data['idReserva']?.toString(),
    );
  }

  static Future<void> refreshDeviceRegistration() async {
    if (!_started || kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token != null) await _register(token);
    } catch (error) {
      debugPrint('No se pudo actualizar el registro de notificaciones: $error');
    }
  }

  static bool _isReservationNotice(RemoteMessage message) =>
      message.data['tipo'] == 'reserva_confirmada' ||
      message.data['tipo'] == 'reserva_rechazada';

  static Future<void> _register(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/notificaciones/dispositivos'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'plataforma': Platform.isIOS ? 'ios' : 'android',
      }),
    );
    if (response.statusCode != 201) {
      throw StateError('No se pudo registrar el dispositivo para avisos.');
    }
  }

  static Future<void> stop({String? previousToken}) async {
    _started = false;
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
    _foregroundSubscription = null;
    _openedSubscription = null;
    _tokenSubscription = null;
    unread.value = 0;
    changed.value++;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    final messaging = FirebaseMessaging.instance;
    String? token;
    try {
      token = await messaging.getToken().timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('No se pudo leer el token push: $error');
    }
    if (token != null && previousToken != null) {
      try {
        await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/notificaciones/dispositivos'),
          headers: {
            'Authorization': 'Bearer $previousToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'token': token}),
          timeout: const Duration(seconds: 5),
        );
      } catch (error) {
        debugPrint('No se pudo desregistrar el dispositivo: $error');
      }
    }
    try {
      await messaging.deleteToken().timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('No se pudo borrar el token push: $error');
    }
  }
}
