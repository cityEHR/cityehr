<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    Spreadsheet2OWL.xsl
    Input is a spreadsheet (MS Office 2003 XML format) with full information model for the specialty
    Generates an OWl/XML ontology as per the City EHR architecture.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0"
    xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:c="urn:schemas-microsoft-com:office:component:spreadsheet"
    xmlns:html="http://www.w3.org/TR/REC-html40" xmlns:o="urn:schemas-microsoft-com:office:office"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:office2003Spreadsheet="urn:schemas-microsoft-com:office:spreadsheet"
    xmlns:x2="http://schemas.microsoft.com/office/excel/2003/xml"
    xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
    xmlns:x="urn:schemas-microsoft-com:office:excel">

    <!-- Output formatted XML -->
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Import module that generates OWL ontology from spreadsheet -->
    <xsl:include href="Spreadsheet2OWL-Module.xsl"/>

    <!-- Get the cityEHR architecture OWL/XML for inclusion in the generated ontology
         This is the original 2017 version - V1 -->
    <xsl:variable name="cityEHRarchitecture"
        select="document('../resources/templates/cityEHRarchitecture.xml')"/>


    <!-- Match root and call template to generate the ontology -->
    <xsl:template match="/">
        <xsl:if test="$processError='false'">
            <xsl:call-template name="generateOWL"/>
        </xsl:if>
        <xsl:if test="$processError='true'">
            <xsl:call-template name="generateOWLError">
                <xsl:with-param name="context">cityEHR Information Model cannot be
                    processed.</xsl:with-param>
                <xsl:with-param name="message">applicationId and specialtyId must be defined in the
                    model.</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
