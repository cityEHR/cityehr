package com.seveninformatics.cityehr.standalone;

import com.seveninformatics.cityehr.standalone.common.CityEhrAsciiLogo;
import com.seveninformatics.cityehr.standalone.common.configuration.Configuration;
import com.seveninformatics.cityehr.standalone.common.configuration.ConfigurationBuilder;
import com.seveninformatics.cityehr.standalone.common.configuration.CliArgumentsParser;
import com.seveninformatics.cityehr.standalone.common.configuration.EnvironmentVariablesParser;
import com.seveninformatics.cityehr.standalone.common.configuration.SystemPropertiesParser;
import org.apache.catalina.Context;
import org.apache.catalina.LifecycleException;
import org.apache.catalina.Server;
import org.apache.catalina.connector.Connector;
import org.apache.catalina.startup.Tomcat;
import org.apache.tomcat.JarScanFilter;
import org.apache.tomcat.JarScanType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.bridge.SLF4JBridgeHandler;

import org.jspecify.annotations.Nullable;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

/**
 * Embedded Tomcat Server for running cityEHR.
 *
 * @author <a href="mailto:adam@evolvedbinary.com">Adam Retter</a>
 */
public class CityEhrTomcatServer {

  public static void main(final String[] args) throws IOException, URISyntaxException, LifecycleException {
    // Parse the Configuration
    final Configuration configuration = parseArguments(args);

    // Setup logging
    final Logger logger = createLogger(configuration);
    logger.info("Starting cityEHR...");

    // Create the Tomcat server for cityEHR
    final Server server = newServer(configuration, logger);
    server.start();

    // Let the user know that cityEHR is now running
    printReadyBanner(configuration, logger);

    // Wait until the server is shutdown
    server.await();
  }

  private static Configuration parseArguments(final String[] args) {
    final Configuration configuration = new ConfigurationBuilder()
        .add(new EnvironmentVariablesParser())
        .add(new SystemPropertiesParser())
        .add(new CliArgumentsParser(args))
        .build();

    // Set the working directory if it has not yet been set
    if (configuration.getServerWorkingDirectory() == null) {
      final Path defaultServerWorkingDirectory = Paths.get("tomcat." + configuration.getServerHttpPort());
      configuration.setServerWorkingDirectory(defaultServerWorkingDirectory);
    }

    return configuration;
  }

  private static Logger createLogger(final Configuration configuration) throws IOException {
    // Redirect JULI to slf4j
    SLF4JBridgeHandler.removeHandlersForRootLogger();
    SLF4JBridgeHandler.install();

    // Set any variables that we refer to from our `logback.xml` config file
    final Path serverLogDirectory = configuration.getServerLogDirectory().normalize().toAbsolutePath();
    if (!Files.exists(serverLogDirectory)) {
      Files.createDirectories(serverLogDirectory);
    }
    System.setProperty("cityehr.slf4j.log-directory", serverLogDirectory.toString());

    // Create the logger
    final Logger logger = LoggerFactory.getLogger(CityEhrTomcatServer.class);
    logger.info("Log directory: {}", serverLogDirectory);

    return logger;
  }

  private static Server newServer(final Configuration configuration, final Logger logger) throws IOException, URISyntaxException {
    final int port = configuration.getServerHttpPort();
    logger.info("Using Server HTTP Port: {}", port);

    final Tomcat tomcat = new Tomcat();
    // NOTE(AR) to set the port correctly, or to add HTTPS, we also need to modify WEB-INF/resources/config/properties-local.xml in the resultant extracted WAR file
    tomcat.setPort(port);

    // Set the directory the war will extract to
    @Nullable final Path workingDirectory = configuration.getServerWorkingDirectory();
    if (workingDirectory != null) {
      if (!Files.exists(workingDirectory)) {
        Files.createDirectories(workingDirectory);
      }
      logger.info("Using Server Working Directory: {}", workingDirectory.normalize().toAbsolutePath());

      tomcat.setBaseDir(workingDirectory.toAbsolutePath().toString());

      // NOTE(AR) create the basedir/webapps otherwise the call to tomcat.addWebapp below will fail
      final Path webappsDirs = workingDirectory.resolve("webapps");
      if (!Files.exists(webappsDirs)) {
        Files.createDirectories(webappsDirs);
      }
      logger.info("Using Web Apps Directory: {}", webappsDirs.normalize().toAbsolutePath());

      final URL warSourceLocation = CityEhrTomcatServer.class.getProtectionDomain().getCodeSource().getLocation();
      final Path warFileName = Paths.get(Paths.get(warSourceLocation.toURI()).getFileName().toString().replace("jar", "war"));
      final Path warTargetPath = webappsDirs.resolve(warFileName);
      final Path expandedWarPath = webappsDirs.resolve("ROOT");

      // if the expanded war path already exists don't copy the war file again
      if (!Files.exists(expandedWarPath)) {
        try (final InputStream is = warSourceLocation.openStream()) {
          Files.copy(is, warTargetPath, StandardCopyOption.REPLACE_EXISTING);
        }
      }

      logger.info("Using WAR source file: {}", warSourceLocation);
      logger.info("Using WAR target file: {}", warTargetPath.normalize().toAbsolutePath());

      final Context context = tomcat.addWebapp(tomcat.getHost(), "", warTargetPath.toAbsolutePath().toString());

      // disable scanning for TLD in Jar files
      context.getJarScanner().setJarScanFilter(new SkipAllJarScanner());
    }

    final Connector connector = tomcat.getConnector();

    final Server server = tomcat.getServer();
    return server;
  }

  private static void printReadyBanner(final Configuration configuration, final Logger logger) {
    logger.info(CityEhrAsciiLogo.logoAndFooter("cityEHR is running!", "Visit: http://localhost:" + configuration.getServerHttpPort()));
  }

  private static class SkipAllJarScanner implements JarScanFilter {
    @Override
    public boolean check(final JarScanType jarScanType, final String jarName) {
      return false;
    }

    @Override
    public boolean isSkipAll() {
      return true;
    }
  }

}
