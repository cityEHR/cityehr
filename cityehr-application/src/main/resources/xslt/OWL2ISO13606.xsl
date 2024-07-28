<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWL2ISO13606.xsl
    Input is an OWl/XML ontology as per the City EHR architecture
    Generates an XML representation of the ISO-13606 model.
    
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
    xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#">
    <xsl:output method="xml" indent="yes" name="xml"/>
 

    <xsl:include href="OWL2ISO13606-Module.xsl"/>
    
    
    <!-- === ISO-13606 Model === 
    ============================ -->

    <!-- Create an ISO-13606 Model for the specialty set as the context for the ontology -->
    
    <xsl:template match="/">
        <xsl:call-template name="generateISO-13606Model">
            <xsl:with-param name="applicationIRI" select="$applicationIRI"/>
            <xsl:with-param name="specialtyIRI" select="$specialtyIRI"/>
            <xsl:with-param name="classIRI" select="$classIRI"/>
        </xsl:call-template>
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
