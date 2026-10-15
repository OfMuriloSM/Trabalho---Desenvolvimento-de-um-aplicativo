/// Entidades da aplicação. Contas iniciais de avaliação são fictícias.
enum Perfil { administrador, professor, aluno }
enum StatusAvaliacao { pendente, agendada, concluida }

extension PerfilRotulo on Perfil {
  String get rotulo => switch (this) {
        Perfil.administrador => 'Administração',
        Perfil.professor => 'Professor',
        Perfil.aluno => 'Aluno',
      };
}

extension StatusAvaliacaoRotulo on StatusAvaliacao {
  String get rotulo => switch (this) {
        StatusAvaliacao.pendente => 'Pendente',
        StatusAvaliacao.agendada => 'Agendada',
        StatusAvaliacao.concluida => 'Concluída',
      };
}

class Usuario {
  Usuario({required this.id, required this.nome, required this.email,
    required this.perfil, required this.academiaId, this.professorId,
    this.statusAvaliacao = StatusAvaliacao.pendente, this.dataAvaliacao,
    this.ativo = true});

  final String id;
  final String nome;
  final String email;
  final Perfil perfil;
  final String academiaId;
  String? professorId;
  StatusAvaliacao statusAvaliacao;
  DateTime? dataAvaliacao;
  bool ativo;

  Map<String, dynamic> toJson() => {
    'id': id, 'nome': nome, 'email': email, 'perfil': perfil.name,
    'academiaId': academiaId, 'professorId': professorId,
    'statusAvaliacao': statusAvaliacao.name,
    'dataAvaliacao': dataAvaliacao?.toIso8601String(), 'ativo': ativo,
  };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as String, nome: json['nome'] as String,
    email: json['email'] as String,
    perfil: Perfil.values.byName(json['perfil'] as String),
    academiaId: json['academiaId'] as String,
    professorId: json['professorId'] as String?,
    statusAvaliacao: StatusAvaliacao.values.byName(
      (json['statusAvaliacao'] as String?) ?? 'pendente'),
    dataAvaliacao: DateTime.tryParse(json['dataAvaliacao'] as String? ?? ''),
    ativo: json['ativo'] as bool? ?? true,
  );
}

class ExercicioPrescrito {
  const ExercicioPrescrito({required this.nome, required this.series,
    required this.repeticoes, required this.cargaKg,
    required this.descansoSegundos, this.observacao = ''});
  final String nome;
  final int series;
  final int repeticoes;
  final double cargaKg;
  final int descansoSegundos;
  final String observacao;

  ExercicioPrescrito copiar() => ExercicioPrescrito(nome: nome,
    series: series, repeticoes: repeticoes, cargaKg: cargaKg,
    descansoSegundos: descansoSegundos, observacao: observacao);

  Map<String, dynamic> toJson() => {
    'nome': nome, 'series': series, 'repeticoes': repeticoes,
    'cargaKg': cargaKg, 'descansoSegundos': descansoSegundos,
    'observacao': observacao,
  };
  factory ExercicioPrescrito.fromJson(Map<String, dynamic> json) => ExercicioPrescrito(
    nome: json['nome'] as String, series: (json['series'] as num).toInt(),
    repeticoes: (json['repeticoes'] as num).toInt(),
    cargaKg: (json['cargaKg'] as num).toDouble(),
    descansoSegundos: (json['descansoSegundos'] as num).toInt(),
    observacao: json['observacao'] as String? ?? '',
  );
}

class ModeloTreino {
  ModeloTreino({required this.id, required this.professorId,
    required this.nome, required List<ExercicioPrescrito> exercicios})
      : exercicios = List.unmodifiable(exercicios.map((e) => e.copiar()));
  final String id;
  final String professorId;
  final String nome;
  final List<ExercicioPrescrito> exercicios;

  Map<String, dynamic> toJson() => {
    'id': id, 'professorId': professorId, 'nome': nome,
    'exercicios': exercicios.map((e) => e.toJson()).toList(),
  };
  factory ModeloTreino.fromJson(Map<String, dynamic> json) => ModeloTreino(
    id: json['id'] as String, professorId: json['professorId'] as String,
    nome: json['nome'] as String,
    exercicios: (json['exercicios'] as List).map(
      (e) => ExercicioPrescrito.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
  );
}

class FichaAtribuida {
  FichaAtribuida({required this.id, required this.alunoId,
    required this.professorId, required this.nome, required this.criadaEm,
    required List<ExercicioPrescrito> exercicios})
      : exercicios = List.unmodifiable(exercicios.map((e) => e.copiar()));
  final String id;
  final String alunoId;
  final String professorId;
  final String nome;
  final DateTime criadaEm;
  final List<ExercicioPrescrito> exercicios;

  Map<String, dynamic> toJson() => {
    'id': id, 'alunoId': alunoId, 'professorId': professorId,
    'nome': nome, 'criadaEm': criadaEm.toIso8601String(),
    'exercicios': exercicios.map((e) => e.toJson()).toList(),
  };
  factory FichaAtribuida.fromJson(Map<String, dynamic> json) => FichaAtribuida(
    id: json['id'] as String, alunoId: json['alunoId'] as String,
    professorId: json['professorId'] as String, nome: json['nome'] as String,
    criadaEm: DateTime.parse(json['criadaEm'] as String),
    exercicios: (json['exercicios'] as List).map(
      (e) => ExercicioPrescrito.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
  );
}

/// Registro da execução do aluno; separado da prescrição original.
class SessaoTreino {
  SessaoTreino({required this.id, required this.alunoId, required this.fichaId,
    required this.iniciadaEm, this.finalizadaEm});
  final String id;
  final String alunoId;
  final String fichaId;
  final DateTime iniciadaEm;
  DateTime? finalizadaEm;
  Map<String, dynamic> toJson() => {
    'id': id, 'alunoId': alunoId, 'fichaId': fichaId,
    'iniciadaEm': iniciadaEm.toIso8601String(),
    'finalizadaEm': finalizadaEm?.toIso8601String(),
  };
  factory SessaoTreino.fromJson(Map<String, dynamic> json) => SessaoTreino(
    id: json['id'] as String, alunoId: json['alunoId'] as String,
    fichaId: json['fichaId'] as String,
    iniciadaEm: DateTime.parse(json['iniciadaEm'] as String),
    finalizadaEm: DateTime.tryParse(json['finalizadaEm'] as String? ?? ''),
  );
}

class RegistroSerie {
  RegistroSerie({required this.id, required this.alunoId, required this.fichaId,
    required this.sessaoId, required this.exercicioIndice, required this.serieNumero,
    required this.repeticoes, required this.cargaKg, required this.concluidaEm});
  final String id;
  final String alunoId;
  final String fichaId;
  final String sessaoId;
  final int exercicioIndice;
  final int serieNumero;
  final int repeticoes;
  final double cargaKg;
  final DateTime concluidaEm;

  Map<String, dynamic> toJson() => {
    'id': id, 'alunoId': alunoId, 'fichaId': fichaId, 'sessaoId': sessaoId,
    'exercicioIndice': exercicioIndice, 'serieNumero': serieNumero,
    'repeticoes': repeticoes, 'cargaKg': cargaKg,
    'concluidaEm': concluidaEm.toIso8601String(),
  };
  factory RegistroSerie.fromJson(Map<String, dynamic> json) => RegistroSerie(
    id: json['id'] as String, alunoId: json['alunoId'] as String,
    fichaId: json['fichaId'] as String, sessaoId: json['sessaoId'] as String,
    exercicioIndice: (json['exercicioIndice'] as num).toInt(),
    serieNumero: (json['serieNumero'] as num).toInt(),
    repeticoes: (json['repeticoes'] as num).toInt(),
    cargaKg: (json['cargaKg'] as num).toDouble(),
    concluidaEm: DateTime.parse(json['concluidaEm'] as String),
  );
}
