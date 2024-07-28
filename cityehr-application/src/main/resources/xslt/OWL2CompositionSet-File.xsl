<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWL2CompositionSet.xsl
    Input is an OWl/XML ontology as per the City EHR architecture
    
    Generates a set of Composition Templates, one for every form on the ontology.
    This set can then be imported as configuration for the cityEHR.
    
    This version outputs to a file in the eXist sand box
    
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

    <!-- view-parameters.xml is passed in on parameters input (so here is read from file) -->
    <xsl:variable name="parameters" select="document('../view-parameters.xml')/parameters"/>

    <!-- Set up the XSLT keys for the OWL ontology -->
    <xsl:include href="OWLKeys-Module.xsl"/>

    <!-- Include main module and utilities -->
    <xsl:include href="OWL2ModelUtilities.xsl"/>
    <xsl:include href="OWL2Composition-Module.xsl"/>


    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist. -->
    <xsl:variable name="applicationLocation" as="xs:string" select="replace(substring($applicationIRI, 2), ':', '-')"/>
    <xsl:variable name="specialtyLocation" as="xs:string" select="replace(substring($specialtyIRI, 2), ':', '-')"/>

    <xsl:template match="/">


        <!-- Redirect output to file, based on the application and specialty  -->
        <xsl:variable name="filename" as="xs:string"
            select="concat('../existSandBox/', $applicationLocation, '/systemConfiguration/', $specialtyLocation, '/compositionset.xml')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">

            <compositionSet xmlns:mif="urn:hl7-org:v3/mif" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cda="urn:hl7-org:v3">

                <!-- Get the set of compositionTypeIRI -->
                <xsl:variable name="compositionTypeIRI"
                    select="//owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI = '#ISO-13606:Composition']/owl:Class[1]/@IRI"/>

                <xsl:for-each select="//owl:Ontology/owl:ClassAssertion[owl:Class/@IRI = $compositionTypeIRI]/owl:NamedIndividual/@IRI">

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

        </xsl:result-document>

    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
