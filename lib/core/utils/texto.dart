/// Comparar texto escrito por personas.
///
/// Existe porque había dos copias de esto y no hacían lo mismo: la de
/// `Evitar` cubría la ã y la õ y la de las píldoras de relleno no, así que
/// buscar «acai» encontraba un relleno en un sitio y no en el otro. Una regla
/// de comparación duplicada no se queda duplicada mucho tiempo: se bifurca.
abstract final class Texto {
  /// Minúsculas y sin tildes. Lo justo para que «jamon» encuentre «Jamón».
  ///
  /// La ñ se convierte en n a propósito. Sí, «año» y «ano» son cosas
  /// distintas, pero esto sólo sirve para buscar y nadie escribe la tilde de
  /// la ñ con el móvil en una mano y una croqueta en la otra.
  static String normalizar(String texto) {
    // Sólo minúsculas: arriba ya se ha pasado todo a minúsculas, así que las
    // acentuadas en mayúscula no llegan hasta aquí.
    const String conTildes = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const String sin = 'aaaaaeeeeiiiiooooouuuunc';

    final StringBuffer salida = StringBuffer();
    for (final int unidad in texto.toLowerCase().runes) {
      final String letra = String.fromCharCode(unidad);
      final int i = conTildes.indexOf(letra);
      salida.write(i == -1 ? letra : sin[i]);
    }
    return salida.toString().trim();
  }

  /// ¿Aparece [aguja] dentro de [pajar], sin mirar tildes ni mayúsculas?
  ///
  /// Una aguja vacía encuentra siempre: quien no ha escrito nada en la caja de
  /// buscar no está filtrando nada.
  static bool contiene(String pajar, String aguja) {
    final String q = normalizar(aguja);
    if (q.isEmpty) return true;
    return normalizar(pajar).contains(q);
  }

  /// ¿Aparece [aguja] en alguno de [textos]?
  ///
  /// Se busca campo a campo y no en todo junto para que una palabra no case a
  /// caballo entre dos: con «Bar Manoli» y «Sevilla» pegados, buscar
  /// «manoli sevilla» encontraría algo que en la ficha no se lee así.
  static bool contieneEnAlguno(Iterable<String> textos, String aguja) {
    if (normalizar(aguja).isEmpty) return true;
    for (final String t in textos) {
      if (t.isNotEmpty && contiene(t, aguja)) return true;
    }
    return false;
  }

  /// Una lista de nombres como se dice en castellano: «A», «B» y «C».
  ///
  /// Estaba escrito de cuatro formas distintas en cuatro pantallas, y la que
  /// leía todo el mundo —la que va pegada al botón de publicar— decía
  /// «A y B y C». Una sola función y una sola forma.
  static String enumerar(List<String> nombres, {bool comillas = true}) {
    String vestir(String n) => comillas ? '«$n»' : n;

    if (nombres.isEmpty) return '';
    if (nombres.length == 1) return vestir(nombres.first);

    final List<String> todos = nombres.map(vestir).toList();
    final String ultimo = todos.removeLast();
    return '${todos.join(', ')} y $ultimo';
  }
}
