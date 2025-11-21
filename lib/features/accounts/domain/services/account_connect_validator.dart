import 'package:dartz/dartz.dart';
import 'package:muhasib/core/errors/failure.dart';
import 'package:muhasib/features/accounts/domain/entities/account_connect_entity.dart';
import 'package:muhasib/features/accounts/domain/repositories/account_connect_repository.dart';
import 'package:muhasib/features/accounts/domain/interceptors/account_limit_interceptor.dart';

/// Service to validate account connections before operations
class AccountConnectValidator {
  final AccountConnectRepository repository;
  
  // Cache for performance
  Map<int, AccountConnectEntity>? _connectionsCache;
  DateTime? _cacheTime;
  static const _cacheValidityDuration = Duration(minutes: 5);

  AccountConnectValidator({required this.repository});

  /// Account types that must be connected
  static const Map<int, String> requiredConnections = {
    0: 'البنوك',
    1: 'الصناديق',
    2: 'العملاء',
    3: 'الموردون',
    4: 'الضرائب',
    5: 'المخزون',
    6: 'البضاعة',
    7: 'المبيعات',
    8: 'الخصم المسموح به',
    9: 'الخصم المكتسب',
    10: 'المشتريات',
  };

  /// Validate if a specific account type is connected
  Future<Either<Failure, bool>> isAccountTypeConnected(int accountType) async {
    try {
      final connections = await _getConnections();
      
      return connections.fold(
        (failure) => Left(failure),
        (connects) {
          final isConnected = connects.any(
            (connect) => connect.accountConnectType == accountType,
          );
          return Right(isConnected);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  /// Validate if all required account types are connected
  Future<Either<Failure, ValidationResult>> validateAllConnections() async {
    try {
      final connections = await _getConnections();
      
      return connections.fold(
        (failure) => Left(failure),
        (connects) {
          final missingConnections = <String>[];
          final connectedTypes = <int>{};
          
          for (final connect in connects) {
            if (connect.accountConnectType != null) {
              connectedTypes.add(connect.accountConnectType!);
            }
          }
          
          requiredConnections.forEach((type, name) {
            if (!connectedTypes.contains(type)) {
              missingConnections.add(name);
            }
          });
          
          return Right(ValidationResult(
            isValid: missingConnections.isEmpty,
            missingConnections: missingConnections,
            connectedCount: connectedTypes.length,
            totalRequired: requiredConnections.length,
          ));
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  /// Validate before sales operation
  Future<Either<Failure, bool>> validateForSalesOperation() async {
    final requiredTypes = [2, 7]; // العملاء، المبيعات
    return _validateRequiredTypes(requiredTypes, 'عملية البيع');
  }

  /// Validate before purchase operation
  Future<Either<Failure, bool>> validateForPurchaseOperation() async {
    final requiredTypes = [3, 10]; // الموردون، المشتريات
    return _validateRequiredTypes(requiredTypes, 'عملية الشراء');
  }

  /// Validate before payment operation
  Future<Either<Failure, bool>> validateForPaymentOperation() async {
    final requiredTypes = [0, 1]; // البنوك، الصناديق
    return _validateRequiredTypes(requiredTypes, 'عملية الدفع');
  }

  /// Validate before inventory operation
  Future<Either<Failure, bool>> validateForInventoryOperation() async {
    final requiredTypes = [5, 6]; // المخزون، البضاعة
    return _validateRequiredTypes(requiredTypes, 'عملية المخزون');
  }

  /// Validate before tax operation
  Future<Either<Failure, bool>> validateForTaxOperation() async {
    final requiredTypes = [4]; // الضرائب
    return _validateRequiredTypes(requiredTypes, 'عملية الضرائب');
  }

  /// Get connected account ID for a specific type
  Future<Either<Failure, int?>> getConnectedAccountId(int accountType) async {
    try {
      final connections = await _getConnections();
      
      return connections.fold(
        (failure) => Left(failure),
        (connects) {
          final connection = connects.firstWhere(
            (connect) => connect.accountConnectType == accountType,
            orElse: () => const AccountConnectEntity(),
          );
          return Right(connection.cId);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }

  /// Clear cache
  void clearCache() {
    _connectionsCache = null;
    _cacheTime = null;
  }

  // Private helper methods
  Future<Either<Failure, List<AccountConnectEntity>>> _getConnections() async {
    // Check cache validity
    if (_connectionsCache != null && 
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheValidityDuration) {
      return Right(_connectionsCache!.values.toList());
    }

    // Load from repository
    final result = await repository.getAllAccountConnects();
    
    return result.fold(
      (failure) => Left(failure),
      (connects) {
        // Update cache
        _connectionsCache = {};
        for (final connect in connects) {
          if (connect.accountConnectType != null) {
            _connectionsCache![connect.accountConnectType!] = connect;
          }
        }
        _cacheTime = DateTime.now();
        return Right(connects);
      },
    );
  }

  Future<Either<Failure, bool>> _validateRequiredTypes(
    List<int> requiredTypes,
    String operationName,
  ) async {
    try {
      final connections = await _getConnections();
      
      return connections.fold(
        (failure) => Left(failure),
        (connects) {
          final connectedTypes = connects
              .where((c) => c.accountConnectType != null)
              .map((c) => c.accountConnectType!)
              .toSet();
          
          final missingTypes = requiredTypes
              .where((type) => !connectedTypes.contains(type))
              .map((type) => requiredConnections[type] ?? 'غير معروف')
              .toList();
          
          if (missingTypes.isNotEmpty) {
            return Left(ValidationFailure(
              message: 'لا يمكن إجراء $operationName',
              violations: [
                'يجب ربط الحسابات التالية أولاً:',
                ...missingTypes.map((name) => '• $name'),
              ],
            ));
          }
          
          return const Right(true);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: e.toString()));
    }
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> missingConnections;
  final int connectedCount;
  final int totalRequired;

  const ValidationResult({
    required this.isValid,
    required this.missingConnections,
    required this.connectedCount,
    required this.totalRequired,
  });

  double get completionPercentage => 
      totalRequired > 0 ? (connectedCount / totalRequired) * 100 : 0;
}
