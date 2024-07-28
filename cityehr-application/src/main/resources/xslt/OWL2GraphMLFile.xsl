<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWL2GraphMLFile.xsl
    Input is an OWl/XML ontology as per the City EHR architecture
    
    Generates a graphML rendition of the ontology that can be edited using Yed and outputs to file.
    
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
    
    <xsl:include href="OWL2GraphML-Module.xsl"/>
    
    <!-- Set locations for filename generation
         Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->  
    <xsl:variable name="applicationLocation" as="xs:string"
    select="replace(substring($applicationIRI,2),':','-')"/>
    <xsl:variable name="specialtyLocation" as="xs:string"
        select="replace(substring($specialtyIRI,2),':','-')"/> 
    <xsl:variable name="classLocation" as="xs:string"
    select="replace(substring($classIRI,2),':','-')"/>
    
    
    <!-- Call template to generate graphML --> 
    <xsl:template match="/">
        
        <!-- Redirect output to file, based on the application, specialty and class -->
        <xsl:variable name="filename" as="xs:string" select="concat('../existSandBox/',$applicationLocation,'/importedFiles/',$specialtyLocation,'/',$classLocation,'.graphML')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">
            <xsl:call-template name="generateGraphML">
                <xsl:with-param name="rootNode" select="$rootNode"/>
                <xsl:with-param name="applicationIRI" select="$applicationIRI"/> 
                <xsl:with-param name="specialtyIRI" select="$specialtyIRI"/> 
                <xsl:with-param name="classIRI" select="$classIRI"/> 
            </xsl:call-template>
        </xsl:result-document>       
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
