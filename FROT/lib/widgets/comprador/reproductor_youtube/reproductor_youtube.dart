// Punto de entrada único: en Flutter Web exporta el embed real de YouTube;
// en el resto de plataformas (Android/iOS/Windows/desktop) exporta un
// widget vacío, ya que la pantalla de detalle usa `embedYoutubeDisponible`
// para decidir cuándo mostrar el reproductor nativo y cuándo el respaldo
// con miniatura + "Abrir en YouTube".
export 'reproductor_youtube_stub.dart'
    if (dart.library.js_interop) 'reproductor_youtube_web.dart';
