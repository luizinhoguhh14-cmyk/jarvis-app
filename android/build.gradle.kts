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
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                // Forca o SDK 36 no AGP 8+
                val method = androidExt.javaClass.getMethod("setCompileSdk", java.lang.Integer::class.java)
                method.invoke(androidExt, 36)
            } catch (e: Exception) {
                try {
                    // Forca o SDK 36 em versoes anteriores
                    val method2 = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    method2.invoke(androidExt, 36)
                } catch (e2: Exception) {}
            }
        }
    }
}
