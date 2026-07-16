const Map<String, Map<String, String>> traducciones = {
  // ── Genéricos / reutilizados ─────────────────────────────────────────────
  'vendedor_inventario.cancelar': {'es': 'Cancelar', 'en': 'Cancel'},
  'vendedor_inventario.editar': {'es': 'Editar', 'en': 'Edit'},
  'vendedor_inventario.eliminar': {'es': 'Eliminar', 'en': 'Delete'},
  'vendedor_inventario.seccion_descripcion': {'es': 'Descripción', 'en': 'Description'},

  // ── Pantalla de inventario: encabezado ──────────────────────────────────
  'vendedor_inventario.titulo_pantalla': {'es': 'Mi inventario', 'en': 'My inventory'},
  'vendedor_inventario.subtitulo_pantalla': {
    'es': 'Gestiona y organiza todos tus productos en un solo lugar.',
    'en': 'Manage and organize all your products in one place.',
  },
  'vendedor_inventario.exportar_inventario': {'es': 'Exportar inventario', 'en': 'Export inventory'},
  'vendedor_inventario.agregar_producto': {'es': 'Agregar producto', 'en': 'Add product'},

  // ── Estadísticas ─────────────────────────────────────────────────────────
  'vendedor_inventario.stat_productos_totales': {'es': 'Productos totales', 'en': 'Total products'},
  'vendedor_inventario.stat_activos': {'es': 'Activos', 'en': 'Active'},
  'vendedor_inventario.stat_agotados': {'es': 'Agotados', 'en': 'Out of stock'},
  'vendedor_inventario.stat_visitas_mes': {'es': 'Visitas este mes', 'en': 'Visits this month'},
  'vendedor_inventario.stat_ventas_totales': {'es': 'Ventas totales', 'en': 'Total sales'},

  // ── Barra de filtros ─────────────────────────────────────────────────────
  'vendedor_inventario.buscar_producto_hint': {'es': 'Buscar producto...', 'en': 'Search product...'},
  'vendedor_inventario.limpiar_filtros': {'es': 'Limpiar filtros', 'en': 'Clear filters'},
  'vendedor_inventario.filtros_avanzados': {'es': 'Filtros avanzados', 'en': 'Advanced filters'},

  // ── Grilla de productos ──────────────────────────────────────────────────
  'vendedor_inventario.sin_productos_filtrados': {
    'es': 'No se encontraron productos con los filtros aplicados.',
    'en': 'No products found matching the applied filters.',
  },

  // ── Eliminar producto (diálogo de confirmación) ─────────────────────────
  'vendedor_inventario.eliminar_producto_titulo': {'es': 'Eliminar producto', 'en': 'Delete product'},
  'vendedor_inventario.confirmar_eliminar_prefijo': {
    'es': '¿Seguro que quieres eliminar "',
    'en': 'Are you sure you want to delete "',
  },
  'vendedor_inventario.confirmar_eliminar_sufijo': {
    'es': '"? Esta acción no se puede deshacer.',
    'en': '"? This action cannot be undone.',
  },
  'vendedor_inventario.no_se_pudo_eliminar_prefijo': {
    'es': 'No se pudo eliminar: ',
    'en': 'Could not delete: ',
  },

  // ── Exportar inventario ──────────────────────────────────────────────────
  'vendedor_inventario.exportado_correctamente': {
    'es': 'Inventario exportado correctamente.',
    'en': 'Inventory exported successfully.',
  },
  'vendedor_inventario.no_se_pudo_exportar_prefijo': {
    'es': 'No se pudo exportar: ',
    'en': 'Could not export: ',
  },

  // ── Error de carga de la pantalla ────────────────────────────────────────
  'vendedor_inventario.no_se_pudo_cargar_prefijo': {
    'es': 'No se pudo cargar el inventario: ',
    'en': 'Could not load inventory: ',
  },

  // ── Diálogos editar/crear producto ───────────────────────────────────────
  'vendedor_inventario.editar_producto_titulo': {'es': 'Editar producto', 'en': 'Edit product'},
  'vendedor_inventario.nuevo_producto_titulo': {'es': 'Nuevo producto', 'en': 'New product'},
  'vendedor_inventario.nuevo_producto_subtitulo': {
    'es': 'Publica una nueva pieza en tu tienda',
    'en': 'Publish a new piece in your shop',
  },
  'vendedor_inventario.error_validacion_producto': {
    'es': 'Revisa que nombre, precio y stock sean válidos.',
    'en': 'Please check that the name, price, and stock are valid.',
  },
  'vendedor_inventario.seccion_informacion_basica': {'es': 'Información básica', 'en': 'Basic information'},
  'vendedor_inventario.seccion_precio_inventario': {'es': 'Precio e inventario', 'en': 'Price & inventory'},
  'vendedor_inventario.seccion_imagen_producto': {'es': 'Imagen del producto', 'en': 'Product image'},
  'vendedor_inventario.label_nombre_producto': {'es': 'Nombre del producto', 'en': 'Product name'},
  'vendedor_inventario.label_precio': {'es': 'Precio', 'en': 'Price'},
  'vendedor_inventario.label_stock': {'es': 'Stock', 'en': 'Stock'},
  'vendedor_inventario.label_categoria': {'es': 'Categoría', 'en': 'Category'},
  'vendedor_inventario.hint_descripcion_producto': {
    'es': 'Materiales, técnica, tamaño, tiempo de elaboración...',
    'en': 'Materials, technique, size, time to make...',
  },
  'vendedor_inventario.tip_precio': {
    'es': 'Compara con productos parecidos de tu categoría antes de fijar el precio: '
        'te ayuda a mantenerte competitivo sin regalar tu trabajo.',
    'en': "Compare with similar products in your category before setting the price — "
        "it helps you stay competitive without underselling your work.",
  },
  'vendedor_inventario.tip_imagen': {
    'es': 'Usa luz natural y un fondo limpio y neutro. Las fotos claras y bien '
        'iluminadas son las que más convierten visitas en ventas.',
    'en': 'Use natural light and a clean, neutral background. Bright, well-lit '
        'photos are the ones that turn visits into sales most often.',
  },
  'vendedor_inventario.tip_descripcion': {
    'es': 'Cuenta la historia detrás de la pieza: qué materiales usaste y de qué '
        'provincia es la técnica. A los compradores les encanta esa conexión.',
    'en': 'Tell the story behind the piece — what materials you used and which '
        'province the technique comes from. Buyers love that connection.',
  },
  'vendedor_inventario.tip_nombre': {
    'es': 'Un nombre claro y específico (ej. "Mola Guna floral tejida a mano") '
        'ayuda a que te encuentren más fácil en las búsquedas.',
    'en': 'A clear, specific name (e.g. "Hand-woven floral Guna Mola") helps '
        'buyers find you more easily in search.',
  },
  'vendedor_inventario.guardando': {'es': 'Guardando...', 'en': 'Saving...'},
  'vendedor_inventario.guardar_cambios': {'es': 'Guardar cambios', 'en': 'Save changes'},
  'vendedor_inventario.creando': {'es': 'Creando...', 'en': 'Creating...'},
  'vendedor_inventario.crear_producto': {'es': 'Crear producto', 'en': 'Create product'},
  'vendedor_inventario.generar_con_ia': {'es': 'Generar con IA', 'en': 'Generate with AI'},
  'vendedor_inventario.generando_ia': {'es': 'Generando...', 'en': 'Generating...'},
  'vendedor_inventario.nombres_sugeridos': {'es': 'Nombres sugeridos (toca uno para usarlo):', 'en': 'Suggested names (tap one to use it):'},
  'vendedor_inventario.error_ia_falta_borrador': {
    'es': 'Escribe algo sobre el producto primero (aunque sea el nombre).',
    'en': 'Write something about the product first (even just the name).',
  },

  // ── Selector de imagen del producto ─────────────────────────────────────
  'vendedor_inventario.label_url_imagen': {'es': 'URL de imagen', 'en': 'Image URL'},
  'vendedor_inventario.subir_imagen_pc': {'es': 'Subir imagen desde PC', 'en': 'Upload image from computer'},
  'vendedor_inventario.tomar_foto_camara': {'es': 'Tomar foto con cámara', 'en': 'Take photo with camera'},

  // ── widgets_inventario.dart: tarjeta de producto ────────────────────────
  'vendedor_inventario.ventas_prefijo': {'es': 'Ventas: ', 'en': 'Sales: '},

  // ── widgets_inventario.dart: badge de estado ────────────────────────────
  'vendedor_inventario.estado_activo': {'es': 'Activo', 'en': 'Active'},
  'vendedor_inventario.estado_agotado': {'es': 'Agotado', 'en': 'Out of stock'},
  'vendedor_inventario.estado_borrador': {'es': 'Borrador', 'en': 'Draft'},

  // ── widgets_inventario.dart: fila de producto (vista de tabla) ──────────
  'vendedor_inventario.mas_opciones_tooltip': {'es': 'Más opciones', 'en': 'More options'},
  'vendedor_inventario.unidades_sufijo': {'es': 'uds.', 'en': 'units'},

  // ── widgets_inventario.dart: paginador ───────────────────────────────────
  'vendedor_inventario.no_hay_productos': {'es': 'No hay productos', 'en': 'No products'},
  'vendedor_inventario.mostrando_prefijo': {'es': 'Mostrando ', 'en': 'Showing '},
  'vendedor_inventario.mostrando_a_infijo': {'es': ' a ', 'en': ' to '},
  'vendedor_inventario.mostrando_de_infijo': {'es': ' de ', 'en': ' of '},
  'vendedor_inventario.mostrando_productos_sufijo': {'es': ' productos', 'en': ' products'},
  'vendedor_inventario.productos_por_pagina': {'es': 'Productos por página:', 'en': 'Products per page:'},

  // ── dialogo_subir_video.dart ─────────────────────────────────────────────
  'vendedor_inventario.subir_mi_video_titulo': {'es': 'Subir mi video', 'en': 'Upload my video'},
  'vendedor_inventario.subir_mi_video_subtitulo': {
    'es': 'Comparte tu conocimiento con la comunidad',
    'en': 'Share your knowledge with the community',
  },
  'vendedor_inventario.label_enlace_youtube': {'es': 'Enlace de YouTube *', 'en': 'YouTube link *'},
  'vendedor_inventario.hint_enlace_ayuda': {
    'es': 'Sube tu video a YouTube y pega aquí el enlace.',
    'en': 'Upload your video to YouTube and paste the link here.',
  },
  'vendedor_inventario.label_titulo_tutorial': {'es': 'Título del tutorial *', 'en': 'Tutorial title *'},
  'vendedor_inventario.placeholder_titulo_tutorial': {
    'es': 'Ej. Técnica de bordado Mola paso a paso',
    'en': 'E.g. Step-by-step Mola embroidery technique',
  },
  'vendedor_inventario.titulo_requerido': {'es': 'El título es requerido', 'en': 'The title is required'},
  'vendedor_inventario.titulo_min_caracteres': {
    'es': 'El título debe tener al menos 5 caracteres',
    'en': 'The title must be at least 5 characters long',
  },
  'vendedor_inventario.placeholder_descripcion_tutorial': {
    'es': 'Describe brevemente qué aprenderán los espectadores...',
    'en': 'Briefly describe what viewers will learn...',
  },
  'vendedor_inventario.label_categoria_video': {'es': 'Categoría *', 'en': 'Category *'},
  'vendedor_inventario.hint_seleccionar_categoria': {
    'es': 'Selecciona una categoría',
    'en': 'Select a category',
  },
  'vendedor_inventario.youtube_requerido': {
    'es': 'El enlace de YouTube es requerido',
    'en': 'The YouTube link is required',
  },
  'vendedor_inventario.youtube_invalido': {
    'es': 'Ingresa un enlace válido de YouTube',
    'en': 'Enter a valid YouTube link',
  },
  'vendedor_inventario.seleccionar_categoria_snackbar': {
    'es': 'Por favor selecciona una categoría.',
    'en': 'Please select a category.',
  },
  'vendedor_inventario.no_se_pudo_publicar_tutorial_prefijo': {
    'es': 'No se pudo publicar el tutorial: ',
    'en': "Couldn't publish the tutorial: ",
  },
  'vendedor_inventario.subir_tutorial_btn': {'es': 'Subir tutorial', 'en': 'Upload tutorial'},

  // ── tarjeta_tutorial.dart ─────────────────────────────────────────────────
  'vendedor_inventario.vistas_sufijo': {'es': 'vistas', 'en': 'views'},

  // ── tarjeta_mi_video.dart ────────────────────────────────────────────────
  'vendedor_inventario.opciones_tooltip': {'es': 'Opciones', 'en': 'Options'},

  // ── widgets/inventario.dart (tabla de productos, sin usar actualmente) ──
  'vendedor_inventario.editar_producto_tooltip': {'es': 'Editar producto', 'en': 'Edit product'},
  'vendedor_inventario.mostrando_registros': {'es': 'Mostrando 1 a {n} de {total} productos', 'en': 'Showing 1 to {n} of {total} products'},
};
