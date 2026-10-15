import 'package:flutter_test/flutter_test.dart';
import 'package:academia_app/domain/academia_store.dart';
import 'package:academia_app/domain/models.dart';

void main() {
  late AcademiaStore store;
  setUp(() => store = AcademiaStore());
  tearDown(() => store.dispose());

  test('e-mail e senha válidos identificam perfil correto', () {
    store.entrar(email: 'ANA@EXEMPLO.TEST', senha: 'Admin@2026!');
    expect(store.usuarioAtual?.perfil, Perfil.administrador);
  });

  test('senha inválida e usuário desconhecido são bloqueados', () {
    expect(() => store.entrar(email: 'ana@exemplo.test', senha: 'errada'),
      throwsStateError);
    expect(() => store.entrar(email: 'nada@exemplo.test', senha: 'Admin@2026!'),
      throwsStateError);
    expect(store.usuarioAtual, isNull);
  });

  test('administrador cria conta com senha inicial e aluno autentica', () {
    store.entrar(email: 'ana@exemplo.test', senha: 'Admin@2026!');
    store.criarUsuario(nome: 'Nova Aluna', email: 'nova@exemplo.test',
      perfil: Perfil.aluno, senhaInicial: 'Inicial@2026');
    store.sair();
    store.entrar(email: 'nova@exemplo.test', senha: 'Inicial@2026');
    expect(store.usuarioAtual?.nome, 'Nova Aluna');
    expect(store.usuarioAtual?.perfil, Perfil.aluno);
  });

  test('troca de senha invalida a senha anterior', () {
    store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!');
    store.alterarMinhaSenha(senhaAtual: 'Prof@2026!',
      novaSenha: 'NovaSenha@2026');
    store.sair();
    expect(() => store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!'),
      throwsStateError);
    store.entrar(email: 'bruno@exemplo.test', senha: 'NovaSenha@2026');
    expect(store.usuarioAtual?.perfil, Perfil.professor);
  });

  test('não restaura sessão após serialização; restaura hashes', () {
    store.entrar(email: 'ana@exemplo.test', senha: 'Admin@2026!');
    store.alterarMinhaSenha(senhaAtual: 'Admin@2026!',
      novaSenha: 'NovaSenha@2026');
    final dados = store.exportarDados();
    expect(dados.toString().contains('NovaSenha@2026'), isFalse);
    final restaurado = AcademiaStore();
    addTearDown(restaurado.dispose);
    restaurado.importarDados(dados);
    expect(restaurado.usuarioAtual, isNull);
    restaurado.entrar(email: 'ana@exemplo.test', senha: 'NovaSenha@2026');
    expect(restaurado.usuarioAtual?.perfil, Perfil.administrador);
  });

  test('professor não redefine senha de terceiros', () {
    store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!');
    expect(() => store.redefinirSenha(usuarioId: 'aluno-1',
      novaSenha: 'NovaSenha@2026'), throwsStateError);
  });
}
