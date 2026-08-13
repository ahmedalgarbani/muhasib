import 'package:flutter/material.dart';
import 'package:muhasib/core/widgets/hasib_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/route_names.dart';
import 'package:muhasib/core/helpers/buildsnackbar.dart';
import 'package:muhasib/features/initial/presentation/cubit/initial_cubit.dart';
import 'package:muhasib/features/initial/presentation/cubit/initial_state.dart';

class InitialGatePage extends StatefulWidget {
  const InitialGatePage({super.key});

  @override
  State<InitialGatePage> createState() => _InitialGatePageState();
}

class _InitialGatePageState extends State<InitialGatePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndRedirect());
  }

  bool _hasNavigated = false;

  Future<void> _checkAndRedirect() async {
    if (!mounted) return;
    context.read<InitialCubit>().checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InitialCubit, InitialState>(
      listener: (context, state) {
        if (state is InitialLoaded && !_hasNavigated) {
          _hasNavigated = true;
          if (state.isComplete) {
            context.go(AppRoutes.home);
          } else {
            context.go(AppRoutes.initialSetup);
          }
        }
        if (state is InitialError) {
          AppToast.showError(context, state.message);
        }
      },
      child: Scaffold(
        body: BlocBuilder<InitialCubit, InitialState>(
          builder: (context, state) {
            if (state is InitialError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      HasibButton(
                        label: 'حاولة مجدداً',
                        onPressed: () =>
                            context.read<InitialCubit>().checkStatus(),
                        variant: HasibButtonVariant.primary,
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
