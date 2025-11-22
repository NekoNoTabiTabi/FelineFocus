buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Suppress Java compilation warnings
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf(
            "-Xlint:-unchecked",
            "-Xlint:-deprecation",
            "-Xlint:-options"
        ))
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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Project-level plugins are configured in module build files. Keep only the
// Google services classpath above and add Firebase dependencies in the
// `android/app/build.gradle` `dependencies` block, for example:
//
// dependencies {
//   implementation platform('com.google.firebase:firebase-bom:34.6.0')
//   implementation 'com.google.firebase:firebase-analytics'
// }