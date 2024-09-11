package com.seveninformatics.cityehr.standalone.common.configuration;

import org.jspecify.annotations.Nullable;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Standalone Configuration for cityEHR.
 */
public class Configuration {
  public static final int DEFAULT_SERVER_HTTP_PORT = 8080;
  public static final String DEFAULT_SERVER_LOG_DIRECTORY_NAME = "log";

  // null indicates the value has not been configured
  private @Nullable Integer serverHttpPort = null;
  private @Nullable Path serverWorkingDirectory = null;
  private @Nullable Path serverLogDirectory = null;

  /**
   * Default constructor.
   */
  public Configuration() {
  }

  /**
   * Copy constructor.
   *
   * @param configuration the configuration to copy.
   */
  private Configuration(final Configuration configuration) {
    this.serverHttpPort = configuration.serverHttpPort;
    this.serverWorkingDirectory = configuration.serverWorkingDirectory;
    this.serverLogDirectory = configuration.serverLogDirectory;
  }

  /**
   * Get the TCP port number that cityEHR will listen on for HTTP requests.
   *
   * @return the TCP port number that cityEHR will listen on for HTTP requests.
   */
  public int getServerHttpPort() {
    if (serverHttpPort != null) {
      return serverHttpPort;
    }
    return DEFAULT_SERVER_HTTP_PORT;
  }

  /**
   * Set the TCP port number that cityEHR will listen on for HTTP requests.
   *
   * @param serverHttpPort the TCP port number that cityEHR will listen on for HTTP requests.
   */
  public void setServerHttpPort(final int serverHttpPort) {
    this.serverHttpPort = serverHttpPort;
  }

  /**
   * Get the working directory for holding the server code and data.
   *
   * @return the working directory for holding the server code and data.
   */
  public @Nullable Path getServerWorkingDirectory() {
    return serverWorkingDirectory;
  }

  /**
   * Set the working directory for holding the server code and data.
   *
   * @param serverWorkingDirectory the working directory for holding the server code and data.
   */
  public void setServerWorkingDirectory(final Path serverWorkingDirectory) {
    this.serverWorkingDirectory = serverWorkingDirectory;
  }

  /**
   * Get the log directory for holding the server log files.
   *
   * @return the log directory for holding the server log files.
   */
  public Path getServerLogDirectory() {
    if (serverLogDirectory != null) {
      return serverLogDirectory;
    }

    if (serverWorkingDirectory != null) {
      return serverWorkingDirectory.resolve(DEFAULT_SERVER_LOG_DIRECTORY_NAME);
    }

    return Paths.get(DEFAULT_SERVER_LOG_DIRECTORY_NAME);
  }

  /**
   * Set the log directory for holding the server log files.
   *
   * @param serverLogDirectory the log directory for holding the server log files.
   */
  public void setServerLogDirectory(final Path serverLogDirectory) {
    this.serverLogDirectory = serverLogDirectory;
  }

  /**
   * Overlay any configuration options on these configuration options
   * in a new configuration options that is returned.
   *
   * @param overlayConfiguration the configuration to overlay.
   *
   * @return the new configuration combining this and the overlay configuration.
   */
  public Configuration overlay(final Configuration overlayConfiguration) {
    final Configuration newConfiguration = new Configuration(this);

    if (overlayConfiguration.serverHttpPort != null) {
      newConfiguration.serverHttpPort = overlayConfiguration.serverHttpPort;
    }

    if (overlayConfiguration.serverWorkingDirectory != null) {
      newConfiguration.serverWorkingDirectory = overlayConfiguration.serverWorkingDirectory;
    }

    return newConfiguration;
  }
}
