import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class Paleta {
  static const fundo = Color(0xFF0B0B0B);
  static const superficie = Color(0xFF171717);
  static const superficieClara = Color(0xFF222222);
  static const borda = Color(0xFF363636);
  static const vermelho = Color(0xFFD90429);
  static const texto = Color(0xFFEAEAEA);
  static const secundario = Color(0xFFA8A8A8);
  // Cinza da referência visual; tom mais claro em [secundario] preserva contraste.
  static const cinza = Color(0xFF6E7070);
  static const vermelhoBrilho = Color(0xFFFF1744);
  static const verde = Color(0xFF60D9AA);
  static const amarelo = Color(0xFFFFCC74);
}

ThemeData criarTema({bool fontesOnline = true}) {
  final esquema = ColorScheme.fromSeed(
    seedColor: Paleta.vermelho,
    brightness: Brightness.dark,
    surface: Paleta.superficie,
  ).copyWith(primary: Paleta.vermelho, onPrimary: Colors.white,
    surface: Paleta.superficie, onSurface: Paleta.texto,
    outline: Paleta.borda);
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Paleta.fundo,
    // Fonte online habilitada no app; em widget tests desabilitada para execução offline.
    fontFamily: fontesOnline ? GoogleFonts.rajdhani().fontFamily : 'Roboto',
    textTheme: fontesOnline ? GoogleFonts.rajdhaniTextTheme(ThemeData.dark().textTheme) : ThemeData.dark().textTheme,
    primaryTextTheme: fontesOnline ? GoogleFonts.rajdhaniTextTheme(ThemeData.dark().primaryTextTheme) : ThemeData.dark().primaryTextTheme,
    appBarTheme: const AppBarTheme(backgroundColor: Paleta.fundo,
      foregroundColor: Paleta.texto, elevation: 0, centerTitle: false),
    cardTheme: CardThemeData(
      color: Paleta.superficie,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Paleta.borda, width: .8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Paleta.superficieClara,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Paleta.borda)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Paleta.borda)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      side: const BorderSide(color: Paleta.borda),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Paleta.superficie,
      height: 74,
      indicatorColor: Paleta.vermelho.withValues(alpha: .17),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11,
        fontWeight: FontWeight.w600))),
    dividerColor: Paleta.borda,
    visualDensity: VisualDensity.standard,
  );
}
