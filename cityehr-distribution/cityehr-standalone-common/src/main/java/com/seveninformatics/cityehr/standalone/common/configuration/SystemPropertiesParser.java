package com.seveninformatics.cityehr.standalone.common.configuration;


import javax.annotation.Nullable;
import java.nio.file.InvalidPathException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Properties;

/**
 * Parse arguments from System Properties.
 */
public class SystemPropertiesParser extends AbstractConfigurationParser<Properties> {

  public static final String SYSTEM_PROPERTY_NAME_SERVER_HTTP_PORT = "cityehr.server.http.port";
  public static final String SYSTEM_PROPERTY_NAME_SERVER_WORKING_DIRECTORY = "cityehr.server.working-directory";
  public static final String SYSTEM_PROPERTY_NAME_SERVER_LOG_DIRECTORY = "cityehr.server.log-directory";

  /**
   * Constructor.
   */
  public SystemPropertiesParser() {
    super(System.getProperties());
  }

  @Override
  public Configuration parse() {
    final Configuration configuration = new Configuration();

    @Nullable Integer serverHttpPort = parseInt(SYSTEM_PROPERTY_NAME_SERVER_HTTP_PORT);
    if (serverHttpPort != null) {
      configuration.setServerHttpPort(serverHttpPort);
    }

    @Nullable Path serverWorkingDirectory = parsePath(SYSTEM_PROPERTY_NAME_SERVER_WORKING_DIRECTORY);
    if (serverWorkingDirectory != null) {
      configuration.setServerWorkingDirectory(serverWorkingDirectory);
    }

    @Nullable Path serverLogDirectory = parsePath(SYSTEM_PROPERTY_NAME_SERVER_LOG_DIRECTORY);
    if (serverLogDirectory != null) {
      configuration.setServerLogDirectory(serverLogDirectory);
    }

    return configuration;
  }

  private @Nullable Integer parseInt(final String systemPropertyName) {
    final @Nullable String value = input.getProperty(systemPropertyName);
    if (value != null) {
      try {
        return Integer.parseInt(value);
      } catch (final NumberFormatException e) {
        // no-op
      }
    }
    return null;
  }

  private @Nullable String parseString(final String systemPropertyName) {
    return input.getProperty(systemPropertyName);
  }

  private @Nullable Path parsePath(final String systemPropertyName) {
    final @Nullable String value = parseString(systemPropertyName);
    if (value != null) {
      try {
        return Paths.get(value);
      } catch (final InvalidPathException e) {
        // no-op
      }
    }
    return null;
  }
}
