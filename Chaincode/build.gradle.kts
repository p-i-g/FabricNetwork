plugins {
    java
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
    implementation("org.hyperledger.fabric-chaincode-java:fabric-chaincode-shim:2.5.+")
    implementation("org.json:json:+")
    implementation("com.owlike:genson:1.5")
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.2")
    testImplementation("org.assertj:assertj-core:3.25.3")
    testImplementation("org.mockito:mockito-core:5.12.0")
}

tasks {
    jar {
        manifest {
            attributes(
                "Main-Class" to "org.example.MainClass" // Set your main class here
            )
        }
    }
}