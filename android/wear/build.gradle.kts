import java.util.Properties

// Wear-OS-Begleit-App „Fitness“: Kachel und Komplikation „Nächstes Training“.
// Eigenes APK (`./gradlew :wear:assembleRelease`), gleiche applicationId und
// gleicher Schlüssel wie die Telefon-App — sonst verbindet die
// Wearable-Datenschicht die beiden nicht.
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) keyPropertiesFile.inputStream().use { load(it) }
}

// Version wie die Telefon-App (pubspec.yaml, „version: 1.2.3+4“).
val pubspecVersion = rootProject.file("../pubspec.yaml").readLines()
    .firstOrNull { it.startsWith("version:") }
    ?.substringAfter(":")?.trim() ?: "0.0.0+1"

android {
    namespace = "space.mai.mai_fitness.wear"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "space.mai.mai_fitness"
        // Wear OS 3+ (Kacheln, Komplikations-Datenquellen).
        minSdk = 30
        targetSdk = 36
        versionCode = pubspecVersion.substringAfter("+", "1").toIntOrNull() ?: 1
        versionName = pubspecVersion.substringBefore("+")
    }

    signingConfigs {
        if (keyPropertiesFile.exists()) {
            create("release") {
                // Pfad wie in app/build.gradle.kts (relativ zu android/app).
                storeFile = project(":app").file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Wie die Telefon-App: ohne android/key.properties Debug-Key.
            signingConfig = signingConfigs.getByName(
                if (keyPropertiesFile.exists()) "release" else "debug",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("androidx.wear.tiles:tiles:1.4.1")
    implementation("androidx.wear.protolayout:protolayout:1.2.1")
    implementation("androidx.wear.watchface:watchface-complications-data-source:1.2.1")
    implementation("androidx.concurrent:concurrent-futures:1.2.0")
    implementation("com.google.android.gms:play-services-wearable:18.2.0")
}
