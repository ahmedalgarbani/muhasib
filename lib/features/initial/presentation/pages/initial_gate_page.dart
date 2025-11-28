import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muhasib/core/route/route_names.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
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
                      ElevatedButton(
                        onPressed: () =>
                            context.read<InitialCubit>().checkStatus(),
                        child: const Text('حاولة مجدداً'),
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
