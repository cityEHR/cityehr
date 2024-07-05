<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    CDA2XForm.xsl
    Input is a CDA document, or any other document that contains a CDA Document
    PLUS view-parameters.xml is passed in on parameters input
    (PLUS dictionary.xml is passed in on dictionary input)
    
    Root of the CDA document is cda:ClinicalDocument
    Generates an XForm to be displayed in CityEHR
    
    Variables in this stylesheet are for XSLT or for XForms. All Xforms variables start with 'xforms'
       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet version="2.0" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xxf="http://orbeon.org/oxf/xml/xforms" xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:cda="urn:hl7-org:v3" xmlns:iso-13606="http://www.iso.org/iso-13606" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" xmlns:saxon="http://saxon.sf.net/">
    <!-- Need the indent="no" to make sure no white space is output between elements -->
    <xsl:output method="xml" indent="no" name="xml"/>

    <!-- The combined parameters are passed in on parameters input -->
    <xsl:variable name="view-parameters" select="document('input:parameters')//parameters[@type='view']"/>
    <xsl:variable name="system-parameters" select="document('input:parameters')//parameters[@type='system']"/>
    <xsl:variable name="session-parameters" select="document('input:parameters')//parameters[@type='session']"/>

    <!-- dictionary.xml is passed in on dictionary input -->
    <xsl:variable name="dictionary" select="document('input:dictionary')"/>
    
    <!-- image maps are passed in on svgImageMaps input -->
    <xsl:variable name="svgImageMaps" select="document('input:svgImageMaps')"/>
        
    <!-- Main templates for CDA to HTML conversion -->
    <xsl:include href="CDA2XForm-Module.xsl"/>
    
    <!-- Set global variables for view-parameter settings -->

    <xsl:variable name="applicationId" select="replace(substring($session-parameters/applicationIRI,2),':','-')"/>
    <xsl:variable name="specialtyId" select="replace(substring($session-parameters/specialtyIRI,2),':','-')"/>
    
    <xsl:variable name="applicationStorageLocation" select="concat($session-parameters/storageLocation,'/applications/',$applicationId)"/>
    <xsl:variable name="applicationDatabaseLocation" select="concat($session-parameters/databaseLocation,$applicationStorageLocation)"/>

    <!-- Match cda:ClinicalDocument to output the CDA document -->
    <xsl:template match="cda:ClinicalDocument">
        <xsl:variable name="compositionTypeIRI" select="cda:typeId/@root"/>
        <xsl:call-template name="renderCDADocument">
            <xsl:with-param name="composition" select="."/>
            <xsl:with-param name="compositionTypeIRI" select="$compositionTypeIRI"/>
        </xsl:call-template>

    </xsl:template>
    

</xsl:stylesheet>
