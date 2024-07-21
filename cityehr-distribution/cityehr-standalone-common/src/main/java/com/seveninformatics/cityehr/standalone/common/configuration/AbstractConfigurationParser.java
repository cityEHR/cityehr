package com.seveninformatics.cityehr.standalone.common.configuration;

public abstract class AbstractConfigurationParser<T> implements ConfigurationParser<T> {
  protected final T input;

  public AbstractConfigurationParser(final T input) {
    this.input = input;
  }
}
