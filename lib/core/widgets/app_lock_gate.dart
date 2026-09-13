import 'package:flutter/material.dart';
import 'package:muhasib/core/services/settings_cache.dart';
import 'package:muhasib/core/theme/app_spacing.dart';

/// Global lock state so app-level services (e.g. exit reminder) can check
/// whether the lock screen is currently blocking the UI.
class AppLockState {
  static final ValueNotifier<bool> locked = ValueNotifier<bool>(false);
}

/// Wraps the app content and enforces the password lock configured in
/// settings (`security_info.isActive` + `security_info.password`).
///
/// The app locks on cold start and whenever it is sent to the background.
/// Content stays mounted underneath an opaque lock screen so navigation
/// state is preserved while interaction is blocked.
class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setLocked(_securityEnabled);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _securityEnabled {
    final password = SettingsCache.securityPassword;
    return SettingsCache.securityIsActive &&
        password != null &&
        password.isNotEmpty;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _securityEnabled && !_locked) {
      _setLocked(true);
    }
  }

  void _setLocked(bool value) {
    AppLockState.locked.value = value;
    if (mounted) {
      setState(() => _locked = value);
    } else {
      _locked = value;
    }
  }

  void _unlock() {
    _setLocked(false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ExcludeFocus(
          excluding: _locked,
          child: AbsorbPointer(absorbing: _locked, child: widget.child),
        ),
        if (_locked)
          Positioned.fill(
            child: AppLockScreen(onUnlocked: _unlock),
          ),
      ],
    );
  }
}

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _tryUnlock() {
    final password = SettingsCache.securityPassword;
    if (password != null && _controller.text == password) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _error = 'كلمة المرور غير صحيحة';
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 46,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'التطبيق مقفل',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'أدخل كلمة المرور للمتابعة',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _tryUnlock(),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'كلمة المرور',
                      errorText: _error,
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _tryUnlock,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('دخول'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
