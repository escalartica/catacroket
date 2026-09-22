import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../data/paises.dart';
import '../models/lugar.dart';

/// Qué ha pasado al pedir la ubicación.
///
/// Los tres fallos posibles se distinguen porque se arreglan de formas
/// distintas: el GPS apagado lo arregla el usuario en ajustes del sistema, un
/// permiso denegado una vez se arregla volviendo a pedirlo, y uno denegado
/// para siempre sólo se arregla en los ajustes de la app. Un único "ha
/// fallado" obligaría a la pantalla a mentir en dos de los tres casos.
sealed class ResultadoUbicacion {
  const ResultadoUbicacion();
}

class UbicacionLista extends ResultadoUbicacion {
  const UbicacionLista(this.lugar);
  final Lugar lugar;
}

class UbicacionApagada extends ResultadoUbicacion {
  const UbicacionApagada();
}

class UbicacionSinPermiso extends ResultadoUbicacion {
  const UbicacionSinPermiso({required this.definitivo});

  /// Denegado "para siempre": volver a preguntar no abre ningún diálogo, hay
  /// que mandar al usuario a los ajustes.
  final bool definitivo;
}

class UbicacionFallida extends ResultadoUbicacion {
  const UbicacionFallida(this.mensaje);
  final String mensaje;
}

/// GPS y geocodificación.
///
/// El buscador y la geocodificación inversa van contra Nominatim, el servicio
/// público de OpenStreetMap: no necesita clave ni tarjeta, que es lo mismo
/// que ya decidimos para las teselas del mapa. A cambio pide identificarse
/// con un User-Agent de verdad y no pasar de una consulta por segundo, y por
/// eso el buscador espera a que dejes de escribir en vez de consultar letra a
/// letra. Si algún día esto lo usa mucha gente, hay que pagar un
/// geocodificador; hasta entonces, esto es lo honesto y lo suficiente.
class UbicacionService {
  const UbicacionService._();

  static const String _agente = 'Catacroket/1.0 (com.escalartica.catacroket)';
  static const String _base = 'nominatim.openstreetmap.org';
  static const Duration _espera = Duration(seconds: 12);

  // ── GPS ──────────────────────────────────────────────────────────────────

  /// Dónde estás ahora mismo, con la ciudad y el país ya deducidos si se
  /// puede. Si la geocodificación inversa falla, devuelve el punto igual: las
  /// coordenadas son el dato que importa y el nombre es un extra.
  static Future<ResultadoUbicacion> dondeEstoy() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const UbicacionApagada();
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.deniedForever) {
        return const UbicacionSinPermiso(definitivo: true);
      }
      if (permiso == LocationPermission.denied) {
        return const UbicacionSinPermiso(definitivo: false);
      }

      final Position posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _espera,
        ),
      );

      final Lugar? conNombre = await inverso(
        posicion.latitude,
        posicion.longitude,
      );

      return UbicacionLista(
        conNombre ??
            Lugar(
              nombre: 'Donde estás',
              lat: posicion.latitude,
              lon: posicion.longitude,
            ),
      );
    } on Object catch (e) {
      return UbicacionFallida(
        e is TimeoutException
            ? 'El GPS ha tardado demasiado. Prueba a salir a la calle.'
            : 'No se ha podido leer el GPS.',
      );
    }
  }

  // ── Nominatim ───────────────────────────────────────────────────────────

  /// Busca un sitio por texto libre ("Bar Manoli, Sevilla").
  ///
  /// Devuelve lista vacía si no hay resultados o si no hay red: un buscador
  /// que revienta la pantalla por estar en el metro no sirve de nada, y el
  /// usuario siempre puede poner el punto a mano en el mapa.
  static Future<List<Lugar>> buscar(String consulta) async {
    final String q = consulta.trim();
    if (q.length < 3) return const <Lugar>[];

    final Uri uri = Uri.https(_base, '/search', <String, String>{
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '6',
      'accept-language': 'es',
    });

    final dynamic crudo = await _pedir(uri);
    if (crudo is! List<dynamic>) return const <Lugar>[];

    return crudo
        .map((dynamic e) => _leer(e))
        .whereType<Lugar>()
        .toList();
  }

  /// Qué hay en estas coordenadas.
  static Future<Lugar?> inverso(double lat, double lon) async {
    final Uri uri = Uri.https(_base, '/reverse', <String, String>{
      'lat': '$lat',
      'lon': '$lon',
      'format': 'jsonv2',
      'addressdetails': '1',
      'zoom': '18',
      'accept-language': 'es',
    });

    final dynamic crudo = await _pedir(uri);
    return _leer(crudo);
  }

  static Future<dynamic> _pedir(Uri uri) async {
    HttpClient? cliente;
    try {
      cliente = HttpClient()
        ..userAgent = _agente
        ..connectionTimeout = const Duration(seconds: 8);
      final HttpClientRequest peticion = await cliente.getUrl(uri);
      final HttpClientResponse respuesta =
          await peticion.close().timeout(_espera);
      if (respuesta.statusCode != 200) return null;
      final String cuerpo = await utf8.decoder.bind(respuesta).join();
      return jsonDecode(cuerpo);
    } on Object catch (_) {
      return null;
    } finally {
      cliente?.close(force: true);
    }
  }

  /// Convierte un resultado de Nominatim en un [Lugar].
  ///
  /// La ciudad se busca por orden de tamaño porque no todos los sitios tienen
  /// `city`: un bar de pueblo trae `village` y uno de polígono, `municipality`.
  static Lugar? _leer(dynamic crudo) {
    if (crudo is! Map<dynamic, dynamic>) return null;
    final Map<String, dynamic> json = Map<String, dynamic>.from(crudo);

    final double? lat = double.tryParse('${json['lat']}');
    final double? lon = double.tryParse('${json['lon']}');
    if (lat == null || lon == null) return null;

    final Map<String, dynamic> dir = json['address'] is Map<dynamic, dynamic>
        ? Map<String, dynamic>.from(json['address'] as Map<dynamic, dynamic>)
        : <String, dynamic>{};

    String texto(String clave) => (dir[clave] ?? '').toString();
    final String ciudad = <String>[
      texto('city'),
      texto('town'),
      texto('village'),
      texto('municipality'),
      texto('county'),
    ].firstWhere((String s) => s.isNotEmpty, orElse: () => '');

    final String codigo = texto('country_code').toUpperCase();
    final String completo = (json['display_name'] ?? '').toString();
    final String nombre = (json['name'] ?? '').toString().isNotEmpty
        ? json['name'].toString()
        : completo.split(',').first.trim();

    return Lugar(
      nombre: nombre.isEmpty ? 'Sitio sin nombre' : nombre,
      lat: lat,
      lon: lon,
      ciudad: ciudad,
      pais: Paises.existe(codigo) ? codigo : '',
    );
  }
}
