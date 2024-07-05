<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    DataSet2CSVFile.xsl
    Input is a patient cohort with patientInfo and patientData elements
    
    Produces text file in CSV Format
       
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

    <!-- Templates to generate the spreadsheet -->
    <xsl:include href="DataSet2CSV-Module.xsl"/>

    <!-- Match root node - set up output file and call template to generate the spreadsheet -->
    <xsl:template match="/">
        <!-- Redirect output to file, in the examples directory -->
        <xsl:variable name="filename" as="xs:string"
            select="concat('../examples/export/',$externalId,'.csv')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="text">

            <xsl:call-template name="generate-csv"/>

        </xsl:result-document>

    </xsl:template>

    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
