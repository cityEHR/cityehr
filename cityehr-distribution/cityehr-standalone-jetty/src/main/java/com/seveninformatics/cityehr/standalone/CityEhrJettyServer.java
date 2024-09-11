package com.seveninformatics.cityehr.standalone;

import com.seveninformatics.cityehr.standalone.common.CityEhrAsciiLogo;
import com.seveninformatics.cityehr.standalone.common.configuration.Configuration;
import com.seveninformatics.cityehr.standalone.common.configuration.ConfigurationBuilder;
import com.seveninformatics.cityehr.standalone.common.configuration.CliArgumentsParser;
import com.seveninformatics.cityehr.standalone.common.configuration.EnvironmentVariablesParser;
import com.seveninformatics.cityehr.standalone.common.configuration.SystemPropertiesParser;
import org.eclipse.jetty.server.Connector;
import org.eclipse.jetty.server.HttpConfiguration;
import org.eclipse.jetty.server.HttpConnectionFactory;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.util.resource.Resource;
import org.eclipse.jetty.webapp.WebAppContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.jspecify.annotations.Nullable;
import java.io.IOException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Embedded Jetty Server for running cityEHR.
 *
 * @author <a href="mailto:adam@evolvedbinary.com">Adam Retter</a>
 */
public class CityEhrJettyServer {

  public static void main(final String[] args) throws Exception {
    // Parse the Configuration
    final Configuration configuration = parseArguments(args);

    // Setup logging
    final Logger logger = createLogger(configuration);
    logger.info("Starting cityEHR...");

    // Create the Jetty server for cityEHR
    final Server server = newServer(configuration, logger);
    workaroundLargeRequestHeaders(server);
    server.start();

    // Let the user know that cityEHR is now running
    printReadyBanner(configuration, logger);

    // Wait until the server is shutdown
    server.join();
  }

  private static Configuration parseArguments(final String[] args) {
    final Configuration configuration = new ConfigurationBuilder()
        .add(new EnvironmentVariablesParser())
        .add(new SystemPropertiesParser())
        .add(new CliArgumentsParser(args))
        .build();

    // Set the working directory if it has not yet been set
    if (configuration.getServerWorkingDirectory() == null) {
      final Path defaultServerWorkingDirectory = Paths.get("jetty." + configuration.getServerHttpPort());
      configuration.setServerWorkingDirectory(defaultServerWorkingDirectory);
    }

    return configuration;
  }

  private static Logger createLogger(final Configuration configuration) throws IOException {
    // Set any variables that we refer to from our `logback.xml` config file
    final Path serverLogDirectory = configuration.getServerLogDirectory().normalize().toAbsolutePath();
    if (!Files.exists(serverLogDirectory)) {
      Files.createDirectories(serverLogDirectory);
    }
    System.setProperty("cityehr.slf4j.log-directory", serverLogDirectory.toString());

    // Create the logger
    final Logger logger = LoggerFactory.getLogger(CityEhrJettyServer.class);
    logger.info("Log directory: {}", serverLogDirectory);

    return logger;
  }

  private static Server newServer(final Configuration configuration, final Logger logger) throws IOException {
    final int port = configuration.getServerHttpPort();
    logger.info("Using Server HTTP Port: {}", port);

    final URL warLocation = CityEhrJettyServer.class.getProtectionDomain().getCodeSource().getLocation();
    final Resource warResource = Resource.newResource(warLocation);

    // NOTE(AR) to set the port correctly, or to add HTTPS, we also need to modify WEB-INF/resources/config/properties-local.xml in the resultant extracted WAR file
    final Server server = new Server(port);
    final WebAppContext context = new WebAppContext("ROOT", "/");
    // NOTE(AR) has to be set - see: https://www.eclipse.org/lists/jetty-users/msg10722.html
    context.setExtractWAR(true);

    // Set the directory the war will extract to
    @Nullable final Path workingDirectory = configuration.getServerWorkingDirectory();
    if (workingDirectory != null) {
      if (!Files.exists(workingDirectory)) {
        Files.createDirectories(workingDirectory);
      }
      logger.info("Using Server Working Directory: {}", workingDirectory.normalize().toAbsolutePath());

      final Path webappsDirs = workingDirectory.resolve("webapps");
      if (!Files.exists(webappsDirs)) {
        Files.createDirectories(webappsDirs);
      }
      context.setTempDirectory(webappsDirs.toFile());
      logger.info("Using Web Apps Directory: {}", webappsDirs.normalize().toAbsolutePath());
    }

    context.setWarResource(warResource);
    logger.info("Using WAR file: {}", warResource);

    context.setParentLoaderPriority(true);
    server.setHandler(context);

    return server;
  }

  /**
   * cityEHR/Orbeon seem to need to use large request headers,
   * without this we see warnings in the `jetty.log` file like:
   * <pre>WARN [qtp1632492873-35] org.eclipse.jetty.http.HttpParser [HttpParser.java:1139] -- Header is too large 8193>8192</pre>.
   *
   * This is not without potential consequences:
   * See: https://stackoverflow.com/questions/59670602/sparkjava-error-org-eclipse-jetty-http-httpparser-header-is-too-large-8192
   *
   * @deprecated This should be considered a temporary workaround until we can upgrade Orbeon to a newer version that hopefully addresses this.
   *
   * @param server the server to configure.
   */
  @Deprecated
  private static void workaroundLargeRequestHeaders(final Server server) {
    for (final Connector connector : server.getConnectors()) {
      if (connector instanceof HttpConnectionFactory) {
        final HttpConfiguration httpConfiguration = ((HttpConnectionFactory) connector).getHttpConfiguration();
        httpConfiguration.setRequestHeaderSize(16 * 1024); // 16 KB
      }
    }
  }

  private static void printReadyBanner(final Configuration configuration, final Logger logger) {
    logger.info(CityEhrAsciiLogo.logoAndFooter("cityEHR is running!", "Visit: http://localhost:" + configuration.getServerHttpPort()));
  }
}
