# cityEHR

[![Java 8](https://img.shields.io/badge/java-8-blue.svg)](https://adoptopenjdk.net/)
[![License](https://img.shields.io/badge/license-LGPL%202.1-blue.svg)](https://www.gnu.org/licenses/lgpl-2.1.html)

## Building cityEHR from Source Code
Requires:
    * Java 8+
    * Apache Maven 3.9.6+

Then run:
```shell
$ mvn clean package
```

## Running cityEHR
There are two options at present:

1. (Preferred) Run the stand-alone cityEHR Jar file that embeds Jetty Server.
    ```shell
    $ java -jar cityehr-distribution/cityehr-standalone-jetty/target/cityehr-standalone-jetty-1.8.0-SNAPSHOT.jar
    ```
    Note: As the Jar file is stand-alone you can copy it to any location you prefer before running it. 

2. Copy and deploy the WAR file from the `cityehr-distribution/cityehr-webapp/target` folder to your favourite Java EE server.

## Running cityEHR for Development Purposes
There are two options at present:

1. Run with Jetty via Codehaus Cargo through Maven:
    ```shell
    $ mvn clean verify -pl cityehr-distribution/cityehr-webapp org.codehaus.cargo:cargo-maven3-plugin:run
    ```

2. Run with Tomcat via Codehaus Cargo through Maven:
    ```shell
    $ mvn clean verify -pl cityehr-distribution/cityehr-webapp org.codehaus.cargo:cargo-maven3-plugin:run -Dcargo.maven.containerId=tomcat9x
    ```