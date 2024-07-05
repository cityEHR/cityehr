<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    AnonymiseDataSet.xsl
    Input is a patient cohort with patientInfo and patientData elements
    PLUS view-parameters.xml is passed in on parameters input
    
    Anonymises the data set, according to the option set in parameters
       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Set the parameters from the view-parameters -->
    <!-- Set the parameters from the input document -->
    <xsl:variable name="parameters" select="document('input:parameters')/parameters"/>
    

    <!-- Templates to generate the spreadsheet -->
    <xsl:include href="AnonymiseDataSet-Module.xsl"/>

    <!-- Match root node - apply templates to anonymise the data set
         If the input does not contain patientSet (e.g. it contains an error message) then all inout is copied through to output -->
    <xsl:template match="/">
            <xsl:apply-templates/>
    </xsl:template>


</xsl:stylesheet>
