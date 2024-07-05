<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:j2ee="http://java.sun.com/xml/ns/j2ee"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns="http://java.sun.com/xml/ns/j2ee"
  exclude-result-prefixes="xs j2ee"
  version="2.0">

  <xsl:param name="version" as="xs:string" required="yes"/>

  <xsl:output indent="yes"/>

  <xsl:template match="j2ee:display-name[parent::j2ee:web-app]">
    <xsl:copy>cityEHR <xsl:value-of select="$version"/></xsl:copy>
  </xsl:template>

  <xsl:template match="j2ee:init-param[j2ee:param-name eq 'oxf.error-processor.name'][parent::j2ee:servlet[j2ee:servlet-name eq 'orbeon-main-servlet']]">
    <xsl:copy>
      <xsl:copy-of select="j2ee:param-name"/>
      <param-value>{http://www.orbeon.com/oxf/processors}pipeline</param-value>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="j2ee:init-param[j2ee:param-name eq 'oxf.error-processor.input.controller'][parent::j2ee:servlet[j2ee:servlet-name eq 'orbeon-main-servlet']]">
    <xsl:copy>
      <param-name>oxf.error-processor.input.config</param-name>
      <param-value>oxf:/apps/ehr/pipelines/cityEHRFatalError.xpl</param-value>
    </xsl:copy>
  </xsl:template>

  <!-- identity transform -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>