<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    DataSet2CSV-Module.xsl
    Input is a patient cohort with patientInfo and patientData elements
    
    Produces text file in CSV Format
    
    If the patientData has structure (child elements) then need to convert entry/element to CSV
    If patientData has no structure, then it is already converted to CSV and just the value is output

       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0"
    xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="text" omit-xml-declaration="yes" indent="no" name="text"/>

    <!-- === Variables === -->
    <xsl:variable name="root" select="//patientSet"/>

    <!-- Set externalId -->
    <xsl:variable name="externalId" select="$root/@externalId"/>


    <!-- === Generate CSV ===========================
         Output header line if selected
         One line for each patient
         One field for each element
         ============================================ -->
    <xsl:template name="generate-csv">
        <!-- Header.
        Has been generated in the first element the patientData, so don't need to do anything extra here -->
        <!--
        <xsl:if test="$root[@outputHeaderRow=true()]">
            <xsl:call-template name="outputHeaderRow">
                <xsl:with-param name="patientData" select="$root/patientData[1]"/>
            </xsl:call-template>
        </xsl:if>
        -->
        <!-- Output data -->
        <xsl:apply-templates select="$root/patientData"/>
    </xsl:template>


    <!-- Output line for each patient.
         If the patientData has structure (child elements) then need to convert entry/element to CSV
         If patientData has no structure, then it is already converted to CSV and just the value is output -->
    <xsl:template match="patientData">
        <!-- Output every entry/element, assuming the structure is identical for each patient -->
        <xsl:value-of select="if (exists(./*)) then string-join(descendant::cda:value/@value,',') else ."/>
        <xsl:value-of select="'&#xA;'"/>
    </xsl:template>

    <!-- === Output header row ===========================
     Iterate through each element in the patientData
     Output name of element
     If 
     ============================================ -->
    <xsl:template name="outputHeaderRow">
        <xsl:param name="patientData"/>
        <xsl:value-of
            select="string-join($patientData/descendant::cda:value/substring-after(@extension,'#ISO-13606:Element:'),',')"/>
        <xsl:value-of select="'&#xA;'"/>
    </xsl:template>

</xsl:stylesheet>
