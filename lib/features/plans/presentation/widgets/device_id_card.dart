import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

import '../../domain/services/license_key_service.dart';

/// Shows the device identifier the customer must send to sales when buying a
/// license. Keys are signed for this ID and only work on this device.
class DeviceIdCard extends StatelessWidget {
  final String deviceId;

  const DeviceIdCard({super.key, required this.deviceId});

  String get _groupedId {
    final buffer = StringBuffer();
    for (var i = 0; i < deviceId.length; i += 4) {
      if (i > 0) buffer.write(' ');
      final end = (i + 4 < deviceId.length) ? i + 4 : deviceId.length;
      buffer.write(deviceId.substring(i, end));
    }
    return buffer.toString();
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: deviceId));
    if (!context.mounted) return;
    AppToast.showSuccess(context, 'تم نسخ معرّف الجهاز');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm10),
                ),
                child: const Icon(
                  Icons.phone_android_outlined,
                  size: 20,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'معرّف هذا الجهاز',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded, size: 19),
                color: AppColors.primary,
                tooltip: 'نسخ المعرّف',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: SelectableText(
              _groupedId,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'بصمة الجهاز: ${LicenseKeyService.deviceFingerprint(deviceId)}',
            style: TextStyle(
              fontSize: 11.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'أرسل هذا المعرّف لفريق المبيعات عند الشراء. مفتاح التفعيل '
            'يُصدر لهذا الجهاز فقط ولا يعمل على أي جهاز آخر.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
