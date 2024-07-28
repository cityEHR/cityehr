<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWL2NodeDisplay.xsl
    Input is an OWl/XML ontology as per the City EHR architecture
    PLUS a parameters file 
    
    Generates a an HTML view of the ontology, of different types depending on informationModelType and informationModelDisplay.
    
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

    <!-- Set the type of information model (Class or Specialty) -->
    <xsl:variable name="parameters" select="document('input:parameters')/parameters"/>
    <xsl:variable name="informationModelType" select="$parameters/informationModelType"/>
    <xsl:variable name="informationModelDisplay" select="$parameters/informationModelDisplay"/>

    <xsl:include href="OWL2NodeDisplay-Module.xsl"/>
    
    <!-- Call template to generate the node display requested -->
    <!-- The following cases need to be handled:
        
        informationModelType - Class
        1) Display nodes by level
        2) Display all nodes
        
        informationModelType - Specialty or Combined
        (1) Display the full data dictionary
    -->
    
    <xsl:template match="/">
            <html>
                <xsl:call-template name="generateNodeDisplay"/>
            </html>
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
