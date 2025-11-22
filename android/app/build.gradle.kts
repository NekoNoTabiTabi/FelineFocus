// Temporary wrapper so tools expecting a Kotlin DSL file can proceed.
// This delegates to the existing Groovy build.gradle in the same directory.
apply(from = "build.gradle")
