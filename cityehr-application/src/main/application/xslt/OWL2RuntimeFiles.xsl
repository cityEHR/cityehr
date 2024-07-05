<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    
    OWL2RuntimeFiles.xsl
    Input is an OWl/XML ontology as per the City EHR architecture
    Generates a set of separate documents to be loaded as runtime configuration for the City EHR
    
    Stores output on the file system, simulating the eXist database:
        existSandBox/systemConfiguration/<specialty>/dictionary.xml
        existSandBox/systemConfiguration/<specialty>/forms/<formId>.xml
        existSandBox/systemConfiguration/<specialty>/messages/<messageId>.xml
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    **********************************************************************************************************
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- view-parameters.xml is passed in on parameters input -->
    <xsl:variable name="parameters" select="document('../view-parameters.xml')/parameters"/>

    <!-- Set up the XSLT keys for the OWL ontology -->
    <xsl:include href="OWLKeys-Module.xsl"/>


    <!-- === Set global variables that are used in modules ========== 
    ============================================================ -->

    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="/owl:Ontology"/>

    <!-- Set the Application for this ontology configuration -->
    <xsl:variable name="applicationIRI" as="xs:string" select="/owl:Ontology/owl:ClassAssertion[owl:Class/@IRI='#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="applicationId" as="xs:string" select="replace(substring($applicationIRI,2),':','-')"/>

    <!-- Set the Specialty for this ontology configuration -->
    <xsl:variable name="specialtyIRI" as="xs:string" select="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasContent'][owl:NamedIndividual[1]/@IRI=$applicationIRI]/owl:NamedIndividual[2]/@IRI"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="specialtyId" as="xs:string" select="replace(substring($specialtyIRI,2),':','-')"/>

    <!-- Set the Class for this ontology configuration, if there is one -->
    <xsl:variable name="classIRI" as="xs:string" select="if (exists(/owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI)) then /owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI else ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="classId" as="xs:string" select="replace(substring($classIRI,2),':','-')"/>

    <!-- === Data Dictionary === 
        ============================ -->

    <!-- Create a data dictionary for the specialty set as the context for the ontology -->

    <xsl:include href="OWL2DataDictionary-Module.xsl"/>

    <xsl:variable name="dictionaryFilename" as="xs:string" select="if ($classId != '') then concat('../existSandBox/',$applicationId,'/systemConfiguration/',$specialtyId,'/dictionary/',$classId,'.xml') else concat('../existSandBox/',$applicationId,'/systemConfiguration/',$specialtyId,'/dictionary/',$specialtyId,'.xml')"/>   

    <!-- Read the data dictionary as input to the rest of the processing -->
    <xsl:variable name="dictionary" select="document('{$dictionaryFilename}')"/>
    
    <!-- This transformation no longer generates the dictionary - need to run owl2datadictionary first to make sur ethe dictionary is updated -->
    
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>




    <!-- === Named templates used for generating CDA in Forms and Messages === 
         ===================================================================== -->

    <xsl:include href="OWL2ModelUtilities.xsl"/>
    <xsl:include href="OWL2Composition-Module.xsl"/>


    <!-- === Views === 
        ============================ -->

    <!-- Process all the views declared in the ontology -->

    <!-- These are now just listed in the data dictionary -->
    

    <!-- === Forms === 
        ============================ -->

    <!-- Process all the forms declared in the ontology -->

    <xsl:template match="owl:Ontology/owl:ClassAssertion[owl:Class/@IRI='#CityEHR:Form']/owl:NamedIndividual">
        <!-- Redirect output to file, based on the form identity 
            Strip the leading # from IRIs and replace : with - to get unique ids -->
        <xsl:variable name="formIRI" as="xs:string" select="./@IRI"/>
        <xsl:variable name="formId" as="xs:string" select="replace(substring($formIRI,2),':','-')"/>
        <xsl:variable name="filename" as="xs:string" select="concat('../existSandBox/',$applicationId,'/systemConfiguration/',$specialtyId,'/forms/',$formId,'.xml')"/>

        <xsl:result-document href="{$filename}" format="xml">

            <xsl:call-template name="generateComposition">
                <xsl:with-param name="rootNode" select="$rootNode"/>
                <xsl:with-param name="compositionIRI" select="$formIRI"/>
                <xsl:with-param name="applicationIRI" select="$applicationIRI"/>
                <xsl:with-param name="specialtyIRI" select="$specialtyIRI"/>
            </xsl:call-template>

        </xsl:result-document>

    </xsl:template>


    <!-- === Letters === 
        ============================ -->

    <!-- Process all the letters declared in the ontology -->

    <xsl:template match="owl:Ontology/owl:ClassAssertion[owl:Class/@IRI='#CityEHR:Letter']/owl:NamedIndividual">
        <!-- Redirect output to file, based on the letter identity 
            Strip the leading # from IRIs and replace : with - to get unique ids -->
        <xsl:variable name="letterIRI" as="xs:string" select="./@IRI"/>
        <xsl:variable name="letterId" as="xs:string" select="replace(substring($letterIRI,2),':','-')"/>
        <xsl:variable name="filename" as="xs:string" select="concat('../existSandBox/',$applicationId,'/systemConfiguration/',$specialtyId,'/letters/',$letterId,'.xml')"/>

        <xsl:result-document href="{$filename}" format="xml">

            <xsl:call-template name="generateComposition">
                <xsl:with-param name="rootNode" select="$rootNode"/>
                <xsl:with-param name="compositionIRI" select="$letterIRI"/>
                <xsl:with-param name="applicationIRI" select="$applicationIRI"/>
                <xsl:with-param name="specialtyIRI" select="$specialtyIRI"/>
            </xsl:call-template>

        </xsl:result-document>
    </xsl:template>


    <!-- === Messages === 
        ============================ -->

    <!-- Process all the messages declared in the ontology -->

    <xsl:template match="owl:Ontology/owl:ClassAssertion[owl:Class/@IRI='#CityEHR:Message']/owl:NamedIndividual">
        <!-- Redirect output to file, based on the message identity 
             Strip the leading # from IRIs and replace : with - to get unique ids -->
        <xsl:variable name="messageIRI" as="xs:string" select="./@IRI"/>
        <xsl:variable name="messageId" as="xs:string" select="replace(substring($messageIRI,2),':','-')"/>
        <xsl:variable name="filename" as="xs:string" select="concat('../existSandBox/',$applicationId,'/systemConfiguration/',$specialtyId,'/messages/',$messageId,'.xml')"/>

        <xsl:result-document href="{$filename}" format="xml">

            <xsl:call-template name="generateComposition">
                <xsl:with-param name="rootNode" select="$rootNode"/>
                <xsl:with-param name="compositionIRI" select="$messageIRI"/>
                <xsl:with-param name="applicationIRI" select="$applicationIRI"/>
                <xsl:with-param name="specialtyIRI" select="$specialtyIRI"/>
            </xsl:call-template>

        </xsl:result-document>
    </xsl:template>


    <!-- === Orders === 
        ============================ -->

    <!-- Process all the orders declared in the ontology -->

    <xsl:template match="owl:Ontology/owl:ClassAssertion[owl:Class/@IRI='#CityEHR:Order']/owl:NamedIndividual">
        <!-- Redirect output to file, based on the message identity 
            Strip the leading # from IRIs and replace : with - to get unique ids -->
        <xsl:variable name="orderIRI" as="xs:string" select="./@IRI"/>
        <xsl:variable name="orderId" as="xs:string" select="replace(substring($orderIRI,2),':','-')"/>
        <xsl:variable name="filename" as="xs:string" select="concat('../existSandBox/',$applicationId,'/systemConfiguration/',$specialtyId,'/orders/',$orderId,'.xml')"/>

        <xsl:result-document href="{$filename}" format="xml">

            <xsl:call-template name="generateComposition">
                <xsl:with-param name="rootNode" select="$rootNode"/>
                <xsl:with-param name="compositionIRI" select="$orderIRI"/>
                <xsl:with-param name="applicationIRI" select="$applicationIRI"/>
                <xsl:with-param name="specialtyIRI" select="$specialtyIRI"/>
            </xsl:call-template>

        </xsl:result-document>
    </xsl:template>


    <!-- === Pathways === 
        ============================ -->

    <!-- Process all the pathways declared in the ontology -->

    <xsl:template match="owl:Ontology/owl:ClassAssertion[owl:Class/@IRI='#CityEHR:Pathway']/owl:NamedIndividual">
        <!-- Redirect output to file, based on the message identity 
            Strip the leading # from IRIs and replace : with - to get unique ids -->
        <xsl:variable name="pathwayIRI" as="xs:string" select="./@IRI"/>
        <xsl:variable name="pathwayId" as="xs:string" select="replace(substring($pathwayIRI,2),':','-')"/>
        <xsl:variable name="filename" as="xs:string" select="concat('../existSandBox/',$applicationId,'/systemConfiguration/',$specialtyId,'/pathways/',$pathwayId,'.xml')"/>

        <xsl:result-document href="{$filename}" format="xml">

            <xsl:call-template name="generateComposition">
                <xsl:with-param name="rootNode" select="$rootNode"/>
                <xsl:with-param name="compositionIRI" select="$pathwayIRI"/>
                <xsl:with-param name="applicationIRI" select="$applicationIRI"/>
                <xsl:with-param name="specialtyIRI" select="$specialtyIRI"/>
            </xsl:call-template>

        </xsl:result-document>
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
