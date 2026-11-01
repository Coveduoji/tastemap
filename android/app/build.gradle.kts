plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tastemap.tastemap"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tastemap.tastemap"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // The same ignored local SDK key is needed by the bundled positioning SDK.
        val localConfig = rootProject.file("../lib/config.dart")
        val localKey = if (localConfig.exists()) Regex("amapAndroidApiKey\\s*=\\s*['\"]([^'\"]+)['\"]").find(localConfig.readText())?.groupValues?.get(1) else null
        manifestPlaceholders["AMAP_API_KEY"] = providers.environmentVariable("AMAP_ANDROID_KEY").orNull ?: localKey.orEmpty()
    }

    buildTypes {
        configureEach {
            // Opt-in side-by-side build for device QA; preserve the installed app.
            if (providers.environmentVariable("TASTEMAP_PREVIEW").orNull == "1") {
                applicationIdSuffix = ".preview"
                if (!flutter.versionName.contains("-preview")) {
                    versionNameSuffix = "-preview"
                }
            }
        }
        release {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.amap.api:3dmap-location-search:11.3.100_loc11.3.101_sea9.8.1")
}
