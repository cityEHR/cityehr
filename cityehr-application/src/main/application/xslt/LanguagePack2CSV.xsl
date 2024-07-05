<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    LanguagePack2CSV.xsl
    Input is a language pack for an information model, application parameters or system parameters, with assertions of the form:    
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

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <xsl:output method="text" omit-xml-declaration="yes" indent="no" name="text"/>

    <!-- === Variables === -->
    <xsl:variable name="root" select="/*"/>

    <!-- === Information model
         The language pack is an ontology with assertions of the form:
            
        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="#CityEHR:Term:TotalHipchangerperyearsincefirst3F"/>
            <Literal xml:lang="en-gb" datatypeIRI="&amp;rdf;PlainLiteral">Total Hip changer per year since first?</Literal>
        </DataPropertyAssertion>
    
        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="#CityEHR:Term:VertebralFracture"/>
            <Literal xml:lang="cmn-cn" datatypeIRI="&amp;rdf;PlainLiteral">椎骨骨折</Literal>
        </DataPropertyAssertion>
    
        The assertions are either in the base language (not translated) or the target language (translated)
    
        The base and target languages are specified by the assertions:
        
        hasBaseLanguage and
        hasLanguage
        
        The language pack also has assertions that define the application, specialty and class
        
         === -->

    <!-- Global variables for application, base language, language -->
    <xsl:variable name="applicationIRI" as="xs:string"
        select="
            if (exists(/owl:Ontology/owl:ClassAssertion[owl:Class/@IRI = '#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI)) then
                (/owl:Ontology/owl:ClassAssertion[owl:Class/@IRI = '#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI)[1]
            else
                ''"/>
    <xsl:variable name="baseLanguageCode" as="xs:string"
        select="
            if (exists(/owl:Ontology/owl:DataPropertyAssertion[owl:DataProperty/@IRI = '#hasBaseLanguage']/owl:Literal/@xml:lang)) then
                /owl:Ontology/owl:DataPropertyAssertion[owl:DataProperty/@IRI = '#hasBaseLanguage']/owl:Literal/@xml:lang
            else
                ''"/>
    <xsl:variable name="languageCode" as="xs:string"
        select="
            if (exists(/owl:Ontology/owl:DataPropertyAssertion[owl:DataProperty/@IRI = '#hasLanguage']/owl:Literal/@xml:lang)) then
                /owl:Ontology/owl:DataPropertyAssertion[owl:DataProperty/@IRI = '#hasLanguage']/owl:Literal/@xml:lang
            else
                ''"/>

    <!-- Information model language pack root -->
    <xsl:template match="owl:Ontology">
        <!-- Header record is application, base language, language, spacer, term -->
        <xsl:value-of select="string-join(($applicationIRI, $baseLanguageCode, $languageCode, ' - ', 'Term'), ',')"/>
        <xsl:value-of select="'&#xA;'"/>

        <xsl:apply-templates/>

    </xsl:template>

    <!-- Information model language pack base language term -->
    <xsl:template match="owl:DataPropertyAssertion[owl:DataProperty/@IRI = '#hasValue'][owl:Literal/@xml:lang = $baseLanguageCode]">
        <xsl:variable name="termIRI" as="xs:string" select="owl:NamedIndividual/@IRI"/>
        <xsl:variable name="baseLanguageTerm" as="xs:string" select="owl:Literal"/>
        <xsl:variable name="languageTerm" as="xs:string"
            select="
                if (exists(/owl:Ontology/owl:DataPropertyAssertion[owl:NamedIndividual/@IRI = $termIRI]/owl:Literal[@xml:lang = $languageCode])) then
                    /owl:Ontology/owl:DataPropertyAssertion[owl:NamedIndividual/@IRI = $termIRI]/owl:Literal[@xml:lang = $languageCode]
                else
                    ''"/>

        <!-- Quote the terms, in case they contain commas -->
        <xsl:value-of select="concat(' ,&#34;', $baseLanguageTerm, '&#34;,&#34;', $languageTerm, '&#34;, - ,', $termIRI)"/>
        <xsl:value-of select="'&#xA;'"/>

    </xsl:template>


    <!-- === Parameters
         The language pack has a dosument node of languagePack, with elements of the form:
         
        <term>
            <context path="parameters/patientRegistration/id"/>
            <variant code="en-gb" literal="Hospital Number"/>
            <variant code="cmn-cn" literal="医院编号"/>
        </term>
         
         === -->

    <!-- Paramsters language pack root -->
    <xsl:template match="languagePack">
        <xsl:value-of select="string-join(('Parameters', '2', '3'), ',')"/>
        <xsl:value-of select="'&#xA;'"/>
        <xsl:value-of select="string-join(('a', 'b', 'c'), ',')"/>
        <xsl:value-of select="'&#xA;'"/>
    </xsl:template>


    <!-- === Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
