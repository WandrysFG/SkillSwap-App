import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> skills = [];
  bool loading = true;
  String? error;
  String status = 'Sin probar aun';

  @override
  void initState() {
    super.initState();
    fetchSkills();
  }

  Future<void> fetchSkills() async {
    try {
      final response = await Supabase.instance.client.from('skills').select();
      setState(() {
        skills = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _testSignUp() async {
    setState(() => status = 'Registrando...');
    try {
      await _authService.signUp(
        nombre: 'Usuario Prueba',
        email: 'prueba1@skillswap.com',
        password: '123456',
      );
      setState(() => status = 'Registro exitoso');
    } catch (e) {
      setState(() => status = 'Error en registro: $e');
    }
  }

  Future<void> _testSignIn() async {
    setState(() => status = 'Iniciando sesion...');
    try {
      await _authService.signIn(
        email: 'prueba1@skillswap.com',
        password: '123456',
      );
      setState(() => status = 'Login exitoso. UID: ${_authService.currentUser?.id}');
    } catch (e) {
      setState(() => status = 'Error en login: $e');
    }
  }

  Future<void> _testSignOut() async {
    await _authService.signOut();
    setState(() => status = 'Sesion cerrada');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Auth + Supabase')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(status, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(onPressed: _testSignUp, child: const Text('Sign Up')),
                    ElevatedButton(onPressed: _testSignIn, child: const Text('Sign In')),
                    ElevatedButton(onPressed: _testSignOut, child: const Text('Sign Out')),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text('Error: $error'))
                    : ListView.builder(
                        itemCount: skills.length,
                        itemBuilder: (context, index) => ListTile(
                          title: Text(skills[index]['nombre']),
                          subtitle: Text(skills[index]['categoria']),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}