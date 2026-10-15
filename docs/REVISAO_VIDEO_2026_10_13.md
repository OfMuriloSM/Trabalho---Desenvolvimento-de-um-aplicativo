# Revisão do vídeo de execução — 13/10/2026

## Observado

- A interface responsiva está sendo testada em janela estreita no Edge.
- Cadastro administrativo valida e-mail inválido e permite continuar após ajuste.
- Telas de avaliações, vínculos e modelos são navegáveis.
- Na execução da primeira série do aluno, ao pressionar **Salvar série** (aproximadamente 03:22), aparece tela vermelha com `Assertion failed: _dependents.isEmpty is not true`.

## Hipótese técnica e correção

No `lib/features/aluno/telas_aluno.dart`, o diálogo anterior executava `TextEditingController.dispose()` imediatamente ao retornar de `showDialog()`, enquanto a animação de saída da rota podia continuar. O registro da série também chamava `notifyListeners()` antes da remoção completa do overlay.

A implementação foi alterada para dar ciclo de vida próprio aos controladores do diálogo (`StatefulWidget`) e atualizar a store após `DialogRoute.completed`. Essa mudança reduz o risco de reconstrução com overlay em encerramento. **A causa exata depende de confirmação por teste no SDK Flutter do usuário.**

## Verificações

- [ ] `flutter analyze` sem erros.
- [ ] `flutter test` incluindo teste de regressão.
- [ ] Registro da primeira série e edição de uma série existente sem tela vermelha.
- [ ] Conclusão da sessão preserva histórico.
- [ ] `flutter build apk --debug` e instalação em celular Android.

## Situação

Projeto continua em DEMO LOCAL. Não há autenticação real, permissão RLS ou sincronização entre dispositivos.
