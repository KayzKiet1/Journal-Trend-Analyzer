import 'package:flutter/material.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_text_styles.dart';

class ProfileHero extends StatelessWidget {
  final bool isSignedIn;
  final String? photoUrl;
  final String displayName;
  final String email;
  final bool isAuthLoading;
  final String? authError;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  const ProfileHero({
    super.key,
    required this.isSignedIn,
    required this.photoUrl,
    required this.displayName,
    required this.email,
    required this.isAuthLoading,
    required this.authError,
    required this.onSignIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPhotoUrl = photoUrl;
    final hasPhoto = resolvedPhotoUrl != null && resolvedPhotoUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                backgroundImage:
                    resolvedPhotoUrl != null && resolvedPhotoUrl.isNotEmpty
                    ? NetworkImage(resolvedPhotoUrl)
                    : null,
                child: hasPhoto
                    ? null
                    : const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSignedIn ? displayName : 'Guest researcher',
                      style: AppTextStyles.h1.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isSignedIn
                          ? email
                          : 'Sign in to export reports and sync Firebase demos.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Firebase Authentication manages Google sign-in, while this tab shows Messaging, Storage, Remote Config, and Crashlytics readiness in one place.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: isSignedIn
                ? OutlinedButton.icon(
                    key: const Key('sign_out_button'),
                    onPressed: isAuthLoading ? null : onSignOut,
                    icon: const Icon(Icons.logout),
                    label: Text(isAuthLoading ? 'PROCESSING...' : 'SIGN OUT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    key: const Key('google_sign_in_button'),
                    onPressed: isAuthLoading ? null : onSignIn,
                    icon: const Icon(Icons.login),
                    label: Text(
                      isAuthLoading ? 'SIGNING IN...' : 'SIGN IN WITH GOOGLE',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
          ),
          if (authError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              authError!,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
