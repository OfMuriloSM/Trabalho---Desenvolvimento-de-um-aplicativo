import 'package:flutter/material.dart';
import '../domain/models.dart';
import 'tema.dart';

void mensagem(BuildContext context, String texto, {bool erro = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(texto), backgroundColor: erro ? const Color(0xFF9D2238) : Paleta.superficieClara,
    behavior: SnackBarBehavior.floating));
}

void executar(BuildContext context, VoidCallback trabalho, {String sucesso = 'Operação concluída.'}) {
  try { trabalho(); mensagem(context, sucesso); }
  on StateError catch (e) { mensagem(context, e.message, erro: true); }
}

class Secao extends StatelessWidget {
  const Secao({super.key, required this.titulo, required this.filho,
    this.descricao, this.acao});
  final String titulo;
  final String? descricao;
  final Widget filho;
  final Widget? acao;

  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 8,
        children: [Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
          Text(titulo, style: const TextStyle(fontSize: 19,
            fontWeight: FontWeight.w800, color: Paleta.texto)),
          if (descricao != null) ...[
            const SizedBox(height: 4),
            Text(descricao!, style: const TextStyle(fontSize: 12, color: Paleta.secundario)),
          ],
        ]), ?acao]),
      const SizedBox(height: 16),
      filho,
    ])));
}

class Estatistica extends StatelessWidget {
  const Estatistica({super.key, required this.icone, required this.valor,
    required this.rotulo, this.cor = Paleta.vermelho});
  final IconData icone;
  final String valor;
  final String rotulo;
  final Color cor;
  @override
  Widget build(BuildContext context) => SizedBox(width: 218, child: Card(
    child: Padding(padding: const EdgeInsets.all(18), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(
          color: cor.withValues(alpha: .13), borderRadius: BorderRadius.circular(12)),
          child: Icon(icone, size: 22, color: cor)),
        const SizedBox(height: 15),
        Text(valor, style: const TextStyle(fontSize: 31,
          fontWeight: FontWeight.w900, letterSpacing: -.6)),
        const SizedBox(height: 3),
        Text(rotulo, style: const TextStyle(fontSize: 12, color: Paleta.secundario)),
      ]))));
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final StatusAvaliacao status;
  @override
  Widget build(BuildContext context) {
    final cor = switch (status) {
      StatusAvaliacao.concluida => Paleta.verde,
      StatusAvaliacao.agendada => Paleta.amarelo,
      StatusAvaliacao.pendente => Paleta.secundario,
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: cor.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20)),
      child: Text(status.rotulo, style: TextStyle(color: cor,
        fontWeight: FontWeight.w700, fontSize: 11)));
  }
}

class Vazio extends StatelessWidget {
  const Vazio({super.key, required this.icone, required this.titulo,
    required this.mensagem, this.acao});
  final IconData icone;
  final String titulo;
  final String mensagem;
  final Widget? acao;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icone, color: Paleta.secundario, size: 44),
      const SizedBox(height: 11),
      Text(titulo, textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      const SizedBox(height: 5),
      Text(mensagem, textAlign: TextAlign.center,
        style: const TextStyle(color: Paleta.secundario, fontSize: 12)),
      if (acao != null) ...[const SizedBox(height: 16), acao!],
    ])));
}

class Cabecalho extends StatelessWidget {
  const Cabecalho({super.key, required this.titulo, required this.subtitulo,
    this.icone = Icons.fitness_center, this.acao});
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Widget? acao;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(colors: [Color(0xFF3A1927), Color(0xFF181D29)]),
      border: Border.all(color: Paleta.borda)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Paleta.vermelho.withValues(alpha: .19),
          borderRadius: BorderRadius.circular(17)),
        child: Icon(icone, color: Paleta.vermelho, size: 30)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(subtitulo, style: const TextStyle(color: Paleta.secundario, fontSize: 12)),
      ])),
      ?acao,
    ]));
}

String dataCurta(DateTime? valor) {
  if (valor == null) return 'Não agendada';
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(valor.day)}/${dois(valor.month)}/${valor.year} ${dois(valor.hour)}:${dois(valor.minute)}';
}
