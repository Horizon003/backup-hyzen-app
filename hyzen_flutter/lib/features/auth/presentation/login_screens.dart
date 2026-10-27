import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/surfaces.dart';

/// Shared scaffold for auth forms: persistent top bar with Back, keyboard-safe scroll.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: HTopBar(title: title, subtitle: subtitle, onBack: onBack),
      body: HBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            padding: const EdgeInsets.fromLTRB(
              HSpace.screen,
              HSpace.md,
              HSpace.screen,
              HSpace.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.autofill = AutofillHints.password,
    this.focusNode,
    this.helper,
  });
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String autofill;
  final FocusNode? focusNode;
  final String? helper;
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: [widget.autofill],
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pwFocus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return; // prevent duplicate submissions
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    if (!ref.read(firebaseReadyProvider)) {
      setState(
        () => _error =
            'Can\u2019t reach PHARM D WITH HYZEN right now. Please check your connection.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(_email.text, _pw.text);
      TextInput.finishAutofillContext();
      // Router redirect handles navigation on auth change.
    } on FriendlyException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AuthScaffold(
      title: 'Log in',
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HSpace.lg),
              const Center(child: HyzenLogo(size: 64)),
              const SizedBox(height: HSpace.lg),
              Text(
                'Welcome back',
                style: t.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Log in to continue your Pharm-D journey.',
                style: t.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HSpace.xl),
              if (_error != null) ...[
                _ErrorBanner(message: _error!),
                const SizedBox(height: HSpace.md),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.email,
                  AutofillHints.username,
                ],
                autocorrect: false,
                validator: Validators.email,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onFieldSubmitted: (_) => _pwFocus.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: HSpace.md),
              PasswordField(
                controller: _pw,
                focusNode: _pwFocus,
                validator: Validators.loginPassword,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(
                    '/forgot-password',
                    extra: _email.text.trim(),
                  ),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: HSpace.xs),
              HButton(label: 'Log in', loading: _busy, onPressed: _submit),
              const SizedBox(height: HSpace.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New to PHARM D WITH HYZEN?', style: t.textTheme.bodyMedium),
                  TextButton(
                    onPressed: () =>
                        context.pushReplacement('/register/personal'),
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(HSpace.sm),
        decoration: BoxDecoration(
          color: HColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(HRadius.md),
          border: Border.all(color: HColors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: HColors.error),
            const SizedBox(width: HSpace.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: HColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});
  final String? initialEmail;
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on FriendlyException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = AuthErrorMapper.message('unknown'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AuthScaffold(
      title: 'Reset password',
      child: AnimatedSwitcher(
        duration: HMotion.medium,
        child: _sent
            ? Column(
                key: const ValueKey('sent'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: HSpace.xxl),
                  const Center(
                    child: IconBadge(
                      icon: Icons.mark_email_read_rounded,
                      color: HColors.primary,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: HSpace.lg),
                  Text(
                    'Check your inbox',
                    style: t.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: HSpace.xs),
                  Text(
                    'If an account exists for ${_email.text.trim()}, you\u2019ll receive a link to reset your password. Check spam if you don\u2019t see it.',
                    style: t.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: HSpace.xl),
                  HButton(
                    label: 'Back to log in',
                    onPressed: () => context.pop(),
                  ),
                ],
              )
            : Form(
                key: _form,
                child: Column(
                  key: const ValueKey('form'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: HSpace.xl),
                    Text(
                      'Forgot your password?',
                      style: t.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: HSpace.xs),
                    Text(
                      'Enter the email you used for PHARM D WITH HYZEN and we\u2019ll send you a reset link.',
                      style: t.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: HSpace.xl),
                    if (_error != null) ...[
                      _ErrorBanner(message: _error!),
                      const SizedBox(height: HSpace.md),
                    ],
                    SurfacePanel(
                      radius: HRadius.lg,
                      padding: const EdgeInsets.all(HSpace.md),
                      child: TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.send,
                        onFieldSubmitted: (_) => _send(),
                        validator: Validators.email,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: HSpace.lg),
                    HButton(
                      label: 'Send reset link',
                      loading: _busy,
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
