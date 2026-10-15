import 'package:flutter_test/flutter_test.dart';
import 'package:academia_app/domain/academia_store.dart';
import 'package:academia_app/domain/models.dart';

void main() {
  late AcademiaStore store;
  setUp(() => store = AcademiaStore());
  tearDown(() => store.dispose());

  test('administrador cadastra aluno sem professor', () {
    store.entrar(email: 'ana@exemplo.test', senha: 'Admin@2026!');
    final aluno = store.criarUsuario(nome: 'Pessoa Teste', email: 'pessoa@example.test', perfil: Perfil.aluno, senhaInicial: 'Teste@2026!');
    expect(aluno.professorId, isNull);
    expect(aluno.statusAvaliacao, StatusAvaliacao.pendente);
  });

  test('professor não pode cadastrar aluno', () {
    store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!');
    expect(() => store.criarUsuario(nome: 'Pessoa Teste', email: 'pessoa@example.test', perfil: Perfil.aluno, senhaInicial: 'Teste@2026!'), throwsStateError);
  });

  test('professor vincula e desvincula sem apagar conta', () {
    store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!');
    store.vincularAluno(alunoId: 'aluno-1', professorId: 'prof-1');
    expect(store.usuarioPorId('aluno-1')?.professorId, 'prof-1');
    store.desvincularAluno(alunoId: 'aluno-1', professorId: 'prof-1');
    expect(store.usuarioPorId('aluno-1'), isNotNull);
    expect(store.usuarioPorId('aluno-1')?.professorId, isNull);
  });

  test('aluno sem avaliação concluída não pode receber ficha', () {
    store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!');
    store.vincularAluno(alunoId: 'aluno-2', professorId: 'prof-1');
    expect(
      () => store.atribuirFicha(
        alunoId: 'aluno-2', modeloId: 'modelo-1', nome: 'Ficha do Daniel',
        exercicios: store.modelos.first.exercicios,
      ),
      throwsStateError,
    );
  });

  test('ficha personalizada não modifica modelo e persiste após desvínculo em memória', () {
    store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!');
    store.vincularAluno(alunoId: 'aluno-1', professorId: 'prof-1');
    final modelo = store.modelos.first;
    final personalizados = [
      const ExercicioPrescrito(nome: 'Puxada frontal', series: 4, repeticoes: 10, cargaKg: 22, descansoSegundos: 75, observacao: 'Controle a descida.'),
    ];
    final ficha = store.atribuirFicha(alunoId: 'aluno-1', modeloId: modelo.id, nome: 'Ficha individual', exercicios: personalizados);
    expect(ficha.exercicios.first.cargaKg, 22);
    expect(modelo.exercicios.first.cargaKg, 15);
    store.desvincularAluno(alunoId: 'aluno-1', professorId: 'prof-1');
    expect(store.fichasDoAluno('aluno-1'), contains(ficha));
  });

  test('aluno não pode alterar vínculos', () {
    store.entrar(email: 'carla@exemplo.test', senha: 'Aluna@2026!');
    expect(() => store.vincularAluno(alunoId: 'aluno-1', professorId: 'prof-1'), throwsStateError);
  });

  test('administrador pode concluir avaliação e permitir prescrição', () {
    store.entrar(email: 'ana@exemplo.test', senha: 'Admin@2026!');
    store.concluirAvaliacao('aluno-2');
    expect(store.usuarioPorId('aluno-2')?.statusAvaliacao, StatusAvaliacao.concluida);
    store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!');
    store.vincularAluno(alunoId: 'aluno-2', professorId: 'prof-1');
    final ficha = store.atribuirFicha(
      alunoId: 'aluno-2', modeloId: 'modelo-1', nome: 'Ficha liberada', exercicios: store.modelos.first.exercicios,
    );
    expect(ficha.alunoId, 'aluno-2');
  });
}
