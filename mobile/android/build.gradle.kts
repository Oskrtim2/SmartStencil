allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    if (rootProject.projectDir.absolutePath.any { it.code > 127 }) {
        val userHome = System.getProperty("user.home").replace('\\', '/')
        objects.directoryProperty().fileValue(file("$userHome/build_cache/mobile")).get()
    } else {
        rootProject.layout.buildDirectory.dir("../../build").get()
    }
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


