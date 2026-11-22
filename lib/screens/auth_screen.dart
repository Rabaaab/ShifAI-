import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' show ClientException;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../theme/ds.dart';
import '../widgets/ds_widgets.dart';

enum AuthStart { signIn, createAccount }

enum _AuthMode { signIn, createAccount, forgotPassword, verifyEmail }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.start = AuthStart.signIn});

  final AuthStart start;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late _AuthMode _mode;
  String? _message;
  bool _acceptedTerms = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.start == AuthStart.createAccount
        ? _AuthMode.createAccount
        : _AuthMode.signIn;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _changeMode(_AuthMode mode, {String? message}) {
    setState(() {
      _mode = mode;
      _message = message;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  static String get _offline =>
      'Could not reach Supabase. Check your connection and try again.'.tr;
  static String get _timedOut =>
      'The request timed out. Check your connection and try again.'.tr;

  Future<void> _submit() async {
    if (_mode == _AuthMode.verifyEmail) {
      await _resendVerification();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() => _message = null);
    if (!auth.isConfigured) {
      setState(() => _message = SupabaseConfig.configurationError);
      return;
    }

    try {
      switch (_mode) {
        case _AuthMode.signIn:
          await auth.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
          if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          break;
        case _AuthMode.createAccount:
          if (!_acceptedTerms) {
            setState(
              () => _message = 'Review and accept the privacy and health-use notices to continue.'
                  .tr,
            );
            return;
          }
          final response = await auth.signUp(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
          if (response.session == null && mounted) {
            _changeMode(
              _AuthMode.verifyEmail,
              message: 'Check your email for the Supabase verification link before signing in.'
                  .tr,
            );
          } else if (mounted) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
          break;
        case _AuthMode.forgotPassword:
          await auth.sendPasswordReset(_emailController.text);
          if (mounted) {
            setState(
              () => _message = 'If an account exists for this address, a password reset link has been sent.'
                  .tr,
            );
          }
          break;
        case _AuthMode.verifyEmail:
          break;
      }
    } on AuthRetryableFetchException {
      if (mounted) setState(() => _message = _offline);
    } on TimeoutException {
      if (mounted) setState(() => _message = _timedOut);
    } on AuthApiException catch (error) {
      if (!mounted) return;
      if (_mode == _AuthMode.signIn &&
          (error.code == 'email_not_confirmed' ||
              error.message.toLowerCase().contains('email not confirmed'))) {
        _changeMode(
          _AuthMode.verifyEmail,
          message: 'Verify your email before signing in. You can request a new verification link below.'
              .tr,
        );
      } else if (_mode == _AuthMode.signIn &&
          (error.code == 'invalid_credentials' ||
              error.message.toLowerCase().contains(
                'invalid login credentials',
              ))) {
        setState(() => _message = 'The email or password is incorrect.'.tr);
      } else {
        setState(() => _message = error.message);
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on ClientException {
      if (mounted) setState(() => _message = _offline);
    }
  }

  Future<void> _resendVerification() async {
    final auth = context.read<AuthProvider>();
    setState(() => _message = null);
    if (!auth.isConfigured) {
      setState(() => _message = SupabaseConfig.configurationError);
      return;
    }
    try {
      await auth.resendVerification(_emailController.text);
      if (mounted) {
        setState(
          () => _message = 'A new verification email has been requested.'.tr,
        );
      }
    } on AuthRetryableFetchException {
      if (mounted) setState(() => _message = _offline);
    } on TimeoutException {
      if (mounted) setState(() => _message = _timedOut);
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on ClientException {
      if (mounted) setState(() => _message = _offline);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.'.tr;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 8) return 'Use at least 8 characters.'.tr;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isCreate = _mode == _AuthMode.createAccount;
    final isReset = _mode == _AuthMode.forgotPassword;
    final isVerify = _mode == _AuthMode.verifyEmail;

    final title = isVerify
        ? const DsTitle('Verify your', 'email')
        : isReset
        ? const DsTitle('Reset your', 'password')
        : isCreate
        ? const DsTitle('Create', 'account')
        : const DsTitle('Welcome', 'back');

    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
                      children: [
                        Row(
                          children: [
                            DsBackButton(
                              onPressed: () {
                                if (_mode == _AuthMode.forgotPassword ||
                                    _mode == _AuthMode.verifyEmail) {
                                  _changeMode(_AuthMode.signIn);
                                } else {
                                  Navigator.of(context).maybePop();
                                }
                              },
                            ),
                            Expanded(
                              child: Center(
                                child: Image.asset(
                                  'assets/images/shifai_logo.png',
                                  width: 132,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'ShifAI',
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Align(alignment: Alignment.centerLeft, child: title),
                        if (isVerify) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Follow the link sent to {text}.'.trf({
                              'text': _emailController.text,
                            }),
                            style: DS.text(color: DS.muted, height: 1.5),
                          ),
                        ],
                        const SizedBox(height: 32),
                        if (!isVerify)
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (isCreate) ...[
                                  DsTextField(
                                    key: const Key('auth-name'),
                                    controller: _nameController,
                                    icon: Icons.person_outline_rounded,
                                    label: 'First name'.tr,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    validator: (value) =>
                                        (value?.trim().isEmpty ?? true)
                                        ? 'Enter your name.'.tr
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                DsTextField(
                                  key: const Key('auth-email'),
                                  controller: _emailController,
                                  icon: Icons.mail_outline_rounded,
                                  label: 'Email'.tr,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  validator: _validateEmail,
                                ),
                                if (!isReset) ...[
                                  const SizedBox(height: 14),
                                  DsTextField(
                                    key: const Key('auth-password'),
                                    controller: _passwordController,
                                    icon: Icons.lock_outline_rounded,
                                    label: 'Password'.tr,
                                    obscure: !_passwordVisible,
                                    autofillHints: isCreate
                                        ? const [AutofillHints.newPassword]
                                        : const [AutofillHints.password],
                                    validator: isCreate
                                        ? _validatePassword
                                        : null,
                                    trailing: IconButton(
                                      tooltip: _passwordVisible
                                          ? 'Hide password'.tr
                                          : 'Show password'.tr,
                                      onPressed: () => setState(
                                        () => _passwordVisible =
                                            !_passwordVisible,
                                      ),
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: DS.iconMuted,
                                      ),
                                    ),
                                  ),
                                ],
                                if (isCreate) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        'Use at least 8 characters.'.tr,
                                        style: DS.text(
                                          size: 14,
                                          color: DS.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _TermsRow(
                                    accepted: _acceptedTerms,
                                    onChanged: (v) =>
                                        setState(() => _acceptedTerms = v),
                                  ),
                                ],
                                if (_mode == _AuthMode.signIn)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: DsTextAction(
                                      'Forgot password?'.tr,
                                      alignment: Alignment.centerRight,
                                      onPressed: () =>
                                          _changeMode(_AuthMode.forgotPassword),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        if (_message != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: DS.skyTint,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              _message!,
                              style: DS.text(
                                size: 14,
                                weight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                    child: Column(
                      children: [
                        DsPrimaryButton(
                          label: isVerify
                              ? 'Resend verification email'.tr
                              : isReset
                              ? 'Send reset link'.tr
                              : isCreate
                              ? 'Create account'.tr
                              : 'Sign in'.tr,
                          loading: auth.busy,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _changeMode(
                            isCreate
                                ? _AuthMode.signIn
                                : _AuthMode.createAccount,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 52),
                            alignment: Alignment.center,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: isCreate
                                        ? 'Already a member? '.tr
                                        : 'New here? '.tr,
                                    style: DS.text(
                                      size: 15.5,
                                      weight: FontWeight.w600,
                                      color: DS.muted,
                                    ),
                                  ),
                                  TextSpan(
                                    text: isCreate
                                        ? 'Sign in'.tr
                                        : 'Create account'.tr,
                                    style: DS.text(
                                      size: 15.5,
                                      weight: FontWeight.w800,
                                      color: DS.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.accepted, required this.onChanged});
  final bool accepted;
  final ValueChanged<bool> onChanged;

  void _notice(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: DS.text(weight: FontWeight.w800)),
        content: Text(body, style: DS.text(size: 15, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final link = DS
        .text(size: 14, weight: FontWeight.w700, color: DS.navy)
        .copyWith(decoration: TextDecoration.underline);
    final plain = DS.text(size: 14, color: DS.muted);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: accepted,
          activeColor: DS.navy,
          onChanged: (v) => onChanged(v ?? false),
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('I accept the '.tr, style: plain),
              GestureDetector(
                onTap: () => _notice(
                  context,
                  'Privacy notice'.tr,
                  'ShifAI stores your account profile and confirmed lab values '
                          'in your configured Supabase project. Row-Level Security '
                          'is required on every user table. OCR runs on-device; '
                          'report images are not uploaded. Do not enter data until '
                          'your project and policies have been reviewed.'
                      .tr,
                ),
                child: Text('privacy notice'.tr, style: link),
              ),
              Text(' and '.tr, style: plain),
              GestureDetector(
                onTap: () => _notice(
                  context,
                  'Terms of use'.tr,
                  'ShifAI is a screening and awareness tool, not a diagnostic '
                          'device or a substitute for professional medical advice. '
                          'Confirm results and treatment decisions with a licensed '
                          'clinician.'
                      .tr,
                ),
                child: Text('terms of use'.tr, style: link),
              ),
              Text('.', style: plain),
            ],
          ),
        ),
      ],
    );
  }
}

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_passwordController.text.length < 8 ||
        _passwordController.text != _confirmController.text) {
      setState(
        () => _message =
            'Use at least 8 characters and make sure both passwords match.'.tr,
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await context.read<AuthProvider>().updatePassword(
        _passwordController.text,
      );
    } on AuthRetryableFetchException {
      if (mounted) setState(() => _message = _AuthScreenState._offline);
    } on TimeoutException {
      if (mounted) setState(() => _message = _AuthScreenState._timedOut);
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on ClientException {
      if (mounted) setState(() => _message = _AuthScreenState._offline);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DsBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
            children: [
              const DsTitle('Choose a', 'new password'),
              const SizedBox(height: 32),
              DsTextField(
                controller: _passwordController,
                icon: Icons.lock_outline_rounded,
                label: 'New password'.tr,
                obscure: true,
              ),
              const SizedBox(height: 14),
              DsTextField(
                controller: _confirmController,
                icon: Icons.lock_reset_rounded,
                label: 'Confirm password'.tr,
                obscure: true,
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, style: DS.text(size: 14, color: DS.redText)),
              ],
              const SizedBox(height: 24),
              DsPrimaryButton(
                label: 'Update password'.tr,
                loading: _busy,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
