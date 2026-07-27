import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<Map<String, dynamic>> skills = [];
  bool loading = true;
  String? error;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test conexión Supabase')),
      body: loading
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
    );
  }
}