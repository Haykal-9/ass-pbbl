import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/app_user.dart';
import '../services/app_locale.dart';
import '../services/database_helper.dart';
import '../services/session_service.dart';
import '../widgets/custom_snackbar.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _db = DatabaseHelper();
  final _session = SessionService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final username = _usernameCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text.trim();

    if (_isLogin) {
      final user = await _db.getAppUserByCredentials(username, password);
      if (!mounted) return;
      if (user == null || user.id == null) {
        setState(() => _isLoading = false);
        showErrorSnackbar(context, 'Username atau password salah');
        return;
      }
      await _session.setCurrentUserId(user.id!);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      return;
    }

    final existing = await _db.getAppUserByUsername(username);
    if (existing != null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackbar(context, 'Username sudah dipakai');
      return;
    }

    final newUser = AppUser(
      displayName: _nameCtrl.text.trim(),
      username: username,
      password: password,
      bio: _bioCtrl.text.trim().isEmpty ? 'New WanderList user' : _bioCtrl.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    final id = await _db.insertAppUser(newUser);
    await _session.setCurrentUserId(id);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.16),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label: 'WanderList',
                            child: SizedBox(
                              width: 180,
                              height: 54,
                              child: SvgPicture.asset(
                                'wanderlist-logo-horizontal-transparent.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin ? 'Masuk untuk melanjutkan' : 'Buat akun lokal untuk memulai',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.65)),
                          ),
                          const SizedBox(height: 24),
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(labelText: 'Nama lengkap', border: OutlineInputBorder()),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib diisi' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                tooltip: _obscurePassword ? 'Tampilkan password' : 'Sembunyikan password',
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().length < 4) ? 'Password minimal 4 karakter' : null,
                          ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bioCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_isLogin ? 'Masuk' : 'Daftar'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _isLogin = !_isLogin);
                            },
                            child: Text(_isLogin ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Masuk'),
                          ),
                          if (_isLogin) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                _usernameCtrl.text = 'wander_admin';
                                _passwordCtrl.text = 'wander123';
                              },
                              child: const Text('Isi akun demo'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}