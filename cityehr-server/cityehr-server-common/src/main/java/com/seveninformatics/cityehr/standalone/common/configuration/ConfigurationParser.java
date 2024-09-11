package com.seveninformatics.cityehr.standalone.common.configuration;

/**
 * Interface for a class that can parse some
 * input to extract configuration options.
 *
 * @param <T> the type of the input to parse.
 */
public interface ConfigurationParser<T> {

  /**
   * Parse the input to extract the configuration.
   *
   * @return the Configuration.
   */
  Configuration parse();
}
