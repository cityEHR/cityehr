<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    extractLanguagePackOWL-Module.xsl
    Included as a module in extractLanguagePackOWL.xsl and extractLanguagePackOWLFile.xsl
    
    Contains named templates used to extract the language pack from an OWL ontology model (class or specialty).
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<!DOCTYPE stylesheet [
<!ENTITY rdf 
"&amp;rdf;">
]>

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:cda="urn:hl7-org:v3"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:c="urn:schemas-microsoft-com:office:component:spreadsheet"
    xmlns:html="http://www.w3.org/TR/REC-html40" xmlns:o="urn:schemas-microsoft-com:office:office"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:office2003Spreadsheet="urn:schemas-microsoft-com:office:spreadsheet"
    xmlns:x2="http://schemas.microsoft.com/office/excel/2003/xml"
    xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
    xmlns:x="urn:schemas-microsoft-com:office:excel"
    xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:xml="http://www.w3.org/XML/1998/namespace">

    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- === Set global variables that are used in this module ========== 
    ================================================================ -->

    <xsl:variable name="cityEHRlanguagePack"
        select="document('../resources/templates/cityEHRlanguagePack.xml')"/>
    
    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="/owl:Ontology"/>
    
    <!-- Set the Application for this ontology configuration -->
    <xsl:variable name="applicationIRI" as="xs:string" select="/owl:Ontology/owl:ClassAssertion[owl:Class/@IRI='#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="applicationId" as="xs:string" select="replace(substring($applicationIRI,2),':','-')"/>
    
    <!-- Set the Specialty for this ontology configuration -->
    <xsl:variable name="specialtyIRI" as="xs:string"
        select="/owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Folder']/owl:Class[1]/@IRI[1]"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="specialtyId" as="xs:string" select="replace(substring($specialtyIRI,2),':','-')"/>
    
    <!-- Set the Class for this ontology configuration, if there is one -->
    <xsl:variable name="classIRI" as="xs:string" select="if (exists(/owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI)) then /owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI else ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="classId" as="xs:string" select="replace(substring($classIRI,2),':','-')"/>
    
    <!-- Set the base language for this ontology -->
    <xsl:variable name="baseLanguageCode" as="xs:string" select="/owl:Ontology/owl:DataPropertyAssertion[owl:DataProperty/@IRI='#hasBaseLanguage'][1]/owl:Literal"/>
    

    <!-- === 
        Generate language pack from ontology        
        === -->
    <xsl:template name="generateLanguagePackOWL">
        <!-- Output the DOCTYPE and document type declaration subset with entity definitions -->
        <!--
        <xsl:text disable-output-escaping="yes"><![CDATA[
            <!DOCTYPE Ontology [
            <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#" >
            <!ENTITY xml "http://www.w3.org/XML/1998/namespace" >
            <!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#" >
            <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
            ]> 
            ]]></xsl:text>
        -->
        <Ontology xmlns="http://www.w3.org/2002/07/owl#">
            <!-- Copy attributes (including namespace declarations) from root node template -->
            <xsl:copy-of select="$cityEHRlanguagePack/@*"/>

            <!-- Copy core assertions from template.
                 The template includes some assertions with variables that are to be instantiated when a new language pack is created.
                 Variables (for application, specialty and class) are denoted as $applicationIRI, $specialtyIRI and $classIRI
                 These are not needed in this extract process, so are not copied-->
            <xsl:copy-of select="$cityEHRlanguagePack/owl:Ontology/*[not(*/@IRI[starts-with(.,'$')])]"/>

            <!-- Copy assertions for application, specialty and class (if present) from the ontology -->
            <xsl:call-template name="copyOWLBaseAssertions"/>

            <!-- Copy language-specific assertions from the ontology -->
            <xsl:call-template name="copyOWLAssertions"/>

        </Ontology>

    </xsl:template>



    <!-- === Template to copy base assertions in the OWL ontology ===
             
             These define the application and specialty
             Plus the class (if a class model)
             
             rootNode is already set as the root owl:ontology element
                
        ====================================================== -->
    <xsl:template name="copyOWLBaseAssertions">

        <!-- Application -->
        <xsl:copy-of select="$rootNode/owl:Declaration[owl:NamedIndividual/@IRI=$applicationIRI]"/>
        <xsl:copy-of select="$rootNode/owl:ClassAssertion[owl:NamedIndividual/@IRI=$applicationIRI]"/>

        <!-- Specialty -->
        <xsl:copy-of select="$rootNode/owl:Declaration[owl:NamedIndividual/@IRI=$specialtyIRI]"/>
        <xsl:copy-of
            select="$rootNode/owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Folder']"/>

        <!-- Class -->
        <xsl:if test="$classIRI">
            <xsl:copy-of select="$rootNode/owl:Declaration[owl:NamedIndividual/@IRI=$classIRI]"/>
            <xsl:copy-of
                select="$rootNode/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']"/>
        </xsl:if>

        <!-- Language.
             This assertion is used to specify the language of the languagePack.
             Note that the base language of the model is defined by the hasBaseLanguage data property
             But the language of the language pack is defined by #hasLanguage -->
        <owl:DataPropertyAssertion>
            <owl:DataProperty IRI="#hasLanguage"/>
            <owl:NamedIndividual IRI="{$applicationIRI}"/>
            <owl:Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral">
                <xsl:value-of select="$baseLanguageCode"/>
            </owl:Literal>
        </owl:DataPropertyAssertion>

    </xsl:template>


    <!-- === Template to copy assertions in the OWL ontology ===
             rootNode is already set as the root owl:ontology element
             Language pack is made up of DataPropertyAssertion of the form:
             
             <DataPropertyAssertion>
                <DataProperty IRI="#hasValue"/>
                <NamedIndividual IRI="#CityEHR:Term:ImportAssessmentandFracture"/>
                <Literal xml:lang="en-gb" datatypeIRI="rdf:PlainLiteral">Import Assessment and Fracture</Literal>
             </DataPropertyAssertion>
         
            Only copy assertions os hasValue for #CityEHR:Term
         ====================================================== -->
    <xsl:template name="copyOWLAssertions">
        <!-- DataPropertyAssertion -->
        <xsl:for-each
            select="$rootNode/owl:DataPropertyAssertion[owl:DataProperty/@IRI='#hasValue'][starts-with(owl:NamedIndividual/@IRI,'#CityEHR:Term')][owl:Literal/@xml:lang]">
            <xsl:variable name="dataPropertyAssertion" select="."/>

            <owl:DataPropertyAssertion>
                <xsl:copy-of select="$dataPropertyAssertion/owl:DataProperty"/>
                <xsl:copy-of select="$dataPropertyAssertion/owl:NamedIndividual"/>
                <owl:Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="$dataPropertyAssertion/owl:Literal"/>
                </owl:Literal>
            </owl:DataPropertyAssertion>
        </xsl:for-each>

    </xsl:template>



</xsl:stylesheet>
