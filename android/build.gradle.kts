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

// cronet_http 默认走 Google Play Services 版 Cronet（国内 ROM 常缺 Play Services）。
// 通过依赖替换永久钉死为 embedded 版：`org.chromium.net:cronet-embedded`,
// 无需每次构建都传 `--dart-define=cronetHttpNoPlay=true`。
// 版本号对齐 cronet_http 1.6.0 的默认 embedded 依赖，未来升级 cronet_http 时同步 bump。
subprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.google.android.gms" &&
                requested.name == "play-services-cronet"
            ) {
                useTarget("org.chromium.net:cronet-embedded:141.7340.3")
                because("force embedded Cronet: no Play Services dependency")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
