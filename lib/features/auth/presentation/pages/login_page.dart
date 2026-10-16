// =============================================================================
// FILE: lib/features/auth/presentation/pages/login_page.dart
// LAYER: Presentation
// PURPOSE: FindWay login and registration screen with Google OAuth.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:findway_mobile/core/terms/terms_checkbox.dart';
import 'package:findway_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  final Map<String, String> translations;

  const LoginPage({super.key, this.translations = const {}});

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
  String _locale = 'uk';

  final Color _bgDark = const Color(0xFF0F172A);
  final Color _cardDark = const Color(0xFF1E293B);
  final Color _accentCyan = const Color(0xFF00F2FF);
  final Color _accentOrange = const Color(0xFFFF8A00);

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('locale') ?? 'uk';
    if (!mounted) return;
    setState(() {
      _locale = savedLocale.split(RegExp('[-_]')).first.toLowerCase();
    });
  }

  String _t(String key, String fallback) {
    if (widget.translations.containsKey(key) &&
        widget.translations[key]!.trim().isNotEmpty) {
      return widget.translations[key]!;
    }

    const aliases = <String, List<String>>{
      'devise.sessions.new.submit': [
        'devise.sessions.new.sign_in',
        'devise.sessions.sign_in',
        'devise.sessions.submit',
        'helpers.submit.session.create',
      ],
      'devise.registrations.new.submit': [
        'devise.registrations.new.sign_up',
        'devise.registrations.sign_up',
        'devise.registrations.submit',
        'helpers.submit.user.create',
      ],
      'devise.sessions.new.google': [
        'devise.sessions.google',
        'auth.google.sign_in',
        'devise.sessions.new.google_login',
      ],
      'devise.sessions.new.google_register': [
        'devise.registrations.google',
        'auth.google.sign_up',
        'devise.registrations.new.google_register',
      ],
      'devise.sessions.new.email': [
        'devise.sessions.email',
        'users.email',
        'activerecord.attributes.user.email',
      ],
      'devise.sessions.new.password': [
        'devise.sessions.password',
        'users.password',
        'activerecord.attributes.user.password',
      ],
      'devise.registrations.new.username': [
        'devise.registrations.username',
        'users.username',
        'activerecord.attributes.user.username',
      ],
      'devise.registrations.new.password_confirmation': [
        'devise.registrations.password_confirmation',
        'users.password_confirmation',
        'activerecord.attributes.user.password_confirmation',
      ],
      'devise.registrations.terms_notice': [
        'terms.notice',
        'devise.terms_notice',
      ],
      'devise.registrations.terms_link': [
        'terms.title',
        'terms.link',
        'devise.terms_link',
      ],
      'devise.registrations.privacy_link': [
        'privacy.title',
        'privacy.link',
        'devise.privacy_link',
      ],
    };

    final altKeys = aliases[key];
    if (altKeys != null) {
      for (final altKey in altKeys) {
        if (widget.translations.containsKey(altKey) &&
            widget.translations[altKey]!.trim().isNotEmpty) {
          return widget.translations[altKey]!;
        }
      }
    }

    return _authText(key, fallback: fallback);
  }

  String _authText(String key, {String? fallback}) {
    const translations = <String, Map<String, String>>{
      'en': {
        'devise.registrations.signed_up_but_unconfirmed':
            'Registration successful. Please check your email and confirm your account.',
        'devise.failure.invalid': 'Invalid email or password.',
        'errors.registration.invalid':
            'Please check your details. The email may already be registered or the password may not meet the requirements.',
        'errors.network':
            'Could not connect to the server. Check your internet connection.',
        'errors.server': 'A server error occurred. Please try again.',
        'auth.google.cancelled': 'Google sign-in was cancelled.',
        'auth.google.token_missing': 'Could not obtain a Google ID token.',
        'auth.token.missing':
            'The server did not return an authentication token.',
      },
      'pl': {
        'devise.registrations.signed_up_but_unconfirmed':
            'Rejestracja zakończona. Sprawdź pocztę i potwierdź konto.',
        'devise.failure.invalid': 'Nieprawidłowy adres e-mail lub hasło.',
        'errors.registration.invalid':
            'Sprawdź wprowadzone dane. E-mail może być już zarejestrowany lub hasło nie spełnia wymagań.',
        'errors.network':
            'Nie można połączyć się z serwerem. Sprawdź połączenie z internetem.',
        'errors.server': 'Wystąpił błąd serwera. Spróbuj ponownie.',
        'auth.google.cancelled': 'Logowanie przez Google zostało anulowane.',
        'auth.google.token_missing': 'Nie udało się pobrać tokenu Google ID.',
        'auth.token.missing':
            'Serwer nie zwrócił tokenu uwierzytelniającego.',
      },
      'uk': {
        'devise.registrations.signed_up_but_unconfirmed':
            'Реєстрацію завершено. Перевірте пошту та підтвердьте акаунт.',
        'devise.failure.invalid': 'Невірний email або пароль.',
        'errors.registration.invalid':
            'Перевірте введені дані. Можливо, email вже зареєстрований або пароль не відповідає вимогам.',
        'errors.network':
            'Не вдалося з’єднатися із сервером. Перевірте інтернет.',
        'errors.server': 'Помилка сервера. Спробуйте ще раз.',
        'auth.google.cancelled': 'Вхід через Google скасовано.',
        'auth.google.token_missing': 'Не вдалося отримати ID-токен Google.',
        'auth.token.missing': 'Сервер не повернув токен авторизації.',
      },
    };

    final language = translations.containsKey(_locale) ? _locale : 'uk';
    return translations[language]?[key] ?? fallback ?? key;
  }

  String _displayAuthMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return _authText('errors.server');
    return _t(trimmed, trimmed);
  }

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
        SnackBar(
          content: Text(
            _t(
              'devise.registrations.terms_required',
              'Для реєстрації необхідно прийняти умови використання.',
            ),
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
          SnackBar(
            content: Text(
              _t(
                'devise.registrations.passwords_mismatch',
                'Паролі не співпадають',
              ),
            ),
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
                    content: Text(_displayAuthMessage(state.message)),
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
                  content: Text(_displayAuthMessage(state.message)),
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
                            ? _t(
                                'devise.registrations.new.title',
                                'Створення нового акаунту',
                              )
                            : _t(
                                'devise.sessions.new.title',
                                'Вхід у систему',
                              ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Google OAuth.
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _submitGoogleLogin,
                        icon: const _GoogleGLogo(size: 24),
                        label: Text(
                          _isSignUp
                              ? _t(
                                  'devise.sessions.new.google_register',
                                  'Зареєструватися через Google',
                                )
                              : _t(
                                  'devise.sessions.new.google',
                                  'Увійти через Google',
                                ),
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

                      // Terms notice beneath Google Sign-In button using TermsCheckbox component.
                      if (!_isSignUp) ...[
                        const SizedBox(height: 12),
                        TermsCheckbox(
                          value: true,
                          enabled: !isLoading,
                          onChanged: (_) {},
                        ),
                      ],

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
                              _t(
                                'devise.sessions.new.email_separator',
                                'або за допомогою email',
                              ),
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
                            _t(
                              'devise.registrations.new.username',
                              'Ім\'я користувача',
                            ),
                            Icons.person_outline,
                          ),
                          validator: (value) {
                            if (!_isSignUp) return null;

                            if (value == null || value.trim().isEmpty) {
                              return _t(
                                'devise.registrations.new.username_required',
                                'Введіть ім\'я',
                              );
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
                          _t('devise.sessions.new.email', 'Email'),
                          Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null ||
                              !RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(value.trim())) {
                            return _t(
                              'devise.sessions.new.email_invalid',
                              'Введіть коректний email',
                            );
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
                          _t('devise.sessions.new.password', 'Пароль'),
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
                            return _t(
                              'devise.passwords.minimum_length',
                              'Пароль має бути від 6 символів',
                            );
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
                            _t(
                              'devise.registrations.new.password_confirmation',
                              'Підтвердження пароля',
                            ),
                            Icons.lock_outline,
                          ),
                          validator: (value) {
                            if (!_isSignUp) return null;

                            if (value == null || value.isEmpty) {
                              return _t(
                                'devise.registrations.new.password_confirmation_required',
                                'Підтвердіть пароль',
                              );
                            }

                            if (value != _passwordController.text) {
                              return _t(
                                'devise.registrations.passwords_mismatch',
                                'Паролі не співпадають',
                              );
                            }

                            return null;
                          },
                          onFieldSubmitted: (_) {
                            if (!isLoading) _submitForm();
                          },
                        ),
                      ],

                      // Terms and conditions checkbox — registration only.
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
                        onPressed: isLoading || (_isSignUp && !_termsAccepted)
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
                                    ? _t(
                                        'devise.registrations.new.submit',
                                        'ЗАРЕЄСТРУВАТИСЯ',
                                      )
                                    : _t(
                                        'devise.sessions.new.submit',
                                        'УВІЙТИ',
                                      ),
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
                                    ? _t(
                                        'devise.sessions.new.already_have_account',
                                        'Вже є акаунт? ',
                                      )
                                    : _t(
                                        'devise.sessions.new.no_account',
                                        'Ще немає акаунту? ',
                                      ),
                              ),
                              TextSpan(
                                text: _isSignUp
                                    ? _t(
                                        'devise.sessions.new.submit',
                                        'Увійти',
                                      )
                                    : _t(
                                        'devise.registrations.new.submit',
                                        'Зареєструватися',
                                      ),
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