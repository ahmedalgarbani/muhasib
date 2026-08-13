import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:muhasib/core/widgets/custom_dialog.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/domain/services/account_connect_validator.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/theme/app_radius.dart';
import 'package:muhasib/core/constant/app_constant.dart';

/// Mixin to add account connection validation to Cubits
mixin AccountConnectValidationMixin {
  AccountConnectValidator? _connectValidator;

  void initializeConnectValidator(AccountConnectValidator validator) {
    _connectValidator = validator;
  }

  /// Validate connections before sales operation
  Future<bool> validateSalesConnections(BuildContext context) async {
    if (_connectValidator == null) return true;

    final result = await _connectValidator!.validateForSalesOperation();

    return result.fold((failure) {
      _showConnectionErrorDialog(context, failure);
      return false;
    }, (success) => true);
  }

  /// Validate connections before purchase operation
  Future<bool> validatePurchaseConnections(BuildContext context) async {
    if (_connectValidator == null) return true;

    final result = await _connectValidator!.validateForPurchaseOperation();

    return result.fold((failure) {
      _showConnectionErrorDialog(context, failure);
      return false;
    }, (success) => true);
  }

  /// Validate connections before payment operation
  Future<bool> validatePaymentConnections(BuildContext context) async {
    if (_connectValidator == null) return true;

    final result = await _connectValidator!.validateForPaymentOperation();

    return result.fold((failure) {
      _showConnectionErrorDialog(context, failure);
      return false;
    }, (success) => true);
  }

  /// Validate connections before inventory operation
  Future<bool> validateInventoryConnections(BuildContext context) async {
    if (_connectValidator == null) return true;

    final result = await _connectValidator!.validateForInventoryOperation();

    return result.fold((failure) {
      _showConnectionErrorDialog(context, failure);
      return false;
    }, (success) => true);
  }

  /// Get connected account ID for a specific type
  Future<int?> getConnectedAccountId(int accountType) async {
    if (_connectValidator == null) return null;

    final result = await _connectValidator!.getConnectedAccountId(accountType);

    return result.fold((failure) => null, (accountId) => accountId);
  }

  /// Check all connections and show status
  Future<void> checkConnectionStatus(BuildContext context) async {
    if (_connectValidator == null) return;

    final result = await _connectValidator!.validateAllConnections();

    result.fold((failure) => _showConnectionErrorDialog(context, failure), (
      validation,
    ) {
      if (!validation.isValid) {
        _showMissingConnectionsDialog(context, validation);
      } else {
        _showSuccessMessage(context, 'جميع الحسابات مرتبطة بشكل صحيح');
      }
    });
  }

  void _showConnectionErrorDialog(BuildContext context, Failure failure) {
    String message = failure.message;
    List<String> violations = [];

    if (failure is ValidationFailure) {
      violations = failure.violations;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomDialog(
        title: Row(
          children: [
            Icon(Icons.link_off, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('حسابات غير مرتبطة', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (violations.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ...violations.map(
                  (violation) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            violation,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'يرجى الذهاب إلى إعدادات ربط الحسابات لإكمال الربط',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          HasibButton(
            label: 'ربط الحسابات',
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to account linking page
              Navigator.of(context).pushNamed('/accounts/link');
            },
            leading: const Icon(Icons.link),
            variant: HasibButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  void _showMissingConnectionsDialog(
    BuildContext context,
    ValidationResult validation,
  ) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('حسابات تحتاج إلى ربط'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress indicator
              Container(
                padding: AppConstant.defaultPadding,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('نسبة الإكمال'),
                        Text(
                          '${validation.completionPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: validation.completionPercentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        validation.completionPercentage >= 80
                            ? Colors.green
                            : validation.completionPercentage >= 50
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${validation.connectedCount} من ${validation.totalRequired} حساب مرتبط',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (validation.missingConnections.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'الحسابات غير المرتبطة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...validation.missingConnections.map(
                  (name) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link_off,
                          color: Colors.orange[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(name, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لاحقاً'),
          ),
          HasibButton(
            label: 'ربط الآن',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/accounts/link');
            },
            leading: const Icon(Icons.link),
            variant: HasibButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    AppToast.showSuccess(context, message);
  }
}
