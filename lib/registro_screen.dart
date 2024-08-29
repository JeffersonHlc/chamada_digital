import 'package:flutter/material.dart';
import 'database_helper.dart';

class TelaRegistro extends StatefulWidget {
  const TelaRegistro({super.key});

  @override
  TelaRegistroState createState() => TelaRegistroState();
}

class TelaRegistroState extends State<TelaRegistro> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _tipoController = TextEditingController();
  String _erroMensagem = '';

  void _registrar() async {
    final nome = _nomeController.text;
    final email = _emailController.text;
    final senha = _senhaController.text;
    final tipo = _tipoController.text;

    if (nome.isNotEmpty && email.isNotEmpty && senha.isNotEmpty && tipo.isNotEmpty) {
      try {
        final novoUsuario = {
          'nome': nome,
          'email': email,
          'senha': senha,
          'tipo': tipo,
        };
        await _dbHelper.insertUsuario(novoUsuario);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
      } catch (e) {
        setState(() {
          _erroMensagem = 'Erro ao registrar usuário: $e';
        });
      }
    } else {
      setState(() {
        _erroMensagem = 'Preencha todos os campos';
      });
    }
  }

  void _irParaLogin() {
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Crie sua Conta',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildTextField(_nomeController, 'Nome', Icons.person),
              const SizedBox(height: 10),
              _buildTextField(_emailController, 'Email', Icons.email, TextInputType.emailAddress),
              const SizedBox(height: 10),
              _buildTextField(_senhaController, 'Senha', Icons.lock, TextInputType.text, true),
              const SizedBox(height: 10),
              _buildTextField(_tipoController, 'Tipo (professor ou aluno)', Icons.school),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registrar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text('Registrar', style: TextStyle(fontSize: 18)),
              ),
              TextButton(
                onPressed: _irParaLogin,
                child: const Text(
                  'Já tem uma conta? Faça login',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
              if (_erroMensagem.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _erroMensagem,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, IconData icon, [TextInputType keyboardType = TextInputType.text, bool obscureText = false]) {
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
}
