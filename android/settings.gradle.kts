// Temporary wrapper to satisfy tools expecting a Kotlin DSL settings file.
// Delegates to the existing Groovy settings.gradle in this directory.
apply(from = "settings.gradle")
