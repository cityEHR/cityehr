package com.seveninformatics.cityehr.standalone.common;

public class CityEhrAsciiLogo {

  private static final String EOL = System.lineSeparator();

  /**
   * ASCII representation of the cityEHR logo.
   */
  public static final String LOGO = EOL +
      "         _  __          ______ __  __ ____  " + EOL +
      "  _____ (_)/ /_ __  __ / ____// / / // __ \\" + EOL +
      " / ___// // __// / / // __/  / /_/ // /_/ / " + EOL +
      "/ /__ / // /_ / /_/ // /___ / __  // _, _/  " + EOL +
      "\\___//_/ \\__/ \\__, //_____//_/ /_//_/ |_|" + EOL +
      "             /____/                         " + EOL +
      EOL;

  public static String logoAndFooter(final String... footerLines) {
    final StringBuilder builder = new StringBuilder(CityEhrAsciiLogo.LOGO);
    for (int i = 0; i < footerLines.length; i++) {
      builder.append(footerLines[i]);
      if (i < footerLines.length - 1) {
        builder.append(EOL);
      }
    }
    return builder.toString();
  }
}
