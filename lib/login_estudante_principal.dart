import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'database_helper.dart';
import 'geolocalizacao_servico.dart';
import 'package:geolocator/geolocator.dart';

class LoginEstudantePrincipal extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const LoginEstudantePrincipal({super.key, required this.usuario});

  @override
  LoginEstudantePrincipalState createState() => LoginEstudantePrincipalState();
}

class LoginEstudantePrincipalState extends State<LoginEstudantePrincipal> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final GeolocalizacaoServico _geolocalizacaoServico = GeolocalizacaoServico();
  final Logger _logger = Logger('LoginEstudantePrincipal');
  List<Map<String, dynamic>> _disciplinas = [];
  final double _raioMaximo = 300; // Raio máximo em metros para permitir a assinatura

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchDisciplinas();
  }

  Future<List<Map<String, dynamic>>> _fetchDisciplinas() async {
    try {
      return await _dbHelper.queryDisciplinasAbertas();
    } catch (e) {
      _logger.severe('Erro ao consultar disciplinas: $e');
      return [];
    }
  }

  Future<void> _responderChamada(String disciplinaNome) async {
    try {
      Position posicaoAtual = await _geolocalizacaoServico.obterPosicaoAtual();
      if (!mounted) return;

      double latitudeAluno = posicaoAtual.latitude;
      double longitudeAluno = posicaoAtual.longitude;

      // Coordenadas fictícias para o exemplo
      double latitudeDisciplina = -21.8045285; //Uniara
      double longitudeDisciplina = -48.1722567;


      double distancia = _geolocalizacaoServico.calcularDistancia(
          latitudeDisciplina, longitudeDisciplina, latitudeAluno, longitudeAluno);

      if (_isDentroDoRaio(distancia)) {
        final presenca = {
          'disciplina': disciplinaNome,
          'aluno': widget.usuario['nome'],
          'data': DateTime.now().toIso8601String(),
          'latitude': latitudeAluno,
          'longitude': longitudeAluno,
          'presente': true,
        };
        await _dbHelper.insertPresenca(presenca);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Presença registrada para $disciplinaNome')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você está fora do raio permitido para assinar a presença')),
        );
      }
    } catch (e) {
      _logger.severe('Erro ao registrar presença: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao registrar presença: $e')),
      );
    }
  }

  bool _isDentroDoRaio(double distancia) => distancia <= _raioMaximo;

  void _sair() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Disciplinas Abertas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _sair,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchDisciplinas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Erro ao carregar disciplinas'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhuma disciplina aberta no momento.'));
            } else {
              _disciplinas = snapshot.data!;
              return ListView.builder(
                itemCount: _disciplinas.length,
                itemBuilder: (context, index) {
                  final disciplina = _disciplinas[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(
                        disciplina['nome'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _responderChamada(disciplina['nome']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                          textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text('Responder'),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
