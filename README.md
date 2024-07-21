# cityEHR

[![Java 8](https://img.shields.io/badge/java-8-blue.svg)](https://adoptopenjdk.net/)
[![License](https://img.shields.io/badge/license-LGPL%202.1-blue.svg)](https://www.gnu.org/licenses/lgpl-2.1.html)

## Building cityEHR from Source Code
Requires:
* [Java](https://bell-sw.com/pages/downloads/#jdk-8-lts) 8+
* [Apache Maven](https://maven.apache.org/download.cgi) 3.9.6+

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

## Running cityEHR

The following configuration options are available when starting cityEHR and may be specified as either Environment Variables, Java System Properties, or Command Line Arguments:

| Description                                                                           | Environment Variable | Java System Property | Command Line Argument |
|---------------------------------------------------------------------------------------|-|-|-|
| Set the TCP port number that cityEHR will listen on for HTTP requests (default: 8080) | CITYEHR_SERVER_HTTP_PORT | cityehr.server.http.port | --server-http-port |
| Set the working directory for holding the server code and data                        | CITYEHR_SERVER_WORKING_DIRECTORY | cityehr.server.working-directory | --server-working-directory |

There are three options at present:

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
