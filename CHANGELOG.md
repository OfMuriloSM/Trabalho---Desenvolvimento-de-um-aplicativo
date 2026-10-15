# Histórico de versões

## 1.0.0 — 15/10/2026

- Interface de login por e-mail e senha em substituição à seleção livre de perfis.
- Cadastro de contas com senha inicial, redefinição administrativa e troca pelo próprio usuário.
- Credenciais locais armazenadas como hashes com sal; sessão encerrada no logout.
- Persistência local compatível com a base de dados da versão anterior.
- Permissões funcionais para administração, professor e aluno.
- Avaliações, vínculos, modelos de treino, fichas e registro/histórico de séries.
- Identidade visual independente; documentação da equipe e das contas de avaliação.

**Limite:** autenticação e permissões locais, sem backend ou sincronização; não usar em produção.

### Revisao de compilacao (15/10/2026)

- Corrigida responsividade do titulo na barra superior, evitando overflow em testes.
- Eliminada recomendacao de sintaxe no componente `Cabecalho`.
- Desativado temporariamente o cache incremental Kotlin no Android e reduzido uso de memoria do Gradle para build em Windows.
- Adicionado `VALIDAR_ENTREGA.cmd`: identifica e renomeia o `screens.dart` obsoleto de instalacoes anteriores, limpa, analisa, testa e compila.
- Mantida a V1 com persistencia local, sem representar autenticação no servidor.
