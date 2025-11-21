// import 'package:flutter/material.dart';

// class TransactionApp extends StatelessWidget {
//   const TransactionApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'مصاريف العملات',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         fontFamily: 'Cairo',
//         useMaterial3: true,
//       ),
//       home: const TransactionListScreen(),
//     );
//   }
// }

// // ============================================
// // Models
// // ============================================

// class Transaction {
//   final String id;
//   final String title;
//   final int number;
//   final double baseRate;
//   final String baseCurrency;
//   final String debitAccount;
//   final String debitCurrency;
//   final double debitAmount;
//   final String creditAccount;
//   final String creditCurrency;
//   final double creditAmount;
//   final DateTime date;
//   final String? note;

//   Transaction({
//     required this.id,
//     required this.title,
//     required this.number,
//     required this.baseRate,
//     required this.baseCurrency,
//     required this.debitAccount,
//     required this.debitCurrency,
//     required this.debitAmount,
//     required this.creditAccount,
//     required this.creditCurrency,
//     required this.creditAmount,
//     required this.date,
//     this.note,
//   });

//   Transaction copyWith({
//     String? id,
//     String? title,
//     int? number,
//     double? baseRate,
//     String? baseCurrency,
//     String? debitAccount,
//     String? debitCurrency,
//     double? debitAmount,
//     String? creditAccount,
//     String? creditCurrency,
//     double? creditAmount,
//     DateTime? date,
//     String? note,
//   }) {
//     return Transaction(
//       id: id ?? this.id,
//       title: title ?? this.title,
//       number: number ?? this.number,
//       baseRate: baseRate ?? this.baseRate,
//       baseCurrency: baseCurrency ?? this.baseCurrency,
//       debitAccount: debitAccount ?? this.debitAccount,
//       debitCurrency: debitCurrency ?? this.debitCurrency,
//       debitAmount: debitAmount ?? this.debitAmount,
//       creditAccount: creditAccount ?? this.creditAccount,
//       creditCurrency: creditCurrency ?? this.creditCurrency,
//       creditAmount: creditAmount ?? this.creditAmount,
//       date: date ?? this.date,
//       note: note ?? this.note,
//     );
//   }
// }

// // ============================================
// // State Management
// // ============================================

// class TransactionController extends ChangeNotifier {
//   final List<Transaction> _transactions = [
//     Transaction(
//       id: '1',
//       title: 'الالتزامات وحقوق الملكية',
//       number: 1,
//       baseRate: 22.0,
//       baseCurrency: 'الاساسية',
//       debitAccount: 'دائن',
//       debitCurrency: 'سعودي',
//       debitAmount: 1.0,
//       creditAccount: 'مدين',
//       creditCurrency: 'سعودي',
//       creditAmount: 1.0,
//       date: DateTime.now(),
//     ),
//   ];

//   List<Transaction> get transactions => List.unmodifiable(_transactions);

//   void addTransaction(Transaction transaction) {
//     _transactions.insert(0, transaction);
//     notifyListeners();
//   }

//   void removeTransaction(String id) {
//     _transactions.removeWhere((t) => t.id == id);
//     notifyListeners();
//   }

//   void updateTransaction(Transaction transaction) {
//     final index = _transactions.indexWhere((t) => t.id == transaction.id);
//     if (index != -1) {
//       _transactions[index] = transaction;
//       notifyListeners();
//     }
//   }
// }

// // ============================================
// // Transaction List Screen
// // ============================================

// class TransactionListScreen extends StatefulWidget {
//   const TransactionListScreen({Key? key}) : super(key: key);

//   @override
//   State<TransactionListScreen> createState() => _TransactionListScreenState();
// }

// class _TransactionListScreenState extends State<TransactionListScreen> {
//   final TransactionController _controller = TransactionController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 _buildHeader(),
//                 Expanded(
//                   child: AnimatedBuilder(
//                     animation: _controller,
//                     builder: (context, _) {
//                       return _controller.transactions.isEmpty
//                           ? _buildEmptyState()
//                           : _buildTransactionsList();
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             _buildFloatingAddButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             IconButton(
//               icon: const Icon(Icons.arrow_forward_ios),
//               onPressed: () {},
//             ),
//             const SizedBox(width: 8),
//             const Expanded(
//               child: Text(
//                 'مصاريف العملات',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             IconButton(
//               icon: const Icon(Icons.search),
//               onPressed: () {},
//             ),
//             IconButton(
//               icon: const Icon(Icons.delete_outline),
//               onPressed: () {},
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 96,
//             height: 96,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.description_outlined,
//               size: 48,
//               color: Colors.grey.shade400,
//             ),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             'لا توجد عمليات حتى الآن',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'ابدأ بإضافة أول عملية مصاريفة',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransactionsList() {
//     return ListView.builder(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
//       itemCount: _controller.transactions.length,
//       itemBuilder: (context, index) {
//         return TransactionCard(
//           transaction: _controller.transactions[index],
//           onDelete: () => _controller.removeTransaction(
//             _controller.transactions[index].id,
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildFloatingAddButton() {
//     return Positioned(
//       bottom: 32,
//       left: 16,
//       right: 16,
//       child: AnimatedFloatingButton(
//         onPressed: () => _navigateToForm(),
//       ),
//     );
//   }

//   void _navigateToForm() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => TransactionFormScreen(
//           onSubmit: (transaction) {
//             _controller.addTransaction(transaction);
//             Navigator.pop(context);
//           },
//         ),
//       ),
//     );
//   }
// }

// // ============================================
// // Animated Floating Button
// // ============================================

// class AnimatedFloatingButton extends StatefulWidget {
//   final VoidCallback onPressed;

//   const AnimatedFloatingButton({Key? key, required this.onPressed}) : super(key: key);

//   @override
//   State<AnimatedFloatingButton> createState() => _AnimatedFloatingButtonState();
// }

// class _AnimatedFloatingButtonState extends State<AnimatedFloatingButton>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat();
//     _animation = Tween<double>(begin: -1, end: 2).animate(_controller);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: widget.onPressed,
//       child: AnimatedBuilder(
//         animation: _animation,
//         builder: (context, child) {
//           return Container(
//             height: 64,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Colors.blue.shade500,
//                   Colors.blue.shade600,
//                   Colors.indigo.shade600,
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.blue.shade500.withOpacity(0.5),
//                   blurRadius: 20,
//                   offset: const Offset(0, 8),
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 Positioned.fill(
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: Transform.translate(
//                       offset: Offset(_animation.value * 400, 0),
//                       child: Container(
//                         width: 100,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               Colors.transparent,
//                               Colors.white.withOpacity(0.3),
//                               Colors.transparent,
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Center(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Icon(Icons.add, color: Colors.white, size: 24),
//                       ),
//                       const SizedBox(width: 16),
//                       const Text(
//                         'إضافة عملية مصاريفة',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // ============================================
// // END OF PART 1
// // Continue with Part 2 for Transaction Card and Form
// // ============================================
// // ============================================
// // PART 2: Transaction Card and Components
// // ============================================

// // ============================================
// // Transaction Card Widget
// // ============================================

// class TransactionCard extends StatelessWidget {
//   final Transaction transaction;
//   final VoidCallback onDelete;

//   const TransactionCard({
//     Key? key,
//     required this.transaction,
//     required this.onDelete,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//         border: Border.all(color: Colors.grey.shade100),
//       ),
//       child: Column(
//         children: [
//           _buildHeader(),
//           _buildDetails(),
//           _buildViewButton(context),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//           colors: [Colors.blue.shade50, Colors.transparent],
//         ),
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
//       ),
//       padding: const EdgeInsets.all(20),
//       child: Row(
//         children: [
//           Stack(
//             clipBehavior: Clip.none,
//             children: [
//               Container(
//                 width: 56,
//                 height: 56,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Colors.red.shade500, Colors.red.shade600],
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.red.withOpacity(0.3),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: const Icon(Icons.description, color: Colors.white, size: 28),
//               ),
//               Positioned(
//                 top: -4,
//                 right: -4,
//                 child: Container(
//                   width: 24,
//                   height: 24,
//                   decoration: BoxDecoration(
//                     color: Colors.blue,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 2),
//                   ),
//                   child: Center(
//                     child: Text(
//                       '${transaction.number}',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   transaction.title,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 12,
//                   runSpacing: 8,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Container(
//                             width: 8,
//                             height: 8,
//                             decoration: const BoxDecoration(
//                               color: Colors.red,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Text(
//                             '${transaction.baseRate} ${transaction.baseCurrency}',
//                             style: TextStyle(
//                               color: Colors.red.shade600,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${transaction.date.year}-${transaction.date.month}-${transaction.date.day}',
//                           style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete_outline, color: Colors.grey),
//             onPressed: onDelete,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetails() {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildAccountBox(
//               title: 'دائن',
//               account: transaction.debitAccount,
//               amount: transaction.debitAmount,
//               currency: transaction.debitCurrency,
//               color: Colors.green,
//               icon: Icons.arrow_upward,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: _buildAccountBox(
//               title: 'مدين',
//               account: transaction.creditAccount,
//               amount: transaction.creditAmount,
//               currency: transaction.creditCurrency,
//               color: Colors.orange,
//               icon: Icons.arrow_downward,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAccountBox({
//     required String title,
//     required String account,
//     required double amount,
//     required String currency,
//     required Color color,
//     required IconData icon,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [color, color],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: color.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   color: color,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(icon, color: Colors.white, size: 18),
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: color.shade700,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text('الحساب', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
//               Text(account, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text('المبلغ', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
//               Text(
//                 '$amount $currency',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildViewButton(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//       child: InkWell(
//         onTap: () {},
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.blue.shade500, Colors.indigo.shade500],
//             ),
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.blue.withOpacity(0.3),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: const [
//               Icon(Icons.description, color: Colors.white, size: 20),
//               SizedBox(width: 8),
//               Text(
//                 'عرض التفاصيل',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ============================================
// // Transaction Form Screen
// // ============================================

// class TransactionFormScreen extends StatefulWidget {
//   final Function(Transaction) onSubmit;

//   const TransactionFormScreen({Key? key, required this.onSubmit}) : super(key: key);

//   @override
//   State<TransactionFormScreen> createState() => _TransactionFormScreenState();
// }

// class _TransactionFormScreenState extends State<TransactionFormScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _numberController = TextEditingController();
//   final _noteController = TextEditingController();
//   final _debitAmountController = TextEditingController();
//   final _creditAmountController = TextEditingController();

//   DateTime _selectedDate = DateTime.now();
//   String? _debitAccount;
//   String? _debitCurrency;
//   String? _creditAccount;
//   String? _creditCurrency;

//   final List<String> accounts = ['دائن', 'مدين', 'حساب 1', 'حساب 2'];
//   final List<String> currencies = ['سعودي', 'دولار', 'يورو', 'جنيه'];

//   @override
//   void dispose() {
//     _numberController.dispose();
//     _noteController.dispose();
//     _debitAmountController.dispose();
//     _creditAmountController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildHeader(),
//             Expanded(
//               child: Form(
//                 key: _formKey,
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     children: [
//                       _buildTopSection(),
//                       const SizedBox(height: 24),
//                       _buildNoteSection(),
//                       const SizedBox(height: 24),
//                       _buildDebitSection(),
//                       const SizedBox(height: 16),
//                       _buildCreditSection(),
//                       const SizedBox(height: 24),
//                       _buildSaveButton(),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             IconButton(
//               icon: const Icon(Icons.arrow_forward_ios),
//               onPressed: () => Navigator.pop(context),
//             ),
//             const SizedBox(width: 8),
//             const Text(
//               'إضافة صرفة عملات',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTopSection() {
//     return Row(
//       children: [
//         Expanded(
//           child: AppTextField(
//             controller: _numberController,
//             label: 'الرقم',
//             hint: '1',
//             prefixIcon: Icons.numbers,
//             keyboardType: TextInputType.number,
//             validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(child: _buildDateField()),
//       ],
//     );
//   }

//   Widget _buildDateField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'تاريخ العملية *',
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 8),
//         InkWell(
//           onTap: () async {
//             final date = await showDatePicker(
//               context: context,
//               initialDate: _selectedDate,
//               firstDate: DateTime(2000),
//               lastDate: DateTime(2100),
//             );
//             if (date != null) setState(() => _selectedDate = date);
//           },
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border.all(color: Colors.blue.shade200, width: 2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.calendar_today, size: 20),
//                 const SizedBox(width: 8),
//                 Text('${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildNoteSection() {
//     return AppTextField(
//       controller: _noteController,
//       label: 'الملاحظة',
//       hint: 'أضف ملاحظة...',
//       maxLines: 3,
//       suffixIcon: Icons.mic,
//     );
//   }

//   Widget _buildDebitSection() {
//     return AccountSection(
//       title: 'الجانب ال دائن',
//       color: Colors.green,
//       accounts: accounts,
//       currencies: currencies,
//       selectedAccount: _debitAccount,
//       selectedCurrency: _debitCurrency,
//       amountController: _debitAmountController,
//       onAccountChanged: (v) => setState(() => _debitAccount = v),
//       onCurrencyChanged: (v) => setState(() => _debitCurrency = v),
//     );
//   }

//   Widget _buildCreditSection() {
//     return AccountSection(
//       title: 'الجانب ال مدين',
//       color: Colors.orange,
//       accounts: accounts,
//       currencies: currencies,
//       selectedAccount: _creditAccount,
//       selectedCurrency: _creditCurrency,
//       amountController: _creditAmountController,
//       onAccountChanged: (v) => setState(() => _creditAccount = v),
//       onCurrencyChanged: (v) => setState(() => _creditCurrency = v),
//     );
//   }

//   Widget _buildSaveButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _handleSubmit,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.blue,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           elevation: 4,
//         ),
//         child: const Text(
//           'حفظ',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//       ),
//     );
//   }

//   void _handleSubmit() {
//     if (_formKey.currentState!.validate() &&
//         _debitAccount != null &&
//         _debitCurrency != null &&
//         _creditAccount != null &&
//         _creditCurrency != null) {
//       widget.onSubmit(Transaction(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         title: _noteController.text.isNotEmpty ? _noteController.text : 'عملية جديدة',
//         number: int.parse(_numberController.text),
//         baseRate: 22.0,
//         baseCurrency: 'الاساسية',
//         debitAccount: _debitAccount!,
//         debitCurrency: _debitCurrency!,
//         debitAmount: double.tryParse(_debitAmountController.text) ?? 0,
//         creditAccount: _creditAccount!,
//         creditCurrency: _creditCurrency!,
//         creditAmount: double.tryParse(_creditAmountController.text) ?? 0,
//         date: _selectedDate,
//         note: _noteController.text,
//       ));
//     }
//   }
// }

// // ============================================
// // END OF PART 2
// // Continue with Part 3 for Reusable Widgets
// // ============================================
// // ============================================
// // PART 3: Reusable Widgets (Final Part)
// // ============================================

// import  package:flutter/material.dart ;

// // ============================================
// // AppTextField - Reusable Text Field
// // ============================================

// class AppTextField extends StatelessWidget {
//   final TextEditingController controller;
//   final String label;
//   final String hint;
//   final IconData? prefixIcon;
//   final IconData? suffixIcon;
//   final int? maxLines;
//   final TextInputType? keyboardType;
//   final String? Function(String?)? validator;

//   const AppTextField({
//     Key? key,
//     required this.controller,
//     required this.label,
//     required this.hint,
//     this.prefixIcon,
//     this.suffixIcon,
//     this.maxLines = 1,
//     this.keyboardType,
//     this.validator,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RichText(
//           text: TextSpan(
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//             children: [
//               TextSpan(text: label),
//               if (validator != null)
//                 const TextSpan(text:   * , style: TextStyle(color: Colors.red)),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           maxLines: maxLines,
//           keyboardType: keyboardType,
//           validator: validator,
//           decoration: InputDecoration(
//             hintText: hint,
//             prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
//             suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.blue, width: 2),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.red, width: 2),
//             ),
//             focusedErrorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.red, width: 2),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ============================================
// // AccountSection - Reusable Account Form Section
// // ============================================

// class AccountSection extends StatelessWidget {
//   final String title;
//   final Color color;
//   final List<String> accounts;
//   final List<String> currencies;
//   final String? selectedAccount;
//   final String? selectedCurrency;
//   final TextEditingController amountController;
//   final ValueChanged<String?> onAccountChanged;
//   final ValueChanged<String?> onCurrencyChanged;

//   const AccountSection({
//     Key? key,
//     required this.title,
//     required this.color,
//     required this.accounts,
//     required this.currencies,
//     required this.selectedAccount,
//     required this.selectedCurrency,
//     required this.amountController,
//     required this.onAccountChanged,
//     required this.onCurrencyChanged,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade200, width: 2),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildDropdownField(
//             label:  الحساب ,
//             value: selectedAccount,
//             items: accounts,
//             onChanged: onAccountChanged,
//           ),
//           const SizedBox(height: 16),
//           _buildDropdownField(
//             label:  العملة ,
//             value: selectedCurrency,
//             items: currencies,
//             onChanged: onCurrencyChanged,
//           ),
//           const SizedBox(height: 16),
//           _buildAmountField(),
//         ],
//       ),
//     );
//   }

//   Widget _buildDropdownField({
//     required String label,
//     required String? value,
//     required List<String> items,
//     required ValueChanged<String?> onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RichText(
//           text: TextSpan(
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//             children: [
//               TextSpan(text: label),
//               const TextSpan(text:   * , style: TextStyle(color: Colors.red)),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border.all(color: Colors.grey.shade300, width: 2),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: value,
//               isExpanded: true,
//               hint: Text( اختر $label ),
//               icon: const Icon(Icons.keyboard_arrow_down),
//               items: items.map((String item) {
//                 return DropdownMenuItem<String>(
//                   value: item,
//                   child: Text(item),
//                 );
//               }).toList(),
//               onChanged: onChanged,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAmountField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RichText(
//           text: const TextSpan(
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//             children: [
//               TextSpan(text:  المبلغ ),
//               TextSpan(text:   * , style: TextStyle(color: Colors.red)),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: amountController,
//           keyboardType: const TextInputType.numberWithOptions(decimal: true),
//           decoration: InputDecoration(
//             hintText:  0.00 ,
//             suffixIcon: Icon(Icons.calculate, color: color),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: color, width: 2),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ============================================
// // AppButton - Reusable Button
// // ============================================

// class AppButton extends StatelessWidget {
//   final String text;
//   final VoidCallback onPressed;
//   final Color? backgroundColor;
//   final Color? textColor;
//   final IconData? icon;
//   final bool isLoading;

//   const AppButton({
//     Key? key,
//     required this.text,
//     required this.onPressed,
//     this.backgroundColor,
//     this.textColor,
//     this.icon,
//     this.isLoading = false,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: ElevatedButton(
//         onPressed: isLoading ? null : onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: backgroundColor ?? Colors.blue,
//           foregroundColor: textColor ?? Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: 4,
//         ),
//         child: isLoading
//             ? const SizedBox(
//                 width: 24,
//                 height: 24,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                 ),
//               )
//             : Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   if (icon != null) ...[
//                     Icon(icon, size: 20),
//                     const SizedBox(width: 8),
//                   ],
//                   Text(
//                     text,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }
// }

// // ============================================
// // EmptyStateWidget - Empty State Display
// // ============================================

// class EmptyStateWidget extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final VoidCallback? onAction;
//   final String? actionText;

//   const EmptyStateWidget({
//     Key? key,
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     this.onAction,
//     this.actionText,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 icon,
//                 size: 60,
//                 color: Colors.grey.shade400,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               subtitle,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey.shade600,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             if (onAction != null && actionText != null) ...[
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: onAction,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: Text(
//                   actionText!,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ============================================
// // LoadingWidget - Loading Indicator
// // ============================================

// class LoadingWidget extends StatelessWidget {
//   final String? message;

//   const LoadingWidget({Key? key, this.message}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(),
//           if (message != null) ...[
//             const SizedBox(height: 16),
//             Text(
//               message!,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// // ============================================
// // AppCard - Reusable Card Widget
// // ============================================

// class AppCard extends StatelessWidget {
//   final Widget child;
//   final EdgeInsetsGeometry? padding;
//   final EdgeInsetsGeometry? margin;
//   final Color? color;
//   final VoidCallback? onTap;

//   const AppCard({
//     Key? key,
//     required this.child,
//     this.padding,
//     this.margin,
//     this.color,
//     this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: color ?? Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(16),
//           child: Padding(
//             padding: padding ?? const EdgeInsets.all(16),
//             child: child,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ============================================
// // AppBadge - Badge Widget
// // ============================================

// class AppBadge extends StatelessWidget {
//   final String text;
//   final Color color;
//   final IconData? icon;

//   const AppBadge({
//     Key? key,
//     required this.text,
//     required this.color,
//     this.icon,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (icon != null) ...[
//             Icon(icon, size: 14, color: color),
//             const SizedBox(width: 6),
//           ],
//           Text(
//             text,
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ============================================
// // Constants and Theme
// // ============================================

// class AppColors {
//   static const Color primary = Color(0xFF2196F3);
//   static const Color secondary = Color(0xFF3F51B5);
//   static const Color success = Color(0xFF4CAF50);
//   static const Color warning = Color(0xFFFF9800);
//   static const Color error = Color(0xFFF44336);
//   static const Color background = Color(0xFFF8FAFC);
// }

// class AppConstants {
//   static const double borderRadius = 12.0;
//   static const double cardElevation = 4.0;
//   static const EdgeInsets cardPadding = EdgeInsets.all(16);
//   static const EdgeInsets screenPadding = EdgeInsets.all(16);
// }

// // ============================================
// // END OF PART 3
// // This completes the Flutter Transaction App
// // ============================================
