# Academia — Gestão de Alunos e Treinos

**Versão:** 1.0.0 · **Curso:** Análise e Desenvolvimento de Sistemas · **Disciplina:** Programação para Dispositivos Móveis

## Equipe

- Murilo Soares Maciel
- Richard Gabriel Vasconcelos Martins
- Francisco Wesley Rocha Felix
- Francisco Gustavo Tabosa Vaz
- Joao Pedro Mesquita Silva

## Sobre o sistema

Aplicativo desenvolvido em **Flutter/Dart** para organizar o cotidiano de uma academia. Reúne o cadastro de alunos e professores, agendamento e situação das avaliações, associação entre alunos e professores, criação de modelos de treino, prescrição individualizada e acompanhamento das séries realizadas.

O mesmo projeto possui uma interface adaptável a **Android e Web**, com navegação separada por perfil de acesso.

## Funcionalidades principais

- **Administração:** cadastro com senha inicial, consulta e arquivamento de contas, definição de vínculos e controle das avaliações.
- **Professor:** consulta de alunos, vínculo/desvínculo, criação e edição de modelos e atribuição personalizada de treinos.
- **Aluno:** fichas, execução de séries, registro de cargas e repetições, descanso e histórico.
- **Conta:** acesso por e-mail/senha, alteração de senha, saída segura da sessão e redefinição de senha pela administração.

## Contas iniciais para avaliação

| Perfil | Usuário | E-mail | Senha inicial |
| --- | --- | --- | --- |
| Administração | Ana | `ana@exemplo.test` | `Admin@2026!` |
| Professor | Bruno | `bruno@exemplo.test` | `Prof@2026!` |
| Aluna | Carla | `carla@exemplo.test` | `Aluna@2026!` |
| Aluno | Daniel | `daniel@exemplo.test` | `Aluno@2026!` |

**Como avaliar:** acesse a conta administrativa e conclua a avaliação de um aluno; entre como professor, vincule-o e atribua um treino; depois acesse como aluno para consultar a ficha e registrar uma sessão.

> As credenciais acima são **exclusivamente de teste** e aparecem publicamente neste repositório. A edição V1 acadêmica utiliza autenticação **local** por senha e persistência no navegador/dispositivo, **sem banco online ou sincronização entre computadores**. Os dados de cadastro e treino não são criptografados; **não cadastre pessoas reais**. O uso comercial exigirá um backend e regras de segurança no servidor.

## Instalação e execução

Requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install), Dart e um navegador compatível ou Android SDK.

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Abra `http://127.0.0.1:8080` no navegador. Para gerar o APK de avaliação:

```bash
flutter build apk --debug
```

O APK é gerado em `build/app/outputs/flutter-apk/app-debug.apk`. No GitHub, o workflow **Validação Flutter e APK** também pode gerar um APK de avaliação na seção **Actions → Artifacts**. A versão de produção exigirá assinatura de release própria.

**Observação:** dados salvos no navegador Web não são compartilhados automaticamente com o aplicativo Android. A aplicação tem migração dos registros locais criados na versão anterior no mesmo dispositivo.

---

Projeto acadêmico independente; identidade visual própria com preto, grafite e vermelho. Não possui vínculo com outras marcas ou empresas.
