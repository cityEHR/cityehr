<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    GetOWLClassHandles.xsl
    Input is the OWL ontology for a specialty
    PLUS view-parameters.xml is passed in on parameters input
    
    Finds each of the cityEHR classes declared in the specialty.
    And generates a collection of the database handles
    Uses the database location set in the parameters input
    
    <handles>
        <handle> </handle>
        <handle> </handle>
    </handles>    
       
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

    <!-- view-parameters.xml is passed on the parameters input.
         Or use the one from the file system for standalone testing. -->
    <xsl:variable name="parameters" select="document('input:parameters')/parameters"/>
    <!--
    <xsl:variable name="parameters" select="document('../view-parameters.xml')/parameters"/>
    -->

    <!-- Use this variable to find the ontology root (may not be root document node) -->
    <xsl:variable name="ontology" select="/descendant::owl:Ontology[1]"/>

    <!-- Set the Application for this ontology configuration -->
    <xsl:variable name="applicationIRI" as="xs:string" select="$ontology/owl:ClassAssertion[owl:Class/@IRI='#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="applicationId" as="xs:string" select="replace(substring($applicationIRI,2),':','-')"/>


    <!-- Set the Specialty for this ontology configuration -->
    <xsl:variable name="specialtyIRI" as="xs:string" select="$ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasContent'][owl:NamedIndividual[1]/@IRI=$applicationIRI]/owl:NamedIndividual[2]/@IRI"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="specialtyId" as="xs:string" select="replace(substring($specialtyIRI,2),':','-')"/>


    <!-- === Match root node and generated the handles ========== 
         ======================================================== -->
    <xsl:template match="/">
        <handles xmlns="">
            <xsl:apply-templates/>
        </handles>
    </xsl:template>


    <!-- Match the cityEHR class assertions -->
    <xsl:template match="owl:Ontology/owl:ClassAssertion[owl:Class/@IRI='#CityEHR:Class']/owl:NamedIndividual[1]">
        <xsl:variable name="classIRI" select="./@IRI"/>
        <xsl:variable name="classId" select="replace(substring($classIRI,2),':','-')"/>
        <xsl:variable name="classLocation" select="concat($parameters/storageLocation,'/applications/',$applicationId,'/informationModel/',$specialtyId,'/',$classId)"/>
        <xsl:variable name="classHandle" select="concat($parameters/applicationDatabaseLocation,'/informationModel/',$specialtyId,'/',$classId)"/>

        <xsl:if test="/descendant::informationModel/handle = $classLocation">
            <handle>
                <xsl:value-of select="$classHandle"/>
            </handle>
        </xsl:if>
        
    </xsl:template>

    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>



</xsl:stylesheet>
