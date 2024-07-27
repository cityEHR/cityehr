# Install latest JRE 8 in Debian Stretch (which is the base of gcr.io/distroless/java:8)
FROM debian:stretch-slim as updated-jre
RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list
RUN echo "deb http://archive.debian.org/debian stretch-backports main" >> /etc/apt/sources.list
RUN apt-get update && apt-get -y dist-upgrade
RUN apt-get install -y openjdk-8-jre-headless

FROM gcr.io/distroless/java:8

# Copy over updated JRE from Debian Stretch
COPY --from=updated-jre /etc/java-8-openjdk /etc/java-8-openjdk
COPY --from=updated-jre /usr/lib/jvm/java-8-openjdk-amd64 /usr/lib/jvm/java-8-openjdk-amd64
COPY --from=updated-jre /usr/share/gdb/auto-load/usr/lib/jvm/java-8-openjdk-amd64 /usr/share/gdb/auto-load/usr/lib/jvm/java-8-openjdk-amd6

# Copy cityEHR into the image
COPY LICENSE /cityehr/
COPY cityehr-standalone-jetty-${project.version}.jar /cityehr/lib/

MAINTAINER Evolved Binary Ltd <tech@evolvedbinary.com>

# Build-time metadata as defined at http://label-schema.org
# and used by autobuilder @hooks/build
LABEL org.label-schema.build-date=${maven.build.timestamp} \
      org.label-schema.description="${project.description}" \
      org.label-schema.name="cityEHR" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.url="${project.url}" \
      org.label-schema.vcs-ref=${build-commit-abbrev} \
      org.label-schema.vcs-url="${project.scm.url}" \
      org.label-schema.vendor="cityEHR" \
      name="cityEHR ${project.version}" \
      vendor="Seven Informatics Ltd"

EXPOSE 8080

ENTRYPOINT [ "java", \
        "-XX:+UseG1GC", \
        "-XX:+UseStringDeduplication", \
        "-XX:+UseContainerSupport", \
        "-XX:MaxRAMPercentage=75.0", \
        "-XX:+ExitOnOutOfMemoryError", \
        "-Djava.awt.headless=true", \
        "-jar", "/cityehr/lib/cityehr-standalone-jetty-${project.version}.jar", "--server-working-directory", "/cityehr"]
