import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Read .env file
val envFile = rootProject.file("../.env")
val envProperties = Properties().apply {
    if (envFile.exists()) {
        load(envFile.inputStream())
    }
}

// Read local.properties for versioning
val localPropsFile = rootProject.file("local.properties")
val localProps = Properties().apply {
    if (localPropsFile.exists()) {
        load(localPropsFile.inputStream())
    }
}
val versionCodeFromLocal = localProps.getProperty("flutter.versionCode")?.toIntOrNull() ?: 1
val versionNameFromLocal = localProps.getProperty("flutter.versionName") ?: "1.0.0"

android {
    namespace = "com.unemployednerds.resqtail"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.unemployednerds.resqtail"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = versionCodeFromLocal
        versionName = versionNameFromLocal
        manifestPlaceholders["googleMapsApiKey"] = envProperties.getProperty("GOOGLE_MAPS_API_KEY", "")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
