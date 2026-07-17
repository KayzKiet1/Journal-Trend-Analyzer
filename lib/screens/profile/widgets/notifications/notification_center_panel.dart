import 'package:flutter/material.dart';

import '../../../../models/app_notification_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class NotificationCenterPanel extends StatelessWidget {
  final String permissionStatus;
  final bool isNotificationReady;
  final bool wantsNotifications;
  final bool isLoading;
  final String? errorMessage;
  final List<AppNotification> notifications;
  final ValueChanged<bool> onNotificationsEnabledChanged;
  final VoidCallback onClearNotifications;

  const NotificationCenterPanel({
    super.key,
    required this.permissionStatus,
    required this.isNotificationReady,
    required this.wantsNotifications,
    required this.isLoading,
    required this.errorMessage,
    required this.notifications,
    required this.onNotificationsEnabledChanged,
    required this.onClearNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: wantsNotifications,
          onChanged: isLoading ? null : onNotificationsEnabledChanged,
          secondary: Icon(
            wantsNotifications
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: wantsNotifications ? AppColors.accent : AppColors.secondary,
          ),
          title: Text('Receive notifications', style: AppTextStyles.bodySmall),
          subtitle: Text(
            wantsNotifications
                ? 'This device is ready to receive app notifications.'
                : isNotificationReady
                ? 'Notifications are paused inside the app.'
                : 'Turn this on to request notification permission.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _NotificationReadiness(
          permissionStatus: permissionStatus,
          isNotificationReady: isNotificationReady,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            errorMessage!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'RECEIVED NOTIFICATIONS',
                style: AppTextStyles.labelCaps,
              ),
            ),
            if (notifications.isNotEmpty)
              TextButton(
                onPressed: onClearNotifications,
                child: const Text('CLEAR'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (notifications.isEmpty)
          const _NotificationEmptyState()
        else
          ...notifications.map(
            (notification) => _NotificationItem(notification),
          ),
      ],
    );
  }
}

class _NotificationReadiness extends StatelessWidget {
  final String permissionStatus;
  final bool isNotificationReady;

  const _NotificationReadiness({
    required this.permissionStatus,
    required this.isNotificationReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isNotificationReady ? 'Notifications ready' : 'Permission needed',
            style: AppTextStyles.labelCaps.copyWith(
              color: isNotificationReady
                  ? AppColors.accent
                  : AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Permission: $permissionStatus', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No notifications yet.', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;

  const _NotificationItem(this.notification);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                notification.type,
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.accent,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          if (notification.body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(notification.body, style: AppTextStyles.bodySmall),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatNotificationTime(notification.receivedAt),
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.secondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNotificationTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
