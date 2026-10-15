import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'academia_store.dart';

/// Estado persistido no navegador/dispositivo atual (edição offline).
/// Não usar para dados pessoais reais: o armazenamento não é cifrado,
/// não há servidor, sincronização ou autorização remota.
class PersistenciaLocal {
  PersistenciaLocal(this.store, this.prefs);
  static const chave = 'academia_offline_v1';
  static const chaveLegada = 'academia_demo_v2';
  final AcademiaStore store;
  final SharedPreferences prefs;
  Future<void> _fila = Future<void>.value();

  static Future<PersistenciaLocal> iniciar(AcademiaStore store) async {
    final prefs = await SharedPreferences.getInstance();
    final persistencia = PersistenciaLocal(store, prefs);
    final salvo = prefs.getString(chave) ?? prefs.getString(chaveLegada);
    if (salvo != null) {
      try {
        store.importarDados(Map<String, dynamic>.from(jsonDecode(salvo) as Map));
      } on Object catch (e) {
        // Um armazenamento corrompido não pode impedir a abertura do app.
        debugPrint('Dados locais inválidos, iniciando estado padrão: $e');
      }
    }
    store.addListener(persistencia.salvar);
    if (salvo != null && !prefs.containsKey(chave)) persistencia.salvar();
    return persistencia;
  }

  void salvar() {
    // Snapshot é capturado agora; gravações são serializadas para não inverter ordem.
    final json = jsonEncode(store.exportarDados());
    _fila = _fila.then((_) async { await prefs.setString(chave, json); });
  }

  Future<void> aguardarGravacao() => _fila;
  Future<void> limpar() async {
    await _fila;
    await prefs.remove(chave);
  }
  void dispose() => store.removeListener(salvar);
}
