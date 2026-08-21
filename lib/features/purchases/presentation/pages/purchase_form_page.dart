import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:muhasib/core/constant/app_constant.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/core/helpers/get_it.dart';
import 'package:muhasib/core/theme/app_color.dart';
import 'package:muhasib/core/widgets/custom_app_bar.dart';
import 'package:muhasib/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:muhasib/features/purchases/presentation/cubit/purchases_cubit.dart';
import 'package:muhasib/features/purchases/presentation/pages/purchase_line_editor_page.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_form_header.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_form_info_card.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_form_products_card.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_form_supplier_warehouse_card.dart';
import 'package:muhasib/features/purchases/presentation/widgets/purchase_form_totals_and_notes.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_entity.dart';
import 'package:muhasib/features/sales/domain/entities/invoice_line_entity.dart';
import 'package:muhasib/features/stores/presentation/cubit/warehouses_cubit.dart';

part 'purchase_form_widgets.dart';

class PurchaseFormPage extends StatefulWidget {
  final InvoiceEntity? invoice;
  final int invoiceType;

  const PurchaseFormPage({super.key, this.invoice, this.invoiceType = 2});

  @override
  State<PurchaseFormPage> createState() => _PurchaseFormPageState();
}
