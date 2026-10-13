// =============================================================================
// FILE: lib/features/auth/presentation/pages/login_page.dart
// LAYER: Presentation Layer
// RESPONSIBILITY: Unified Login & Registration Screen with Google OAuth.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:findway_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  // Цветовая палитра FindWay
  final Color _bgDark = const Color(0xFF0F172A);
  final Color _cardDark = const Color(0xFF1E293B);
  final Color _accentCyan = const Color(0xFF00F2FF);
  final Color _accentOrange = const Color(0xFFFF8A00);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isSignUp) {
        // TODO: Регистрация по email (если требуется отдельное событие)
        context.read<AuthBloc>().add(LoginSubmitted(email, password));
      } else {
        context.read<AuthBloc>().add(LoginSubmitted(email, password));
      }
    }
  }

  void _submitGoogleLogin() {
    debugPrint('>>> [UI] Google Sign-In button clicked');
    context.read<AuthBloc>().add(GoogleLoginSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- ЛОГОТИП / ЗАГОЛОВОК ---
                      Text(
                        'FINDWAY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _accentCyan,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUp ? 'Створення нового акаунту' : 'Вхід у систему',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),

                      const SizedBox(height: 36),

                      // --- КНОПКА GOOGLE SIGN-IN ---
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _submitGoogleLogin,
                        icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.white),
                        label: Text(
                          _isSignUp ? 'Зареєструватися через Google' : 'Увійти через Google',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: _accentCyan.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- РАЗДЕЛИТЕЛЬ ---
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'або за допомогою email',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- ПОЛЕ USERNAME (Только для регистрации) ---
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Ім\'я користувача', Icons.person_outline),
                          validator: (v) => _isSignUp && (v == null || v.trim().isEmpty)
                              ? 'Введіть ім\'я'
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // --- ПОЛЕ EMAIL ---
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Email', Icons.email_outlined),
                        validator: (v) => v == null || !v.contains('@') ? 'Введіть коректний email' : null,
                      ),

                      const SizedBox(height: 16),

                      // --- ПОЛЕ PASSWORD ---
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Пароль', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'Пароль має бути від 6 символів' : null,
                      ),

                      const SizedBox(height: 28),

                      // --- КНОПКА ОТПРАВКИ ФОРМЫ ---
                      ElevatedButton(
                        onPressed: isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : Text(
                                _isSignUp ? 'ЗАРЕЄСТРУВАТИСЯ' : 'УВІЙТИ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),

                      const SizedBox(height: 20),

                      // --- ПЕРЕКЛЮЧАТЕЛЬ: ВХОД / РЕГИСТРАЦИЯ ---
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            _formKey.currentState?.reset();
                          });
                        },
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            children: [
                              TextSpan(
                                text: _isSignUp
                                    ? 'Вже є акаунт? '
                                    : 'Ще немає акаунту? ',
                              ),
                              TextSpan(
                                text: _isSignUp ? 'Увійти' : 'Зареєструватися',
                                style: TextStyle(
                                  color: _accentCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      prefixIcon: Icon(icon, color: _accentCyan, size: 20),
      filled: true,
      fillColor: _cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}