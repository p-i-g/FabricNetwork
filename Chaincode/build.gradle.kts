plugins {
    id("java")
}

group = "com.blockport"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
    mavenLocal()
    maven {
        url = uri("https://jitpack.io")
    }
}

dependencies {
    testImplementation(platform("org.junit:junit-bom:5.10.0"))
    testImplementation("org.junit.jupiter:junit-jupiter")

    // Hyperledger Fabric Java SDK (Fabric Chaincode Shim)
    implementation("org.hyperledger.fabric-chaincode-java:fabric-chaincode-shim:2.5+")

    // Optional: Logging dependencies
    implementation("org.slf4j:slf4j-api:1.7.30")
    implementation("org.slf4j:slf4j-simple:1.7.30")
}

tasks.test {
    useJUnitPlatform()
}