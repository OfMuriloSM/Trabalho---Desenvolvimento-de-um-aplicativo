import 'package:flutter/material.dart';
import '../domain/academia_store.dart';
import '../domain/models.dart';

class _RascunhoExercicio {
  _RascunhoExercicio([ExercicioPrescrito? origem])
      : nome = TextEditingController(text: origem?.nome ?? ''),
        series = TextEditingController(text: '${origem?.series ?? 3}'),
        repeticoes = TextEditingController(text: '${origem?.repeticoes ?? 12}'),
        carga = TextEditingController(text: '${origem?.cargaKg ?? 0}'),
        descanso = TextEditingController(text: '${origem?.descansoSegundos ?? 60}'),
        observacao = TextEditingController(text: origem?.observacao ?? '');

  final TextEditingController nome;
  final TextEditingController series;
  final TextEditingController repeticoes;
  final TextEditingController carga;
  final TextEditingController descanso;
  final TextEditingController observacao;

  ExercicioPrescrito converter() => ExercicioPrescrito(
    nome: nome.text.trim(),
    series: int.parse(series.text),
    repeticoes: int.parse(repeticoes.text),
    cargaKg: double.parse(carga.text.replaceAll(',', '.')),
    descansoSegundos: int.parse(descanso.text),
    observacao: observacao.text.trim(),
  );

  void dispose() {
    nome.dispose();
    series.dispose();
    repeticoes.dispose();
    carga.dispose();
    descanso.dispose();
    observacao.dispose();
  }
}

String? _validarInteiro(String? valor, {bool permiteZero = false}) {
  final numero = int.tryParse(valor?.trim() ?? '');
  if (numero == null || (permiteZero ? numero < 0 : numero <= 0)) return 'Valor inválido';
  return null;
}

String? _validarCarga(String? valor) {
  final numero = double.tryParse((valor ?? '').replaceAll(',', '.'));
  if (numero == null || !numero.isFinite || numero < 0) return 'Carga inválida';
  return null;
}

class _CamposExercicio extends StatelessWidget {
  const _CamposExercicio({super.key, required this.indice, required this.rascunho, this.remover});
  final int indice;
  final _RascunhoExercicio rascunho;
  final VoidCallback? remover;

  @override
  Widget build(BuildContext context) => Card.filled(child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text('Exercício ${indice + 1}', style: Theme.of(context).textTheme.titleMedium)),
        if (remover != null) IconButton(tooltip: 'Remover exercício', onPressed: remover, icon: const Icon(Icons.delete_outline)),
      ]),
      const SizedBox(height: 10),
      TextFormField(controller: rascunho.nome, decoration: const InputDecoration(labelText: 'Nome do exercício'),
        validator: (v) => (v?.trim().isNotEmpty ?? false) ? null : 'Informe o exercício.'),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _CampoNumero(rotulo: 'Séries', controller: rascunho.series, validator: _validarInteiro),
        _CampoNumero(rotulo: 'Repetições', controller: rascunho.repeticoes, validator: _validarInteiro),
        _CampoNumero(rotulo: 'Carga (kg)', controller: rascunho.carga, validator: _validarCarga),
        _CampoNumero(rotulo: 'Descanso (seg)', controller: rascunho.descanso, validator: (v) => _validarInteiro(v, permiteZero: true)),
      ]),
      const SizedBox(height: 10),
      TextFormField(controller: rascunho.observacao, maxLines: 2, decoration: const InputDecoration(labelText: 'Observação personalizada (opcional)')),
    ]),
  ));
}

class _CampoNumero extends StatelessWidget {
  const _CampoNumero({required this.rotulo, required this.controller, required this.validator});
  final String rotulo;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 156,
    child: TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: rotulo),
      validator: validator,
    ),
  );
}

class EditorModeloScreen extends StatefulWidget {
  const EditorModeloScreen({super.key, required this.store});
  final AcademiaStore store;

  @override
  State<EditorModeloScreen> createState() => _EditorModeloScreenState();
}

class _EditorModeloScreenState extends State<EditorModeloScreen> {
  final formulario = GlobalKey<FormState>();
  final nome = TextEditingController();
  final List<_RascunhoExercicio> rascunhos = [_RascunhoExercicio()];
  final List<_RascunhoExercicio> removidos = [];

  @override
  void dispose() {
    nome.dispose();
    for (final item in [...rascunhos, ...removidos]) { item.dispose(); }
    super.dispose();
  }

  void salvar() {
    if (!formulario.currentState!.validate()) return;
    try {
      widget.store.criarModelo(nome: nome.text, exercicios: rascunhos.map((item) => item.converter()).toList());
      Navigator.pop(context);
    } on StateError catch (erro) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novo modelo de treino')),
    body: Form(
      key: formulario,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: nome, decoration: const InputDecoration(labelText: 'Nome do modelo'),
          validator: (v) => (v?.trim().isNotEmpty ?? false) ? null : 'Informe o nome do modelo.'),
        const SizedBox(height: 15),
        for (var i = 0; i < rascunhos.length; i++) Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CamposExercicio(
            key: ObjectKey(rascunhos[i]),
            indice: i,
            rascunho: rascunhos[i],
            remover: rascunhos.length > 1 ? () => setState(() => removidos.add(rascunhos.removeAt(i))) : null,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() => rascunhos.add(_RascunhoExercicio())),
          icon: const Icon(Icons.add), label: const Text('Adicionar exercício'),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: salvar, icon: const Icon(Icons.save_outlined), label: const Text('Salvar modelo')),
      ]),
    ),
  );
}

class EditorAtribuicaoScreen extends StatefulWidget {
  const EditorAtribuicaoScreen({super.key, required this.store, required this.aluno});
  final AcademiaStore store;
  final Usuario aluno;

  @override
  State<EditorAtribuicaoScreen> createState() => _EditorAtribuicaoScreenState();
}

class _EditorAtribuicaoScreenState extends State<EditorAtribuicaoScreen> {
  final formulario = GlobalKey<FormState>();
  final nome = TextEditingController();
  final List<_RascunhoExercicio> todos = [];
  List<_RascunhoExercicio> atuais = [];
  String? modeloId;

  @override
  void initState() {
    super.initState();
    final opcoes = widget.store.modelosDoProfessor(widget.store.usuarioAtual!.id);
    if (opcoes.isNotEmpty) selecionarModelo(opcoes.first);
  }

  void selecionarModelo(ModeloTreino modelo) {
    modeloId = modelo.id;
    nome.text = '${modelo.nome} · ${widget.aluno.nome}';
    atuais = modelo.exercicios.map((e) => _RascunhoExercicio(e)).toList();
    todos.addAll(atuais);
  }

  @override
  void dispose() {
    nome.dispose();
    for (final draft in todos) { draft.dispose(); }
    super.dispose();
  }

  void salvar() {
    if (modeloId == null || !formulario.currentState!.validate()) return;
    try {
      widget.store.atribuirFicha(
        alunoId: widget.aluno.id,
        modeloId: modeloId!,
        nome: nome.text,
        exercicios: atuais.map((item) => item.converter()).toList(),
      );
      Navigator.pop(context);
    } on StateError catch (erro) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelos = widget.store.modelosDoProfessor(widget.store.usuarioAtual!.id);
    return Scaffold(
      appBar: AppBar(title: Text('Prescrever para ${widget.aluno.nome}')),
      body: modelos.isEmpty
        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Crie primeiro um modelo na área “Modelos de treino”.')))
        : Form(key: formulario, child: ListView(padding: const EdgeInsets.all(16), children: [
            Text('Avaliação: ${widget.aluno.statusAvaliacao.rotulo}'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(modeloId),
              initialValue: modeloId,
              decoration: const InputDecoration(labelText: 'Modelo de origem'),
              items: modelos.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nome))).toList(),
              onChanged: (id) {
                final modelo = modelos.where((m) => m.id == id).firstOrNull;
                if (modelo != null) setState(() => selecionarModelo(modelo));
              },
            ),
            const SizedBox(height: 12),
            TextFormField(controller: nome, decoration: const InputDecoration(labelText: 'Nome desta ficha individual'),
              validator: (v) => (v?.trim().isNotEmpty ?? false) ? null : 'Informe um nome.'),
            const SizedBox(height: 15),
            const Text('Personalize a cópia abaixo. O modelo original não será alterado.'),
            const SizedBox(height: 12),
            for (var i = 0; i < atuais.length; i++) Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CamposExercicio(key: ObjectKey(atuais[i]), indice: i, rascunho: atuais[i]),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: salvar, icon: const Icon(Icons.assignment_turned_in), label: const Text('Atribuir ficha ao aluno')),
          ])),
    );
  }
}
