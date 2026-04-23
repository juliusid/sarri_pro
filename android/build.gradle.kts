
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // This is the line you need for Firebase
        classpath("com.google.gms:google-services:4.4.2") 
    }
}


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

    plugins.configureEach {
        if (this is com.android.build.gradle.api.AndroidBasePlugin) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // Fix missing namespaces for AGP 8.0+
            if (android.namespace == null) {
                val group = project.group.toString()
                val name = project.name
                android.namespace = if (group.isNotEmpty()) "$group.$name" else "com.sarri.$name"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
