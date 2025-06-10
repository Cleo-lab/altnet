plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Оптимизация сборки
gradle.projectsLoaded {
    gradle.rootProject {
        allprojects {
            extra.apply {
                set("kotlinVersion", "1.9.22")
            }
        }
    }
}

gradle.projectsEvaluated {
    gradle.rootProject {
        allprojects {
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "1.8"
                }
            }
        }
    }
}

gradle.startParameter.apply {
    isParallelProjectExecutionEnabled = true
    isBuildCacheEnabled = true
    isConfigureOnDemand = true
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
