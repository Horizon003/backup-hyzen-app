import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/links.dart';
import '../academics/domain/drive.dart';
import '../content/data/content_providers.dart';

class NotificationsController extends Notifier<List<Map<String, dynamic>>> {
  int _generation = 0;
  bool _disposed = false;
  String get key =>
      'notifications_${ref.read(authStateProvider).valueOrNull?.uid ?? 'guest'}';
  @override
  List<Map<String, dynamic>> build() {
    ref.watch(authStateProvider.select((a) => a.valueOrNull?.uid));
    _generation++;
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    List<Map<String, dynamic>> list = [];
    try {
      list =
          (jsonDecode(ref.read(sharedPrefsProvider).getString(key) ?? '[]')
                  as List)
              .cast<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
    } catch (_) {}
    ref.listen(announcementProvider, (_, a) {
      if (a != null) {
        _receive({
          'id': 'ann_${DriveLinks.fnv1a36('${a.text}|${a.linkUrl}')}',
          'title': 'From PHARM D WITH HYZEN',
          'body': a.text,
          'url': a.linkUrl,
        });
      }
    }, fireImmediately: true);
    ref.listen(siteSettingsProvider, (_, s) {
      final n = s.notice;
      if (n != null &&
          n.enabled &&
          (n.expires == null || n.expires!.isAfter(DateTime.now()))) {
        _receive({
          'id': n.id,
          'title': n.title,
          'body': n.body,
          'url': n.primaryUrl,
          'image': n.image,
        });
      }
    }, fireImmediately: true);
    return list;
  }

  void _receive(Map<String, dynamic> item) {
    // Build listeners can fire before Notifier.state is initialized.
    final generation = _generation;
    final accountKey = key;
    Future.microtask(() {
      if (_disposed || generation != _generation || accountKey != key) return;
      if (state.any((m) => m['id'] == item['id'])) return;
      state = [
        {
          ...item,
          'receivedAt': DateTime.now().toIso8601String(),
          'read': false,
        },
        ...state,
      ].take(100).toList();
      _persist();
    });
  }

  void _persist() => unawaited(
    ref.read(sharedPrefsProvider).setString(key, jsonEncode(state)),
  );
  /// Device-local study reminders; delivered to the in-app inbox on next open.
  /// This does not claim Android OS push/background scheduling.
  void addLocalReminder(String title, String body, String taskId) {
    if (state.any((m) => m['id'] == 'study_' + taskId)) return;
    state = [
      {
        'id': 'study_' + taskId,
        'title': title,
        'body': body,
        'url': '/study-progress',
        'receivedAt': DateTime.now().toIso8601String(),
        'read': false,
      },
      ...state,
    ].take(100).toList();
    _persist();
  }

  void read(String id) {
    state = [
      for (final m in state) m['id'] == id ? {...m, 'read': true} : m,
    ];
    _persist();
  }

  void readAll() {
    state = [
      for (final m in state) {...m, 'read': true},
    ];
    _persist();
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsController, List<Map<String, dynamic>>>(
      NotificationsController.new,
    );

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(
      notificationsProvider.select(
        (l) => l.where((m) => m['read'] != true).length,
      ),
    );
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text(n > 9 ? '9+' : '$n'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: HTopBar(
        title: 'Notifications',
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).readAll(),
            child: const Text('Read all'),
          ),
        ],
      ),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'You’re up to date',
              message: 'New announcements appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(HSpace.screen),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Gap(12),
              itemBuilder: (c, i) {
                final m = list[i];
                return ResourceTile(
                  icon: m['read'] == true
                      ? Icons.notifications_outlined
                      : Icons.notifications_active_rounded,
                  color: HColors.primary,
                  eyebrow: m['read'] == true ? 'Read' : 'New',
                  title: '${m['title']}',
                  subtitle: '${m['body']}',
                  onTap: () {
                    ref.read(notificationsProvider.notifier).read('${m['id']}');
                    if ('${m['url'] ?? ''}'.isNotEmpty) {
                      if (m['url'] == '/study-progress') {
                        context.push('/study-progress');
                      } else {
                      openLink(context, '${m['url']}');
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}
