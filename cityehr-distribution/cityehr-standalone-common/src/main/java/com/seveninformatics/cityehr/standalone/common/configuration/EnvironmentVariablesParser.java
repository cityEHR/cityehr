package com.seveninformatics.cityehr.standalone.common.configuration;

import javax.annotation.Nullable;
import java.nio.file.InvalidPathException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;

/**
 * Parse arguments from Environment Variables.
 */
public class EnvironmentVariablesParser extends AbstractConfigurationParser<Map<String, String>> {

  public static final String ENVIRONMENT_VARIABLE_NAME_SERVER_HTTP_PORT = "CITYEHR_SERVER_HTTP_PORT";
  public static final String ENVIRONMENT_VARIABLE_NAME_SERVER_WORKING_DIRECTORY = "CITYEHR_SERVER_WORKING_DIRECTORY";
  public static final String ENVIRONMENT_VARIABLE_NAME_SERVER_LOG_DIRECTORY = "CITYEHR_SERVER_LOG_DIRECTORY";

  /**
   * Constructor.
   */
  public EnvironmentVariablesParser() {
    super(System.getenv());
  }

  @Override
  public Configuration parse() {
    final Configuration configuration = new Configuration();

    @Nullable Integer serverHttpPort = parseInt(ENVIRONMENT_VARIABLE_NAME_SERVER_HTTP_PORT);
    if (serverHttpPort != null) {
      configuration.setServerHttpPort(serverHttpPort);
    }

    @Nullable Path serverWorkingDirectory = parsePath(ENVIRONMENT_VARIABLE_NAME_SERVER_WORKING_DIRECTORY);
    if (serverWorkingDirectory != null) {
      configuration.setServerWorkingDirectory(serverWorkingDirectory);
    }

    @Nullable Path serverLogDirectory = parsePath(ENVIRONMENT_VARIABLE_NAME_SERVER_LOG_DIRECTORY);
    if (serverLogDirectory != null) {
      configuration.setServerLogDirectory(serverLogDirectory);
    }

    return configuration;
  }

  private @Nullable Integer parseInt(final String environmentVariableName) {
    final @Nullable String value = input.get(environmentVariableName);
    if (value != null) {
      try {
        return Integer.parseInt(value);
      } catch (final NumberFormatException e) {
        // no-op
      }
    }
    return null;
  }

  private @Nullable String parseString(final String environmentVariableName) {
    return input.get(environmentVariableName);
  }

  private @Nullable Path parsePath(final String environmentVariableName) {
    final @Nullable String value = parseString(environmentVariableName);
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
