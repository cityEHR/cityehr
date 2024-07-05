<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    DataSet2PatientList.xsl
    Input is a patient cohort with patientInfo and patientData elements
    Outputs list of patient/@id elements
    
    Produces XML spreadsheet file in MS SpreadsheetML (2003) format or ODF Format
    
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
    xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Match root - look for ptientInfo elements -->
    <xsl:template match="/">
        <patientList>
            <xsl:apply-templates select="//patientInfo"/>
        </patientList>
    </xsl:template>

    <!-- Convert patientInfo to patient/@id -->
    <xsl:template match="patientInfo">
        <xsl:if test="exists(@patientId) and @patientId!=''">
            <patient id="{@patientId}"/>
        </xsl:if>
    </xsl:template>

    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
