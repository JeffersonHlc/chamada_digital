import 'dart:async';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final _userStore = intMapStoreFactory.store('usuarios');
  final _chamadaStore = intMapStoreFactory.store('chamadas');
  final _historicoStore = intMapStoreFactory.store('historico_presenca');
  final _disciplinaStore = intMapStoreFactory.store('disciplinas');
  final _cronometroStore = stringMapStoreFactory.store('cronometros');
  final _presencaStore = intMapStoreFactory.store('presencas');
  final Logger _logger = Logger('DatabaseHelper');

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbFactory = databaseFactoryIo;
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = join(directory.path, 'chamada_digital.db');
      _logger.info('Database path: $dbPath');
      return await dbFactory.openDatabase(dbPath);
    } catch (e) {
      _logger.severe('Erro ao inicializar o banco de dados: $e');
      rethrow;
    }
  }

  Future<int> insertUsuario(Map<String, dynamic> row) async {
    try {
      Database db = await database;
      return await _userStore.add(db, row);
    } catch (e) {
      _logger.severe('Erro ao inserir usuário: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> queryUsuario(String email) async {
    try {
      Database db = await database;
      final finder = Finder(filter: Filter.equals('email', email));
      final recordSnapshots = await _userStore.find(db, finder: finder);
      if (recordSnapshots.isNotEmpty) {
        final user = Map<String, dynamic>.from(recordSnapshots.first.value);
        if (user.containsKey('id') && user['id'] != null) {
          user['id'] = int.tryParse(user['id'].toString()) ?? 0;
        }
        return user;
      }
      return null;
    } catch (e) {
      _logger.severe('Erro ao consultar usuário: $e');
      rethrow;
    }
  }

  Future<int> deleteUsuario(int id) async {
    try {
      Database db = await database;
      final finder = Finder(filter: Filter.equals('id', id));
      return await _userStore.delete(db, finder: finder);
    } catch (e) {
      _logger.severe('Erro ao deletar usuário: $e');
      rethrow;
    }
  }

  Future<int> insertChamada(Map<String, dynamic> row) async {
    try {
      Database db = await database;
      return await _chamadaStore.add(db, row);
    } catch (e) {
      _logger.severe('Erro ao inserir chamada: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryChamadas(int professorId) async {
    try {
      Database db = await database;
      final finder = Finder(filter: Filter.equals('professorId', professorId));
      final recordSnapshots = await _chamadaStore.find(db, finder: finder);
      return recordSnapshots.map((snapshot) => Map<String, dynamic>.from(snapshot.value)).toList();
    } catch (e) {
      _logger.severe('Erro ao consultar chamadas: $e');
      rethrow;
    }
  }

  Future<int> insertHistoricoPresenca(Map<String, dynamic> row) async {
    try {
      Database db = await database;
      return await _historicoStore.add(db, row);
    } catch (e) {
      _logger.severe('Erro ao inserir histórico de presença: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryHistoricoPresenca(int chamadaId) async {
    try {
      Database db = await database;
      final finder = Finder(filter: Filter.equals('chamadaId', chamadaId));
      final recordSnapshots = await _historicoStore.find(db, finder: finder);
      return recordSnapshots.map((snapshot) => Map<String, dynamic>.from(snapshot.value)).toList();
    } catch (e) {
      _logger.severe('Erro ao consultar histórico de presença: $e');
      rethrow;
    }
  }

  Future<void> abrirDisciplina(String disciplinaNome) async {
    try {
      Database db = await database;
      final finder = Finder(filter: Filter.equals('nome', disciplinaNome));
      final recordSnapshots = await _disciplinaStore.find(db, finder: finder);

      if (recordSnapshots.isNotEmpty) {
        final record = recordSnapshots.first;
        if (record.value['status'] == 'fechada') {
          await _disciplinaStore.update(
            db,
            {'status': 'aberta'},
            finder: Finder(filter: Filter.byKey(record.key)),
          );
          _logger.info('Disciplina $disciplinaNome aberta com sucesso.');
        } else {
          _logger.info('Disciplina $disciplinaNome já está aberta.');
        }
      } else {
        _logger.warning('Disciplina $disciplinaNome não encontrada.');
      }
    } catch (e) {
      _logger.severe('Erro ao abrir disciplina: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryDisciplinasAbertas() async {
    try {
      Database db = await database;
      final finder = Finder(filter: Filter.equals('status', 'aberta'));
      final recordSnapshots = await _disciplinaStore.find(db, finder: finder);
      return recordSnapshots.map((snapshot) => Map<String, dynamic>.from(snapshot.value)).toList();
    } catch (e) {
      _logger.severe('Erro ao consultar disciplinas abertas: $e');
      rethrow;
    }
  }

  Future<void> fecharDisciplina(String disciplinaNome) async {
    try {
      Database db = await database;
      await _disciplinaStore.update(
        db,
        {'status': 'fechada'},
        finder: Finder(filter: Filter.equals('nome', disciplinaNome)),
      );
      _logger.info('Disciplina $disciplinaNome fechada com sucesso.');
    } catch (e) {
      _logger.severe('Erro ao fechar disciplina: $e');
      rethrow;
    }
  }

  Future<void> fecharDisciplinaAutomaticamente(String disciplinaNome, int tempoEmSegundos) async {
    await Future.delayed(Duration(seconds: tempoEmSegundos));
    await fecharDisciplina(disciplinaNome);
    _logger.info('Disciplina $disciplinaNome fechada automaticamente após $tempoEmSegundos segundos.');
  }

  Future<void> salvarCronometro(String disciplinaNome, int tempoRestante, int timestampInicio) async {
    try {
      Database db = await database;
      await _cronometroStore.record(disciplinaNome).put(db, {
        'tempoRestante': tempoRestante,
        'timestampInicio': timestampInicio,
      });
    } catch (e) {
      _logger.severe('Erro ao salvar cronômetro: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> carregarCronometro(String disciplinaNome) async {
    try {
      Database db = await database;
      final record = await _cronometroStore.record(disciplinaNome).get(db);
      return record != null ? Map<String, dynamic>.from(record) : null;
    } catch (e) {
      _logger.severe('Erro ao carregar cronômetro: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryAllUsuarios() async {
    try {
      Database db = await database;
      final recordSnapshots = await _userStore.find(db);
      return recordSnapshots.map((snapshot) => Map<String, dynamic>.from(snapshot.value)).toList();
    } catch (e) {
      _logger.severe('Erro ao consultar todos os usuários: $e');
      rethrow;
    }
  }

  Future<int> deleteAllUsuarios() async {
    try {
      Database db = await database;
      return await _userStore.delete(db);
    } catch (e) {
      _logger.severe('Erro ao deletar todos os usuários: $e');
      rethrow;
    }
  }

  Future<int> insertPresenca(Map<String, dynamic> row) async {
    try {
      Database db = await database;
      return await _presencaStore.add(db, row);
    } catch (e) {
      _logger.severe('Erro ao inserir presença: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryAllPresencas() async {
    try {
      Database db = await database;
      final recordSnapshots = await _presencaStore.find(db);
      return recordSnapshots.map((snapshot) => Map<String, dynamic>.from(snapshot.value)).toList();
    } catch (e) {
      _logger.severe('Erro ao consultar todas as presenças: $e');
      rethrow;
    }
  }

  Future<void> inserirDisciplinasIniciais() async {
    Database db = await database;
    List<Map<String, dynamic>> disciplinasIniciais = [
      {'nome': 'Inteligência Artificial', 'status': 'fechada'},
      {'nome': 'Estrutura de Dados', 'status': 'fechada'},
      {'nome': 'Sistemas Operacionais', 'status': 'fechada'},
      {'nome': 'Arquitetura de Software', 'status': 'fechada'},
      {'nome': 'Trabalho de Conclusão de Curso', 'status': 'fechada'},
    ];
    for (var disciplina in disciplinasIniciais) {
      await _disciplinaStore.add(db, disciplina);
    }
  }

  Future<void> fecharTodasDisciplinas() async {
    try {
      Database db = await database;
      final finder = Finder(filter: Filter.equals('status', 'aberta'));
      final recordSnapshots = await _disciplinaStore.find(db, finder: finder);

      for (var record in recordSnapshots) {
        final disciplina = Map<String, dynamic>.from(record.value);
        await _disciplinaStore.update(
          db,
          {'status': 'fechada'},
          finder: Finder(filter: Filter.equals('nome', disciplina['nome'])),
        );
        _logger.info('Disciplina ${disciplina['nome']} fechada com sucesso.');
      }
    } catch (e) {
      _logger.severe('Erro ao fechar todas as disciplinas: $e');
      rethrow;
    }
  }
}
