import 'package:catacroket/core/models/persona.dart';
import 'package:catacroket/core/providers/yo_provider.dart';
import 'package:catacroket/core/theme/tokens/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Yo', () {
    test('de partida no hay foto y la inicial sale del nombre', () {
      const Yo yo = Yo();
      expect(yo.foto, isNull);
      expect(yo.tieneFoto, isFalse);
      expect(yo.inicial, 'T');
    });

    test('la inicial ignora espacios y va en mayúscula', () {
      expect(const Yo(nombre: '  ana  ').inicial, 'A');
    });

    test('un nombre vacío no deja la app sin avatar', () {
      expect(const Yo(nombre: '   ').inicial, '?');
    });

    test('una ruta que no existe no cuenta como foto', () {
      // Es el caso real: el sistema limpia la carpeta o el usuario borra el
      // fichero, y la ruta guardada se queda apuntando a la nada.
      const Yo yo = Yo(foto: '/no/existe/foto.jpg');
      expect(yo.foto, isNotNull);
      expect(yo.tieneFoto, isFalse);
    });

    test('copiaCon cambia sólo lo que se le pasa', () {
      const Yo yo = Yo(nombre: 'Ana', foto: '/x.jpg');
      expect(yo.copiaCon(nombre: 'Eva').foto, '/x.jpg');
      expect(yo.copiaCon(nombre: 'Eva').nombre, 'Eva');
      expect(yo.copiaCon(quitarFoto: true).foto, isNull);
      expect(yo.copiaCon(quitarFoto: true).nombre, 'Ana');
    });
  });

  group('ResultadoFoto', () {
    test('listo y cancelado no dicen nada', () {
      // Cancelar es una decisión, no un error: avisar ahí sería regañar al
      // usuario por cambiar de idea.
      expect(ResultadoFoto.listo.aviso, isNull);
      expect(ResultadoFoto.cancelado.aviso, isNull);
    });

    test('un fallo siempre tiene algo que decir', () {
      // Éste es el caso que rompía: permiso denegado, la excepción se comía
      // el error y el botón parecía no hacer nada.
      expect(ResultadoFoto.sinCamara.aviso, isNotNull);
      expect(ResultadoFoto.sinGaleria.aviso, isNotNull);
      expect(ResultadoFoto.sinCamara.aviso, contains('Ajustes'));
    });
  });

  group('Persona con foto', () {
    test('copiaCon conserva id y color', () {
      const Persona p = Persona(id: 'yo', nombre: 'Ana', color: AppColors.menta);
      final Persona q = p.copiaCon(nombre: 'Eva', foto: '/x.jpg');
      expect(q.id, 'yo');
      expect(q.color, AppColors.menta);
      expect(q.nombre, 'Eva');
      expect(q.foto, '/x.jpg');
    });

    test('sin foto sigue habiendo inicial', () {
      const Persona p = Persona(id: 'x', nombre: 'Jose', color: AppColors.uva);
      expect(p.foto, isNull);
      expect(p.inicial, 'J');
    });
  });
}
