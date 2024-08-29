import 'package:flutter/material.dart';
import 'database_helper.dart';

class LoginPrincipal extends StatefulWidget {
  const LoginPrincipal({super.key});

  @override
  LoginPrincipalState createState() => LoginPrincipalState();
}

class LoginPrincipalState extends State<LoginPrincipal> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  String _erroMensagem = '';

  static const String tipoProfessor = 'professor';
  static const String tipoAluno = 'aluno';

  void _login() async {
    final email = _emailController.text;
    final senha = _senhaController.text;

    if (email.isNotEmpty && senha.isNotEmpty) {
      try {
        final usuario = await _dbHelper.queryUsuario(email);
        if (!mounted) return;
        if (usuario != null && usuario['senha'] == senha) {
          if (usuario['tipo'] == tipoProfessor) {
            Navigator.pushNamedAndRemoveUntil(context, '/professor', (route) => false, arguments: usuario);
          } else if (usuario['tipo'] == tipoAluno) {
            Navigator.pushNamedAndRemoveUntil(context, '/aluno', (route) => false, arguments: usuario);
          }
        } else {
          setState(() {
            _erroMensagem = 'Credenciais inválidas';
          });
        }
      } catch (e) {
        setState(() {
          _erroMensagem = 'Erro ao consultar usuário: $e';
        });
      }
    } else {
      setState(() {
        _erroMensagem = 'Preencha todos os campos';
      });
    }
  }

  void _irParaRegistro() {
    Navigator.pushNamedAndRemoveUntil(context, '/registrar', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Acesse sua Conta',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildTextField(_emailController, 'Email', Icons.email, TextInputType.emailAddress),
              const SizedBox(height: 10),
              _buildTextField(_senhaController, 'Senha', Icons.lock, TextInputType.text, true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 18)),
              ),
              TextButton(
                onPressed: _irParaRegistro,
                child: const Text(
                  'Registrar',
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
}
  