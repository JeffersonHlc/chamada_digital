import 'dart:async';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:logging/logging.dart';

class LoginPrincipalProfessor extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const LoginPrincipalProfessor({super.key, required this.usuario});

  @override
  LoginPrincipalProfessorState createState() => LoginPrincipalProfessorState();
}

class LoginPrincipalProfessorState extends State<LoginPrincipalProfessor> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final List<String> _disciplinas = [
    'Inteligência Artificial',
    'Estrutura de Dados',
    'Sistemas Operacionais',
    'Arquitetura de Software',
    'Trabalho de Conclusão de Curso'
  ];
  final Logger _logger = Logger('LoginPrincipalProfessor');
  String? _disciplinaAtiva;
  final TextEditingController _tempoController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.info('Tela de professor inicializada');
    _verificarDisciplinasAbertas();
  }

  Future<void> _abrirDisciplina() async {
    if (_disciplinaAtiva != null && _tempoController.text.isNotEmpty) {
      int tempoEmSegundos = int.tryParse(_tempoController.text) ?? 0;
      _logger.info('Abrindo disciplina: $_disciplinaAtiva por $tempoEmSegundos segundos');

      // Verifica se a disciplina já está aberta antes de tentar abrir
      List<Map<String, dynamic>> disciplinasAbertas = await _dbHelper.queryDisciplinasAbertas();
      bool isAlreadyOpen = disciplinasAbertas.any((disciplina) => disciplina['nome'] == _disciplinaAtiva);

      if (isAlreadyOpen) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Disciplina $_disciplinaAtiva já está aberta')),
          );
        }
        return;
      }

      await _dbHelper.abrirDisciplina(_disciplinaAtiva!);
      _logger.info('Disciplina $_disciplinaAtiva aberta com sucesso (log antes da SnackBar).');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disciplina $_disciplinaAtiva aberta com sucesso')),
        );
      }

      await _dbHelper.fecharDisciplinaAutomaticamente(_disciplinaAtiva!, tempoEmSegundos);

      setState(() {
        _disciplinaAtiva = null;
      });
      _verificarDisciplinasAbertas();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione uma disciplina e defina o tempo de abertura')),
        );
      }
    }
  }

  Future<void> fecharTodasDisciplinas() async {
    await _dbHelper.fecharTodasDisciplinas();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todas as disciplinas foram fechadas')),
      );
    }
    _verificarDisciplinasAbertas();
  }

  void _sair() {
    _logger.info('Usuário saiu');
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _verificarDisciplinasAbertas() async {
    List<Map<String, dynamic>> disciplinasAbertas = await _dbHelper.queryDisciplinasAbertas();
    _logger.info('Disciplinas Abertas: $disciplinasAbertas');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escolher Disciplina',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Seja bem-vindo(a), ${widget.usuario['nome']}!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildDropdownButton(),
              const SizedBox(height: 20),
              _buildTextField(_tempoController, 'Tempo de abertura (segundos)', Icons.timer, TextInputType.number),
              const SizedBox(height: 20),
              _buildActionButton(_abrirDisciplina, 'Abrir Disciplina', Colors.green),
              const SizedBox(height: 20),
              _buildActionButton(fecharTodasDisciplinas, 'Fechar Todas Disciplinas', Colors.red),
              const SizedBox(height: 20),
              _buildActionButton(() {
                Navigator.pushNamed(context, '/presencas', arguments: widget.usuario);
              }, 'Ver Presenças', Colors.blue),
              const SizedBox(height: 20),
              _buildActionButton(_sair, 'Sair', Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownButton() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Selecione uma Disciplina',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _disciplinaAtiva,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
          dropdownColor: Colors.blue[50],
          hint: const Text(
            'Selecione uma Disciplina',
            style: TextStyle(color: Colors.blue),
          ),
          items: _disciplinas.map<DropdownMenuItem<String>>((disciplina) {
            return DropdownMenuItem<String>(
              value: disciplina,
              child: Text(disciplina),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _disciplinaAtiva = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, IconData icon, TextInputType keyboardType, [bool obscureText = false]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }

  Widget _buildActionButton(VoidCallback onPressed, String text, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18)),
    );
  }
}