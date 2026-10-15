import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:academia_app/domain/academia_store.dart';
import 'package:academia_app/domain/models.dart';

void main() {
  late AcademiaStore store;
  setUp(() => store = AcademiaStore());
  tearDown(() => store.dispose());

  FichaAtribuida prepararFicha() {
    store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!');
    store.vincularAluno(alunoId: 'aluno-1', professorId: 'prof-1');
    return store.atribuirFicha(alunoId: 'aluno-1', modeloId: 'modelo-1',
      nome: 'Ficha de teste', exercicios: store.modelos.first.exercicios);
  }

  test('aluno registra série sem modificar a prescrição', () {
    final ficha = prepararFicha();
    store.entrar(email: 'carla@exemplo.test', senha: 'Aluna@2026!');
    final sessao = store.iniciarSessao(ficha.id);
    store.registrarSerie(sessaoId: sessao.id, exercicioIndice: 0,
      serieNumero: 1, repeticoes: 11, cargaKg: 27);
    expect(store.registrosDaSessao(sessao.id).single.cargaKg, 27);
    expect(ficha.exercicios.first.cargaKg, 15);
  });

  test('duas sessões na mesma ficha preservam histórico', () {
    final ficha = prepararFicha();
    store.entrar(email: 'carla@exemplo.test', senha: 'Aluna@2026!');
    final primeira = store.iniciarSessao(ficha.id);
    store.registrarSerie(sessaoId: primeira.id, exercicioIndice: 0,
      serieNumero: 1, repeticoes: 12, cargaKg: 17);
    store.finalizarSessao(primeira.id);
    final segunda = store.iniciarSessao(ficha.id);
    expect(segunda.id, isNot(primeira.id));
    expect(store.sessoesDoAluno('aluno-1').length, 2);
    expect(store.registrosDaSessao(primeira.id).length, 1);
    expect(store.registrosDaSessao(segunda.id), isEmpty);
  });

  test('professor não registra série em nome do aluno', () {
    final ficha = prepararFicha();
    expect(() => store.iniciarSessao(ficha.id), throwsStateError);
  });

  test('edição de modelo não altera ficha já atribuída', () {
    final ficha = prepararFicha();
    store.editarModelo(modeloId: 'modelo-1', nome: 'Novo nome',
      exercicios: const [ExercicioPrescrito(nome: 'Agachamento', series: 3,
        repeticoes: 12, cargaKg: 33, descansoSegundos: 60)]);
    expect(store.modelos.first.nome, 'Novo nome');
    expect(ficha.exercicios.first.nome, 'Puxada frontal');
  });

  test('desvincular preserva conta, ficha, sessão e registros', () {
    final ficha = prepararFicha();
    store.entrar(email: 'carla@exemplo.test', senha: 'Aluna@2026!');
    final sessao = store.iniciarSessao(ficha.id);
    store.registrarSerie(sessaoId: sessao.id, exercicioIndice: 0,
      serieNumero: 1, repeticoes: 12, cargaKg: 20);
    store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!');
    store.desvincularAluno(alunoId: 'aluno-1', professorId: 'prof-1');
    expect(store.usuarioPorId('aluno-1'), isNotNull);
    expect(store.fichasDoAluno('aluno-1').length, 1);
    expect(store.registrosDaSessao(sessao.id).length, 1);
  });

  test('dados podem fazer ida e volta em JSON sem salvar login', () {
    final ficha = prepararFicha();
    store.entrar(email: 'carla@exemplo.test', senha: 'Aluna@2026!');
    final sessao = store.iniciarSessao(ficha.id);
    store.registrarSerie(sessaoId: sessao.id, exercicioIndice: 0,
      serieNumero: 1, repeticoes: 10, cargaKg: 22);
    final dados = jsonDecode(jsonEncode(store.exportarDados())) as Map<String, dynamic>;
    final outra = AcademiaStore();
    addTearDown(outra.dispose);
    outra.importarDados(dados);
    expect(outra.usuarioAtual, isNull);
    expect(outra.fichas.length, 1);
    expect(outra.sessoes.length, 1);
    expect(outra.registros.single.cargaKg, 22);
  });

  test('admin arquiva professor e aluno fica sem vínculo', () {
    store.entrar(email: 'ana@exemplo.test', senha: 'Admin@2026!');
    store.vincularAluno(alunoId: 'aluno-1', professorId: 'prof-1');
    store.arquivarUsuario('prof-1');
    expect(store.usuarioPorId('aluno-1')!.professorId, isNull);
    expect(() => store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!'), throwsStateError);
  });
}
