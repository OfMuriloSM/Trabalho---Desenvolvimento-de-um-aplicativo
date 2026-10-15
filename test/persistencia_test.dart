import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:academia_app/domain/academia_store.dart';
import 'package:academia_app/domain/models.dart';
import 'package:academia_app/domain/persistencia_local.dart';

void main() {
  test('persistência restaura cadastros e credenciais após reinicialização', () async {
    SharedPreferences.setMockInitialValues({});
    final primeiro = AcademiaStore();
    final persistencia = await PersistenciaLocal.iniciar(primeiro);
    primeiro.entrar(email: 'ana@exemplo.test', senha: 'Admin@2026!');
    primeiro.criarUsuario(nome: 'Teste Local',
      email: 'local@example.test', perfil: Perfil.aluno, senhaInicial: 'Teste@2026!');
    await persistencia.aguardarGravacao();
    persistencia.dispose();
    primeiro.dispose();

    final segundo = AcademiaStore();
    final restaurada = await PersistenciaLocal.iniciar(segundo);
    expect(segundo.alunos.any((a) => a.nome == 'Teste Local'), isTrue);
    expect(segundo.usuarioAtual, isNull);
    segundo.entrar(email: 'local@example.test', senha: 'Teste@2026!');
    expect(segundo.usuarioAtual?.nome, 'Teste Local');
    restaurada.dispose();
    segundo.dispose();
  });
}
