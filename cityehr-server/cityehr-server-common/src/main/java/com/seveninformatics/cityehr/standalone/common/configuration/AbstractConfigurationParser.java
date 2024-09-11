package com.seveninformatics.cityehr.standalone.common.configuration;

/**
 * Base class of a Configuration Parser that operates on some input.
 *
 * @param <T> the type of the input to parse.
 */
public abstract class AbstractConfigurationParser<T> implements ConfigurationParser<T> {
  protected final T input;

  public AbstractConfigurationParser(final T input) {
    this.input = input;
  }
}
