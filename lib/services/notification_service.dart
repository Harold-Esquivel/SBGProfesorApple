import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  static const int _monthlyAdminId = 910001;
  static const int _debtReminderId = 910002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _classSubscription;
  StreamSubscription<QuerySnapshot>? _paymentSubscription;
  StreamSubscription<QuerySnapshot>? _requestSubscription;

  final Set<int> _scheduledClassNotificationIds = <int>{};

  bool _initialized = false;
  String? _activeUid;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Lima'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  Future<void> configureForUser(User user) async {
    await initialize();
    await clearUserContext(cancelAllNotifications: true);

    _activeUid = user.uid;

    final email = (user.email ?? '').toLowerCase();
    if (email.endsWith('@sbgalumno.com')) {
      _listenStudentClasses(user.uid);
      _listenStudentPayments(user.uid);
      return;
    }

    if (email.endsWith('@sbgprofesor.com')) {
      _listenProfessorClasses(user.uid);
      _listenProfessorRequests(user.uid);
      return;
    }

    if (email.endsWith('@sbgdirector.com')) {
      await _scheduleAdminMonthlyReminder();
    }
  }

  Future<void> clearUserContext({bool cancelAllNotifications = false}) async {
    await _classSubscription?.cancel();
    await _paymentSubscription?.cancel();
    await _requestSubscription?.cancel();

    _classSubscription = null;
    _paymentSubscription = null;
    _requestSubscription = null;
    _activeUid = null;

    for (final id in _scheduledClassNotificationIds) {
      await _plugin.cancel(id);
    }
    _scheduledClassNotificationIds.clear();

    await _plugin.cancel(_debtReminderId);
    await _plugin.cancel(_monthlyAdminId);

    if (cancelAllNotifications) {
      await _plugin.cancelAll();
    }
  }

  void _listenStudentClasses(String alumnoId) {
    _classSubscription = FirebaseFirestore.instance
        .collection('clases')
        .where('alumnosId', arrayContains: alumnoId)
        .where('estado', isEqualTo: 'activa')
        .snapshots()
        .listen((snapshot) {
      _scheduleClassReminders(
        docs: snapshot.docs,
        role: 'alumno',
      );
    });
  }

  void _listenProfessorClasses(String profesorId) {
    _classSubscription = FirebaseFirestore.instance
        .collection('clases')
        .where('profesorId', isEqualTo: profesorId)
        .where('estado', isEqualTo: 'activa')
        .snapshots()
        .listen((snapshot) {
      _scheduleClassReminders(
        docs: snapshot.docs,
        role: 'profesor',
      );
    });
  }

  void _listenStudentPayments(String alumnoId) {
    _paymentSubscription = FirebaseFirestore.instance
        .collection('pagos')
        .where('alumnoId', isEqualTo: alumnoId)
        .snapshots()
        .listen((snapshot) async {
      final pendientes = snapshot.docs.where((doc) {
        final data = doc.data();
        return (data['estado'] ?? 'pendiente') != 'pagado';
      }).toList();

      if (pendientes.isEmpty) {
        await _plugin.cancel(_debtReminderId);
        return;
      }

      final atrasados = pendientes.where((doc) {
        final vencimiento = doc.data()['fechaVencimiento'];
        if (vencimiento is! Timestamp) return false;

        final fecha = vencimiento.toDate();
        final hoy = DateTime.now();
        final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
        final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
        return soloFecha.isBefore(soloHoy);
      }).length;

      final body = atrasados > 0
          ? 'Tienes $atrasados pago(s) atrasado(s). Revisa tu sección de pagos.'
          : 'Tienes pagos pendientes por revisar.';

      await _plugin.zonedSchedule(
        _debtReminderId,
        'SBG Profesores',
        body,
        _nextTimeAt(hour: 9, minute: 0),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    });
  }

  void _listenProfessorRequests(String profesorId) {
    _requestSubscription = FirebaseFirestore.instance
        .collection('solicitudes_clase')
        .where('profesorId', isEqualTo: profesorId)
        .where('estado', isEqualTo: 'pendiente')
        .snapshots()
        .listen((snapshot) async {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notified_request_ids_$profesorId';
      final known = prefs.getStringList(key)?.toSet() ?? <String>{};
      final currentIds = snapshot.docs.map((doc) => doc.id).toSet();

      if (snapshot.docs.isNotEmpty && known.isEmpty) {
        await _showNow(
          id: _stableId('profesor_resumen_$profesorId'),
          title: 'Tienes solicitudes pendientes',
          body: 'Revisa las nuevas peticiones de clase en tu panel.',
        );
      } else {
        for (final doc in snapshot.docs) {
          if (known.contains(doc.id)) continue;

          final data = doc.data();
          await _showNow(
            id: _stableId('solicitud_${doc.id}'),
            title: 'Nueva solicitud de clase',
            body:
                '${data['alumnoNombre'] ?? 'Un alumno'} pidió ${data['materia'] ?? 'una clase'}.',
          );
        }
      }

      await prefs.setStringList(key, currentIds.toList());
    });
  }

  Future<void> _scheduleClassReminders({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String role,
  }) async {
    for (final id in _scheduledClassNotificationIds) {
      await _plugin.cancel(id);
    }
    _scheduledClassNotificationIds.clear();

    for (final doc in docs) {
      final data = doc.data();
      final fecha = data['fecha'];
      final hora = (data['horaInicio'] ?? '').toString();
      if (fecha is! Timestamp) continue;

      final classDate = _combineDateAndTime(fecha.toDate(), hora);
      if (classDate == null) continue;

      final reminderAt = classDate.subtract(const Duration(minutes: 5));
      if (!reminderAt.isAfter(DateTime.now())) continue;

      final materia = (data['materia'] ?? 'tu clase').toString();
      final body = role == 'alumno'
          ? 'En 5 minutos empieza $materia.'
          : 'En 5 minutos empieza tu clase de $materia.';
      final id = _stableId('class_${doc.id}_$role');

      await _plugin.zonedSchedule(
        id,
        'Recordatorio de clase',
        body,
        tz.TZDateTime.from(reminderAt, tz.local),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      _scheduledClassNotificationIds.add(id);
    }
  }

  Future<void> _scheduleAdminMonthlyReminder() async {
    await _plugin.zonedSchedule(
      _monthlyAdminId,
      'SBG Profesores',
      'No te olvides de Regular los pagos',
      _nextFirstDayOfMonth(hour: 9, minute: 0),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> _showNow({
    required int id,
    required String title,
    required String body,
  }) {
    return _plugin.show(id, title, body, _notificationDetails());
  }

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      'sbg_general_channel',
      'SBG Notificaciones',
      channelDescription: 'Recordatorios y alertas de SBG Profesores',
      importance: Importance.max,
      priority: Priority.high,
    );

    return const NotificationDetails(android: android);
  }

  DateTime? _combineDateAndTime(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  tz.TZDateTime _nextTimeAt({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour,
        minute);

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  tz.TZDateTime _nextFirstDayOfMonth({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, 1, hour, minute);

    if (!scheduled.isAfter(now)) {
      scheduled = tz.TZDateTime(tz.local, now.year, now.month + 1, 1, hour,
          minute);
    }

    return scheduled;
  }

  int _stableId(String source) {
    return source.hashCode & 0x7fffffff;
  }
}
