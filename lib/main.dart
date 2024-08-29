import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'login_principal.dart';
import 'login_principal_professor.dart';
import 'login_estudante_principal.dart';
import 'registro_screen.dart';
import 'database_helper.dart';
import 'tela_presenca.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupLogging();
  final dbHelper = DatabaseHelper();

  // Inserir disciplinas iniciais
  await dbHelper.inserirDisciplinasIniciais();

  runApp(const MyApp());
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chamada Digital',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPrincipal(),
        '/professor': (context) => LoginPrincipalProfessor(
            usuario: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
        '/aluno': (context) => LoginEstudantePrincipal(
            usuario: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
        '/registrar': (context) => const TelaRegistro(),
        '/presencas': (context) => TelaPresenca(
            usuario: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
      },
    );
  }
}
