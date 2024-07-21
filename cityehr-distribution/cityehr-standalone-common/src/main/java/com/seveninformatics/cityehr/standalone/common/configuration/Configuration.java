package com.seveninformatics.cityehr.standalone.common.configuration;

import javax.annotation.Nullable;
import java.nio.file.Path;

/**
 * Standalone Configuration for cityEHR.
 */
public class Configuration {
  public final static int DEFAULT_SERVER_HTTP_PORT = 8080;

  // null indicates the value has not been configured
  private @Nullable Integer serverHttpPort = null;
  private @Nullable Path serverWorkingDirectory = null;

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
