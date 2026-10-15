import 'package:flutter/material.dart';
import '../core/tema.dart';
import '../domain/academia_store.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.store});
  final AcademiaStore store;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final senha = TextEditingController();
  bool visivel = false;
  String? erro;

  @override
  void dispose() {
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  void _entrar() {
    if (!form.currentState!.validate()) return;
    setState(() => erro = null);
    try {
      widget.store.entrar(email: email.text, senha: senha.text);
    } on StateError catch (e) {
      if (mounted) setState(() => erro = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(builder: (context, constraints) {
      final larga = constraints.maxWidth >= 900;
      final formulario = Container(
        constraints: const BoxConstraints(maxWidth: 470),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Paleta.superficie,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Paleta.borda),
        ),
        child: Form(key: form, child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.fitness_center, size: 44, color: Paleta.vermelho),
            const SizedBox(height: 12),
            const Text('ACADEMIA', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                letterSpacing: 3.5)),
            const Text('GERENCIAMENTO DE TREINOS', textAlign: TextAlign.center,
              style: TextStyle(color: Paleta.secundario, fontSize: 11,
                letterSpacing: 1.5)),
            const SizedBox(height: 32),
            const Text('Acesse sua conta',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            const Text('Entre com o e-mail e a senha cadastrados.',
              style: TextStyle(color: Paleta.secundario, fontSize: 14)),
            const SizedBox(height: 24),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'E-mail', prefixIcon: Icon(Icons.alternate_email)),
              validator: (valor) => (valor?.contains('@') ?? false)
                ? null : 'Informe um e-mail válido.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: senha,
              obscureText: !visivel,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _entrar(),
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Senha', prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: visivel ? 'Ocultar senha' : 'Mostrar senha',
                  onPressed: () => setState(() => visivel = !visivel),
                  icon: Icon(visivel ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                ),
              ),
              validator: (valor) => (valor?.isNotEmpty ?? false)
                ? null : 'Informe sua senha.',
            ),
            if (erro != null) ...[
              const SizedBox(height: 14),
              Text(erro!, style: const TextStyle(color: Color(0xFFFF8B9C))),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _entrar,
              icon: const Icon(Icons.login),
              label: const Text('Entrar'),
            ),
            const SizedBox(height: 14),
            const Text('As contas são criadas pela administração.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Paleta.secundario, fontSize: 12)),
          ],
        )),
      );
      return Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: larga
            ? Row(children: [
                const Expanded(child: _Apresentacao()),
                const SizedBox(width: 52),
                Expanded(child: formulario),
              ])
            : formulario,
        ),
      ));
    }),
  );
}

class _Apresentacao extends StatelessWidget {
  const _Apresentacao();
  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('CONTROLE EM CADA REPETIÇÃO.',
        style: TextStyle(fontWeight: FontWeight.w900,
          color: Paleta.vermelho, letterSpacing: 2.5, fontSize: 13)),
      SizedBox(height: 22),
      Text('Sua academia.\nSeu ritmo.',
        style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900,
          height: 1.07, letterSpacing: -1.2)),
      SizedBox(height: 24),
      Text('Da recepção ao treino: pessoas, avaliações e fichas\norganizadas em um único aplicativo.',
        style: TextStyle(color: Paleta.secundario, fontSize: 16, height: 1.6)),
      SizedBox(height: 28),
      Wrap(spacing: 18, runSpacing: 15, children: [
        _Destaque(icone: Icons.groups_outlined, texto: 'Gestão de alunos'),
        _Destaque(icone: Icons.fact_check_outlined, texto: 'Avaliações'),
        _Destaque(icone: Icons.fitness_center_outlined, texto: 'Treinos'),
      ]),
    ],
  );
}

class _Destaque extends StatelessWidget {
  const _Destaque({required this.icone, required this.texto});
  final IconData icone;
  final String texto;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icone, color: Paleta.verde, size: 18),
      const SizedBox(width: 8),
      Text(texto, style: const TextStyle(fontWeight: FontWeight.w700,
        fontSize: 12)),
    ],
  );
}
