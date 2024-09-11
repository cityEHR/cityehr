package com.seveninformatics.cityehr.standalone.common.configuration;

import java.util.ArrayList;
import java.util.List;

/**
 * Standalone Configuration Builder for cityEHR.
 */
public class ConfigurationBuilder {
  private final List<ConfigurationParser<?>> configurationParsers = new ArrayList<>();

  /**
   * Add a Configuration Parser.
   *
   * @param configurationParser the configuration parser to add.
   *
   * @return this.
   */
  public ConfigurationBuilder add(final ConfigurationParser<?> configurationParser) {
    configurationParsers.add(configurationParser);
    return this;
  }

  /**
   * Invokes all the configuration parsers and returns the built configuration.
   *
   * @return the built configuration.
   */
  public Configuration build() {
    Configuration configuration = new Configuration();
    for (ConfigurationParser<?> configurationParser : configurationParsers) {
      configuration = configuration.overlay(configurationParser.parse());
    }
    return configuration;
  }
}
