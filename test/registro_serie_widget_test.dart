import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:academia_app/domain/academia_store.dart';
import 'package:academia_app/features/aluno/telas_aluno.dart';

void main() {
  testWidgets('salvar série fecha diálogo e atualiza a sessão sem exceção',
      (tester) async {
    final store = AcademiaStore();
    addTearDown(store.dispose);

    store.entrar(email: 'bruno@exemplo.test', senha: 'Prof@2026!');
    store.vincularAluno(alunoId: 'aluno-1', professorId: 'prof-1');
    final ficha = store.atribuirFicha(
      alunoId: 'aluno-1',
      modeloId: 'modelo-1',
      nome: 'Treino de teste',
      exercicios: store.modelos.first.exercicios,
    );
    store.entrar(email: 'carla@exemplo.test', senha: 'Aluna@2026!');

    await tester.pumpWidget(MaterialApp(
      home: ExecutarTreino(store: store, ficha: ficha),
    ));
    await tester.tap(find.text('Iniciar treino'));
    await tester.pump();
    final concluir = find.text('Concluir').first;
    await tester.ensureVisible(concluir);
    await tester.tap(concluir);
    await tester.pumpAndSettle();
    expect(find.text('Salvar série'), findsOneWidget);

    await tester.tap(find.text('Salvar série'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(store.registros.length, 1);
    expect(store.registros.first.cargaKg, 15);
    expect(ficha.exercicios.first.cargaKg, 15);
    expect(find.text('1/6'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
