import 'package:flutter/material.dart';
import '../../core/componentes.dart';
import '../../core/tema.dart';
import '../../domain/academia_store.dart';
import '../../domain/models.dart';

class PainelAdmin extends StatelessWidget {
  const PainelAdmin({super.key, required this.store});
  final AcademiaStore store;
  @override
  Widget build(BuildContext context) {
    final alunos = store.alunos;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Cabecalho(titulo: 'Visão geral',
        subtitulo: 'O pulso da sua academia, em um só lugar.',
        icone: Icons.space_dashboard_outlined),
      const SizedBox(height: 16),
      Wrap(spacing: 12, runSpacing: 8, children: [
        Estatistica(icone: Icons.people, valor: '${alunos.length}', rotulo: 'Alunos ativos'),
        Estatistica(icone: Icons.school_outlined, valor: '${store.professores.length}',
          rotulo: 'Professores', cor: Paleta.verde),
        Estatistica(icone: Icons.person_add_alt_1, valor: '${alunos.where((a) => a.professorId == null).length}',
          rotulo: 'Aguardando professor', cor: Paleta.amarelo),
        Estatistica(icone: Icons.pending_actions_outlined,
          valor: '${alunos.where((a) => a.statusAvaliacao != StatusAvaliacao.concluida).length}',
          rotulo: 'Avaliações pendentes'),
      ]),
      const SizedBox(height: 14),
      Secao(titulo: 'Próximas avaliações', descricao: 'Agenda operacional da recepção',
        filho: Builder(builder: (context) {
          final lista = alunos.where((a) => a.statusAvaliacao == StatusAvaliacao.agendada).toList()
            ..sort((a,b) => (a.dataAvaliacao ?? DateTime(9999)).compareTo(b.dataAvaliacao ?? DateTime(9999)));
          return lista.isEmpty ? const Vazio(icone: Icons.event_available,
              titulo: 'Agenda livre', mensagem: 'Os agendamentos aparecerão aqui.')
            : Column(children: [for (final aluno in lista.take(8)) ListTile(
              leading: const CircleAvatar(child: Icon(Icons.calendar_month)),
              title: Text(aluno.nome), subtitle: Text(dataCurta(aluno.dataAvaliacao)),
              trailing: StatusChip(status: aluno.statusAvaliacao))]);
        })),
      const Secao(titulo: 'Como funciona', filho: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('01  Recepção cadastra aluno e agenda avaliação.'),
          SizedBox(height: 10),
          Text('02  Após a avaliação, a recepção confirma seu status.'),
          SizedBox(height: 10),
          Text('03  Professor localiza e vincula o aluno à própria lista.'),
          SizedBox(height: 10),
          Text('04  Professor atribui um treino personalizado.'),
          SizedBox(height: 10),
          Text('05  Aluno consulta e registra a execução.'),
        ])),
    ]);
  }
}

class PessoasAdmin extends StatefulWidget {
  const PessoasAdmin({super.key, required this.store});
  final AcademiaStore store;
  @override
  State<PessoasAdmin> createState() => _PessoasAdminState();
}
class _PessoasAdminState extends State<PessoasAdmin> {
  String busca = '';
  @override
  Widget build(BuildContext context) {
    final todos = widget.store.usuarios.where((u) => u.ativo &&
      u.perfil != Perfil.administrador &&
      (u.nome.toLowerCase().contains(busca.toLowerCase()) ||
        u.email.toLowerCase().contains(busca.toLowerCase()))).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Cabecalho(titulo: 'Pessoas & vínculos', subtitulo: 'Cadastros e associação professor–aluno.',
        icone: Icons.people_outline),
      const SizedBox(height: 14),
      Secao(titulo: 'Usuários da academia',
        acao: FilledButton.icon(onPressed: () => showDialog<void>(context: context,
            builder: (_) => _NovoUsuarioDialog(store: widget.store)),
          icon: const Icon(Icons.person_add_alt_1), label: const Text('Novo cadastro')),
        filho: Column(children: [
          TextField(onChanged: (v) => setState(() => busca = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nome ou e-mail')),
          const SizedBox(height: 12),
          if (todos.isEmpty) const Vazio(icone: Icons.manage_search,
            titulo: 'Nenhum resultado', mensagem: 'Tente outro nome ou cadastre uma pessoa.'),
          for (final pessoa in todos) _PessoaAdminTile(store: widget.store, pessoa: pessoa),
        ])),
    ]);
  }
}

class _PessoaAdminTile extends StatelessWidget {
  const _PessoaAdminTile({required this.store, required this.pessoa});
  final AcademiaStore store;
  final Usuario pessoa;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ListTile(contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: Paleta.superficieClara,
          child: Text(pessoa.nome.substring(0,1).toUpperCase(),
            style: const TextStyle(color: Paleta.vermelho, fontWeight: FontWeight.w800))),
        title: Text(pessoa.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${pessoa.email} · ${pessoa.perfil.rotulo}',
          style: const TextStyle(fontSize: 12))),
      if (pessoa.perfil == Perfil.aluno) ...[
        Text('Professor: ${store.usuarioPorId(pessoa.professorId)?.nome ?? 'Não associado'}',
          style: const TextStyle(color: Paleta.secundario, fontSize: 12)),
        const SizedBox(height: 9),
      ],
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (pessoa.perfil == Perfil.aluno && pessoa.professorId == null)
          OutlinedButton.icon(onPressed: () => _vincular(context),
            icon: const Icon(Icons.link), label: const Text('Associar professor')),
        if (pessoa.perfil == Perfil.aluno && pessoa.professorId != null)
          OutlinedButton.icon(onPressed: () => executar(context, () => store.desvincularAluno(
            alunoId: pessoa.id, professorId: pessoa.professorId!),
            sucesso: 'Vínculo encerrado sem excluir o aluno.'),
            icon: const Icon(Icons.link_off), label: const Text('Desvincular')),
        OutlinedButton.icon(onPressed: () => _redefinirSenha(context),
          icon: const Icon(Icons.key), label: const Text('Redefinir senha')),
        TextButton.icon(onPressed: () async {
          final confirmar = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
            title: const Text('Arquivar conta?'),
            content: Text('O acesso de ${pessoa.nome} será desativado. Treinos e histórico serão preservados.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Arquivar'))]));
          if (confirmar == true && context.mounted) {
            executar(context, () => store.arquivarUsuario(pessoa.id), sucesso: 'Conta arquivada.');
          }
        }, icon: const Icon(Icons.archive_outlined), label: const Text('Arquivar')),
      ]),
    ])));

  Future<void> _redefinirSenha(BuildContext context) async {
    final controlador = TextEditingController();
    final rota = DialogRoute<String>(context: context,
      builder: (dialogo) => AlertDialog(
        title: Text('Nova senha · ${pessoa.nome}'),
        content: TextField(controller: controlador, obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nova senha (mínimo 8 caracteres)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (controlador.text.length < 8) {
              mensagem(dialogo, 'A senha precisa ter 8 caracteres ou mais.', erro: true);
              return;
            }
            Navigator.pop(dialogo, controlador.text);
          }, child: const Text('Salvar')),
        ],
      ));
    final novaSenha = await Navigator.of(context).push(rota);
    await rota.completed;
    controlador.dispose();
    if (novaSenha == null || !context.mounted) return;
    executar(context, () => store.redefinirSenha(
      usuarioId: pessoa.id, novaSenha: novaSenha),
      sucesso: 'Senha atualizada.');
  }

  Future<void> _vincular(BuildContext context) async {
    final professores = store.professores;
    if (professores.isEmpty) { mensagem(context, 'Cadastre um professor primeiro.', erro: true); return; }
    String escolhido = professores.first.id;
    await showDialog<void>(context: context, builder: (dialogo) => StatefulBuilder(
      builder: (context, atualizar) => AlertDialog(
        title: Text('Vincular ${pessoa.nome}'),
        content: DropdownButtonFormField<String>(initialValue: escolhido,
          isExpanded: true, decoration: const InputDecoration(labelText: 'Professor'),
          items: professores.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nome))).toList(),
          onChanged: (v) { if (v != null) atualizar(() => escolhido = v); }),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogo), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            try { store.vincularAluno(alunoId: pessoa.id, professorId: escolhido);
              Navigator.pop(dialogo);
            } on StateError catch (e) { mensagem(context, e.message, erro: true); }
          }, child: const Text('Vincular'))],
      )));
  }
}

class _NovoUsuarioDialog extends StatefulWidget {
  const _NovoUsuarioDialog({required this.store});
  final AcademiaStore store;
  @override
  State<_NovoUsuarioDialog> createState() => _NovoUsuarioDialogState();
}
class _NovoUsuarioDialogState extends State<_NovoUsuarioDialog> {
  final form = GlobalKey<FormState>();
  final nome = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  Perfil perfil = Perfil.aluno;
  bool mostrarSenha = false;
  @override
  void dispose() { nome.dispose(); email.dispose(); senha.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Novo cadastro'),
    content: SizedBox(width: 460, child: SingleChildScrollView(
      child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nome, decoration: const InputDecoration(labelText: 'Nome completo'),
          validator: (v) => (v?.trim().length ?? 0) >= 3 ? null : 'Informe pelo menos 3 caracteres.'),
        const SizedBox(height: 12),
        TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail'),
          validator: (v) => (v?.contains('@') ?? false) ? null : 'E-mail inválido.'),
        const SizedBox(height: 12),
        TextFormField(controller: senha, obscureText: !mostrarSenha,
          decoration: InputDecoration(labelText: 'Senha inicial (mínimo 8 caracteres)',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: 'Mostrar ou ocultar senha',
              icon: Icon(mostrarSenha ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => mostrarSenha = !mostrarSenha))),
          validator: (v) => (v?.length ?? 0) >= 8 ? null : 'Use ao menos 8 caracteres.'),
        const SizedBox(height: 12),
        DropdownButtonFormField<Perfil>(initialValue: perfil,
          decoration: const InputDecoration(labelText: 'Perfil'),
          items: [Perfil.aluno, Perfil.professor].map((p) =>
            DropdownMenuItem(value: p, child: Text(p.rotulo))).toList(),
          onChanged: (v) { if (v != null) setState(() => perfil = v); }),
        const SizedBox(height: 8),
        const Text('Aluno novo começa sem professor e com avaliação pendente.',
          style: TextStyle(color: Paleta.secundario, fontSize: 12)),
      ])))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(onPressed: () {
        if (!form.currentState!.validate()) return;
        try {
          widget.store.criarUsuario(nome: nome.text, email: email.text,
            perfil: perfil, senhaInicial: senha.text);
          Navigator.pop(context);
        } on StateError catch (e) { mensagem(context, e.message, erro: true); }
      }, child: const Text('Cadastrar'))],
  );
}

class AvaliacoesAdmin extends StatelessWidget {
  const AvaliacoesAdmin({super.key, required this.store});
  final AcademiaStore store;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Cabecalho(titulo: 'Avaliações físicas',
        subtitulo: 'A recepção agenda e registra o status.',
        icone: Icons.assignment_turned_in_outlined),
      const SizedBox(height: 14),
      Secao(titulo: 'Alunos', descricao: 'Sem avaliação concluída, o professor não pode atribuir uma ficha.',
        filho: store.alunos.isEmpty
          ? const Vazio(icone: Icons.event_busy, titulo: 'Sem alunos',
              mensagem: 'Cadastre um aluno antes de agendar avaliações.')
          : Column(children: [for (final aluno in store.alunos)
            Card(child: Padding(padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 9),
                Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip(status: aluno.statusAvaliacao),
                    Text(dataCurta(aluno.dataAvaliacao),
                      style: const TextStyle(color: Paleta.secundario, fontSize: 12)),
                    if (aluno.statusAvaliacao != StatusAvaliacao.concluida) ...[
                      OutlinedButton(onPressed: () => _agendar(context, aluno),
                        child: const Text('Agendar')),
                      FilledButton(onPressed: () => executar(context,
                        () => store.concluirAvaliacao(aluno.id),
                        sucesso: 'Avaliação marcada como concluída.'),
                        child: const Text('Concluir avaliação')),
                    ],
                  ]),
              ]))),
          ])),
    ]);

  Future<void> _agendar(BuildContext context, Usuario aluno) async {
    final dia = await showDatePicker(context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)));
    if (dia == null || !context.mounted) return;
    final horario = await showTimePicker(context: context,
      initialTime: TimeOfDay.now());
    if (horario == null || !context.mounted) return;
    executar(context, () => store.agendarAvaliacao(alunoId: aluno.id,
      data: DateTime(dia.year, dia.month, dia.day, horario.hour, horario.minute)),
      sucesso: 'Avaliação agendada.');
  }
}
