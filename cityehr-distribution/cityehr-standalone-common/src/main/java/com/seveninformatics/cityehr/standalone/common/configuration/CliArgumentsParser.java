package com.seveninformatics.cityehr.standalone.common.configuration;

import javax.annotation.Nullable;
import java.nio.file.InvalidPathException;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Parse arguments from a Command Line Interface style args array.
 */
public class CliArgumentsParser extends AbstractConfigurationParser<String[]> {

  /**
   * Constructor.
   *
   * @param args the Command Line Interface style args array.
   */
  public CliArgumentsParser(final String[] args) {
    super(args);
  }

  @Override
  public Configuration parse() {

    final Configuration configuration = new Configuration();

    for (int i = 0; i < input.length; i++) {
      final String arg = input[i];
      switch (arg) {

        case "--server-http-port":
          @Nullable Integer serverHttpPort = parseInt(i + 1);
          if (serverHttpPort != null) {
            configuration.setServerHttpPort(serverHttpPort);
          }
          break;

        case "--server-working-directory":
          @Nullable Path serverWorkingDirectory = parsePath(i + 1);
          if (serverWorkingDirectory != null) {
            configuration.setServerWorkingDirectory(serverWorkingDirectory);
          }
          break;

        case "--server-log-directory":
          @Nullable Path serverLogDirectory = parsePath(i + 1);
          if (serverLogDirectory != null) {
            configuration.setServerLogDirectory(serverLogDirectory);
          }
          break;
      }
    }

    return configuration;
  }

  private @Nullable Integer parseInt(final int index) {
    if (index < input.length) {
      final String value = input[index];
      if (!value.startsWith("--")) {
        try {
          return Integer.parseInt(value);
        } catch (final NumberFormatException e) {
          // no-op
        }
      }
    }
    return null;
  }

  private @Nullable String parseString(final int index) {
    if (index < input.length) {
      final String value = input[index];
      if (!value.startsWith("--")) {
        return value;
      }
    }
    return null;
  }

  private @Nullable Path parsePath(final int index) {
    final @Nullable String value = parseString(index);
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
