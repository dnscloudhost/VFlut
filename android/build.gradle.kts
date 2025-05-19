import com.android.build.gradle.BaseExtension
import org.gradle.kotlin.dsl.configure

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // تغییر مسیر build
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // اطمینان از ارزیابی ماژول app
    project.evaluationDependsOn(":app")

    // ----- این بلوک را اضافه کنید -----
    // اگر کتابخانه اندرویدی است، namespace را ست کن
    plugins.withId("com.android.library") {
        extensions.configure<BaseExtension> {
            if (namespace.isNullOrBlank()) {
                namespace = project.group.toString()
            }
        }
    }
    // اگر اپلیکیشن اندرویدی است، namespace را ست کن
    plugins.withId("com.android.application") {
        extensions.configure<BaseExtension> {
            if (namespace.isNullOrBlank()) {
                namespace = project.group.toString()
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
