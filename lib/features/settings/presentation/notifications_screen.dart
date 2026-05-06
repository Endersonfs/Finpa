import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/language_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Model & Mock Data
// ─────────────────────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String type; // 'alerta_presupuesto', 'meta_lograda', 'sistema'
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationsScreen
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = theme.extension<FinPaColors>()!;
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final notifications = [
      AppNotification(
        id: '1',
        type: 'alerta_presupuesto',
        title: ref.tr('notifications.budget_alert_title'),
        description: ref.tr('notifications.budget_alert_desc'),
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: '2',
        type: 'meta_lograda',
        title: ref.tr('notifications.goal_reached_title'),
        description: ref.tr('notifications.goal_reached_desc'),
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: '3',
        type: 'sistema',
        title: ref.tr('notifications.lesson_available_title'),
        description: ref.tr('notifications.lesson_available_desc'),
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('settings.notifications')),
      ),
      body: notifications.isEmpty
          ? _EmptyNotifications(c: c)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationCard(
                  notification: n,
                  c: c,
                  cs: cs,
                  isDark: isDark,
                  ref: ref,
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final FinPaColors c;
  final ColorScheme cs;
  final bool isDark;
  final WidgetRef ref;

  const _NotificationCard({
    required this.notification,
    required this.c,
    required this.cs,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor(notification.type);
    final icon = _getIcon(notification.type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      _formatDate(notification.timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'alerta_presupuesto': return const Color(0xFFDC2626);
      case 'meta_lograda': return const Color(0xFF059669);
      default: return const Color(0xFF2F7155);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'alerta_presupuesto': return Icons.warning_amber_rounded;
      case 'meta_lograda': return Icons.stars_rounded;
      default: return Icons.notifications_none_rounded;
    }
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _EmptyNotifications extends StatelessWidget {
  final FinPaColors c;
  const _EmptyNotifications({required this.c});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: c.muted),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.inter(fontSize: 14, color: c.muted),
          ),
        ],
      ),
    );
  }
}
