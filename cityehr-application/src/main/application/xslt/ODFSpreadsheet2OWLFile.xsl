<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    ODFSpreadsheet2OWLFile.xsl
    Input is a ODF spreadsheet (content.xml file from the ODF .ods zip) with information model for the specialty or class
    Generates an OWl/XML ontology as per the City EHR architecture and outputs to file.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema">

    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Import module that generates OWL ontology from spreadsheet -->
    <xsl:include href="ODFSpreadsheet2OWL-Module.xsl"/>

    <!-- Get the cityEHR architecture OWL/XML for inclusion in the generated ontology -->
    <xsl:variable name="cityEHRarchitecture" select="document('../resources/templates/cityEHRarchitecture-2018.xml')"/>
    
    <!-- Get the view-paraemters (needed for error messages) -->
    <xsl:variable name="viewParameters" select="document('../view-parameters.xml')"/>

    <!-- Set locations to mirror the exist database collections -->
    <xsl:variable name="applicationLocation" select="concat('ISO-13606-EHR_Extract-',$applicationId)"/>
    <xsl:variable name="specialtyLocation" select="concat('ISO-13606-Folder-',$specialtyId)"/>

    <!-- Match root node - set up output file and call template to generate the ontology -->
    <xsl:template match="/">
        <!-- Redirect output to file, based on the application and specialty -->
        <xsl:variable name="filename" as="xs:string"
            select="concat('../existSandBox/',$applicationLocation,'/informationModel/',$specialtyLocation,'/',$specialtyLocation,'.owl')"/>
        <!-- Needed if results are output to a file.
            <xsl:result-document href="{$filename}" format="xml"> 
            With format="xml" will resolve the &amp;rdf; to &rdf; which then needs to be defined as an entity to have a well-formed document. -->
        <xsl:result-document href="{$filename}">
            <xsl:if test="$processError='false'">
                <xsl:apply-templates/>
            </xsl:if>
            <!-- Note that if applicationId and/or specialtyId are not defined then the filename will be different from when valid -->
            <xsl:if test="$processError='true'">
                <xsl:call-template name="generateOWLError">
                    <xsl:with-param name="context">cityEHR Information Model cannot be processed.</xsl:with-param>
                    <xsl:with-param name="message">applicationId and specialtyId must be defined in the model.</xsl:with-param>
                </xsl:call-template>
            </xsl:if>
        </xsl:result-document>
    </xsl:template>

    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>
</xsl:stylesheet>
