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
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            try {
                val namespaceMethod = android.javaClass.getMethod("getNamespace")
                val namespace = namespaceMethod.invoke(android)
                if (namespace == null) {
                    val setNamespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespaceMethod.invoke(android, "com.pennytracker.generated.${project.name.replace("-", ".")}")
                }
            } catch (e: Exception) {
                // If the method doesn't exist or fails, it might be an older AGP or different structure
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
