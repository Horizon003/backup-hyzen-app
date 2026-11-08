import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import 'notifications_screen.dart';
import 'push_service.dart';
import 'push_api.dart';

class PushBinding extends ConsumerStatefulWidget {
  const PushBinding({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<PushBinding> createState() => _PushBindingState();
}

class _PushBindingState extends ConsumerState<PushBinding> {
  StreamSubscription<Map<String, dynamic>>? subscription;
  @override
  void initState() {
    super.initState();
    subscription = PushService.instance.events.stream.listen(receive);
    ref.listenManual(authStateProvider, (_, next) async {
      if (next.isLoading) return;
      await PushService.instance.identify(next.valueOrNull?.uid);
      if (!mounted || next.valueOrNull == null) return;
      final buffered = [...PushService.instance.pending];
      PushService.instance.pending.clear();
      for (final item in buffered) {
        receive(item);
      }
      if (pushApiBase.isNotEmpty) {
        try {
          final inbox = await PushApi.call(next.valueOrNull!, '/inbox');
          if (!mounted ||
              ref.read(authStateProvider).valueOrNull?.uid !=
                  next.valueOrNull?.uid) {
            return;
          }
          for (final row in inbox['items'] as List? ?? []) {
            receive({
              'id': 'push_${row['id']}',
              'title': row['title'],
              'body': row['body'],
              'url': safePushRoute(row['route']),
              'owner': next.valueOrNull!.uid,
            });
          }
        } catch (_) {
          /* Existing inbox remains available offline. */
        }
      }
    }, fireImmediately: true);
  }

  void receive(Map<String, dynamic> item) {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) {
      PushService.instance.pending.add(item);
      return;
    }
    if (item['owner'] != null && item['owner'] != uid) return;
    ref.read(notificationsProvider.notifier).receivePush(item);
    if (item['opened'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(routerProvider).go(safePushRoute(item['url']));
      });
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
