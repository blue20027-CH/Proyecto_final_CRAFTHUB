// lib/screens/vendedor/pantalla_eventos_vendedor.dart
//
// Pantalla de calendario de eventos para el VENDEDOR: descubre ferias,
// talleres, exposiciones, bazares y festivales en todo el país, solicita
// un espacio de venta contactando directamente a la organización, y puede
// publicar sus propios eventos en el calendario.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/evento_modelo.dart';
import '../../services/eventos_api_service.dart';
import '../../widgets/eventos/banner_cta_evento.dart';
import '../../widgets/eventos/calendario_mensual.dart';
import '../../widgets/eventos/chip_categoria_evento.dart';
import '../../widgets/eventos/dialogo_crear_evento.dart';
import '../../widgets/eventos/encabezado_eventos.dart';
import '../../widgets/eventos/modal_detalle_evento.dart';
import '../../widgets/eventos/tarjeta_evento_proximo.dart';

class PantallaEventosVendedor extends StatefulWidget {
  final String userId;
  final String nombreVendedor;
  final String telefonoVendedor;

  const PantallaEventosVendedor({
    super.key,
    this.userId = '',
    this.nombreVendedor = 'Vendedor',
    this.telefonoVendedor = '',
  });

  @override
  State<PantallaEventosVendedor> createState() => _PantallaEventosVendedorState();
}

class _PantallaEventosVendedorState extends State<PantallaEventosVendedor> {
  DateTime _mesMostrado = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _diaSeleccionado;
  String _categoriaActiva = 'Todos';
  String? _provinciaActiva;

  bool _cargando = true;
  String? _error;
  List<EventoArtesanal> _eventos = [];

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final eventos = await EventosApiService.getEventos(
        categoria: _categoriaActiva,
        provincia: _provinciaActiva,
      );
      if (!mounted) return;
      setState(() => _eventos = eventos);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudieron cargar los eventos.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Set<DateTime> get _diasConEventos {
    final dias = <DateTime>{};
    for (final ev in _eventos) {
      var cursor = ev.soloFechaInicio;
      while (!cursor.isAfter(ev.soloFechaFin)) {
        if (cursor.year == _mesMostrado.year && cursor.month == _mesMostrado.month) {
          dias.add(cursor);
        }
        cursor = cursor.add(const Duration(days: 1));
      }
    }
    return dias;
  }

  Set<DateTime> get _diasConDescuento {
    final dias = <DateTime>{};
    for (final ev in _eventos) {
      if (!ev.tieneDescuento) continue;
      var cursor = ev.soloFechaInicio;
      while (!cursor.isAfter(ev.soloFechaFin)) {
        if (cursor.year == _mesMostrado.year &&
            cursor.month == _mesMostrado.month &&
            ev.estaEnDescuento(cursor)) {
          dias.add(cursor);
        }
        cursor = cursor.add(const Duration(days: 1));
      }
    }
    return dias;
  }

  /// true cuando hay un día seleccionado pero ningún evento ocurre justo ese
  /// día — en ese caso la lista cae de vuelta a "próximos eventos" en orden
  /// cronológico para que el usuario pueda hacer scroll hasta el más cercano.
  bool get _diaSeleccionadoSinEventos {
    if (_diaSeleccionado == null) return false;
    return !_eventos.any((ev) => ev.ocurreEnDia(_diaSeleccionado!));
  }

  List<EventoArtesanal> get _eventosFiltrados {
    final lista = List<EventoArtesanal>.from(_eventos);
    if (_diaSeleccionado != null) {
      final delDia = lista.where((ev) => ev.ocurreEnDia(_diaSeleccionado!)).toList();
      if (delDia.isNotEmpty) {
        delDia.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
        return delDia;
      }
      // No hay nada justo ese día: mostrar los próximos eventos a partir de
      // esa fecha para que el usuario pueda desplazarse hasta encontrar uno.
      final cercanos = lista.where((ev) => !ev.soloFechaFin.isBefore(_diaSeleccionado!)).toList();
      cercanos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
      return cercanos;
    }
    final proximos = lista.where((ev) => !ev.haTerminado).toList();
    proximos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
    return proximos;
  }

  void _irMes(int delta) {
    setState(() => _mesMostrado = DateTime(_mesMostrado.year, _mesMostrado.month + delta));
  }

  void _irHoy() {
    final hoy = DateTime.now();
    setState(() {
      _mesMostrado = DateTime(hoy.year, hoy.month);
      _diaSeleccionado = DateTime(hoy.year, hoy.month, hoy.day);
    });
  }

  Future<void> _abrirCrearEvento() async {
    final nuevo = await mostrarDialogoCrearEvento(
      context,
      nombreOrganizador: widget.nombreVendedor,
      telefonoOrganizador: widget.telefonoVendedor,
    );
    if (nuevo == null || !mounted) return;
    setState(() => _eventos = [nuevo, ..._eventos]);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Tu evento ya está publicado en el calendario!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: CraftHubColors.fondo(oscuro),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final esMovil = constraints.maxWidth < 900;

            // En móvil toda la pantalla es una sola columna con scroll natural.
            if (esMovil) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EncabezadoEventos(
                      titulo: 'Eventos Artesanales',
                      subtitulo:
                          'Encuentra ferias en todo el país y contacta directo a los organizadores.',
                      accionExtra: _BotonNuevoEvento(onTap: _abrirCrearEvento),
                    ),
                    const SizedBox(height: 20),
                    _buildFiltros(oscuro),
                    const SizedBox(height: 20),
                    _buildColumnaMovil(oscuro),
                  ],
                ),
              );
            }

            // En escritorio el encabezado y los filtros quedan fijos, y las
            // dos columnas (calendario / próximos eventos) se desplazan de
            // forma independiente dentro del espacio restante.
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EncabezadoEventos(
                    titulo: 'Eventos Artesanales',
                    subtitulo:
                        'Encuentra ferias en todo el país y contacta directo a los organizadores.',
                    accionExtra: _BotonNuevoEvento(onTap: _abrirCrearEvento),
                  ),
                  const SizedBox(height: 20),
                  _buildFiltros(oscuro),
                  const SizedBox(height: 20),
                  Expanded(child: _buildFilasEscritorio(oscuro)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFiltros(bool oscuro) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...categoriasEvento.map((cat) => ChipCategoriaEvento(
              categoria: cat,
              activo: _categoriaActiva == cat,
              onTap: () {
                setState(() => _categoriaActiva = cat);
                _cargarEventos();
              },
            )),
        _ChipProvinciaEvento(
          provinciaSeleccionada: _provinciaActiva,
          onSeleccionar: (prov) {
            setState(() => _provinciaActiva = prov);
            _cargarEventos();
          },
        ),
      ],
    );
  }

  Widget _buildCalendario() {
    return CalendarioMensual(
      mesMostrado: _mesMostrado,
      diaSeleccionado: _diaSeleccionado,
      diasConEventos: _diasConEventos,
      diasConDescuento: _diasConDescuento,
      alSeleccionarDia: (dia) {
        setState(() {
          if (dia.month != _mesMostrado.month || dia.year != _mesMostrado.year) {
            _mesMostrado = DateTime(dia.year, dia.month);
          }
          _diaSeleccionado = _diaSeleccionado == dia ? null : dia;
        });
      },
      alMesAnterior: () => _irMes(-1),
      alMesSiguiente: () => _irMes(1),
      alIrHoy: _irHoy,
    );
  }

  Widget _buildCta() {
    return BannerCtaEvento(
      icono: Icons.campaign_outlined,
      titulo: '¿Organizas un evento artesanal?',
      subtitulo: 'Publícalo en el calendario y llega a compradores de todo el país.',
      textoBoton: 'Publicar evento',
      onPressed: _abrirCrearEvento,
    );
  }

  Widget _buildEncabezadoProximos(bool oscuro) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: CraftHubColors.vinoTintoSuave,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.event_available_outlined, size: 16, color: CraftHubColors.vinoTinto),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Próximos eventos',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CraftHubColors.textoPrincipal(oscuro),
            ),
          ),
        ),
        _BotonVerMapaVendedor(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mapa de eventos próximamente.')),
          ),
        ),
      ],
    );
  }

  BoxDecoration _decorTarjeta(bool oscuro) => BoxDecoration(
        color: CraftHubColors.panel(oscuro),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CraftHubColors.borde(oscuro)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      );

  Widget? _buildFiltroDiaChip(bool oscuro) {
    if (_diaSeleccionado == null) return null;
    final d = _diaSeleccionado!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            children: [
              Chip(
                label: Text(
                  'Día ${d.day}/${d.month}/${d.year}',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white),
                ),
                backgroundColor: CraftHubColors.vinoTinto,
                deleteIcon: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
                onDeleted: () => setState(() => _diaSeleccionado = null),
              ),
            ],
          ),
          if (_diaSeleccionadoSinEventos) ...[
            const SizedBox(height: 6),
            Text(
              'No hay eventos justo ese día — mostrando los más próximos a partir de esa fecha.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: CraftHubColors.textoSecundario(oscuro),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaPara(EventoArtesanal evento) {
    return TarjetaEventoProximo(
      evento: evento,
      textoBotonPrimario: evento.solicitudEnviada ? 'Solicitado' : 'Solicitar espacio',
      iconoBotonPrimario:
          evento.solicitudEnviada ? Icons.check_circle_outline : Icons.storefront_outlined,
      alVerDetalles: () => mostrarDetalleEvento(
        context,
        evento: evento,
        esVendedor: true,
        usuarioId: widget.userId,
      ).then((_) => setState(() {})),
      alPresionarPrimario: () => mostrarDetalleEvento(
        context,
        evento: evento,
        esVendedor: true,
        usuarioId: widget.userId,
      ).then((_) => setState(() {})),
    );
  }

  Widget _buildListaEventos(bool oscuro, {bool comoColumna = false}) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: CraftHubColors.vinoTinto)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(_error!, style: const TextStyle(fontFamily: 'Poppins', color: CraftHubColors.error)),
        ),
      );
    }
    final eventos = _eventosFiltrados;
    if (eventos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No hay eventos para mostrar con estos filtros.',
            style: TextStyle(fontFamily: 'Poppins', color: CraftHubColors.textoSecundario(oscuro)),
          ),
        ),
      );
    }

    if (comoColumna) {
      return Column(
        children: [
          for (final ev in eventos) ...[
            _tarjetaPara(ev),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return ListView.separated(
      itemCount: eventos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _tarjetaPara(eventos[i]),
    );
  }

  Widget _buildColumnaMovil(bool oscuro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendario(),
        const SizedBox(height: 20),
        _buildCta(),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _decorTarjeta(oscuro),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEncabezadoProximos(oscuro),
              const SizedBox(height: 14),
              _buildFiltroDiaChip(oscuro) ?? const SizedBox.shrink(),
              _buildListaEventos(oscuro, comoColumna: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilasEscritorio(bool oscuro) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalendario(),
                const SizedBox(height: 20),
                _buildCta(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: _decorTarjeta(oscuro),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEncabezadoProximos(oscuro),
                const SizedBox(height: 14),
                _buildFiltroDiaChip(oscuro) ?? const SizedBox.shrink(),
                Expanded(child: _buildListaEventos(oscuro)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BotonNuevoEvento extends StatefulWidget {
  final VoidCallback onTap;
  const _BotonNuevoEvento({required this.onTap});

  @override
  State<_BotonNuevoEvento> createState() => _BotonNuevoEventoState();
}

class _BotonNuevoEventoState extends State<_BotonNuevoEvento> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _hover ? CraftHubColors.vinoTintoOscuro : CraftHubColors.vinoTinto,
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 17, color: Colors.white),
              SizedBox(width: 6),
              Text('Nuevo evento',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonVerMapaVendedor extends StatefulWidget {
  final VoidCallback onTap;
  const _BotonVerMapaVendedor({required this.onTap});

  @override
  State<_BotonVerMapaVendedor> createState() => _BotonVerMapaVendedorState();
}

class _BotonVerMapaVendedorState extends State<_BotonVerMapaVendedor> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hover ? CraftHubColors.vinoTinto.withValues(alpha: 0.08) : CraftHubColors.panel(oscuro),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: CraftHubColors.vinoTinto),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 15, color: CraftHubColors.vinoTinto),
              const SizedBox(width: 6),
              const Text('Ver mapa',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: CraftHubColors.vinoTinto)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipProvinciaEvento extends StatelessWidget {
  final String? provinciaSeleccionada;
  final ValueChanged<String?> onSeleccionar;

  const _ChipProvinciaEvento({required this.provinciaSeleccionada, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (val) => onSeleccionar(val == '__todas' ? null : val),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: '__todas',
          child: Text('Todas las provincias',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuDivider(),
        ...provinciasEvento.map((p) => PopupMenuItem(
              value: p,
              child: Text(p, style: GoogleFonts.poppins(fontSize: 13)),
            )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0xFFC9A84C), width: 0.9),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF7A5800)),
          const SizedBox(width: 5),
          Text(provinciaSeleccionada ?? 'Provincia',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF7A5800),
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF7A5800)),
        ]),
      ),
    );
  }
}
