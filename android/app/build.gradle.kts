import com.android.build.gradle.internal.api.BaseVariantOutputImpl

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.capstone_terea"
    
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.capstone_terea" 
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        setProperty("archivesBaseName", "TEREA")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs = freeCompilerArgs + listOf("-Xskip-metadata-version-check")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    applicationVariants.all {
        val variant = this
        variant.outputs.all {
            val output = this as? BaseVariantOutputImpl
            if (variant.buildType.name == "release") {
                output?.outputFileName = "TEREA.apk"
            }
        }
    }
}

flutter {
    source = "../.."
}

tasks.matching { it.name.contains("AarMetadata", ignoreCase = true) }.configureEach {
    enabled = false
}
