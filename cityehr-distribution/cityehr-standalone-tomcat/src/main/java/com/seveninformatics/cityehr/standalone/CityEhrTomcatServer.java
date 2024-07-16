package com.seveninformatics.cityehr.standalone;

import org.apache.catalina.Context;
import org.apache.catalina.Server;
import org.apache.catalina.connector.Connector;
import org.apache.catalina.startup.Tomcat;
import org.apache.tomcat.JarScanFilter;
import org.apache.tomcat.JarScanType;

import java.io.InputStream;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

public class CityEhrTomcatServer {

  public static void main(final String[] args) throws Exception {
    final int port = 8080;
    final Path baseDirPath = Paths.get("tomcat." + port);

    final Tomcat tomcat = new Tomcat();
    tomcat.setPort(port);
    tomcat.setBaseDir(baseDirPath.toAbsolutePath().toString());

    // NOTE(AR) create the basedir/webapps otherwise the call to tomcat.addWebapp below will fail
    final Path webappsDirs = baseDirPath.resolve("webapps");
    Files.createDirectories(webappsDirs);

    final URL warSourceLocation = CityEhrTomcatServer.class.getProtectionDomain().getCodeSource().getLocation();
    final Path warFileName = Paths.get(Paths.get(warSourceLocation.toURI()).getFileName().toString().replace("jar", "war"));
    final Path warTargetPath = webappsDirs.resolve(warFileName);
    final Path expandedWarPath = webappsDirs.resolve("ROOT");

//    System.out.println("warSourceLocation=" + warSourceLocation);
//    System.out.println("warFileName=" + warFileName);
//    System.out.println("warTargetLocation=" + warTargetPath);
//    System.out.println("expandedWarPath=" + expandedWarPath);

    // if the expanded war path already exists don't copy the war file again
    if (!Files.exists(expandedWarPath)) {
      try (final InputStream is = warSourceLocation.openStream()) {
        Files.copy(is, warTargetPath, StandardCopyOption.REPLACE_EXISTING);
      }
    }

    final Context context = tomcat.addWebapp(tomcat.getHost(), "",  warTargetPath.toAbsolutePath().toString());

    // disable scanning for TLD in Jar files
    context.getJarScanner().setJarScanFilter(new SkipAllJarScanner());

    final Connector connector = tomcat.getConnector();

    final Server server = tomcat.getServer();
    server.start();

    server.await();
  }

  private static class SkipAllJarScanner implements JarScanFilter {
    @Override
    public boolean check(final JarScanType jarScanType, final String jarName) {
      return false;
    }

    @Override
    public boolean isSkipAll() {
      return true;
    }
  }

}
