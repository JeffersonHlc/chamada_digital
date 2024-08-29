import 'package:flutter/material.dart';
import 'database_helper.dart';

class TelaPresenca extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const TelaPresenca({super.key, required this.usuario});

  @override
  TelaPresencaState createState() => TelaPresencaState();
}

class TelaPresencaState extends State<TelaPresenca> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _presencas = [];

  @override
  void initState() {
    super.initState();
    _fetchPresencas();
  }

  Future<void> _fetchPresencas() async {
    try {
      final presencas = await _dbHelper.queryAllPresencas();
      if (!mounted) return;
      setState(() {
        _presencas = presencas;
      });
    } catch (e) {
      // Log error if necessary
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Presenças'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _presencas.length,
          itemBuilder: (context, index) {
            final presenca = _presencas[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                title: Text(
                  'Disciplina: ${presenca['disciplina']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Aluno: ${presenca['aluno']} - Data: ${presenca['data']}'),
              ),
            );
          },
        ),
      ),
    );
  }
}