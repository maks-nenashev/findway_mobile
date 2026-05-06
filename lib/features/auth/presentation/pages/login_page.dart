import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Импортируем Service Locator
import 'package:findway_mobile/injection_container.dart'; 
// Импортируем Репозиторий из DATA слоя (правильный путь)
import 'package:findway_mobile/features/auth/data/repositories/auth_repository.dart';
// Импортируем Блок
import 'package:findway_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      // Прямой вызов репозитория для теста (позже обернем в BLoC)
      await sl<AuthRepository>().login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/'); // На главную
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Твой темный стиль
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("FINDWAY LOGIN", style: TextStyle(color: Color(0xFF00F2FF), fontSize: 24, fontFamily: 'Orbitron')),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Email", labelStyle: TextStyle(color: Colors.white70)),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Password", labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 40),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _handleLogin, child: const Text("ENTER")),
          ],
        ),
      ),
    );
  }
}