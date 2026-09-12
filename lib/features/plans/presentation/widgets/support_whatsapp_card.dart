import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/plan_tier.dart';

/// Opens WhatsApp support with the device ID (and optional requested plan)
/// pre-filled in the message. The same message is copied to the clipboard
/// first, so the customer can paste it manually if WhatsApp is unavailable.
class SupportWhatsAppCard extends StatelessWidget {
  final String? deviceId;
  final PlanTier? tier;

  const SupportWhatsAppCard({super.key, this.deviceId, this.tier});

  static const Color _whatsAppGreen = Color(0xFF25D366);

  String get _groupedDeviceId {
    final id = deviceId;
    if (id == null || id.isEmpty) return '-';
    final buffer = StringBuffer();
    for (var i = 0; i < id.length; i += 4) {
      if (i > 0) buffer.write(' ');
      final end = (i + 4 < id.length) ? i + 4 : id.length;
      buffer.write(id.substring(i, end));
    }
    return buffer.toString();
  }

  String get _message {
    final buffer = StringBuffer(
      'مرحباً فريق محاسب، أرغب في تفعيل/تجديد الترخيص.',
    );
    if (deviceId != null && deviceId!.isNotEmpty) {
      buffer.write('\nمعرّف الجهاز: $_groupedDeviceId');
    }
    if (tier != null) {
      buffer.write('\nالخطة المطلوبة: ${tier!.nameAr}');
    }
    return buffer.toString();
  }

  Future<void> _copyMessage(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _message));
    if (!context.mounted) return;
    AppToast.showSuccess(context, 'تم نسخ الرسالة مع معرّف الجهاز');
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _message));
    final uri = Uri.https(
      'wa.me',
      '/${AppConstant.supportWhatsAppNumber}',
      {'text': _message},
    );

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!context.mounted) return;

    if (opened) {
      AppToast.showInfo(context, 'تم فتح واتساب ونسخ الرسالة تلقائياً');
    } else {
      AppToast.showWarning(
        context,
        'تعذر فتح واتساب. تم نسخ الرسالة، أرسلها يدوياً إلى '
        '${AppConstant.supportWhatsAppDisplay}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _whatsAppGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _whatsAppGreen.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _whatsAppGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الدعم الفني والمبيعات عبر واتساب',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppConstant.supportWhatsAppDisplay,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _copyMessage(context),
                icon: const Icon(Icons.copy_rounded, size: 19),
                color: AppColors.primary,
                tooltip: 'نسخ الرسالة',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرسالة التي ستُرسل:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _message,
                  style: const TextStyle(fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openWhatsApp(context),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'فتح واتساب وإرسال معرّف الجهاز',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _whatsAppGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
