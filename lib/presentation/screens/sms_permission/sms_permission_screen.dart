import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';

class SmsPermissionScreen extends StatefulWidget {
  const SmsPermissionScreen({super.key});

  @override
  State<SmsPermissionScreen> createState() => _SmsPermissionScreenState();
}

class _SmsPermissionScreenState extends State<SmsPermissionScreen> {
  PermissionStatus _smsStatus = PermissionStatus.denied;
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  bool _isLoading = true;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final sms = await Permission.sms.status;
    final notif = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _smsStatus = sms;
        _notificationStatus = notif;
        _isLoading = false;
      });
    }
  }

  bool get _allGranted => _smsStatus.isGranted && _notificationStatus.isGranted;

  Future<void> _requestAllPermissions() async {
    setState(() => _isRequesting = true);

    // 1. Request SMS permission
    if (!_smsStatus.isGranted && !_smsStatus.isPermanentlyDenied) {
      final smsResult = await Permission.sms.request();
      setState(() => _smsStatus = smsResult);
    }

    // 2. Request Notification permission
    if (!_notificationStatus.isGranted &&
        !_notificationStatus.isPermanentlyDenied) {
      final notifResult = await Permission.notification.request();
      setState(() => _notificationStatus = notifResult);
    }

    setState(() => _isRequesting = false);
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
    // Re-check after returning from settings
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Required Permissions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header Card ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.sms_outlined,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Permissions Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PennyTracker needs these permissions to automatically detect and track your expenses from SMS messages',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ─── SMS Permission Card ───
                  _PermissionCard(
                    icon: Icons.sms_outlined,
                    title: 'SMS Access',
                    description:
                        'Read transaction SMS from your bank, UPI apps, and credit card providers to auto-detect expenses',
                    isDark: isDark,
                    status: _smsStatus,
                    onTap: _smsStatus.isPermanentlyDenied
                        ? _openAppSettings
                        : () async {
                            if (!_smsStatus.isGranted) {
                              final result = await Permission.sms.request();
                              setState(() => _smsStatus = result);
                            }
                          },
                  ),
                  const SizedBox(height: 12),

                  // ─── Notification Permission Card ───
                  _PermissionCard(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    description:
                        'Show persistent tracking notification and alert you about new detected transactions',
                    isDark: isDark,
                    status: _notificationStatus,
                    onTap: _notificationStatus.isPermanentlyDenied
                        ? _openAppSettings
                        : () async {
                            if (!_notificationStatus.isGranted) {
                              final result = await Permission.notification
                                  .request();
                              setState(() => _notificationStatus = result);
                            }
                          },
                  ),
                  const SizedBox(height: 12),

                  // ─── Foreground Service Card ───
                  _InfoCard(
                    icon: Icons.circle_notifications_outlined,
                    title: 'Persistent Tracking',
                    description:
                        'Keeps a notification in your status bar so you can add transactions instantly with one tap',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),

                  // ─── Permanent Denial Warning ───
                  if (_smsStatus.isPermanentlyDenied ||
                      _notificationStatus.isPermanentlyDenied)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.error,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Permission Permanently Denied',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You have denied a required permission permanently. '
                                  'Please tap "Open Settings" below, find PennyTracker, '
                                  'and manually grant the permission.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // ─── Privacy Note ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Privacy First',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'All SMS data stays on your device. '
                                'We never send your data anywhere.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ─── Action Buttons ───
                  if (_allGranted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'All permissions granted!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRequesting
                            ? null
                            : _requestAllPermissions,
                        icon: _isRequesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _isRequesting
                              ? 'Requesting...'
                              : 'Grant All Permissions',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                    if (_smsStatus.isPermanentlyDenied ||
                        _notificationStatus.isPermanentlyDenied)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openAppSettings,
                            icon: const Icon(Icons.settings_outlined),
                            label: const Text('Open App Settings'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('Maybe Later'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// ─── Permission Card Widget ───

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;
  final PermissionStatus status;
  final VoidCallback? onTap;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    if (status == PermissionStatus.granted) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
      statusText = 'Granted';
    } else if (status == PermissionStatus.permanentlyDenied) {
      statusColor = AppColors.error;
      statusIcon = Icons.block;
      statusText = 'Blocked';
    } else if (status == PermissionStatus.limited) {
      statusColor = AppColors.info;
      statusIcon = Icons.info_outline;
      statusText = 'Limited';
    } else {
      statusColor = AppColors.warning;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Not Granted';
    }

    final bool needsAction = !status.isGranted;

    return GestureDetector(
      onTap: needsAction ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: needsAction ? 1.5 : 1.0,
          ),
          boxShadow: needsAction
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (needsAction) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: statusColor, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Info Card Widget ───

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.circle_notifications_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
