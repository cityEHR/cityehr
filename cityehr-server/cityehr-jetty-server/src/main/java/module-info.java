module cityehr.jetty.server {
  requires java.base;
  requires cityehr.server.common;
  requires org.jspecify;
  requires org.eclipse.jetty.server;
  requires org.eclipse.jetty.util;
  requires org.eclipse.jetty.webapp;
  // Jetty 12
//  requires org.eclipse.jetty.ee8.webapp;
  requires org.slf4j;

  exports com.seveninformatics.cityehr.standalone;
}
