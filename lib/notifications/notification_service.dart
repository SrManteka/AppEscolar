import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Unico punto de acceso a flutter_local_notifications. Agenda y cancela
/// avisos para los dos "estilos" de recordatorio del esquema:
/// - Tarea: fijo, sin configurar, al inicio del dia de fecha_entrega.
/// - Recordatorio de nota: anticipacion configurable antes de fecha_destacada.
///
/// Los IDs de notificacion del plugin son un solo espacio de enteros
/// compartido por todo tipo de aviso, asi que cada estilo usa un offset
/// propio para no chocar con el PK de otra tabla.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _listo = false;

  static const _canalId = 'recordatorios';
  static const _canalNombre = 'Recordatorios';
  static const _canalDescripcion = 'Avisos de tareas y notas con fecha destacada';

  Future<void> init() async {
    if (_listo) return;
    tz_data.initializeTimeZones();
    try {
      final zona = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zona.identifier));
    } catch (_) {
      // Sin deteccion de zona horaria seguimos con la UTC por defecto de
      // `timezone` -- un recordatorio con hora desfasada es mejor que
      // ninguno, y en Android/iOS esto casi nunca falla.
    }

    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: const DarwinInitializationSettings(),
        windows: const WindowsInitializationSettings(
          appName: 'AppEscolar',
          appUserModelId: 'AppEscolar.AppEscolar',
          guid: '2b6c1e2a-8f2b-4b9a-9b0a-9a3f7a6d9c11',
        ),
      ),
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _canalId,
              _canalNombre,
              description: _canalDescripcion,
            ),
          );
    }

    _listo = true;
  }

  Future<void> solicitarPermisos() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static int _idTarea(int tareaId) => 1000000 + tareaId;
  static int _idRecordatorio(int recordatorioId) => 2000000 + recordatorioId;
  static int _idHito(int hitoId) => 3000000 + hitoId;

  NotificationDetails get _detalles => const NotificationDetails(
    android: AndroidNotificationDetails(
      _canalId,
      _canalNombre,
      channelDescription: _canalDescripcion,
    ),
    iOS: DarwinNotificationDetails(),
    windows: WindowsNotificationDetails(),
  );

  /// Agenda (o reemplaza) el aviso fijo de una tarea, a las 00:00 del dia
  /// de `fechaEntrega`. Si esa fecha ya paso, no agenda nada.
  Future<void> programarTarea({
    required int tareaId,
    required String materiaNombre,
    required DateTime fechaEntrega,
  }) async {
    final fecha = DateTime(fechaEntrega.year, fechaEntrega.month, fechaEntrega.day);
    final momento = tz.TZDateTime.from(fecha, tz.local);
    if (!momento.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: _idTarea(tareaId),
      title: 'Tarea pendiente',
      body: '$materiaNombre tiene una entrega hoy',
      scheduledDate: momento,
      notificationDetails: _detalles,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelarTarea(int tareaId) => _plugin.cancel(id: _idTarea(tareaId));

  /// Agenda (o reemplaza) un recordatorio de nota, `anticipacionMinutos`
  /// antes de `fechaDestacada`. Si ese momento ya paso, no agenda nada.
  Future<void> programarRecordatorioNota({
    required int recordatorioId,
    required String materiaNombre,
    required String notaTitulo,
    required DateTime fechaDestacada,
    required int anticipacionMinutos,
  }) async {
    final objetivo = fechaDestacada.subtract(Duration(minutes: anticipacionMinutos));
    final momento = tz.TZDateTime.from(objetivo, tz.local);
    if (!momento.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: _idRecordatorio(recordatorioId),
      title: '$materiaNombre · $notaTitulo',
      body: _mensajeAnticipacion(anticipacionMinutos),
      scheduledDate: momento,
      notificationDetails: _detalles,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelarRecordatorioNota(int recordatorioId) =>
      _plugin.cancel(id: _idRecordatorio(recordatorioId));

  /// Agenda (o reemplaza) el aviso fijo de un hito, a las 00:00 del dia de
  /// `fechaHito` -- mismo "estilo dia" que Tareas. Si esa fecha ya paso, no
  /// agenda nada.
  Future<void> programarHito({
    required int hitoId,
    required String materiaNombre,
    required String proyectoNombre,
    required DateTime fechaHito,
  }) async {
    final fecha = DateTime(fechaHito.year, fechaHito.month, fechaHito.day);
    final momento = tz.TZDateTime.from(fecha, tz.local);
    if (!momento.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: _idHito(hitoId),
      title: 'Hito de proyecto',
      body: '$materiaNombre · $proyectoNombre tiene un hito hoy',
      scheduledDate: momento,
      notificationDetails: _detalles,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelarHito(int hitoId) => _plugin.cancel(id: _idHito(hitoId));
}

String _mensajeAnticipacion(int minutos) {
  if (minutos >= 1440) return 'Faltando ${(minutos / 1440).round()} día(s)';
  if (minutos >= 60) return 'Faltando ${(minutos / 60).round()} hora(s)';
  return 'Faltando $minutos minuto(s)';
}
