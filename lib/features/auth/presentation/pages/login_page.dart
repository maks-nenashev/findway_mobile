// =============================================================================
// FILE: lib/features/auth/presentation/pages/login_page.dart
// LAYER: Presentation
// PURPOSE: FindWay login and registration screen with Google OAuth.
// =============================================================================
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:findway_mobile/core/terms/terms_checkbox.dart';
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
  final _passwordConfirmationController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _termsAccepted = false;

  final Color _bgDark = const Color(0xFF0F172A);
  final Color _cardDark = const Color(0xFF1E293B);
  final Color _accentCyan = const Color(0xFF00F2FF);
  final Color _accentOrange = const Color(0xFFFF8A00);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_isSignUp && !_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Для реєстрації необхідно прийняти умови використання.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      final username = _usernameController.text.trim();
      final confirmation = _passwordConfirmationController.text;

      if (password != confirmation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Паролі не співпадають'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      context.read<AuthBloc>().add(
            RegisterSubmitted(
              username: username,
              email: email,
              password: password,
              passwordConfirmation: confirmation,
              termsAccepted: _termsAccepted,
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            LoginSubmitted(email, password),
          );
    }
  }

  void _submitGoogleLogin() {
    debugPrint('>>> [UI] Google Sign-In button clicked');
    context.read<AuthBloc>().add(GoogleLoginSubmitted());
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _termsAccepted = false;
      _formKey.currentState?.reset();
    });
  }

  void _showRegistrationSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$message\nПеревірте пошту та підтвердьте акаунт.',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );

    setState(() {
      _isSignUp = false;
      _termsAccepted = false;
      _formKey.currentState?.reset();
    });

    _passwordController.clear();
    _passwordConfirmationController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          debugPrint('[LoginPage] STATE: ${state.runtimeType}');

          if (state is AuthRegistrationSuccess) {
            debugPrint('[LoginPage] REGISTRATION SUCCESS');

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    '${state.message}\n'
                    'Перевірте пошту та підтвердьте акаунт.',
                  ),
                  duration: const Duration(seconds: 8),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green,
                ),
              );

            setState(() {
              _isSignUp = false;
              _termsAccepted = false;
            });

            _passwordController.clear();
            _passwordConfirmationController.clear();
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, state) {
  
            final isLoading = state is AuthLoading;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                        color: _accentCyan.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _accentCyan,
                                          width: 2,
                                        ),
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
                        _isSignUp
                            ? 'Створення нового акаунту'
                            : 'Вхід у систему',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Google OAuth — existing flow preserved.
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _submitGoogleLogin,
                        icon: const _GoogleGLogo(size: 24),
                        label: Text(
                          _isSignUp
                              ? 'Зареєструватися через Google'
                              : 'Увійти через Google',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: _accentCyan.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Colors.white24),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              'або за допомогою email',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Colors.white24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Username — registration only.
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            "Ім'я користувача",
                            Icons.person_outline,
                          ),
                          validator: (value) {
                            if (!_isSignUp) return null;

                            if (value == null || value.trim().isEmpty) {
                              return "Введіть ім'я";
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Email.
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'Email',
                          Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null ||
                              !RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(value.trim())) {
                            return 'Введіть коректний email';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password.
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: _isSignUp
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        textInputAction: _isSignUp
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!isLoading && !_isSignUp) {
                            _submitForm();
                          }
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'Пароль',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Пароль має бути від 6 символів';
                          }

                          return null;
                        },
                      ),

                      // Password confirmation — registration only.
                      if (_isSignUp) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordConfirmationController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            'Підтвердження пароля',
                            Icons.lock_outline,
                          ),
                          validator: (value) {
                            if (!_isSignUp) return null;

                            if (value == null || value.isEmpty) {
                              return 'Підтвердіть пароль';
                            }

                            if (value != _passwordController.text) {
                              return 'Паролі не співпадають';
                            }

                            return null;
                          },
                          onFieldSubmitted: (_) {
                            if (!isLoading) _submitForm();
                          },
                        ),
                      ],

                      // Terms and conditions.
                      if (_isSignUp) ...[
                        const SizedBox(height: 16),
                        TermsCheckbox(
                          value: _termsAccepted,
                          enabled: !isLoading,
                          onChanged: (accepted) {
                            setState(() {
                              _termsAccepted = accepted;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ] else
                        const SizedBox(height: 24),

                      // Submit.
                      ElevatedButton(
                        onPressed:
                            isLoading || (_isSignUp && !_termsAccepted)
                                ? null
                                : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentOrange,
                          disabledBackgroundColor:
                              _accentOrange.withValues(alpha: 0.35),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isSignUp
                                    ? 'ЗАРЕЄСТРУВАТИСЯ'
                                    : 'УВІЙТИ',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Switch between login and registration.
                      TextButton(
                        onPressed: isLoading ? null : _toggleAuthMode,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: _isSignUp
                                    ? 'Вже є акаунт? '
                                    : 'Ще немає акаунту? ',
                              ),
                              TextSpan(
                                text: _isSignUp
                                    ? 'Увійти'
                                    : 'Зареєструватися',
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
      labelStyle: const TextStyle(
        color: Colors.white54,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: _accentCyan,
        size: 20,
      ),
      filled: true,
      fillColor: _cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _GoogleGLogo extends StatelessWidget {
  final double size;

  const _GoogleGLogo({this.size = 24});

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

    final Rect rect = Rect.fromCircle(
      center: Offset(center, center),
      radius: radius - 2,
    );

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
      Rect.fromLTWH(
        center - 1,
        center - strokeWidth / 2,
        radius * 0.9,
        strokeWidth,
      ),
      blueFill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}