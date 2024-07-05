<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    CDA2XFormFile.xsl
    Input is a CDA document or container (such as a formDefinition)
    PLUS view-parameters.xml is passed in on parameters input
         and dictionary.xml is passed in on dictionary input
    
    Generates an XForm to be displayed in CityEHR
       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet version="2.0" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xxf="http://orbeon.org/oxf/xml/xforms" xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:cda="urn:hl7-org:v3" xmlns:iso-13606="http://www.iso.org/iso-13606" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" xmlns:saxon="http://saxon.sf.net/" xmlns:owl="http://www.w3.org/2002/07/owl#">
    <xsl:output method="xml" indent="yes" name="xml"/>
    
    <!-- Set the Application and Specialty for this CDA Document.
        These are found in the cda element:
        <templateId root="#ISO-13606:EHR_Extract:Elfin" extension="#ISO-13606:Folder:NOC"/> 
        Which is a child of the ClinicalDocument element -->
    <xsl:variable name="applicationIRI" select="//cda:ClinicalDocument/cda:templateId/@root"/>
    <xsl:variable name="specialtyIRI" select="//cda:ClinicalDocument/cda:templateId/@extension"/>

    <!-- view-parameters.xml passed in as input-->
    <!--
    <xsl:variable name="parameters" select="document('input:parameters')/parameters"/>
    -->
    <xsl:variable name="parameters" select="document('../view-parameters.xml')/parameters"/>
    
    <!-- Set global variables for view-parameter settings -->   
    <xsl:variable name="applicationId" select="replace(substring($applicationIRI,2),':','-')"/>
    <xsl:variable name="specialtyId" select="replace(substring($specialtyIRI,2),':','-')"/>
    
    <xsl:variable name="applicationStorageLocation" select="concat($parameters/storageLocation,'/applications/',$applicationId)"/>
    <xsl:variable name="applicationDatabaseLocation" select="concat($parameters/databaseLocation,$applicationStorageLocation)"/>
    
    
    <!-- Get the composition for this CDA document.
         This is found in the cda element:
            <typeId root="cityEHR" extension="#CityEHR:Letter:patientletter"/>
        Which is a child of the ClinicalDocument element
    -->
    <xsl:variable name="compositionIRI" select="//cda:ClinicalDocument/cda:typeId/@extension"/>
       
    <!-- Set locations to mirror the exist database collections -->
    <xsl:variable name="applicationLocation" select="replace(substring($applicationIRI,2),':','-')"/>
    <xsl:variable name="specialtyLocation" select="replace(substring($specialtyIRI,2),':','-')"/>
    <xsl:variable name="compositionLocation" select="replace(substring($compositionIRI,2),':','-')"/>
    
    <!-- Set the dictionary input -->
    <xsl:variable name="dictionaryFilename" as="xs:string" select="concat('../existSandBox/',$applicationLocation,'/systemConfiguration/',$specialtyLocation,'/dictionary.xml')"/>   
    <xsl:variable name="dictionary" select="document($dictionaryFilename/>
    
    <!-- Set the svgImageMaps input -->
    <xsl:variable name="svgImageMapsFilename" as="xs:string" select="concat('../existSandBox/',$applicationLocation,'/systemConfiguration/',$specialtyLocation,'/svgImageMaps.xml')"/>   
        <xsl:variable name="svgImageMaps" select="document($svgImageMapsFilename"/>

    

    <!-- Main templates for CDA to HTML conversion -->
    <xsl:include href="CDA2XForm-Module.xsl"/>


    <!-- Match root node - set up output file and call template to generate the ontology -->

    <!-- ===  Match the root node to output an HTML document =========================================
        Creates the shell HTML document, then applies templates to output each CDA document found in the source
        ===================================================================================================== -->
    <xsl:template match="cda:ClinicalDocument">
        <!-- Redirect output to file, based on the application and specialty -->
        <xsl:variable name="filename" as="xs:string" select="concat('../existSandBox/',$applicationLocation,'/systemConfiguration/',$specialtyLocation,'/xforms/',$compositionLocation,'.xhtml')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">
            <xsl:variable name="compositionTypeIRI" select="cda:typeId/@root"/>
            <xsl:call-template name="renderCDADocument">
                <xsl:with-param name="composition" select="."/>
                <xsl:with-param name="compositionTypeIRI" select="$compositionTypeIRI"/>
            </xsl:call-template>
        </xsl:result-document>
    </xsl:template>




</xsl:stylesheet>
