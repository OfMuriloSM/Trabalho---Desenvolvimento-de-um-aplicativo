import 'package:flutter/material.dart';
import 'core/tema.dart';
import 'domain/academia_store.dart';
import 'domain/persistencia_local.dart';
import 'features/login.dart';
import 'features/shell.dart';

class AcademiaApp extends StatefulWidget {
  const AcademiaApp({super.key, this.fontesOnline = true});
  final bool fontesOnline;
  @override
  State<AcademiaApp> createState() => _AcademiaAppState();
}

class _AcademiaAppState extends State<AcademiaApp> {
  final store = AcademiaStore();
  PersistenciaLocal? persistencia;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      persistencia = await PersistenciaLocal.iniciar(store);
    } catch (erro) {
      debugPrint('Não foi possível ativar persistência local: $erro');
    }
    if (mounted) setState(() => carregando = false);
  }

  @override
  void dispose() {
    persistencia?.dispose();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Academia | Gestão de treinos',
    theme: criarTema(fontesOnline: widget.fontesOnline),
    debugShowCheckedModeBanner: false,
    home: carregando
      ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : AnimatedBuilder(animation: store, builder: (context, _) {
          final usuario = store.usuarioAtual;
          return usuario == null
            ? LoginPage(store: store)
            : Shell(key: ValueKey(usuario.id), store: store);
        }),
  );
}
