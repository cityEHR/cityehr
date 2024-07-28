<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    tblPatientDemographics.xsl
    This transformation is for data migration specific to the Elfin application.
    
    Input is an MS Acess XML export from the tblPatientDemographics
    PLUS view-parameters.xml is passed in on parameters input
    
    Produces a set of HL7 CDA documents
       
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
    <xsl:output method="xml" indent="yes"/>

    <!-- view-parameters.xml passed in on parameters input -->
    <xsl:variable name="parameters" select="document('input:parameters')"/>

    <!-- dictionary.xml passed in on dictionary input -->
    <xsl:variable name="template" select="document('input:template')"/>

    <!-- Use document('') to return this stylehseet to use its look-up table -->
    <xsl:variable name="lookup" select="document('')/xsl:template/cityEHR:lookup"/>


    <!-- Template for generating the CDA Header -->
    <xsl:include href="generateCDAHeader.xsl"/>


    <!-- ======= Match root node and transform ========== 
         ================================================ -->
    <xsl:template match="/">
        <recordSet>
            <xsl:apply-templates/>
        </recordSet>
    </xsl:template>

    <xsl:template match="tblPatientDemographics">
        <cda:ClinicalDocument>
            <xsl:call-template name="generateCDAHeader">
                <xsl:with-param name="demographics" select="."/>
            </xsl:call-template>
            <xsl:apply-templates/>
        </cda:ClinicalDocument>
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


    <!-- === Lookup table for mapping MS Access fields to HL7 CDA === 
         ============================================================ -->
    <cityEHR:lookup>
        <cityEHR:field name="FPSID" entryIRI="" elementIRI=""/>
    </cityEHR:lookup>

</xsl:stylesheet>
