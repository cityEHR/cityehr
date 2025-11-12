<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    checkExpressions.xsl
    Input is an OWl/XML ontology as per the City EHR architecture
    
    Generates a summary of all expressions defined in the ontology.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs"
    version="2.0" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>
    
    <!-- view-parameters.xml is passed in on parameters input -->
    <xsl:variable name="parameters" select="document('input:parameters')/parameters"/>

    <!-- Set up the XSLT keys for the OWL ontology -->
    <xsl:include href="OWLKeys-Module.xsl"/>

    <!-- Include main module and utilities -->
    <xsl:include href="checkExpressions-Module.xsl"/>

    <!-- Match document element to process expressions -->
    <xsl:template match="owl:Ontology">
        <expressionSet xmlns:mif="urn:hl7-org:v3/mif" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cda="urn:hl7-org:v3">
            <xsl:apply-templates/>
        </expressionSet>
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
