import java.io.FileInputStream
import java.util.Properties

// La firma de release NO va en el repositorio.
//
// `android/key.properties` apunta al almacén de claves y lleva las
// contraseñas; los dos están en .gitignore. Si el fichero no existe —otro
// ordenador, un clon recién hecho— la app se sigue compilando con la clave
// de depuración, para que `flutter run --release` funcione sin montar nada.
// Lo que no se puede es SUBIR eso a Play: un .aab firmado con la clave de
// depuración lo rechaza la consola.
val ficheroFirma = rootProject.file("key.properties")
val hayFirmaPropia = ficheroFirma.exists()
val firma = Properties().apply {
    if (hayFirmaPropia) FileInputStream(ficheroFirma).use { load(it) }
}

// Si key.properties existe pero está a medio rellenar, mejor enterarse ahora
// que dentro de cuatro minutos, cuando falle la última tarea del build con un
// «keystore password was incorrect» que no explica nada.
//
// Sólo se comprueba al compilar release: un `flutter run` de depuración no
// usa esta firma y no tiene por qué romperse por esto.
val vaDeRelease = gradle.startParameter.taskNames.any { it.contains("elease") }
if (hayFirmaPropia && vaDeRelease) {
    val aMedias = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
        .filter { campo ->
            val valor = firma.getProperty(campo).orEmpty().trim()
            valor.isEmpty() ||
                valor.startsWith("AQUI-") ||
                valor.startsWith("LA-MISMA") ||
                valor.startsWith("la-contrasena") ||
                valor.startsWith("tu-")
        }
    if (aMedias.isNotEmpty()) {
        throw GradleException(
            "android/key.properties sigue con el texto de la plantilla en: " +
                aMedias.joinToString(", ") + ".\n" +
                "Rellénalo con los datos reales del almacén de claves. " +
                "storePassword y keyPassword son la misma contraseña."
        )
    }
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.escalartica.catacroket"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // El mismo identificador que en iOS. Cambiarlo rompe google-services.json.
        applicationId = "com.escalartica.catacroket"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hayFirmaPropia) {
            create("release") {
                storeFile = firma.getProperty("storeFile")?.let { file(it) }
                storePassword = firma.getProperty("storePassword")
                keyAlias = firma.getProperty("keyAlias")
                keyPassword = firma.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hayFirmaPropia) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
