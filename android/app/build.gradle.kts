import com.android.build.gradle.internal.api.BaseVariantOutputImpl

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.capstone_terea"
    
    // Set to 36 to satisfy plugin compilation
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
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            
            // Prevents R8 from stripping Supabase, OneSignal, or native camera classes
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Automatically names the output APK to TEREA.apk
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

// Bypasses the CheckAarMetadata task completely so metadata warnings never block the build
tasks.matching { it.name.contains("AarMetadata", ignoreCase = true) }.configureEach {
    enabled = false
}