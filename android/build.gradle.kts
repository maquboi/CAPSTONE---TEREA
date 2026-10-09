allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.browser" && requested.name == "browser") {
                useVersion("1.8.0")
            }
            if (requested.group == "androidx.activity") {
                useVersion("1.9.3")
            }
            if (requested.group == "androidx.core") {
                useVersion("1.15.0")
            }
        }
    }
}

subprojects {
    tasks.matching { it.name.contains("Kotlin", ignoreCase = true) }.configureEach {
        try {
            val getMethod = this.javaClass.getMethod("getKotlinOptions")
            val kOptions = getMethod.invoke(this)
            val getArgsMethod = kOptions.javaClass.getMethod("getFreeCompilerArgs")
            val setArgsMethod = kOptions.javaClass.getMethod("setFreeCompilerArgs", List::class.java)
            @Suppress("UNCHECKED_CAST")
            val currentArgs = (getArgsMethod.invoke(kOptions) as? List<String>)?.toMutableList() ?: mutableListOf<String>()
            if (!currentArgs.contains("-Xskip-metadata-version-check")) {
                currentArgs.add("-Xskip-metadata-version-check")
                setArgsMethod.invoke(kOptions, currentArgs)
            }
        } catch (_: Exception) {}
        try {
            val getCompMethod = this.javaClass.getMethod("getCompilerOptions")
            val compOptions = getCompMethod.invoke(this)
            val getFreeArgsMethod = compOptions.javaClass.getMethod("getFreeCompilerArgs")
            val freeArgsProp = getFreeArgsMethod.invoke(compOptions)
            val addMethod = freeArgsProp.javaClass.getMethod("add", Any::class.java)
            addMethod.invoke(freeArgsProp, "-Xskip-metadata-version-check")
        } catch (_: Exception) {}
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
