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
  /// Optional translations already supplied by the caller. The page also loads
  /// the current locale's auth translations from the Rails I18n API.
  final Map<String, String> translations;

  const LoginPage({super.key, this.translations = const {}});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Map<String, String> _translations = {};

  String _t(String key, String fallback) {
    final value = _translations[key];
    return value == null || value.trim().isEmpty ? fallback : value;
  }

  String? _translatedOrNull(String key) {
    final value = _translations[key];
    return value == null || value.trim().isEmpty ? null : value;
  }

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  bool _termsAccepted = false;
  String _locale = 'uk';

  @override
  void initState() {
    super.initState();
    _translations.addAll(widget.translations);
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('locale') ?? 'uk';
    final locale = savedLocale.split(RegExp('[-_]')).first.toLowerCase();

    if (!mounted) return;
    setState(() => _locale = locale);

    await _loadTranslations(locale);
  }

  Future<void> _loadTranslations(String locale) async {
    try {
      // Call the existing Rails metadata endpoint directly from this page.
      // The SearchController's `scope=auth` branch returns flattened I18n keys.
      final response = await context.read<AuthBloc>().repository.client.get(
        '/api/v1/search/new_meta',
        queryParameters: {
          'locale': locale,
          'scope': 'auth',
        },
      );

      final dynamic body = response.data;
      if (body is! Map) {
        throw const FormatException('Invalid auth translations response');
      }

      final dynamic rawTranslations = body['translations'];
      if (rawTranslations is! Map) {
        throw const FormatException('Missing translations map in Rails response');
      }

      final incoming = <String, String>{};
      rawTranslations.forEach((dynamic key, dynamic value) {
        if (key == null || value == null || value is Map || value is List) {
          return;
        }
        final translated = value.toString();
        if (translated.trim().isNotEmpty) {
          incoming[key.toString()] = translated;
        }
      });

      if (!mounted) return;

      setState(() {
        // Rails is the source of truth and overrides optional constructor values.
        _translations.addAll(incoming);
        _locale = incoming['locale_code'] ?? locale;
      });

      debugPrint(
        '[LoginPage] Loaded ${incoming.length} Rails I18n keys for $_locale',
      );
    } catch (error) {
      // Keep a usable screen if the API is unavailable; no locale dictionaries
      // are embedded in this widget.
      debugPrint('[LoginPage] Failed to load Rails auth translations: $error');
    }
  }

  String _displayAuthMessage(String message) {
    final key = message.trim();
    if (key.isEmpty) {
      return _translations['errors.server'] ?? 'errors.server';
    }

    final translated = _translations[key];
    if (translated != null && translated.trim().isNotEmpty) {
      return translated;
    }

    // Keep a server-provided localized sentence if the current repository
    // still returns text instead of a stable I18n key. The recommended contract
    // is to have AuthRepository/AuthBloc emit Rails keys.
    if (!key.contains(' ') && key.contains('.')) {
      final genericError = _translations['errors.server'];
      if (genericError != null && genericError.trim().isNotEmpty) {
        debugPrint('[LoginPage] Missing Rails translation for key: $key');
        return genericError;
      }
    }

    return key;
  }

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
        SnackBar(
          content: Text(
            _t('legal.terms.acceptance.validation_error', 'Для реєстрації необхідно прийняти умови використання.'),
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

      // Temporary diagnostic: compare the domain with the Rails Parameters log
      // without printing the complete email address to Flutter logs.
      final emailDomain = email.contains('@') ? email.split('@').last : '<invalid>';
      debugPrint('[LoginPage] Registration email domain being submitted: $emailDomain');

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

            final successKey = _translations.containsKey(state.message.trim())
                ? state.message.trim()
                : 'devise.registrations.signed_up_but_unconfirmed';

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(_displayAuthMessage(successKey)),
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
                            ? _t('devise.registrations.new.title', 'Створення нового акаунту')
                            : _t('devise.sessions.new.title', 'Вхід у систему'),
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
                              ? _t('devise.sessions.new.google', 'Зареєструватися через Google')
                              : _t('devise.sessions.new.google', 'Увійти через Google'),
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

                      // Existing Terms document and link below Google sign-in.
                      // The Google flow shows the notice without a checkbox.
                      if (!_isSignUp) ...[
                        const SizedBox(height: 12),
                        TermsCheckbox(
                          value: true,
                          onChanged: (_) {},
                          enabled: !isLoading,
                          locale: _locale,
                          showCheckbox: false,
                          disclaimerTemplate: _translatedOrNull(
                            'devise.sessions.new.oauth_disclaimer_html',
                          ),
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
                              _t('devise.sessions.new.email', 'Email'),
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
                            _t('devise.registrations.new.username', 'Ім\'я користувача'),
                            Icons.person_outline,
                          ),
                          validator: (value) {
                            if (!_isSignUp) return null;

                            if (value == null || value.trim().isEmpty) {
                              final usernameLabel = _t(
                                'devise.registrations.new.username',
                                'Username',
                              );
                              final blankMessage = _t(
                                'errors.messages.blank',
                                "can't be blank",
                              );
                              return '$usernameLabel $blankMessage';
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
                        // Avoid saved-account autofill replacing the address
                        // during registration; keep autofill available for login.
                        autofillHints: _isSignUp ? null : const [AutofillHints.email],
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          _t(
                            _isSignUp
                                ? 'devise.registrations.new.email'
                                : 'devise.sessions.new.email',
                            'Email',
                          ),
                          Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null ||
                              !RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(value.trim())) {
                            final emailLabel = _t(
                              _isSignUp
                                  ? 'devise.registrations.new.email'
                                  : 'devise.sessions.new.email',
                              'Email',
                            );
                            final invalidMessage = _t(
                              'errors.messages.invalid',
                              'is invalid',
                            );
                            return '$emailLabel $invalidMessage';
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
                            final passwordLabel = _t(
                              _isSignUp
                                  ? 'devise.registrations.new.password'
                                  : 'devise.sessions.new.password',
                              'Password',
                            );
                            final minimumText = _t(
                              'devise.registrations.new.six_symbol',
                              'minimum number of characters',
                            );
                            return '$passwordLabel: $minimumText 6';
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
                            _t('devise.registrations.new.new_password', 'Підтвердження пароля'),
                            Icons.lock_outline,
                          ),
                          validator: (value) {
                            if (!_isSignUp) return null;

                            if (value == null || value.isEmpty) {
                              final confirmationLabel = _t(
                                'devise.registrations.new.new_password',
                                'Confirm password',
                              );
                              final blankMessage = _t(
                                'errors.messages.blank',
                                "can't be blank",
                              );
                              return '$confirmationLabel $blankMessage';
                            }

                            if (value != _passwordController.text) {
                              final confirmationLabel = _t(
                                'devise.registrations.new.new_password',
                                'Confirm password',
                              );
                              final mismatch = _t(
                                'errors.messages.confirmation',
                                "doesn't match %{attribute}",
                              ).replaceAll(
                                '%{attribute}',
                                _t('devise.registrations.new.password', 'Password'),
                              );
                              return '$confirmationLabel $mismatch';
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
                          locale: _locale,
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
                                    ? _t('devise.registrations.new.Sign up', 'ЗАРЕЄСТРУВАТИСЯ')
                                    : _t('devise.sessions.new.Log in', 'УВІЙТИ'),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Switch between login and registration using Rails keys.
                      TextButton(
                        onPressed: isLoading ? null : _toggleAuthMode,
                        child: Text(
                          _isSignUp
                              ? _t('devise.shared.links.sign_in', 'Увійти')
                              : _t('devise.shared.links.sign_up', 'Зареєструватися'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _accentCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
