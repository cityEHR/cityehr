<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    CDA2HL7-FHIR.xsl
    Input is a collection of HL7 CDA documents for a patient
    Generates an HL7 FHIR XML representation, contained in a FHIR element.
    Uses the HL7 FHIR representation of a ClinicalDocument
    
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
    xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

    <xsl:output method="xml" indent="yes" name="xml"/>

   
    <!-- Get timestamp to create unique Ids -->
    <xsl:variable name="timeStamp" as="xs:string"
    select="replace(replace(string(current-dateTime()),':','-'),'\+','*')"/>
    
    <!-- Match root and call template to generate the ontology -->
    <xsl:template match="/">
        <xsl:variable name="patientId" select="//cda:recordTarget[1]/cda:patientRole/cda:id/@extension"/>
        <FHIR>
                <xsl:apply-templates/>
        </FHIR>
    </xsl:template>
    
    <xsl:template match="cda:ClinicalDocument">
        <xsl:variable name="compositionId" select="cda:id[1]/@extension"/>
        <xsl:variable name="displayName" select="cda:code[1]/@displayName"/>
        <xsl:variable name="effectiveTime" select="cda:effectiveTime[1]/@value"/>
        
            <xsl:apply-templates/>
        
    </xsl:template>
    
    <xsl:template match="cda:section">
        <xsl:variable name="sectionId" select="cda:id[1]/@extension"/>
        <xsl:variable name="displayName" select="cda:title[1]"/>

            <xsl:apply-templates/>
        
    </xsl:template>
    
    <xsl:template match="cda:entry">
        <xsl:variable name="entryId" select="*/cda:id[1]/@extension"/>
        <xsl:variable name="typeId" select="*/cda:typeId[1]/@extension"/>
        <xsl:variable name="displayName" select="*/cda:code[1]/@displayName"/>

            <xsl:apply-templates/>
        
    </xsl:template>
    
    <xsl:template match="cda:value[cda:value]">
        <xsl:variable name="clusterId" select="@extension"/>
        <xsl:variable name="displayName" select="@displayName"/>

            <xsl:apply-templates/>
        
    </xsl:template>
    
    <xsl:template match="cda:value">
        <xsl:variable name="elementId" select="@extension"/>
        <xsl:variable name="elementDisplayName" select="@elementDisplayName"/>
        <xsl:variable name="value" select="@value"/>
        <xsl:variable name="displayName" select="@displayName"/>
        
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
