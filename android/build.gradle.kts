allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    if (project.state.executed) {
        configureCompileSdk(project)
    } else {
        project.afterEvaluate {
            configureCompileSdk(project)
        }
    }
}

fun configureCompileSdk(proj: Project) {
    val android = proj.extensions.findByName("android")
    if (android != null) {
        try {
            val method = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
            method.invoke(android, 36)
        } catch (e: Exception) {
            try {
                val method = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                method.invoke(android, 36)
            } catch (e2: Exception) {
                // Ignore
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
