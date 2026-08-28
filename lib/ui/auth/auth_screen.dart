import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../widgets.dart';

/// Вход (по мотивам Android-флоу): signIn / signUp + код подтверждения.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _login = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _signUp = false;
  bool _needCode = false;
  String? _hash;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 24),
            Row(children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.maybePop(context)),
            ]),
            const SizedBox(height: 12),
            Text(_signUp ? 'Регистрация' : 'Вход',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            _field('Логин', _login),
            if (_signUp) ...[
              const SizedBox(height: 12),
              _field('Email', _email),
            ],
            const SizedBox(height: 12),
            _field('Пароль', _password, obscure: true),
            if (_needCode) ...[
              const SizedBox(height: 12),
              _field('Код из письма', _code),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: AppColors.badgeNew, fontSize: 13.5)),
            ],
            const SizedBox(height: 20),
            LightPillButton(
              label: _needCode ? 'Подтвердить' : (_signUp ? 'Зарегистрироваться' : 'Войти'),
              loading: _loading,
              onTap: _submit,
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => setState(() { _signUp = !_signUp; _needCode = false; _error = null; }),
                child: Text(_signUp ? 'Уже есть аккаунт — войти' : 'Создать аккаунт',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController c, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_needCode) {
        final p = await Api.I.verify(_login.text, _email.text, _password.text, _hash ?? '', _code.text);
        if (p != null) await _saveProfileId(p.id);
        if (mounted) Navigator.pop(context, true);
      } else if (_signUp) {
        final hash = await Api.I.signUp(_login.text, _email.text, _password.text);
        setState(() { _needCode = true; _hash = hash; });
      } else {
        final p = await Api.I.signIn(_login.text, _password.text);
        if (p != null) await _saveProfileId(p.id);
        if (mounted) Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfileId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('my_profile_id', id);
  }
}
