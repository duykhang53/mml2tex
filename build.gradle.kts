plugins {
    // Apply the java-library plugin for API and implementation separation.
    `java-library`
    `maven-publish`
}

version = "1.1.0"
group = "com.github.transpect"
// artifactId("mml2tex")

repositories {
    mavenCentral()
}

dependencies {
    api("commons-io:commons-io:2.0")
    api("org.apache.commons:commons-lang3:3.10")
    api("org.apache.httpcomponents:httpcore:4.3")
    api("org.apache.httpcomponents:httpclient:4.5.8")
    implementation("net.sf.saxon:Saxon-HE:9.4")
}


java {
    sourceSets {
        main {
            java.srcDir("src")
            resources.srcDir(layout.buildDirectory.dir("res"))
        }
    }
}

tasks.register<Copy>("copyResources") {
    from(".") {
        include("xpl/**", "xsl/**", "texmap/**", "xmlcatalog/**")
    }
    into(layout.buildDirectory.dir("res")) 
}

tasks.named("processResources") {
    dependsOn("copyResources")
}

publishing {
    publications {
        create<MavenPublication>("mavenJava") {
            from(components["java"])
            

            versionMapping {
                allVariants {
                    fromResolutionResult()
                }
            }
        }
    }
}