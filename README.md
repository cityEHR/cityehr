# cityEHR

[![Java 8](https://img.shields.io/badge/java-8-blue.svg)](https://adoptopenjdk.net/)
[![License](https://img.shields.io/badge/license-LGPL%202.1-blue.svg)](https://www.gnu.org/licenses/lgpl-2.1.html)

## Project Structure
The project is split into a number of separate modules. Thought has been given to separation of concerns so as to try and
achieve a clean modular system whereby each module does only one thing. Composition is used so that some modules are
built by combining the output of one or more other modules.

### Project Modules

| Name                                           | Description                                                                                                         |
|------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| cityehr-parent                                 | Contains common build configuration that is inherited by all modules                                                |
| cityehr-orbeon-minimal                         | Converts and configures an Orbeon Forms WAR into a minimal WAR as needed for running `cityehr-application`          |
| cityehr-application                            | Contains the Application Code for cityEHR (XML, XPL, XQuery, XSLT, etc.)                                            |
| cityehr-distribution/cityehr-war               | Builds a WAR file of cityEHR by combining `cityehr-orbeon-minimal` and `cityehr-application`                        |
| cityehr-distribution/cityehr-standalone-common | Common Java Code needed for `cityehr-standalone-jetty` and `cityehr-standalone-tomcat`                              |
| cityehr-distribution/cityehr-standalone-jetty  | Builds a single standalone JAR file application from `cityehr-war` by embedding Eclipse Jetty Server to run cityEHR |
| cityehr-distribution/cityehr-standalone-tomcat | Builds a single standalone JAR file application from `cityehr-war` by embedding Apache Tomcat Server to run cityEHR |
| cityehr-distribution/cityehr-docker            | Builds a cityEHR Docker Image from `cityehr-standalone-jetty`                                                       |

<img width="60%" src="https://github.com/evolvedbinary/cityehr/blob/main/cityehr-build-graph.svg?raw=true" alt="cityEHR Graph of Modules that produce Artifacts" />

## Building cityEHR from Source Code
Requires:
* [Java](https://bell-sw.com/pages/downloads/#jdk-8-lts) 8+
* [Apache Maven](https://maven.apache.org/download.cgi) 3.9.6+
* (Optional) [Docker](https://docs.docker.com/engine/install/)

You first need to obtain a copy of the Source Code from GitHub if you have not already done so.
The process to do this is the same as you would do for any GitHub repository.
If you are not familiar with GitHub you can use one of the many available GUI tools
for working with it (such as [GitHub Desktop](https://github.com/apps/desktop), [SourceTree](https://www.sourcetreeapp.com/), or [GitKraken](https://www.gitkraken.com/)),
or if you prefer to use the Command Line / Terminal, and have already installed [git](https://git-scm.com/downloads), then you can just run:

```shell
$ git clone https://github.com/cityehr/cityehr.git
$ cd cityehr
```

Note: You only need to do the above once!

Then to build cityEHR, run:
```shell
$ mvn clean package
```

NOTE: If you wish to also build the Docker Image you need to add the `-Pdocker` argument to the above command, i.e. `mvn clean package -Pdocker`.

## Running cityEHR

The following configuration options are available when starting cityEHR and may be specified as either Environment Variables, Java System Properties, or Command Line Arguments:

| Description                                                                           | Environment Variable             | Java System Property             | Command Line Argument      |
|---------------------------------------------------------------------------------------|----------------------------------|----------------------------------|----------------------------|
| Set the TCP port number that cityEHR will listen on for HTTP requests (default: 8080) | CITYEHR_SERVER_HTTP_PORT         | cityehr.server.http.port         | --server-http-port         |
| Set the working directory for holding the server code and data                        | CITYEHR_SERVER_WORKING_DIRECTORY | cityehr.server.working-directory | --server-working-directory |
| Set the log directory for holding the server log files                                | CITYEHR_SERVER_LOG_DIRECTORY     | cityehr.server.log-directory     | --server-log-directory     |

There are four options at present:

1. (Preferred) Run the stand-alone cityEHR Jar file that embeds Jetty Server.
    ```shell
    $ java -jar cityehr-distribution/cityehr-standalone-jetty/target/cityehr-standalone-jetty-1.8.0-SNAPSHOT.jar
    ```
    Note: As the Jar file is stand-alone you can copy it to any location you prefer before running it.

2. Run the stand-alone cityEHR Jar file that embeds Tomcat Server.
    ```shell
    $ java -jar cityehr-distribution/cityehr-standalone-tomcat/target/cityehr-standalone-tomcat-1.8.0-SNAPSHOT.jar
    ```
   Note: As the Jar file is stand-alone you can copy it to any location you prefer before running it.

3. Copy and deploy the WAR file from the `cityehr-distribution/cityehr-webapp/target` folder to your favourite Java EE server.

4. If you built the Docker Image, you can start a Docker Container form that image by running: `docker run -it -p 8080:8080 cityehr/cityehr:1.8.0-SNAPSHOT`.

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
