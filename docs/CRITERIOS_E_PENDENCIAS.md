# Critérios de aceite — V1.0.0 acadêmica

## Validar no Windows antes de publicar

- [ ] `flutter pub get`
- [ ] `flutter analyze` sem erros
- [ ] `flutter test` com todos os testes aprovados
- [ ] Login por e-mail e senha com 4 contas iniciais
- [ ] Senha incorreta recusa acesso; logout exige novo login
- [ ] Administração cadastra professor/aluno com senha inicial
- [ ] Administração agenda ou conclui avaliação
- [ ] Professor vincula e desvincula aluno já cadastrado
- [ ] Treino só pode ser prescrito após avaliação concluída
- [ ] Modelo reutilizável mantém prescrição individual independente
- [ ] Aluno conclui séries com carga e repetições; histórico permanece
- [ ] Reiniciar navegador preserva cadastros e senhas alteradas **nesse navegador**
- [ ] Tela Web se adapta a desktop e largura de smartphone
- [ ] `flutter build apk --debug` e instalação real no celular

## Limites desta entrega

- **Funciona sem servidor:** cadastro, login com verificação local de senha, vínculos, avaliação, treinos e histórico.
- **Não há:** autenticação de servidor, sincronização entre aparelhos, controle de acesso confiável no backend, administração multiacademia, infraestrutura comercial ou exclusão definitiva LGPD.
- Os dados são guardados por `shared_preferences` sem criptografia do conteúdo. **Usar exclusivamente contas e dados fictícios.**
- Contas iniciais são públicas no README e servem para a banca avaliar os três perfis.
- O projeto inclui esboço SQL Supabase em `supabase/migrations/`, não aplicado e não integrado.
- Esta versão não foi compilada no ambiente onde o ZIP foi preparado; a validação Flutter deverá ocorrer no computador de desenvolvimento.

## Próximas versões

- V1.1: backend Supabase/Firebase configurado, cadastro administrativo via servidor, RLS, sincronização e testes multiusuário.
- V1.2+: históricos detalhados, biblioteca de exercícios, métricas e evolução comercial.
