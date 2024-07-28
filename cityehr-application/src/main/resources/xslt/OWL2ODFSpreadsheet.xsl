<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWL2ODFSpreadsheet.xsl
    Input is an OWl/XML ontology as per the cityEHR architecture
    PLUS a parameters file and spreadsheetTemplate
    
    Generates a an HTML view of the ontology, of different types depending on informationModelType and informationModelDisplay.
    
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
    xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <xsl:output method="xml" indent="yes" name="xml"/>
    
    <!-- Set the parameters from the input view-parameters document -->
    <xsl:variable name="parameters" select="document('input:parameters')/parameters"/>
    
    <!-- Set the template content from the input document -->
    <xsl:variable name="template" select="document('input:spreadsheetTemplate')"/>
    
    <xsl:include href="OWL2ODFSpreadsheet-Module.xsl"/>
   
    <!-- Call template to generate the spreadsheet content -->
    <xsl:template match="/">
        <xsl:call-template name="generateSpreadsheetContent"/>
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
