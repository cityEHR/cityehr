<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    AnonymiseDataSetFile.xsl
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
    <xsl:variable name="parameters"
        select="document('../view-parameters.xml')/parameters"/>

    <!-- Templates to generate the spreadsheet -->
    <xsl:include href="AnonymiseDataSet-Module.xsl"/>

    <!-- Match root node - set up output file and apply templates to anonymise the data set
        If the input does not contain patientSet (e.g. it contains an error message) then all input is copied through to output -->
    <xsl:template match="/">
        <!-- Redirect output to file, in the examples directory -->
        <xsl:variable name="filename" as="xs:string"
            select="concat('../examples/export/',$anonymisationType,'.xml')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">
            <xsl:apply-templates/>
        </xsl:result-document>

    </xsl:template>


</xsl:stylesheet>
