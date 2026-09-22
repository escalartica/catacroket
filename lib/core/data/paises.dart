/// Un país, con su código ISO de dos letras y su nombre en español.
class Pais {
  const Pais(this.codigo, this.nombre);

  final String codigo;
  final String nombre;

  /// La bandera no se guarda: se calcula. Cada letra del código se convierte
  /// en su "indicador regional" Unicode, y el par de indicadores lo pinta el
  /// sistema como la bandera. Así no hay que empaquetar 200 imágenes ni
  /// mantener una tabla de emojis que se quede desactualizada.
  String get bandera => codigo.toUpperCase().codeUnits
      .map((int c) => String.fromCharCode(0x1F1E6 + c - 65))
      .join();

  String get conBandera => '$bandera  $nombre';
}

/// Los países donde es plausible catar una croqueta, empezando por casa.
///
/// No es la lista completa de la ONU a propósito: una lista de 200 en un
/// selector es peor que una de 60 bien elegidos, y siempre queda "Otro país"
/// para lo que falte. Si alguien cata una croqueta en Kiribati, se merece que
/// se lo pidamos por escrito.
class Paises {
  const Paises._();

  static const String porDefecto = 'ES';

  static const List<Pais> todos = <Pais>[
    Pais('ES', 'España'),
    Pais('PT', 'Portugal'),
    Pais('FR', 'Francia'),
    Pais('IT', 'Italia'),
    Pais('DE', 'Alemania'),
    Pais('GB', 'Reino Unido'),
    Pais('IE', 'Irlanda'),
    Pais('NL', 'Países Bajos'),
    Pais('BE', 'Bélgica'),
    Pais('LU', 'Luxemburgo'),
    Pais('CH', 'Suiza'),
    Pais('AT', 'Austria'),
    Pais('DK', 'Dinamarca'),
    Pais('SE', 'Suecia'),
    Pais('NO', 'Noruega'),
    Pais('FI', 'Finlandia'),
    Pais('IS', 'Islandia'),
    Pais('PL', 'Polonia'),
    Pais('CZ', 'Chequia'),
    Pais('SK', 'Eslovaquia'),
    Pais('HU', 'Hungría'),
    Pais('RO', 'Rumanía'),
    Pais('BG', 'Bulgaria'),
    Pais('GR', 'Grecia'),
    Pais('HR', 'Croacia'),
    Pais('SI', 'Eslovenia'),
    Pais('RS', 'Serbia'),
    Pais('AL', 'Albania'),
    Pais('EE', 'Estonia'),
    Pais('LV', 'Letonia'),
    Pais('LT', 'Lituania'),
    Pais('MT', 'Malta'),
    Pais('CY', 'Chipre'),
    Pais('TR', 'Turquía'),
    Pais('MA', 'Marruecos'),
    Pais('DZ', 'Argelia'),
    Pais('TN', 'Túnez'),
    Pais('EG', 'Egipto'),
    Pais('SN', 'Senegal'),
    Pais('ZA', 'Sudáfrica'),
    Pais('US', 'Estados Unidos'),
    Pais('CA', 'Canadá'),
    Pais('MX', 'México'),
    Pais('GT', 'Guatemala'),
    Pais('CR', 'Costa Rica'),
    Pais('PA', 'Panamá'),
    Pais('CU', 'Cuba'),
    Pais('DO', 'República Dominicana'),
    Pais('PR', 'Puerto Rico'),
    Pais('CO', 'Colombia'),
    Pais('VE', 'Venezuela'),
    Pais('EC', 'Ecuador'),
    Pais('PE', 'Perú'),
    Pais('BO', 'Bolivia'),
    Pais('CL', 'Chile'),
    Pais('AR', 'Argentina'),
    Pais('UY', 'Uruguay'),
    Pais('PY', 'Paraguay'),
    Pais('BR', 'Brasil'),
    Pais('JP', 'Japón'),
    Pais('KR', 'Corea del Sur'),
    Pais('CN', 'China'),
    Pais('TH', 'Tailandia'),
    Pais('VN', 'Vietnam'),
    Pais('ID', 'Indonesia'),
    Pais('PH', 'Filipinas'),
    Pais('IN', 'India'),
    Pais('AE', 'Emiratos Árabes Unidos'),
    Pais('IL', 'Israel'),
    Pais('AU', 'Australia'),
    Pais('NZ', 'Nueva Zelanda'),
    Pais('XX', 'Otro país'),
  ];

  static final Map<String, Pais> _porCodigo = <String, Pais>{
    for (final Pais p in todos) p.codigo: p,
  };

  /// Nunca falla: un código desconocido cae en "Otro país" en vez de romper
  /// la ficha de una cata.
  static Pais de(String codigo) =>
      _porCodigo[codigo.toUpperCase()] ?? todos.last;

  /// Si el código está en la lista. Lo usa el geocodificador: un país que no
  /// está aquí no se escribe en el formulario, porque acabaría enseñándose
  /// como "Otro país" y sería peor que no tocar nada.
  static bool existe(String codigo) =>
      _porCodigo.containsKey(codigo.toUpperCase());

  /// Búsqueda sin acentos ni mayúsculas, para el selector.
  static List<Pais> buscar(String texto) {
    final String q = _normalizar(texto);
    if (q.isEmpty) return todos;
    return todos
        .where((Pais p) => _normalizar(p.nombre).contains(q))
        .toList();
  }

  static String _normalizar(String texto) {
    const String con = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const String sin = 'aaaaaeeeeiiiiooooouuuunc';
    final StringBuffer salida = StringBuffer();
    for (final int unidad in texto.toLowerCase().runes) {
      final String caracter = String.fromCharCode(unidad);
      final int indice = con.indexOf(caracter);
      salida.write(indice >= 0 ? sin[indice] : caracter);
    }
    return salida.toString().trim();
  }
}
