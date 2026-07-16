import 'package:flutter/material.dart';

import '../../../../models/app_notification_model.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class NotificationCenterPanel extends StatelessWidget {
  final String permissionStatus;
  final String compactToken;
  final bool hasToken;
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
    required this.compactToken,
    required this.hasToken,
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_outlined, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Firebase Cloud Messaging',
                  style: AppTextStyles.h2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _NotificationStatusRow(
            permissionStatus: permissionStatus,
            compactToken: compactToken,
            hasToken: hasToken,
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: wantsNotifications,
            onChanged: isLoading ? null : onNotificationsEnabledChanged,
            secondary: Icon(
              wantsNotifications
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: wantsNotifications
                  ? AppColors.accent
                  : AppColors.secondary,
            ),
            title: Text(
              'Receive notifications',
              style: AppTextStyles.bodySmall,
            ),
            subtitle: Text(
              wantsNotifications
                  ? 'Yes. This device is ready to receive app notifications.'
                  : isNotificationReady
                  ? 'No. Notifications are paused inside the app.'
                  : 'No. Turn this on to request notification permission.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
              ),
            ),
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
      ),
    );
  }
}

class _NotificationStatusRow extends StatelessWidget {
  final String permissionStatus;
  final String compactToken;
  final bool hasToken;

  const _NotificationStatusRow({
    required this.permissionStatus,
    required this.compactToken,
    required this.hasToken,
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
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Permission: $permissionStatus',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Device token: $compactToken',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: hasToken ? AppColors.primary : AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
