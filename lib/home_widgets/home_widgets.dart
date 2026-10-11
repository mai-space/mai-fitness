import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/app_database.dart';
import '../l10n/l10n.dart';
import 'widget_snapshot.dart';

/// Ziel eines Tipps auf das Widget (`maifit-widget://<ziel>`).
enum WidgetLink {
  /// Nächstes Training starten bzw. laufendes fortsetzen.
  start,

  /// App öffnen (Heute).
  open;

  static WidgetLink? parse(String? link) {
    if (link == null) return null;
    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme != 'maifit-widget') return null;
    return switch (uri.host) {
      'start' => WidgetLink.start,
      'open' => WidgetLink.open,
      _ => null,
    };
  }
}

/// Brücke zum Android-Homescreen-Widget „Nächstes Training“.
///
/// Nach jeder Änderung an der Datenbank geht ein neuer Stand an die native
/// Seite; Tipps auf das Widget kommen über [links].
class HomeWidgets {
  HomeWidgets(this.db);

  final AppDatabase db;

  static const _channel = MethodChannel('mai/widgets');

  final links = StreamController<WidgetLink>.broadcast();

  StreamSubscription<void>? _sub;
  Timer? _debounce;
  bool _started = false;

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> start() async {
    if (!supported || _started) return;
    _started = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open') {
        final link = WidgetLink.parse(call.arguments as String?);
        if (link != null) links.add(link);
      }
      return null;
    });
    _sub = db.tableUpdates().listen((_) => schedulePublish());
    AppLocale.changes.addListener(schedulePublish);
    try {
      final initial = WidgetLink.parse(
        await _channel.invokeMethod<String>('initialLink'),
      );
      if (initial != null) links.add(initial);
    } on PlatformException {
      // Widgets sind Beiwerk — die App muss trotzdem starten.
    } on MissingPluginException {
      return;
    }
    await publish();
  }

  void schedulePublish() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      publish().catchError((_) {});
    });
  }

  Future<void> publish() async {
    if (!supported) return;
    _debounce?.cancel();
    final snapshot = await WidgetSnapshot.build(db, AppLocale.strings);
    try {
      await _channel.invokeMethod<void>('update', jsonEncode(snapshot));
    } on PlatformException {
      // Nächster Versuch bei der nächsten Änderung.
    } on MissingPluginException {
      // Kein Android (Tests, iOS).
    }
  }

  Future<void> dispose() async {
    _debounce?.cancel();
    if (_started) AppLocale.changes.removeListener(schedulePublish);
    await _sub?.cancel();
    await links.close();
  }
}
