<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:c="http://www.orbeon.com/oxf/controller"
  xmlns="http://www.orbeon.com/oxf/controller"
  exclude-result-prefixes="c"
  version="2.0">

  <xsl:output indent="yes"/>

  <xsl:template match="c:page[@id eq 'home']">
    <page id="home" path-info="/ehr/" model="apps/ehr/page-flow.xml"/>
  </xsl:template>

  <xsl:template match="c:not-found-handler">
    <not-found-handler page="home"/>
  </xsl:template>

  <!-- identity transform -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>