// Motor central de traducciones. Cada pantalla/widget tiene su propio
// archivo de claves en core/i18n/keys/, y aquí se combinan todos en un solo
// diccionario. Uso: tr(context, 'pantalla.clave').
//
// Al agregar traducciones para una pantalla nueva:
//   1. Crear core/i18n/keys/keys_<pantalla>.dart con su Map traducciones.
//   2. Importarlo abajo y agregarlo al spread de _traducciones.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../locale_provider.dart';

import 'keys/keys_topbar.dart' as k_topbar;
import 'keys/keys_comprador_home.dart' as k_comprador_home;
import 'keys/keys_vendedor_dashboard.dart' as k_vendedor_dashboard;
import 'keys/keys_comprador_social.dart' as k_comprador_social;
import 'keys/keys_auth.dart' as k_auth;
import 'keys/keys_vendedor_inventario.dart' as k_vendedor_inventario;
import 'keys/keys_comprador_secundario.dart' as k_comprador_secundario;
import 'keys/keys_compartido.dart' as k_compartido;
import 'keys/keys_vendedor_operaciones.dart' as k_vendedor_operaciones;
import 'keys/keys_vendedor_operaciones2.dart' as k_vendedor_operaciones2;

const Map<String, Map<String, String>> _traducciones = {
  ...k_topbar.traducciones,
  ...k_comprador_home.traducciones,
  ...k_vendedor_dashboard.traducciones,
  ...k_comprador_social.traducciones,
  ...k_auth.traducciones,
  ...k_vendedor_inventario.traducciones,
  ...k_comprador_secundario.traducciones,
  ...k_compartido.traducciones,
  ...k_vendedor_operaciones.traducciones,
  ...k_vendedor_operaciones2.traducciones,
};

// Pensado para usarse dentro de build(): usa watch() para que el widget se
// reconstruya solo cuando el usuario cambia de idioma. Pero también se llama
// desde muchos lugares fuera de la fase de construcción (SnackBars armados
// en un catch, mensajes de error guardados en setState desde un callback
// async, etc.) — watch() revienta con una aserción ahí ("Tried to listen...
// from outside of the widget tree"), así que si eso pasa, se degrada a una
// lectura puntual con read() en vez de propagar el error.
String tr(BuildContext context, String clave) {
  bool ingles;
  try {
    ingles = context.watch<LocaleProvider>().esIngles;
  } catch (_) {
    ingles = context.read<LocaleProvider>().esIngles;
  }
  final entrada = _traducciones[clave];
  if (entrada == null) return clave;
  return entrada[ingles ? 'en' : 'es'] ?? entrada['es'] ?? clave;
}
