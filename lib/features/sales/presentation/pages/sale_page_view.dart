import 'package:flutter/material.dart';
import 'package:muhasib/features/sales/presentation/widgets/sale_page_body.dart';

class SalePageView extends StatelessWidget {
  const SalePageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: SalePageBody()));
  }
}
