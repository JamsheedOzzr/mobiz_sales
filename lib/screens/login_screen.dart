import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _api = ApiService();
  final _email = TextEditingController(text: 'sales@shop.com');
  final _password = TextEditingController(text: '12345678');
  bool _hidePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      showSnack(context, 'Enter email and password');
      return;
    }
    setState(() => _loading = true);
    try {
      final session = await _api.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(session: session, api: _api)),
      );
    } catch (error) {
      if (mounted) showSnack(context, error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height,
          child: Stack(
            children: [
              Container(
                height: 360,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(150)),
                ),
                padding: const EdgeInsets.fromLTRB(34, 95, 24, 0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 62,
                        height: 0.9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Sales',
                      style: TextStyle(color: Colors.white, fontSize: 52, height: 1),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.fromLTRB(28, 38, 28, 44),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Log In',
                        style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text('Please sign in with your details', style: TextStyle(fontSize: 22)),
                      const SizedBox(height: 34),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Username',
                          prefixIcon: const Icon(Icons.person, size: 34),
                          contentPadding: const EdgeInsets.symmetric(vertical: 22),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(34)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(34),
                            borderSide: const BorderSide(color: Colors.grey, width: 3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _password,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock, size: 34),
                          suffixIcon: IconButton(
                            icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 22),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(34)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(34),
                            borderSide: const BorderSide(color: Colors.grey, width: 3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 44),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Log In', style: TextStyle(fontSize: 30)),
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
  }
}
