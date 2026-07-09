Logos actuales (ya cargados):

  visa.png
  mastercard.webp
  yappy.webp
  paypal.webp
  banistmo.png

Falta: transferencia.png (icono generico de banco / transferencia).

Si reemplazas alguno, respeta el nombre base (visa, mastercard, yappy,
paypal, banistmo, transferencia). La extension puede ser .png o .webp —
si cambias la extension de un archivo existente, actualiza el mapa
_extensiones en lib/screens/comprador/pantalla_pago.dart -> _LogoMetodoPago.

Descarga los logos desde el sitio oficial o el "media kit" / "brand kit" de
cada empresa (ej: newsroom.paypal-corp.com para PayPal, yappy.com para Yappy)
para respetar sus lineamientos de marca.

Si un archivo no existe todavia, la pantalla de pago sigue funcionando: usa
automaticamente el logotipo dibujado como respaldo (ver
lib/screens/comprador/pantalla_pago.dart -> _LogoMetodoPago).
