FROM gcr.io/distroless/java:11

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
        "-Dfile.encoding=UTF8", \
        "-Djava.awt.headless=true", \
        "-XX:+UseNUMA", \
        "-XX:+UseG1GC", \
        "-XX:+UseStringDeduplication", \
        "-XX:+UseContainerSupport", \
        "-XX:MaxRAMPercentage=75.0", \
        "-XX:+ExitOnOutOfMemoryError", \
        "-jar", "/cityehr/lib/cityehr-standalone-jetty-${project.version}.jar", "--server-working-directory", "/cityehr"]
