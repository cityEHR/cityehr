<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWL2ISO13606.xsl
    Input is an OWl/XML ontology as per the City EHR architecture
    Generates an XML representation of the ISO-13606 model.
    
    Stores output on the file system, simulating the eXist database:
    existSandBox/<applicationId/>ISO13606/<specialty>-ISO13606.xml
    
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
    xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#">
    <xsl:output method="xml" indent="yes" name="xml"/>
    
    <!-- Include main module -->
    <xsl:include href="OWL2MindMap-Module.xsl"/>
    
    <!-- Create a Mind Map for the specialty or class set as the context for the ontology -->
    <xsl:template match="/">
        <!-- Redirect output to file, based on the application, specialty and class -->
        <xsl:variable name="filename" as="xs:string"
            select="if ($classId!='') then concat('../existSandBox/',$applicationFileId,'/MindMap/',$specialtyFileId,'-',$classFileId,'-MindMap.mm') else concat('../existSandBox/',$applicationFileId,'/MindMap/',$specialtyFileId,'-MindMap.mm')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">
            <xsl:call-template name="generateMindMap">
                <xsl:with-param name="applicationIRI" select="$applicationIRI"/>
                <xsl:with-param name="specialtyIRI" select="$specialtyIRI"/>
                <xsl:with-param name="classIRI" select="$classIRI"/>
            </xsl:call-template>
        </xsl:result-document>

    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
