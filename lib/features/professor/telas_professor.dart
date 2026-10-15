import 'package:flutter/material.dart';
import '../../core/componentes.dart';
import '../../core/tema.dart';
import '../../domain/academia_store.dart';
import '../../domain/models.dart';
import 'editores.dart';

class AlunosProfessor extends StatefulWidget {
  const AlunosProfessor({super.key, required this.store});
  final AcademiaStore store;
  @override
  State<AlunosProfessor> createState() => _AlunosProfessorState();
}
class _AlunosProfessorState extends State<AlunosProfessor> {
  String busca = '';
  @override
  Widget build(BuildContext context) {
    final professor = widget.store.usuarioAtual!;
    final vinculados = widget.store.alunos.where((a) => a.professorId == professor.id &&
      a.nome.toLowerCase().contains(busca.toLowerCase())).toList();
    final disponiveis = widget.store.alunos.where((a) => a.professorId == null &&
      a.nome.toLowerCase().contains(busca.toLowerCase())).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Cabecalho(titulo: 'Olá, ${professor.nome.split(' ').first}!',
        subtitulo: 'Gerencie seus alunos e atribua treinos personalizados.',
        icone: Icons.groups_2_outlined),
      const SizedBox(height: 14),
      Secao(titulo: 'Meus alunos (${vinculados.length})',
        filho: Column(children: [
          TextField(onChanged: (v) => setState(() => busca = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
              hintText: 'Pesquisar aluno cadastrado')),
          const SizedBox(height: 10),
          if (vinculados.isEmpty) const Vazio(icone: Icons.group_add_outlined,
            titulo: 'Nenhum aluno encontrado',
            mensagem: 'Vincule alunos cadastrados pela recepção.'),
          for (final aluno in vinculados) Card(child: Padding(padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(aluno.nome,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                StatusChip(status: aluno.statusAvaliacao)]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton.icon(onPressed: aluno.statusAvaliacao == StatusAvaliacao.concluida
                  ? () => Navigator.push(context, MaterialPageRoute<void>(
                      builder: (_) => EditorAtribuicaoScreen(store: widget.store, aluno: aluno)))
                  : null,
                  icon: const Icon(Icons.post_add), label: const Text('Prescrever')),
                OutlinedButton.icon(onPressed: () => executar(context,
                    () => widget.store.desvincularAluno(alunoId: aluno.id, professorId: professor.id),
                    sucesso: 'Aluno desvinculado. Histórico preservado.'),
                  icon: const Icon(Icons.link_off), label: const Text('Desvincular')),
              ]),
              if (aluno.statusAvaliacao != StatusAvaliacao.concluida) ...[
                const SizedBox(height: 8),
                const Text('Aguarde a avaliação física para liberar a prescrição.',
                  style: TextStyle(color: Paleta.amarelo, fontSize: 11)),
              ],
            ]))),
        ])),
      Secao(titulo: 'Alunos disponíveis (${disponiveis.length})',
        descricao: 'Cadastros já realizados pela recepção e ainda sem professor.',
        filho: disponiveis.isEmpty
          ? const Vazio(icone: Icons.how_to_reg_outlined,
            titulo: 'Nenhum aluno disponível', mensagem: 'Todos os alunos já estão vinculados ou não há cadastros.')
          : Column(children: [for (final aluno in disponiveis) ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 2),
            title: Text(aluno.nome), subtitle: Text('Avaliação: ${aluno.statusAvaliacao.rotulo}'),
            trailing: IconButton(tooltip: 'Adicionar à minha lista',
              onPressed: () => executar(context, () => widget.store.vincularAluno(
                alunoId: aluno.id, professorId: professor.id),
                sucesso: '${aluno.nome} vinculado(a) à sua lista.'),
              icon: const Icon(Icons.person_add_alt_1, color: Paleta.verde)),
          )])),
    ]);
  }
}

class ModelosProfessor extends StatelessWidget {
  const ModelosProfessor({super.key, required this.store});
  final AcademiaStore store;
  @override
  Widget build(BuildContext context) {
    final modelos = store.modelosDoProfessor(store.usuarioAtual!.id);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Cabecalho(titulo: 'Biblioteca de modelos',
        subtitulo: 'Crie uma vez, personalize para cada aluno.',
        icone: Icons.library_books_outlined),
      const SizedBox(height: 14),
      Secao(titulo: 'Meus modelos (${modelos.length})',
        acao: FilledButton.icon(onPressed: () => Navigator.push(context,
          MaterialPageRoute<void>(builder: (_) => EditorModeloScreen(store: store))),
          icon: const Icon(Icons.add), label: const Text('Novo modelo')),
        filho: modelos.isEmpty
          ? const Vazio(icone: Icons.menu_book,
              titulo: 'Nenhum modelo', mensagem: 'Crie seu primeiro treino reutilizável.')
          : Column(children: [for (final modelo in modelos)
              Card(child: ExpansionTile(
                title: Text(modelo.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${modelo.exercicios.length} exercícios',
                  style: const TextStyle(color: Paleta.secundario)),
                trailing: const Icon(Icons.expand_more),
                children: [
                  for (final exercicio in modelo.exercicios) ListTile(
                    leading: const Icon(Icons.fitness_center, color: Paleta.vermelho),
                    title: Text(exercicio.nome),
                    subtitle: Text('${exercicio.series} × ${exercicio.repeticoes}  ·  ${exercicio.cargaKg} kg  ·  ${exercicio.descansoSegundos}s')),
                  Padding(padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(onPressed: () => Navigator.push(context,
                      MaterialPageRoute<void>(builder: (_) => EditorModeloScreen(
                        store: store, modelo: modelo))),
                      icon: const Icon(Icons.edit_outlined), label: const Text('Editar modelo'))),
                ])),
            ])),
    ]);
  }
}

class FichasProfessor extends StatelessWidget {
  const FichasProfessor({super.key, required this.store});
  final AcademiaStore store;
  @override
  Widget build(BuildContext context) {
    final fichas = store.fichasDoProfessor(store.usuarioAtual!.id).reversed.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Cabecalho(titulo: 'Fichas atribuídas',
        subtitulo: 'Cada aluno recebe sua própria cópia personalizada.',
        icone: Icons.assignment_outlined),
      const SizedBox(height: 14),
      Secao(titulo: 'Histórico de atribuições (${fichas.length})',
        filho: fichas.isEmpty
          ? const Vazio(icone: Icons.assignment_late_outlined,
              titulo: 'Nenhuma ficha atribuída',
              mensagem: 'Abra Meus alunos e prescreva um treino após a avaliação.')
          : Column(children: [for (final ficha in fichas)
            Card(child: ExpansionTile(
              title: Text(ficha.nome),
              subtitle: Text('Aluno: ${store.usuarioPorId(ficha.alunoId)?.nome ?? 'Indisponível'} · ${dataCurta(ficha.criadaEm)}'),
              children: [for (final exercicio in ficha.exercicios)
                ListTile(title: Text(exercicio.nome),
                  subtitle: Text('${exercicio.series} × ${exercicio.repeticoes} · ${exercicio.cargaKg} kg · ${exercicio.descansoSegundos}s\n${exercicio.observacao}'))],
            )),
          ])),
    ]);
  }
}
