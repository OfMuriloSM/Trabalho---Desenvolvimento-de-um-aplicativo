import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'models.dart';

/// Regras de negócio e autenticação local para a edição acadêmica offline.
/// Os dados locais não substituem um backend e RLS para uso comercial.
class AcademiaStore extends ChangeNotifier {
  AcademiaStore() {
    _iniciarCredenciaisPadrao();
  }

  static const academiaPadraoId = 'academia-local';
  final Map<String, _Credencial> _credenciais = {};
  static const Map<String, String> _senhasIniciais = {
    'admin-1': 'Admin@2026!',
    'prof-1': 'Prof@2026!',
    'aluno-1': 'Aluna@2026!',
    'aluno-2': 'Aluno@2026!',
  };

  void _iniciarCredenciaisPadrao() {
    for (final entrada in _senhasIniciais.entries) {
      _credenciais[entrada.key] = _gerarCredencial(entrada.value);
    }
  }

  // Sal + SHA-256 iterativo: evita senha em texto claro no armazenamento.
  // Não constitui autenticação de produção, pois o armazenamento é local.
  _Credencial _gerarCredencial(String senha) {
    final aleatorio = Random.secure();
    final salt = base64UrlEncode(
      List<int>.generate(16, (_) => aleatorio.nextInt(256)));
    return _Credencial(salt, _derivarHash(senha, salt));
  }

  String _derivarHash(String senha, String salt) {
    List<int> dados = utf8.encode('$salt:$senha');
    for (var i = 0; i < 12000; i++) {
      dados = sha256.convert(dados).bytes;
    }
    return base64Encode(dados);
  }

  bool _senhaCorreta(_Credencial? credencial, String senha) {
    if (credencial == null) return false;
    final calculado = base64Decode(_derivarHash(senha, credencial.salt));
    final esperado = base64Decode(credencial.hash);
    if (calculado.length != esperado.length) return false;
    var diferenca = 0;
    for (var i = 0; i < esperado.length; i++) {
      diferenca |= calculado[i] ^ esperado[i];
    }
    return diferenca == 0;
  }

  void _validarSenha(String senha) {
    if (senha.length < 8 || senha.length > 128) {
      throw StateError('A senha deve ter de 8 a 128 caracteres.');
    }
  }

  String? _usuarioAtualId;
  int _proximoId = 10;

  final List<Usuario> _usuarios = [
    Usuario(
      id: 'admin-1',
      nome: 'Ana (recepção)',
      email: 'ana@exemplo.test',
      perfil: Perfil.administrador,
      academiaId: academiaPadraoId,
    ),
    Usuario(
      id: 'prof-1',
      nome: 'Bruno (professor)',
      email: 'bruno@exemplo.test',
      perfil: Perfil.professor,
      academiaId: academiaPadraoId,
    ),
    Usuario(
      id: 'aluno-1',
      nome: 'Carla (aluna)',
      email: 'carla@exemplo.test',
      perfil: Perfil.aluno,
      academiaId: academiaPadraoId,
      statusAvaliacao: StatusAvaliacao.concluida,
    ),
    Usuario(
      id: 'aluno-2',
      nome: 'Daniel (aluno)',
      email: 'daniel@exemplo.test',
      perfil: Perfil.aluno,
      academiaId: academiaPadraoId,
    ),
  ];

  final List<ModeloTreino> _modelos = [
    ModeloTreino(
      id: 'modelo-1',
      professorId: 'prof-1',
      nome: 'Treino A — Superiores',
      exercicios: const [
        ExercicioPrescrito(nome: 'Puxada frontal', series: 3, repeticoes: 12, cargaKg: 15, descansoSegundos: 60, observacao: 'Executar com controle.'),
        ExercicioPrescrito(nome: 'Supino máquina', series: 3, repeticoes: 10, cargaKg: 20, descansoSegundos: 90),
      ],
    ),
  ];

  final List<FichaAtribuida> _fichas = [];
  final List<RegistroSerie> _registros = [];
  final List<SessaoTreino> _sessoes = [];
  List<RegistroSerie> get registros => List.unmodifiable(_registros);
  List<SessaoTreino> get sessoes => List.unmodifiable(_sessoes);

  List<Usuario> get usuarios => List.unmodifiable(_usuarios);
  List<Usuario> get alunos => List.unmodifiable(_usuarios.where((u) => u.perfil == Perfil.aluno && u.ativo));
  List<Usuario> get professores => List.unmodifiable(_usuarios.where((u) => u.perfil == Perfil.professor && u.ativo));
  List<ModeloTreino> get modelos => List.unmodifiable(_modelos);
  List<FichaAtribuida> get fichas => List.unmodifiable(_fichas);

  Usuario? get usuarioAtual => usuarioPorId(_usuarioAtualId);
  Usuario? usuarioPorId(String? id) {
    if (id == null) return null;
    for (final usuario in _usuarios) {
      if (usuario.id == id) return usuario;
    }
    return null;
  }

  /// Login por e-mail e senha da instalação local atual.
  void entrar({required String email, required String senha}) {
    final emailLimpo = email.trim().toLowerCase();
    Usuario? usuario;
    for (final candidato in _usuarios) {
      if (candidato.email.toLowerCase() == emailLimpo) {
        usuario = candidato;
        break;
      }
    }
    if (usuario == null || !usuario.ativo ||
        !_senhaCorreta(_credenciais[usuario.id], senha)) {
      throw StateError('E-mail ou senha inválidos.');
    }
    _usuarioAtualId = usuario.id;
    notifyListeners();
  }

  /// O administrador pode liberar acesso ou redefinir uma senha local.
  void redefinirSenha({required String usuarioId, required String novaSenha}) {
    _exigirAdmin();
    final usuario = usuarioPorId(usuarioId);
    if (usuario == null || !usuario.ativo ||
        usuario.academiaId != _exigirSessao().academiaId) {
      throw StateError('Usuário indisponível.');
    }
    _validarSenha(novaSenha);
    _credenciais[usuarioId] = _gerarCredencial(novaSenha);
    notifyListeners();
  }

  void alterarMinhaSenha({required String senhaAtual,
      required String novaSenha}) {
    final usuario = _exigirSessao();
    if (!_senhaCorreta(_credenciais[usuario.id], senhaAtual)) {
      throw StateError('A senha atual está incorreta.');
    }
    _validarSenha(novaSenha);
    _credenciais[usuario.id] = _gerarCredencial(novaSenha);
    notifyListeners();
  }

  void sair() {
    _usuarioAtualId = null;
    notifyListeners();
  }

  Usuario _exigirSessao() {
    final atual = usuarioAtual;
    if (atual == null || !atual.ativo) throw StateError('Entre no sistema antes de continuar.');
    return atual;
  }

  void _exigirAdmin() {
    if (_exigirSessao().perfil != Perfil.administrador) {
      throw StateError('Apenas a administração pode executar esta operação.');
    }
  }

  Usuario _exigirProfessor() {
    final atual = _exigirSessao();
    if (atual.perfil != Perfil.professor) throw StateError('Operação exclusiva do professor.');
    return atual;
  }

  Usuario criarUsuario({required String nome, required String email,
      required Perfil perfil, required String senhaInicial}) {
    _exigirAdmin();
    final nomeLimpo = nome.trim();
    final emailLimpo = email.trim().toLowerCase();
    if (perfil == Perfil.administrador) throw StateError('Criação de administradores não disponível nesta versão.');
    if (nomeLimpo.length < 3 || !emailLimpo.contains('@')) throw StateError('Preencha nome e e-mail válidos.');
    _validarSenha(senhaInicial);
    if (_usuarios.any((u) => u.email.toLowerCase() == emailLimpo)) throw StateError('Este e-mail já está cadastrado.');
    final criado = Usuario(
      id: 'user-${_proximoId++}',
      nome: nomeLimpo,
      email: emailLimpo,
      perfil: perfil,
      academiaId: _exigirSessao().academiaId,
    );
    _usuarios.add(criado);
    _credenciais[criado.id] = _gerarCredencial(senhaInicial);
    notifyListeners();
    return criado;
  }

  void agendarAvaliacao({required String alunoId, required DateTime data}) {
    _exigirAdmin();
    final aluno = _exigirAluno(alunoId);
    if (aluno.statusAvaliacao == StatusAvaliacao.concluida) throw StateError('A avaliação já foi concluída.');
    aluno.dataAvaliacao = data;
    aluno.statusAvaliacao = StatusAvaliacao.agendada;
    notifyListeners();
  }

  void concluirAvaliacao(String alunoId) {
    _exigirAdmin();
    final aluno = _exigirAluno(alunoId);
    aluno.statusAvaliacao = StatusAvaliacao.concluida;
    notifyListeners();
  }

  Usuario _exigirAluno(String id) {
    final aluno = usuarioPorId(id);
    if (aluno == null || aluno.perfil != Perfil.aluno || !aluno.ativo) throw StateError('Aluno não encontrado.');
    return aluno;
  }

  void vincularAluno({required String alunoId, required String professorId}) {
    final atual = _exigirSessao();
    if (atual.perfil != Perfil.administrador &&
        !(atual.perfil == Perfil.professor && atual.id == professorId)) {
      throw StateError('Você não tem permissão para este vínculo.');
    }
    final aluno = _exigirAluno(alunoId);
    final professor = usuarioPorId(professorId);
    if (professor == null || professor.perfil != Perfil.professor || !professor.ativo) throw StateError('Professor inválido.');
    if (aluno.academiaId != professor.academiaId || atual.academiaId != aluno.academiaId) {
      throw StateError('Usuários precisam pertencer à mesma academia.');
    }
    if (aluno.professorId != null) throw StateError('O aluno já está associado a um professor.');
    aluno.professorId = professorId;
    notifyListeners();
  }

  void desvincularAluno({required String alunoId, required String professorId}) {
    final atual = _exigirSessao();
    if (atual.perfil != Perfil.administrador &&
        !(atual.perfil == Perfil.professor && atual.id == professorId)) {
      throw StateError('Você não pode remover este vínculo.');
    }
    final aluno = _exigirAluno(alunoId);
    if (aluno.academiaId != atual.academiaId || aluno.professorId != professorId) {
      throw StateError('O vínculo informado não existe.');
    }
    aluno.professorId = null;
    // Conta, avaliações e fichas históricas são preservadas.
    notifyListeners();
  }

  ModeloTreino criarModelo({required String nome, required List<ExercicioPrescrito> exercicios}) {
    final professor = _exigirProfessor();
    if (nome.trim().isEmpty || exercicios.isEmpty) throw StateError('Informe nome e pelo menos um exercício.');
    final novo = ModeloTreino(
      id: 'modelo-${_proximoId++}',
      professorId: professor.id,
      nome: nome.trim(),
      exercicios: exercicios,
    );
    _modelos.add(novo);
    notifyListeners();
    return novo;
  }

  FichaAtribuida atribuirFicha({
    required String alunoId,
    required String modeloId,
    required String nome,
    required List<ExercicioPrescrito> exercicios,
  }) {
    final professor = _exigirProfessor();
    final aluno = _exigirAluno(alunoId);
    final modelo = _modelos.where((m) => m.id == modeloId).firstOrNull;
    if (aluno.professorId != professor.id || aluno.academiaId != professor.academiaId) {
      throw StateError('O aluno deve estar vinculado a você.');
    }
    if (aluno.statusAvaliacao != StatusAvaliacao.concluida) {
      throw StateError('A avaliação precisa estar concluída para atribuir um treino.');
    }
    if (modelo == null || modelo.professorId != professor.id) throw StateError('Modelo de treino inválido.');
    if (nome.trim().isEmpty || exercicios.isEmpty) throw StateError('A ficha precisa de nome e exercícios.');
    final ficha = FichaAtribuida(
      id: 'ficha-${_proximoId++}',
      alunoId: aluno.id,
      professorId: professor.id,
      nome: nome.trim(),
      criadaEm: DateTime.now(),
      exercicios: exercicios,
    );
    _fichas.add(ficha);
    notifyListeners();
    return ficha;
  }

  List<ModeloTreino> modelosDoProfessor(String professorId) =>
      List.unmodifiable(_modelos.where((m) => m.professorId == professorId));

  List<FichaAtribuida> fichasDoAluno(String alunoId) =>
      List.unmodifiable(_fichas.where((f) => f.alunoId == alunoId));

  List<FichaAtribuida> fichasDoProfessor(String professorId) =>
      List.unmodifiable(_fichas.where((f) => f.professorId == professorId));


  /// Arquiva conta local preservando histórico.
  /// Exclusão definitiva/LGPD exigirá fluxo apropriado de backend.
  void arquivarUsuario(String usuarioId) {
    _exigirAdmin();
    final usuario = usuarioPorId(usuarioId);
    if (usuario == null || !usuario.ativo || usuario.perfil == Perfil.administrador) {
      throw StateError('Não é possível arquivar esta conta.');
    }
    if (usuario.academiaId != _exigirSessao().academiaId) {
      throw StateError('Conta de outra academia.');
    }
    usuario.ativo = false;
    if (usuario.perfil == Perfil.professor) {
      for (final aluno in _usuarios) {
        if (aluno.professorId == usuario.id) aluno.professorId = null;
      }
    }
    if (_usuarioAtualId == usuarioId) _usuarioAtualId = null;
    notifyListeners();
  }

  /// Desativa o acesso local sem excluir os registros históricos.
  /// NÃO é exclusão definitiva de dados pessoais.
  void desativarPropriaConta() {
    final usuario = _exigirSessao();
    if (usuario.perfil == Perfil.administrador) {
      throw StateError('Admin não pode desativar a própria conta aqui.');
    }
    usuario.ativo = false;
    if (usuario.perfil == Perfil.professor) {
      for (final aluno in _usuarios) {
        if (aluno.professorId == usuario.id) aluno.professorId = null;
      }
    }
    _usuarioAtualId = null;
    notifyListeners();
  }

  ModeloTreino editarModelo({required String modeloId, required String nome,
      required List<ExercicioPrescrito> exercicios}) {
    final professor = _exigirProfessor();
    final indice = _modelos.indexWhere((m) => m.id == modeloId);
    if (indice == -1 || _modelos[indice].professorId != professor.id) {
      throw StateError('Você não pode alterar esse modelo.');
    }
    if (nome.trim().isEmpty || exercicios.isEmpty) {
      throw StateError('Informe nome e exercícios válidos.');
    }
    final editado = ModeloTreino(id: modeloId, professorId: professor.id,
      nome: nome.trim(), exercicios: exercicios);
    _modelos[indice] = editado;
    notifyListeners();
    return editado;
  }

  SessaoTreino iniciarSessao(String fichaId) {
    final aluno = _exigirSessao();
    if (aluno.perfil != Perfil.aluno) throw StateError('Apenas alunos iniciam sessões.');
    final ficha = _fichas.where((f) => f.id == fichaId).firstOrNull;
    if (ficha == null || ficha.alunoId != aluno.id) {
      throw StateError('Ficha não pertence ao aluno.');
    }
    final aberta = _sessoes.where((s) => s.alunoId == aluno.id &&
      s.fichaId == fichaId && s.finalizadaEm == null).firstOrNull;
    if (aberta != null) return aberta;
    final sessao = SessaoTreino(id: 'sessao-${_proximoId++}',
      alunoId: aluno.id, fichaId: fichaId, iniciadaEm: DateTime.now());
    _sessoes.add(sessao);
    notifyListeners();
    return sessao;
  }

  void finalizarSessao(String sessaoId) {
    final aluno = _exigirSessao();
    final sessao = _sessoes.where((s) => s.id == sessaoId).firstOrNull;
    if (aluno.perfil != Perfil.aluno || sessao == null ||
        sessao.alunoId != aluno.id || sessao.finalizadaEm != null) {
      throw StateError('Sessão inválida ou já finalizada.');
    }
    sessao.finalizadaEm = DateTime.now();
    notifyListeners();
  }

  /// Registra uma série na sessão sem alterar o que o professor prescreveu.
  RegistroSerie registrarSerie({required String sessaoId,
      required int exercicioIndice, required int serieNumero,
      required int repeticoes, required double cargaKg}) {
    final aluno = _exigirSessao();
    if (aluno.perfil != Perfil.aluno) throw StateError('Somente o aluno registra a execução.');
    final sessao = _sessoes.where((s) => s.id == sessaoId).firstOrNull;
    if (sessao == null || sessao.alunoId != aluno.id || sessao.finalizadaEm != null) {
      throw StateError('Sessão inválida ou finalizada.');
    }
    final ficha = _fichas.where((f) => f.id == sessao.fichaId).firstOrNull;
    if (ficha == null || ficha.alunoId != aluno.id) {
      throw StateError('Ficha indisponível.');
    }
    if (exercicioIndice < 0 || exercicioIndice >= ficha.exercicios.length) {
      throw StateError('Exercício inválido.');
    }
    final prescrito = ficha.exercicios[exercicioIndice];
    if (serieNumero < 1 || serieNumero > prescrito.series || repeticoes < 0 ||
        repeticoes > 300 || !cargaKg.isFinite || cargaKg < 0 || cargaKg > 2000) {
      throw StateError('Dados da série inválidos.');
    }
    _registros.removeWhere((r) => r.sessaoId == sessaoId &&
        r.exercicioIndice == exercicioIndice && r.serieNumero == serieNumero);
    final novo = RegistroSerie(id: 'registro-${_proximoId++}', alunoId: aluno.id,
      fichaId: ficha.id, sessaoId: sessaoId, exercicioIndice: exercicioIndice,
      serieNumero: serieNumero, repeticoes: repeticoes, cargaKg: cargaKg,
      concluidaEm: DateTime.now());
    _registros.add(novo);
    notifyListeners();
    return novo;
  }

  List<RegistroSerie> registrosDaSessao(String sessaoId) =>
    List.unmodifiable(_registros.where((r) => r.sessaoId == sessaoId));

  List<SessaoTreino> sessoesDoAluno(String alunoId) =>
    List.unmodifiable(_sessoes.where((s) => s.alunoId == alunoId));

  Map<String, dynamic> exportarDados() => {
    'formato': 2, 'proximoId': _proximoId,
    'credenciais': _credenciais.map((id, item) => MapEntry(id, item.toJson())),
    'usuarios': _usuarios.map((v) => v.toJson()).toList(),
    'modelos': _modelos.map((v) => v.toJson()).toList(),
    'fichas': _fichas.map((v) => v.toJson()).toList(),
    'registros': _registros.map((v) => v.toJson()).toList(),
    'sessoes': _sessoes.map((v) => v.toJson()).toList(),
  };

  /// Restaura dados locais; a sessão nunca é armazenada em disco.
  /// Aceita formato 1 da edição anterior para preservar cadastros e fichas.
  void importarDados(Map<String, dynamic> dados) {
    if (dados['formato'] != 1 && dados['formato'] != 2) {
      throw const FormatException('Formato incompatível.');
    }
    final usuarios = (dados['usuarios'] as List).map((e) =>
      Usuario.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final modelos = (dados['modelos'] as List).map((e) =>
      ModeloTreino.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final fichas = (dados['fichas'] as List).map((e) =>
      FichaAtribuida.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final registros = (dados['registros'] as List).map((e) =>
      RegistroSerie.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final sessoes = (dados['sessoes'] as List).map((e) =>
      SessaoTreino.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    if (!usuarios.any((u) => u.id == 'admin-1' && u.perfil == Perfil.administrador)) {
      throw const FormatException('Dados sem administrador principal.');
    }
    // No formato legado, credenciais padrão são reconstituídas para as
    // quatro contas iniciais; demais contas recebem senha via administrador.
    final credenciaisSalvas = dados['credenciais'];
    if (credenciaisSalvas is Map) {
      final importadas = <String, _Credencial>{};
      for (final entrada in credenciaisSalvas.entries) {
        importadas[entrada.key as String] = _Credencial.fromJson(
          Map<String, dynamic>.from(entrada.value as Map));
      }
      _credenciais..clear()..addAll(importadas);
    }
    _usuarios..clear()..addAll(usuarios);
    _modelos..clear()..addAll(modelos);
    _fichas..clear()..addAll(fichas);
    _registros..clear()..addAll(registros);
    _sessoes..clear()..addAll(sessoes);
    _proximoId = (dados['proximoId'] as num).toInt();
    _usuarioAtualId = null;
    notifyListeners();
  }

}

/// Apenas hash com salt é gravado no dispositivo (não a senha original).
class _Credencial {
  const _Credencial(this.salt, this.hash);
  final String salt;
  final String hash;
  Map<String, String> toJson() => {'salt': salt, 'hash': hash};
  factory _Credencial.fromJson(Map<String, dynamic> json) =>
      _Credencial(json['salt'] as String, json['hash'] as String);
}
