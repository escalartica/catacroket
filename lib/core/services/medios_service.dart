import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../models/medio.dart';

/// Resultado de intentar añadir una foto o un vídeo.
///
/// No es un `Medio?` a secas porque "no hay medio" tiene tres causas muy
/// distintas —el usuario canceló, el vídeo era demasiado largo, algo falló—
/// y la pantalla tiene que decir cosas diferentes en cada caso.
sealed class ResultadoMedio {
  const ResultadoMedio();
}

class MedioListo extends ResultadoMedio {
  const MedioListo(this.medio);
  final Medio medio;
}

class MedioCancelado extends ResultadoMedio {
  const MedioCancelado();
}

class MedioRechazado extends ResultadoMedio {
  const MedioRechazado(this.motivo);
  final String motivo;
}

/// Fotos y vídeos de una cata.
///
/// Todo lo que se elige se COPIA a la carpeta de documentos de la app. Las
/// rutas que devuelve `image_picker` apuntan a una caché temporal que el
/// sistema borra cuando le apetece: guardar esa ruta en la cata es la forma
/// segura de que, semanas después, la ficha aparezca con la foto rota.
class MediosService {
  const MediosService._();

  static final ImagePicker _selector = ImagePicker();

  static Future<ResultadoMedio> foto({required bool camara}) async {
    try {
      final XFile? elegida = await _selector.pickImage(
        source: camara ? ImageSource.camera : ImageSource.gallery,
        // Las fotos de croquetas no necesitan 4000 px. Esto baja el tamaño
        // en disco un orden de magnitud sin que se note en pantalla.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (elegida == null) return const MedioCancelado();

      final String ruta = await _copiar(elegida, 'foto');
      return MedioListo(Medio(tipo: TipoMedio.foto, ruta: ruta));
    } catch (_) {
      return const MedioRechazado('No se pudo abrir la foto.');
    }
  }

  static Future<ResultadoMedio> video({required bool camara}) async {
    try {
      final XFile? elegido = await _selector.pickVideo(
        source: camara ? ImageSource.camera : ImageSource.gallery,
        // Limita la GRABACIÓN a 15 s. Un vídeo elegido de la galería puede
        // ser más largo, así que después se comprueba de verdad.
        maxDuration: Medio.duracionMaxima,
      );
      if (elegido == null) return const MedioCancelado();

      final Duration? duracion = await _duracionDe(elegido.path);
      if (duracion != null && duracion > Medio.duracionMaxima + const Duration(seconds: 1)) {
        return MedioRechazado(
          'Ese vídeo dura ${duracion.inSeconds} s. El máximo son '
          '${Medio.duracionMaxima.inSeconds}: recórtalo y vuelve a probar.',
        );
      }

      final String ruta = await _copiar(elegido, 'video');
      return MedioListo(Medio(tipo: TipoMedio.video, ruta: ruta));
    } catch (_) {
      return const MedioRechazado('No se pudo abrir el vídeo.');
    }
  }

  /// Duración real del fichero. Devuelve nulo si no se puede leer, y en ese
  /// caso se deja pasar: es preferible aceptar un vídeo algo largo que
  /// rechazar uno bueno por un fallo de lectura.
  static Future<Duration?> _duracionDe(String ruta) async {
    VideoPlayerController? control;
    try {
      control = VideoPlayerController.file(File(ruta));
      await control.initialize();
      return control.value.duration;
    } catch (_) {
      return null;
    } finally {
      await control?.dispose();
    }
  }

  static Future<String> _copiar(XFile origen, String prefijo) async {
    final Directory carpeta = await getApplicationDocumentsDirectory();
    final Directory medios = Directory('${carpeta.path}/medios');
    if (!medios.existsSync()) medios.createSync(recursive: true);

    final String extension = origen.path.contains('.')
        ? origen.path.split('.').last
        : (prefijo == 'video' ? 'mp4' : 'jpg');
    final String nombre =
        '${prefijo}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final String destino = '${medios.path}/$nombre';

    await File(origen.path).copy(destino);
    return destino;
  }

  /// Borra el fichero de un medio descartado. Si falla no pasa nada: un
  /// huérfano ocupa unos KB, y reventar aquí sí se notaría.
  static Future<void> borrar(Medio medio) async {
    try {
      final File fichero = File(medio.ruta);
      if (fichero.existsSync()) await fichero.delete();
    } catch (_) {}
  }
}
