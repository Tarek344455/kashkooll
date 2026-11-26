import 'package:flutter/material.dart';
import '../core/models/kashkool_models.dart';
import '../state/kashkool_controller.dart';
import '../ui/space_glass.dart';

class LoginScreen extends StatefulWidget {
  final KashkoolController controller;

  const LoginScreen({super.key, required this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _useCode = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);
    final ok = _useCode
        ? widget.controller.signInWithCode(_codeCtrl.text)
        : widget.controller.signInWithPassword(_emailCtrl.text, _passCtrl.text);
    if (!ok) {
      setState(() => _error = widget.controller.tr('err_invalid_credentials'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [
                                  KashkoolColors.neonCyan,
                                  Color(0xFF0284C7),
                                ],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'ك',
                              style: TextStyle(
                                color: KashkoolColors.cosmicBlack,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text(
                                c.tr('app_title'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: KashkoolColors.textPrimary,
                                ),
                              ),
                              Text(
                                c.tr('zero_cost_badge'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: KashkoolColors.textSecondary,
                                ),
                              ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                      OutlinedButton.icon(
                        onPressed: c.toggleLanguage,
                        icon: const Icon(Icons.language, size: 16),
                        label: Text(
                          c.language == AppLanguage.ar ? 'English' : 'العربية',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    c.tr('welcome'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: KashkoolColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.tr('subtitle_cosmic'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: KashkoolColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ZeroGravityCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: Text(c.tr('email_label')),
                                selected: !_useCode,
                                onSelected: (_) =>
                                    setState(() => _useCode = false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: Text(c.tr('qr_code_label')),
                                selected: _useCode,
                                onSelected: (_) =>
                                    setState(() => _useCode = true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!_useCode) ...[
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: c.tr('email_label'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: c.tr('password_label'),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                          ),
                        ] else
                          TextField(
                            controller: _codeCtrl,
                            decoration: InputDecoration(
                              labelText: c.tr('qr_code_label'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: KashkoolColors.crimsonBlocked,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SpaceButton(
                          label: _useCode ? c.tr('activate_qr') : c.tr('sign_in'),
                          icon: Icons.lock_open,
                          onPressed: _submit,
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
