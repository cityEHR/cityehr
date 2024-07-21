package com.seveninformatics.cityehr.standalone;

import com.seveninformatics.cityehr.standalone.common.configuration.Configuration;
import com.seveninformatics.cityehr.standalone.common.configuration.ConfigurationBuilder;
import com.seveninformatics.cityehr.standalone.common.configuration.CliArgumentsParser;
import com.seveninformatics.cityehr.standalone.common.configuration.EnvironmentVariablesParser;
import com.seveninformatics.cityehr.standalone.common.configuration.SystemPropertiesParser;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.util.log.Log;
import org.eclipse.jetty.util.log.Logger;
import org.eclipse.jetty.util.resource.Resource;
import org.eclipse.jetty.webapp.WebAppContext;

import javax.annotation.Nullable;
import java.io.IOException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Embedded Jetty Server for running cityEHR.
 */
public class CityEhrJettyServer {

  private static final Logger LOG = Log.getLogger(CityEhrJettyServer.class);

  public static void main(final String[] args) throws Exception {
    final Configuration configuration = new ConfigurationBuilder()
        .add(new EnvironmentVariablesParser())
        .add(new SystemPropertiesParser())
        .add(new CliArgumentsParser(args))
        .build();

    final Server server = newServer(configuration);
    server.start();
    server.join();
  }

  public static Server newServer(final Configuration configuration) throws IOException {
    final int port = configuration.getServerHttpPort();
    final Server server = new Server(port);

    final WebAppContext context = new WebAppContext();

    final URL warLocation = CityEhrJettyServer.class.getProtectionDomain().getCodeSource().getLocation();
    final Resource warResource = Resource.newResource(warLocation);

    LOG.info("Using BaseResource: {}", warResource);

    // NOTE(AR) has to be set - see: https://www.eclipse.org/lists/jetty-users/msg10722.html
    context.setExtractWAR(true);

    // Set the directory the war will extract to
    @Nullable Path workingDirectory = configuration.getServerWorkingDirectory();
    if (workingDirectory == null) {
      workingDirectory = Paths.get("jetty." + port);
    }
    if (!Files.exists(workingDirectory)) {
      Files.createDirectories(workingDirectory);
    }
    context.setTempDirectory(workingDirectory.toFile());

    context.setWarResource(warResource);

    context.setContextPath("/");
//    context.setWelcomeFiles(new String[] { "index.html", "welcome.html" });
    context.setParentLoaderPriority(true);
    server.setHandler(context);
    return server;
  }
}
