package com.seveninformatics.cityehr.standalone;

import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.util.log.Log;
import org.eclipse.jetty.util.log.Logger;
import org.eclipse.jetty.util.resource.Resource;
import org.eclipse.jetty.webapp.WebAppContext;

import java.io.IOException;
import java.net.URISyntaxException;
import java.net.URL;

public class CityEhrJettyServer {

  private static final Logger LOG = Log.getLogger(CityEhrJettyServer.class);

  public static void main(final String[] args) throws Exception {
    int port = 8080;
    Server server = newServer(port);
    server.start();
    server.join();
  }

  public static Server newServer(final int port) {
    final Server server = new Server(port);

    final WebAppContext context = new WebAppContext();

    final URL warLocation = CityEhrJettyServer.class.getProtectionDomain().getCodeSource().getLocation();
    final Resource warResource = Resource.newResource(warLocation);

    LOG.info("Using BaseResource: {}", warResource);

    // NOTE(AR) has to be set - see: https://www.eclipse.org/lists/jetty-users/msg10722.html
    context.setExtractWAR(true);

    // (Optional) Set the directory the war will extract to.
    // If not set, java.io.tmpdir will be used, which can cause problems
    // if the temp directory gets cleaned periodically.
    // Your build scripts should remove this directory between deployments
//    webapp.setTempDirectory(new File("/home/olo/dev/webtmp/selfserve"))

    context.setWarResource(warResource);

    context.setContextPath("/");
//    context.setWelcomeFiles(new String[] { "index.html", "welcome.html" });
    context.setParentLoaderPriority(true);
    server.setHandler(context);
    return server;
  }
}
