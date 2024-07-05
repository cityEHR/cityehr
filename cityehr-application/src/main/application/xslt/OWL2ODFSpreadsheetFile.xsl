<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWL2ODFSpreadsheetFile.xsl
    Input is an OWl/XML ontology as per the City EHR architecture
    PLUS the spreadsheet template and a parameters file
    
    Generates an ODF contents file for that can be zipped up to dreate the ODF spreadsheet for the information model.
    
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
    
    <!-- Set the parameters from the view-parameters -->
    <xsl:variable name="parameters" select="document('../view-parameters.xml')/parameters"/>
    
    <xsl:include href="OWL2ODFSpreadsheet-Module.xsl"/>
    
    <!-- Set the template content from the information model type -->
    <xsl:variable name="template" select="if ($informationModelType='specialty') then document('../existSandBox/informationModel/specialtyContent.xml') else document('../existSandBox/informationModel/classContent.xml')"/>
    
    
    <!-- Call template to generate the spreadsheet content -->
    <xsl:template match="/">
        <!-- Redirect output to file, based on the application and specialty -->
        <xsl:variable name="filename" as="xs:string"
            select="concat('../existSandBox/',$applicationFileId,'/informationModel/',$specialtyFileId,'/',$informationModelType,'Content.xml')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">
            <xsl:call-template name="generateSpreadsheetContent"/>
        </xsl:result-document>
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
