// import 'package:flutter/material.dart';
// import '../../../domain/entities/account_entity.dart';

// class AccountLimitCard extends StatelessWidget {
//   final AccountEntity account;
//   final Function(double) onUpdateLimit;

//   const AccountLimitCard({
//     super.key,
//     required this.account,
//     required this.onUpdateLimit,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final usedCredit = account.balance?.abs() ?? 0;
//     final creditLimit = account.creditLimit ?? 0;
//     final availableCredit = creditLimit - usedCredit;
//     final usagePercentage = creditLimit > 0 ? (usedCredit / creditLimit) : 0.0;

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppRadius.md),
//       ),
//       child: InkWell(
//         onTap: () => _showEditDialog(context),
//         borderRadius: BorderRadius.circular(AppRadius.md),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           account.name,
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'كود: ${account.code}',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(usagePercentage).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(AppRadius.lg20),
//                       border: Border.all(
//                         color: _getStatusColor(usagePercentage),
//                         width: 1,
//                       ),
//                     ),
//                     child: Text(
//                       '${(usagePercentage * 100).toStringAsFixed(1)}%',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: _getStatusColor(usagePercentage),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'الحد الائتماني',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           '${creditLimit.toStringAsFixed(2)} ر.س',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'المستخدم',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           '${usedCredit.toStringAsFixed(2)} ر.س',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: _getStatusColor(usagePercentage),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'المتاح',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           '${availableCredit.toStringAsFixed(2)} ر.س',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(AppRadius.xs),
//                 child: LinearProgressIndicator(
//                   value: usagePercentage.clamp(0.0, 1.0),
//                   backgroundColor: Colors.grey[300],
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     _getStatusColor(usagePercentage),
//                   ),
//                   minHeight: 8,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(double percentage) {
//     if (percentage >= 0.9) {
//       return Colors.red;
//     } else if (percentage >= 0.7) {
//       return Colors.orange;
//     } else if (percentage >= 0.5) {
//       return Colors.amber;
//     } else {
//       return Colors.green;
//     }
//   }

//   void _showEditDialog(BuildContext context) {
//     final controller = TextEditingController(
//       text: account.creditLimit?.toStringAsFixed(2) ?? '0.00',
//     );

//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return CustomDialog(
//           title: Text('تعديل حد ${account.name}'),
//           content:TextInputField(
//             controller: controller,
//             keyboardType: const TextInputType.numberWithOptions(decimal: true),
//             decoration: InputDecoration(
//               labelText: 'الحد الائتماني الجديد',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(AppRadius.sm),
//               ),
//               prefixIcon: const Icon(Icons.attach_money),
//               suffixText: 'ر.س',
//             ),
//             autofocus: true,
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(dialogContext).pop(),
//               child: const Text('إلغاء'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 final newLimit = double.tryParse(controller.text);
//                 if (newLimit != null && newLimit >= 0) {
//                   onUpdateLimit(newLimit);
//                   Navigator.of(dialogContext).pop();
//                 }
//               },
//               child: const Text('حفظ'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
