<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    Spreadsheet2CDAFile.xsl
    Input is a spreadsheet (MS Office 2003 XML format) with data for a cohort of patients
    Generates a set of HL7 CDA documents as per the City EHR architecture and outputs to a file.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:c="urn:schemas-microsoft-com:office:component:spreadsheet" xmlns:html="http://www.w3.org/TR/REC-html40" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:office2003Spreadsheet="urn:schemas-microsoft-com:office:spreadsheet" xmlns:x2="http://schemas.microsoft.com/office/excel/2003/xml" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" xmlns:x="urn:schemas-microsoft-com:office:excel">

    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Import module that generates HL7 CDA documents from spreadsheet -->
    <xsl:include href="Spreadsheet2CDA-Module.xsl"/>

    <!-- Match root node - set up output file and call template to generate the ontology -->
    <xsl:template match="/">

        <!-- Redirect output to file, based on the application and specialty -->
        <xsl:variable name="filename" as="xs:string" select="concat('../existSandBox/',$applicationLocation,'/import/',$specialtyLocation,'.xml')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">
            <xsl:if test="$processError='false'">
                <xsl:call-template name="generateCityEHRCDA"/>
            </xsl:if>
            <!-- Note that if applicationId and/or specialtyId are not defined then the filename will be different from when valid -->
            <xsl:if test="$processError='true'">
                <xsl:call-template name="generateCDAError"/>
            </xsl:if>
        </xsl:result-document>

    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
