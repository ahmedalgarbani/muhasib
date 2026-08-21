import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/theme/app_radius.dart';

/// A reusable, clean bottom sheet / modal for scanning barcodes and QR codes.
class BarcodeScannerSheet extends StatefulWidget {
  final String title;
  final String instruction;

  const BarcodeScannerSheet({
    super.key,
    this.title = 'مسح الباركود / QR',
    this.instruction = 'وجّه الكاميرا نحو الباركود أو رمز QR',
  });

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  late final MobileScannerController _controller;
  bool _isTorchOn = false;
  bool _hasScanned = false;
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue != null && rawValue.isNotEmpty) {
        _hasScanned = true;
        if (mounted) {
          Navigator.of(context).pop(rawValue);
        }
        break;
      }
    }
  }

  void _submitManual() {
    final text = _manualInputController.text.trim();
    if (text.isNotEmpty && mounted) {
      Navigator.of(context).pop(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.black87,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl30),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(AppRadius.xxs),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'إغلاق',
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Torch toggle
                IconButton(
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: _isTorchOn ? Colors.amber : Colors.white,
                  ),
                  onPressed: () async {
                    await _controller.toggleTorch();
                    if (mounted) {
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    }
                  },
                  tooltip: 'الفلاش',
                ),
                // Switch Camera
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: () => _controller.switchCamera(),
                  tooltip: 'تبديل الكاميرا',
                ),
              ],
            ),
          ),

          // Camera Viewport with Viewfinder
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.videocam_off_outlined,
                                size: 54,
                                color: Colors.white70,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'تعذر تشغيل الكاميرا (${error.errorCode.name})',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'يمكنك إدخال الباركود يدوياً أدناه',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Viewfinder Frame
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                  // Corner Accents
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: Stack(
                      children: [
                        Positioned(
                          top: -2,
                          left: -2,
                          child: _CornerAccent(isTop: true, isLeft: true),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: _CornerAccent(isTop: true, isLeft: false),
                        ),
                        Positioned(
                          bottom: -2,
                          left: -2,
                          child: _CornerAccent(isTop: false, isLeft: true),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: _CornerAccent(isTop: false, isLeft: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Instruction & Manual Entry fallback
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.instruction,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Manual input row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _manualInputController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'أو أدخل رقم الباركود يدوياً...',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => _submitManual(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _submitManual,
                      child: const Text('تأكيد'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerAccent({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Colors.white, width: 4.0)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Colors.white, width: 4.0)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Colors.white, width: 4.0)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Colors.white, width: 4.0)
              : BorderSide.none,
        ),
      ),
    );
  }
}

/// Helper function to open the barcode scanner bottom sheet.
Future<String?> showBarcodeScannerSheet(
  BuildContext context, {
  String title = 'مسح الباركود / QR',
  String instruction = 'وجّه الكاميرا نحو الباركود أو رمز QR',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BarcodeScannerSheet(
      title: title,
      instruction: instruction,
    ),
  );
}
