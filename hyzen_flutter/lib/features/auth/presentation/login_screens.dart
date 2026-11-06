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
  bool _showForm = false;
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
    if (!_showForm) {
      return AccountChoiceScreen(
        onLogin: () => setState(() => _showForm = true),
      );
    }
    final heroHeight = (MediaQuery.sizeOf(context).height * .32).clamp(
      220.0,
      310.0,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: t.colorScheme.surface,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Stack(
                children: [
                  SizedBox(
                    height: heroHeight + 32,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/auth/login_panda.webp',
                      key: const ValueKey('login-panda-hero'),
                      fit: BoxFit.cover,
                      semanticLabel:
                          'Hyzen panda welcoming you to the pharmacy library',
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Material(
                              color: Colors.white.withValues(alpha: .95),
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: 'Back',
                                color: Colors.black,
                                icon: const Icon(Icons.arrow_back_rounded),
                                onPressed: () => setState(() {
                                  _showForm = false;
                                  _error = null;
                                  _pw.clear();
                                }),
                              ),
                            ),
                            const Spacer(),
                            const HyzenBrandIcon(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: heroHeight),
                    child: Container(
                      key: const ValueKey('login-form-panel'),
                      decoration: BoxDecoration(
                        color: t.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: SafeArea(
                        top: false,
                        child: Form(
                          key: _form,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Welcome to PHARM D WITH HYZEN',
                                  style: t.textTheme.headlineSmall?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Log in to continue your Pharm-D journey.',
                                  style: t.textTheme.bodyMedium?.copyWith(
                                    color: t.colorScheme.onSurfaceVariant,
                                  ),
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
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  onFieldSubmitted: (_) =>
                                      _pwFocus.requestFocus(),
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                    ),
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
                                HButton(
                                  label: 'Log in',
                                  loading: _busy,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: HSpace.lg),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'New to PHARM D WITH HYZEN?',
                                      style: t.textTheme.bodyMedium,
                                    ),
                                    TextButton(
                                      onPressed: () => context.pushReplacement(
                                        '/register/personal',
                                      ),
                                      child: const Text('Create account'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

class AccountChoiceScreen extends StatelessWidget {
  const AccountChoiceScreen({super.key, required this.onLogin});
  final VoidCallback onLogin;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/auth/login_panda.webp',
                    height: 210,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to PHARM D WITH HYZEN',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to continue.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onLogin,
                  child: const Text('Already a user? Log in'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push('/register/personal'),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
