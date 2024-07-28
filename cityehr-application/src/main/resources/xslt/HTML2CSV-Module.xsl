<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    HTML2CSV-Module.xsl
    Input is an HTML document (with a table)
    
    Produces text file in CSV Format
       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0"
    xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="text" omit-xml-declaration="yes" indent="no" name="text"/>

    <!-- === Variables === -->
    <xsl:variable name="root" select="//html[1]"/>

    <!-- Set externalId -->
    <xsl:variable name="externalId" select="$root/head/meta[@name='externalId']/@content"/>


    <!-- === Generate CSV ===========================
         One line for each row in the table
         One field for each cell
         ============================================ -->
    <xsl:template name="generate-csv">
        <xsl:apply-templates select="$root/descendant::table[1]/descendant::tr"/>
    </xsl:template>


    <!-- Output line for each row in the table -->
    <xsl:template match="tr">
        <!-- Output every cell -->
        <xsl:value-of select="string-join(descendant::td,',')"/>
        <xsl:value-of select="'&#xA;'"/>
    </xsl:template>
</xsl:stylesheet>
