module cityehr.tomcat.server {
  requires java.base;
  requires cityehr.server.common;
  requires jul.to.slf4j;
  requires org.jspecify;
  requires org.slf4j;
  requires org.apache.tomcat.embed.core;

  exports com.seveninformatics.cityehr.standalone;
}
