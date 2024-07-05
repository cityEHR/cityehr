<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWL2CompositionSet.xsl
    Input is an OWl/XML ontology as per the City EHR architecture
    PLUS view-parameters.xml is passed in on parameters input
    
    Generates a set of Composition Templates, one for every composition of the specified type in the ontology.
    This set can then be imported as configuration for the cityEHR.
    
    The specified composition type is found in parameters/compositionTypeIRI
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>
    
    <!-- view-parameters.xml is passed in on parameters input -->
    <xsl:variable name="parameters" select="document('input:parameters')/parameters"/>

    <!-- Set up the XSLT keys for the OWL ontology -->
    <xsl:include href="OWLKeys-Module.xsl"/>

    <!-- Include main module and utilities -->
    <xsl:include href="OWL2Composition-Module.xsl"/>
    <xsl:include href="OWL2ModelUtilities.xsl"/>


    <!-- Match root node, create compositionSet, based on the compositionTypeIRI
         e.g. #CityEHR:Form, #CityEHR:Letter, #CityEHR:Order, etc
         These are subclases of #ISO-13606:Composition
         
         <SubClassOf>
            <Class IRI="#CityEHR:Form"/>
            <Class IRI="#ISO-13606:Composition"/>
         </SubClassOf>
         
         Until 2018-08-30 the compositionTypeIRI was passed in as a parameter
         From 2018-08-30 this stylesheet generates all compositions for every type
     -->
    <xsl:template match="/">
        
        <compositionSet xmlns:mif="urn:hl7-org:v3/mif" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cityEHR="http://openhealthinformatics.org/ehr"  xmlns:cda="urn:hl7-org:v3">

            <!-- Get the set of compositionTypeIRI -->
            <xsl:variable name="compositionTypeIRI" select="//owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Composition']/owl:Class[1]/@IRI"/>
            
            <xsl:for-each select="//owl:Ontology/owl:ClassAssertion[owl:Class/@IRI=$compositionTypeIRI]/owl:NamedIndividual/@IRI">

                <!-- Set the compositionIRI for the composition to be generated -->
                <xsl:variable name="compositionIRI" select="."/>

                <xsl:call-template name="generateComposition">
                    <xsl:with-param name="rootNode" select="$rootNode"/>
                    <xsl:with-param name="compositionIRI" select="$compositionIRI"/>
                    <xsl:with-param name="applicationIRI" select="$applicationIRI"/>
                    <xsl:with-param name="specialtyIRI" select="$specialtyIRI"/>
                </xsl:call-template>
            </xsl:for-each>
            
        </compositionSet>

    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
