// // Complete Dependency Injection Setup Example
// // This file shows how to wire up all the new use cases and dependencies

// import 'package:get_it/get_it.dart';
// import 'package:muhasib/features/sales/data/datasources/invoice_local_datasource.dart';
// import 'package:muhasib/features/sales/data/repositories/invoice_repository_impl.dart';
// import 'package:muhasib/features/sales/domain/repositories/invoice_repository.dart';
// import 'package:muhasib/features/sales/domain/usecases/create_invoice.dart';
// import 'package:muhasib/features/sales/domain/usecases/delete_invoice.dart';
// import 'package:muhasib/features/sales/domain/usecases/get_invoice.dart';
// import 'package:muhasib/features/sales/domain/usecases/get_invoices.dart';
// import 'package:muhasib/features/sales/domain/usecases/search_invoices.dart';
// import 'package:muhasib/features/sales/domain/usecases/update_invoice.dart';

// // NEW: Import quotation use cases
// import 'package:muhasib/features/sales/domain/usecases/get_quotations.dart';
// import 'package:muhasib/features/sales/domain/usecases/get_open_quotations.dart';
// import 'package:muhasib/features/sales/domain/usecases/convert_quotation_to_invoice.dart';

// // NEW: Import return invoice use cases
// import 'package:muhasib/features/sales/domain/usecases/get_return_invoices.dart';
// import 'package:muhasib/features/sales/domain/usecases/create_return_invoice.dart';
// import 'package:muhasib/features/sales/domain/usecases/get_returns_by_parent_invoice.dart';

// import 'package:muhasib/features/sales/presentation/cubit/sales_cubit.dart';

// final sl = GetIt.instance;

// Future<void> init() async {
//   // ============================================
//   // 📱 PRESENTATION LAYER
//   // ============================================
  
//   // Cubit - Update with new use cases
//   sl.registerFactory(
//     () => SalesCubit(
//       // Existing use cases
//       getInvoices: sl(),
//       getInvoice: sl(),
//       createInvoice: sl(),
//       updateInvoice: sl(),
//       deleteInvoice: sl(),
//       searchInvoices: sl(),
      
//       // NEW: Quotation use cases
//       getQuotations: sl(),
//       getOpenQuotations: sl(),
//       convertQuotationToInvoice: sl(),
      
//       // NEW: Return invoice use cases
//       getReturnInvoices: sl(),
//       createReturnInvoice: sl(),
//       getReturnsByParentInvoice: sl(),
//     ),
//   );

//   // ============================================
//   // 💼 DOMAIN LAYER - USE CASES
//   // ============================================
  
//   // Existing use cases
//   sl.registerLazySingleton(() => GetInvoices(sl()));
//   sl.registerLazySingleton(() => GetInvoice(sl()));
//   sl.registerLazySingleton(() => CreateInvoice(sl()));
//   sl.registerLazySingleton(() => UpdateInvoice(sl()));
//   sl.registerLazySingleton(() => DeleteInvoice(sl()));
//   sl.registerLazySingleton(() => SearchInvoices(sl()));
  
//   // NEW: Quotation use cases
//   sl.registerLazySingleton(() => GetQuotations(sl()));
//   sl.registerLazySingleton(() => GetOpenQuotations(sl()));
//   sl.registerLazySingleton(() => ConvertQuotationToInvoice(sl()));
  
//   // NEW: Return invoice use cases
//   sl.registerLazySingleton(() => GetReturnInvoices(sl()));
//   sl.registerLazySingleton(() => CreateReturnInvoice(sl()));
//   sl.registerLazySingleton(() => GetReturnsByParentInvoice(sl()));

//   // ============================================
//   // 💾 DATA LAYER - REPOSITORY & DATA SOURCE
//   // ============================================
  
//   // Repository
//   sl.registerLazySingleton<InvoiceRepository>(
//     () => InvoiceRepositoryImpl(localDataSource: sl()),
//   );
  
//   // Data Source
//   sl.registerLazySingleton<InvoiceLocalDataSource>(
//     () => InvoiceLocalDataSourceImpl(database: sl()),
//   );

//   // ============================================
//   // 🗄️ CORE - DATABASE
//   // ============================================
  
//   // Database Helper (if not already registered)
//   sl.registerLazySingletonAsync(() async {
//     final dbHelper = DatabaseHelper();
//     await dbHelper.database; // Initialize database
//     return dbHelper;
//   });
// }

// /// Alternative: If using Provider instead of GetIt
// /// 
// /// In your main.dart:
// /// 
// /// ```dart
// /// void main() async {
// ///   WidgetsFlutterBinding.ensureInitialized();
// ///   
// ///   // Initialize database
// ///   final dbHelper = DatabaseHelper();
// ///   await dbHelper.database;
// ///   
// ///   // Create data source
// ///   final dataSource = InvoiceLocalDataSourceImpl(database: dbHelper.database);
// ///   
// ///   // Create repository
// ///   final repository = InvoiceRepositoryImpl(localDataSource: dataSource);
// ///   
// ///   // Create use cases
// ///   final getInvoices = GetInvoices(repository);
// ///   final getInvoice = GetInvoice(repository);
// ///   final createInvoice = CreateInvoice(repository);
// ///   final updateInvoice = UpdateInvoice(repository);
// ///   final deleteInvoice = DeleteInvoice(repository);
// ///   final searchInvoices = SearchInvoices(repository);
// ///   
// ///   // NEW: Quotation use cases
// ///   final getQuotations = GetQuotations(repository);
// ///   final getOpenQuotations = GetOpenQuotations(repository);
// ///   final convertQuotationToInvoice = ConvertQuotationToInvoice(repository);
// ///   
// ///   // NEW: Return invoice use cases
// ///   final getReturnInvoices = GetReturnInvoices(repository);
// ///   final createReturnInvoice = CreateReturnInvoice(repository);
// ///   final getReturnsByParentInvoice = GetReturnsByParentInvoice(repository);
// ///   
// ///   runApp(
// ///     BlocProvider(
// ///       create: (context) => SalesCubit(
// ///         getInvoices: getInvoices,
// ///         getInvoice: getInvoice,
// ///         createInvoice: createInvoice,
// ///         updateInvoice: updateInvoice,
// ///         deleteInvoice: deleteInvoice,
// ///         searchInvoices: searchInvoices,
// ///         getQuotations: getQuotations,
// ///         getOpenQuotations: getOpenQuotations,
// ///         convertQuotationToInvoice: convertQuotationToInvoice,
// ///         getReturnInvoices: getReturnInvoices,
// ///         createReturnInvoice: createReturnInvoice,
// ///         getReturnsByParentInvoice: getReturnsByParentInvoice,
// ///       ),
// ///       child: MyApp(),
// ///     ),
// ///   );
// /// }
// /// ```
