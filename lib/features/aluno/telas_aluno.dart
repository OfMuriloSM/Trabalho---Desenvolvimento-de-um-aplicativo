import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/componentes.dart';
import '../../core/tema.dart';
import '../../domain/academia_store.dart';
import '../../domain/models.dart';

class HomeAluno extends StatelessWidget {
  const HomeAluno({super.key, required this.store});
  final AcademiaStore store;
  @override
  Widget build(BuildContext context) {
    final aluno = store.usuarioAtual!;
    final fichas = store.fichasDoAluno(aluno.id);
    final concluidas = store.sessoesDoAluno(aluno.id).where((s) => s.finalizadaEm != null).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Cabecalho(titulo: 'Vamos treinar, ${aluno.nome.split(' ').first}!',
        subtitulo: 'Sua evolução começa com a próxima repetição.',
        icone: Icons.bolt),
      const SizedBox(height: 14),
      Wrap(spacing: 12, runSpacing: 7, children: [
        Estatistica(icone: Icons.fitness_center, valor: '${fichas.length}',
          rotulo: 'Fichas disponíveis'),
        Estatistica(icone: Icons.verified_outlined, valor: '$concluidas',
          rotulo: 'Treinos concluídos', cor: Paleta.verde),
      ]),
      const SizedBox(height: 12),
      Secao(titulo: 'Meu acompanhamento', filho: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.assignment_turned_in_outlined, color: Paleta.vermelho),
            title: const Text('Avaliação física'),
            trailing: StatusChip(status: aluno.statusAvaliacao)),
          ListTile(contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline, color: Paleta.verde),
            title: const Text('Professor responsável'),
            subtitle: Text(store.usuarioPorId(aluno.professorId)?.nome ?? 'Ainda não vinculado')),
        ])),
      Secao(titulo: 'Suas fichas',
        filho: fichas.isEmpty
          ? const Vazio(icone: Icons.fitness_center, titulo: 'Seu treino está a caminho',
            mensagem: 'Após a avaliação, o professor poderá atribuir sua ficha.')
          : Column(children: [for (final ficha in fichas.reversed.take(3))
              Card(child: ListTile(
                leading: const Icon(Icons.fitness_center, color: Paleta.vermelho),
                title: Text(ficha.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${ficha.exercicios.length} exercícios'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => ExecutarTreino(store: store, ficha: ficha))),
              )),
            ])),
    ]);
  }
}

class TreinosAluno extends StatelessWidget {
  const TreinosAluno({super.key, required this.store});
  final AcademiaStore store;
  @override
  Widget build(BuildContext context) {
    final fichas = store.fichasDoAluno(store.usuarioAtual!.id).reversed.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Cabecalho(titulo: 'Meus treinos',
        subtitulo: 'Seu plano, suas cargas e seu ritmo.',
        icone: Icons.fitness_center_outlined),
      const SizedBox(height: 14),
      Secao(titulo: 'Fichas atribuídas (${fichas.length})',
        filho: fichas.isEmpty
          ? const Vazio(icone: Icons.hourglass_empty,
              titulo: 'Nenhuma ficha ainda',
              mensagem: 'Consulte seu professor depois da avaliação física.')
          : Column(children: [for (final ficha in fichas)
              Card(child: Padding(padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(ficha.nome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('${ficha.exercicios.length} exercícios · atribuído em ${dataCurta(ficha.criadaEm)}',
                    style: const TextStyle(fontSize: 12, color: Paleta.secundario)),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: () => Navigator.push(context,
                    MaterialPageRoute<void>(builder: (_) => ExecutarTreino(store: store, ficha: ficha))),
                    icon: const Icon(Icons.play_arrow_rounded), label: const Text('Abrir treino')),
                ]))),
            ])),
    ]);
  }
}

class ExecutarTreino extends StatefulWidget {
  const ExecutarTreino({super.key, required this.store, required this.ficha});
  final AcademiaStore store;
  final FichaAtribuida ficha;
  @override
  State<ExecutarTreino> createState() => _ExecutarTreinoState();
}
class _ExecutarTreinoState extends State<ExecutarTreino> {
  SessaoTreino? sessao;
  Timer? temporizador;
  int descansoRestante = 0;

  void iniciarDescanso(int segundos) {
    temporizador?.cancel();
    if (segundos <= 0) return;
    setState(() => descansoRestante = segundos);
    temporizador = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (descansoRestante <= 1) {
        timer.cancel();
        setState(() => descansoRestante = 0);
      } else {
        setState(() => descansoRestante--);
      }
    });
  }

  @override
  void dispose() {
    temporizador?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // A sessão só é criada ao pressionar "Iniciar", para não registrar
    // automaticamente treinos abertos apenas para consulta.
    sessao = widget.store.sessoesDoAluno(widget.store.usuarioAtual!.id)
      .where((s) => s.fichaId == widget.ficha.id && s.finalizadaEm == null).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final ficha = widget.ficha;
    final registros = sessao == null ? <RegistroSerie>[] : widget.store.registrosDaSessao(sessao!.id);
    final seriesTotal = ficha.exercicios.fold<int>(0, (n, e) => n + e.series);
    return Scaffold(
      appBar: AppBar(title: const Text('Minha ficha')),
      body: ListView(padding: const EdgeInsets.all(15), children: [
        Cabecalho(titulo: ficha.nome,
          subtitulo: '${ficha.exercicios.length} exercícios • $seriesTotal séries',
          icone: Icons.fitness_center),
        const SizedBox(height: 13),
        Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Expanded(child: Text('Progresso da sessão',
              style: TextStyle(fontWeight: FontWeight.w800))),
            Text('${registros.length}/$seriesTotal',
              style: const TextStyle(color: Paleta.verde, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 11),
          LinearProgressIndicator(value: seriesTotal == 0 ? 0 : registros.length / seriesTotal,
            minHeight: 7, borderRadius: BorderRadius.circular(6),
            color: Paleta.verde, backgroundColor: Paleta.superficieClara),
          const SizedBox(height: 14),
          if (sessao == null) FilledButton.icon(onPressed: () {
            try { setState(() => sessao = widget.store.iniciarSessao(ficha.id)); }
            on StateError catch (e) { mensagem(context, e.message, erro: true); }
          }, icon: const Icon(Icons.play_arrow), label: const Text('Iniciar treino'))
          else FilledButton.icon(onPressed: () {
            final id = sessao!.id;
            executar(context, () => widget.store.finalizarSessao(id),
              sucesso: 'Treino finalizado!');
            if (context.mounted) Navigator.pop(context);
          }, icon: const Icon(Icons.flag_outlined), label: const Text('Finalizar sessão')),
        ]))),
        if (descansoRestante > 0) Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.timer_outlined, color: Paleta.amarelo),
            const SizedBox(width: 10),
            Expanded(child: Text('Descanso: $descansoRestante segundos',
              style: const TextStyle(fontWeight: FontWeight.w800))),
            TextButton(onPressed: () { temporizador?.cancel();
              setState(() => descansoRestante = 0);
            }, child: const Text('Pular')),
          ]))),
        const SizedBox(height: 10),
        for (var i = 0; i < ficha.exercicios.length; i++) _ExercicioTile(
          index: i, prescrito: ficha.exercicios[i], registros: registros,
          habilitado: sessao != null, registrar: (serie, reps, carga) {
            if (sessao == null) return;
            try {
              widget.store.registrarSerie(sessaoId: sessao!.id,
                exercicioIndice: i, serieNumero: serie,
                repeticoes: reps, cargaKg: carga);
              setState(() {});
              iniciarDescanso(ficha.exercicios[i].descansoSegundos);
            } on StateError catch (e) { mensagem(context, e.message, erro: true); }
          },
        ),
      ]),
    );
  }
}

class _ExercicioTile extends StatelessWidget {
  const _ExercicioTile({required this.index, required this.prescrito,
    required this.registros, required this.habilitado, required this.registrar});
  final int index;
  final ExercicioPrescrito prescrito;
  final List<RegistroSerie> registros;
  final bool habilitado;
  final void Function(int serie, int reps, double carga) registrar;

  @override
  Widget build(BuildContext context) {
    final feitas = registros.where((r) => r.exercicioIndice == index).length;
    return Card(child: ExpansionTile(
      initiallyExpanded: index == 0,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      leading: Container(width: 45, height: 45,
        decoration: BoxDecoration(color: Paleta.vermelho.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.fitness_center, color: Paleta.vermelho)),
      title: Text(prescrito.nome, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text('${prescrito.series} × ${prescrito.repeticoes} · ${prescrito.cargaKg} kg · ${prescrito.descansoSegundos}s descanso',
        style: const TextStyle(color: Paleta.secundario, fontSize: 12)),
      trailing: Text('$feitas/${prescrito.series}',
        style: const TextStyle(color: Paleta.verde, fontWeight: FontWeight.w800)),
      children: [
        if (prescrito.observacao.isNotEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(children: [const Icon(Icons.info_outline, color: Paleta.amarelo, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(prescrito.observacao,
                style: const TextStyle(color: Paleta.amarelo, fontSize: 12)))])),
        for (var serie = 1; serie <= prescrito.series; serie++) Builder(builder: (context) {
          final registro = registros.where((r) =>
            r.exercicioIndice == index && r.serieNumero == serie).firstOrNull;
          return ListTile(
            leading: Icon(registro == null ? Icons.radio_button_unchecked : Icons.check_circle,
              color: registro == null ? Paleta.secundario : Paleta.verde),
            title: Text('Série $serie'),
            subtitle: Text(registro == null
              ? '${prescrito.repeticoes} repetições · ${prescrito.cargaKg} kg sugeridos'
              : '${registro.repeticoes} repetições · ${registro.cargaKg} kg realizados'),
            trailing: OutlinedButton(onPressed: habilitado ? () => _editarSerie(
              context, serie, registro) : null,
              child: Text(registro == null ? 'Concluir' : 'Editar')),
          );
        }),
        if (!habilitado) const Padding(padding: EdgeInsets.all(14),
          child: Text('Inicie uma sessão para registrar as séries.',
            style: TextStyle(color: Paleta.secundario, fontSize: 12))),
      ],
    ));
  }

  Future<void> _editarSerie(BuildContext context, int numero, RegistroSerie? anterior) async {
    // O resultado de Navigator.pop chega ANTES da animação de saída do diálogo.
    // Espere o overlay ser removido para atualizar a store que reconstrói a tela.
    final rota = DialogRoute<(int, double)>(
      context: context,
      builder: (_) => _DialogRegistroSerie(
        numero: numero,
        prescrito: prescrito,
        anterior: anterior,
      ),
    );
    final valores = await Navigator.of(context).push(rota);
    await rota.completed;
    if (!context.mounted || valores == null) return;
    registrar(numero, valores.$1, valores.$2);
  }
}

/// Cada diálogo possui seus controladores: só são descartados após a rota
/// realmente sair da árvore de widgets, e não no começo da animação de saída.
class _DialogRegistroSerie extends StatefulWidget {
  const _DialogRegistroSerie({
    required this.numero,
    required this.prescrito,
    this.anterior,
  });

  final int numero;
  final ExercicioPrescrito prescrito;
  final RegistroSerie? anterior;

  @override
  State<_DialogRegistroSerie> createState() => _DialogRegistroSerieState();
}

class _DialogRegistroSerieState extends State<_DialogRegistroSerie> {
  final formulario = GlobalKey<FormState>();
  late final TextEditingController carga;
  late final TextEditingController repeticoes;

  @override
  void initState() {
    super.initState();
    carga = TextEditingController(
      text: '${widget.anterior?.cargaKg ?? widget.prescrito.cargaKg}',
    );
    repeticoes = TextEditingController(
      text: '${widget.anterior?.repeticoes ?? widget.prescrito.repeticoes}',
    );
  }

  @override
  void dispose() {
    carga.dispose();
    repeticoes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Série ${widget.numero} · ${widget.prescrito.nome}'),
    content: SizedBox(
      width: 380,
      child: Form(
        key: formulario,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: repeticoes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Repetições realizadas'),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 0 || n > 300 ? 'Informe de 0 a 300.' : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: carga,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Carga utilizada (kg)'),
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              return n == null || !n.isFinite || n < 0 || n > 2000
                  ? 'Carga inválida.' : null;
            },
          ),
        ]),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!formulario.currentState!.validate()) return;
          Navigator.pop(context, (
            int.parse(repeticoes.text),
            double.parse(carga.text.replaceAll(',', '.')),
          ));
        },
        child: const Text('Salvar série'),
      ),
    ],
  );
}


class HistoricoAluno extends StatelessWidget {
  const HistoricoAluno({super.key, required this.store});
  final AcademiaStore store;
  @override
  Widget build(BuildContext context) {
    final aluno = store.usuarioAtual!;
    final sessoes = store.sessoesDoAluno(aluno.id).reversed.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Cabecalho(titulo: 'Meu histórico',
        subtitulo: 'Cada sessão conta na sua evolução.', icone: Icons.history),
      const SizedBox(height: 14),
      Secao(titulo: 'Sessões (${sessoes.length})',
        filho: sessoes.isEmpty
          ? const Vazio(icone: Icons.history_toggle_off,
              titulo: 'Sem atividades registradas',
              mensagem: 'Seu histórico aparecerá após iniciar treinos.')
          : Column(children: [for (final sessao in sessoes)
            Card(child: ListTile(
              leading: Icon(sessao.finalizadaEm == null
                ? Icons.timelapse : Icons.check_circle, color: sessao.finalizadaEm == null
                ? Paleta.amarelo : Paleta.verde),
              title: Text(store.fichas.where((f) => f.id == sessao.fichaId)
                .firstOrNull?.nome ?? 'Ficha indisponível'),
              subtitle: Text('${dataCurta(sessao.iniciadaEm)} · ${store.registrosDaSessao(sessao.id).length} séries'),
              trailing: Text(sessao.finalizadaEm == null ? 'Em andamento' : 'Concluída',
                style: const TextStyle(fontSize: 11, color: Paleta.secundario)),
            )),
          ])),
    ]);
  }
}

class PerfilAluno extends StatelessWidget {
  const PerfilAluno({super.key, required this.store});
  final AcademiaStore store;
  @override
  Widget build(BuildContext context) {
    final aluno = store.usuarioAtual!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Cabecalho(titulo: 'Meu perfil', subtitulo: 'Suas informações na academia.',
        icone: Icons.person_outline),
      const SizedBox(height: 14),
      Secao(titulo: 'Dados pessoais', filho: Column(children: [
        ListTile(leading: const Icon(Icons.badge_outlined),
          title: const Text('Nome'), subtitle: Text(aluno.nome)),
        ListTile(leading: const Icon(Icons.mail_outline),
          title: const Text('E-mail'), subtitle: Text(aluno.email)),
        ListTile(leading: const Icon(Icons.school_outlined),
          title: const Text('Professor'),
          subtitle: Text(store.usuarioPorId(aluno.professorId)?.nome ?? 'Não associado')),
        ListTile(leading: const Icon(Icons.event_available_outlined),
          title: const Text('Avaliação'),
          subtitle: Text('${aluno.statusAvaliacao.rotulo} · ${dataCurta(aluno.dataAvaliacao)}')),
      ])),
    ]);
  }
}
