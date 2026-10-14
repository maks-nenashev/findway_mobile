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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- ЛОГОТИП FINDWAY (assets/images/findway_logo.png) ---
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _cardDark,
                            boxShadow: [
                              BoxShadow(
                                color: _accentCyan.withValues(alpha: 0.35),
                                blurRadius: 24,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/findway_logo.png',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/logo.png',
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: _accentCyan.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _accentCyan, width: 2),
                                      ),
                                      child: Icon(
                                        Icons.radar_rounded,
                                        size: 44,
                                        color: _accentCyan,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- ЗАГОЛОВОК FINDWAY ---
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
                      const SizedBox(height: 6),
                      Text(
                        _isSignUp ? 'Створення нового акаунту' : 'Вхід у систему',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),

                      const SizedBox(height: 28),

                      // --- КНОПКА GOOGLE SIGN-IN С ФИРМЕННОЙ "G" ---
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _submitGoogleLogin,
                        icon: const _GoogleGLogo(size: 24),
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

                      const SizedBox(height: 20),

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

                      const SizedBox(height: 20),

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
                        const SizedBox(height: 14),
                      ],

                      // --- ПОЛЕ EMAIL ---
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Email', Icons.email_outlined),
                        validator: (v) => v == null || !v.contains('@') ? 'Введіть коректний email' : null,
                      ),

                      const SizedBox(height: 14),

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

                      const SizedBox(height: 24),

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

                      const SizedBox(height: 16),

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

// =============================================================================
// ВСПОМОГАТЕЛЬНЫЙ ВИДЖЕТ ФИРМЕННОГО МНОГОЦВЕТНОГО ЛОГОТИПА GOOGLE 'G'
// =============================================================================
class _GoogleGLogo extends StatelessWidget {
  final double size;

  const _GoogleGLogo({this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_logo.png',
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/google.png',
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(
              size: Size(size, size),
              painter: _GoogleGLogoPainter(),
            );
          },
        );
      },
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: Offset(center, center), radius: radius - 2);

    final double strokeWidth = size.width * 0.22;

    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint blueFill = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawArc(rect, -0.8, 1.8, false, redPaint);
    canvas.drawArc(rect, 1.0, 1.1, false, yellowPaint);
    canvas.drawArc(rect, 2.1, 1.1, false, greenPaint);
    canvas.drawArc(rect, -0.3, 0.9, false, bluePaint);

    canvas.drawRect(
      Rect.fromLTWH(center - 1, center - strokeWidth / 2, radius * 0.9, strokeWidth),
      blueFill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}