import 'package:flutter/material.dart';
import '../core/componentes.dart';
import '../core/tema.dart';
import '../domain/academia_store.dart';
import '../domain/models.dart';
import 'admin/telas_admin.dart';
import 'professor/telas_professor.dart';
import 'aluno/telas_aluno.dart';

class Shell extends StatefulWidget {
  const Shell({super.key, required this.store});
  final AcademiaStore store;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int indice = 0;

  Future<void> _alterarSenha() async {
    final atual = TextEditingController();
    final nova = TextEditingController();
    final confirmar = TextEditingController();
    final rota = DialogRoute<Map<String, String>>(context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Alterar minha senha'),
        content: SizedBox(width: 390, child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: atual, obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha atual')),
            const SizedBox(height: 12),
            TextField(controller: nova, obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nova senha (mínimo 8 caracteres)')),
            const SizedBox(height: 12),
            TextField(controller: confirmar, obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar nova senha')),
          ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            if (nova.text.length < 8) {
              mensagem(dialogo, 'A nova senha deve ter ao menos 8 caracteres.',
                erro: true);
              return;
            }
            if (nova.text != confirmar.text) {
              mensagem(dialogo, 'As senhas não coincidem.', erro: true);
              return;
            }
            Navigator.pop(dialogo, {'atual': atual.text, 'nova': nova.text});
          }, child: const Text('Atualizar')),
        ],
      ));
    final valores = await Navigator.of(context).push(rota);
    await rota.completed;
    atual.dispose();
    nova.dispose();
    confirmar.dispose();
    if (valores == null || !mounted) return;
    executar(context, () => widget.store.alterarMinhaSenha(
      senhaAtual: valores['atual']!, novaSenha: valores['nova']!),
      sucesso: 'Senha atualizada.');
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.store.usuarioAtual!;
    final destinos = switch (usuario.perfil) {
      Perfil.administrador => const [
        (Icons.space_dashboard_outlined, 'Painel'),
        (Icons.people_alt_outlined, 'Pessoas'),
        (Icons.fact_check_outlined, 'Avaliações'),
      ],
      Perfil.professor => const [
        (Icons.groups_2_outlined, 'Alunos'),
        (Icons.library_books_outlined, 'Modelos'),
        (Icons.assignment_outlined, 'Fichas'),
      ],
      Perfil.aluno => const [
        (Icons.home_outlined, 'Início'),
        (Icons.fitness_center_outlined, 'Treinos'),
        (Icons.history_outlined, 'Histórico'),
        (Icons.person_outline, 'Perfil'),
      ],
    };
    final paginas = switch (usuario.perfil) {
      Perfil.administrador => <Widget>[
        PainelAdmin(store: widget.store),
        PessoasAdmin(store: widget.store),
        AvaliacoesAdmin(store: widget.store),
      ],
      Perfil.professor => <Widget>[
        AlunosProfessor(store: widget.store),
        ModelosProfessor(store: widget.store),
        FichasProfessor(store: widget.store),
      ],
      Perfil.aluno => <Widget>[
        HomeAluno(store: widget.store),
        TreinosAluno(store: widget.store),
        HistoricoAluno(store: widget.store),
        PerfilAluno(store: widget.store),
      ],
    };
    return LayoutBuilder(builder: (context, constraints) {
      final larga = constraints.maxWidth >= 800;
      final pagina = ListView(padding: EdgeInsets.symmetric(
          vertical: 22, horizontal: larga ? 28 : 14), children: [
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            paginas[indice],
            const SizedBox(height: 26),
          ]))),
      ]);
      return Scaffold(
        appBar: AppBar(toolbarHeight: 68,
          title: Row(children: [
            const Icon(Icons.fitness_center, size: 25, color: Paleta.vermelho),
            const SizedBox(width: 9),
            const Flexible(
              child: Text('ACADEMIA', maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900,
                  letterSpacing: 2.8, fontSize: 21)),
            ),
            if (constraints.maxWidth >= 1200) ...[
              const SizedBox(width: 15),
              const Flexible(
                child: Text('GESTÃO DE TREINOS', maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Paleta.secundario,
                    fontSize: 11, letterSpacing: 1.8)),
              ),
            ],
          ]),
          actions: [
            if (larga) Center(child: Text('${usuario.nome} · ${usuario.perfil.rotulo}',
              style: const TextStyle(color: Paleta.secundario, fontSize: 12))),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              tooltip: 'Conta',
              icon: const Icon(Icons.more_vert),
              onSelected: (opcao) async {
                if (opcao == 'sair') { widget.store.sair(); return; }
                if (opcao == 'senha') { await _alterarSenha(); return; }
                if (!context.mounted) return;
                final confirmar = await showDialog<bool>(context: context,
                  builder: (dialogo) => AlertDialog(
                    title: const Text('Desativar minha conta?'),
                    content: const Text('Sua conta será desativada. O histórico de treinos será preservado.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogo, false),
                        child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(dialogo, true),
                        child: const Text('Desativar')),
                    ]));
                if (confirmar == true) widget.store.desativarPropriaConta();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'senha', child: Text('Alterar minha senha')),
                const PopupMenuItem(value: 'sair', child: Text('Sair da conta')),
                if (usuario.perfil != Perfil.administrador)
                  const PopupMenuItem(value: 'desativar', child: Text('Desativar minha conta')),
              ],
            ),
            const SizedBox(width: 10),
          ]),
        body: larga ? Row(children: [
          Container(width: constraints.maxWidth > 1070 ? 270 : 82,
            decoration: const BoxDecoration(color: Paleta.superficie,
              border: Border(right: BorderSide(color: Paleta.borda))),
            child: NavigationRail(
              backgroundColor: Paleta.superficie,
              extended: constraints.maxWidth > 1070,
              selectedIndex: indice,
              onDestinationSelected: (v) => setState(() => indice = v),
              destinations: destinos.map((v) => NavigationRailDestination(
                icon: Icon(v.$1), selectedIcon: Icon(v.$1, color: Paleta.vermelho),
                label: Text(v.$2))).toList(),
            )),
          Expanded(child: pagina),
        ]) : pagina,
        bottomNavigationBar: larga ? null : NavigationBar(
          selectedIndex: indice,
          onDestinationSelected: (v) => setState(() => indice = v),
          destinations: destinos.map((v) => NavigationDestination(
            icon: Icon(v.$1), label: v.$2)).toList(),
        ),
      );
    });
  }
}
