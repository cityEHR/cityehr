<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    checkExpressions-Module.xsl
    Included as a module in checkExpressions.xsl and checkExpressions-File.xsl
    Expands all expressions used in an information model and returns a set of <expression> elements
    
    Used for checking expressions without genrating the full composition set for the model (so is much quicker)
       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>
    
    
    <!-- Include model utilities -->
    <xsl:include href="OWL2ModelUtilities.xsl"/>
    <xsl:include href="OWL2ModelExpressions.xsl"/>
   

    <!-- === Global Variables === -->

    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="//owl:Ontology"/>

    <!-- Set the Application for this ontology configuration -->
    <xsl:variable name="applicationIRI" as="xs:string"
        select="//owl:Ontology/owl:ClassAssertion[owl:Class/@IRI='#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="applicationId" as="xs:string" select="replace(substring($applicationIRI,2),':','-')"/>

    <!-- Set the Specialty for this ontology configuration -->
    <xsl:variable name="specialtyIRI" as="xs:string"
        select="if (count(//owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Folder']/owl:Class[1]/@IRI) = 1) then //owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Folder']/owl:Class[1]/@IRI else ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="specialtyId" as="xs:string" select="replace(substring($specialtyIRI,2),':','-')"/>

    <!-- Set the Class for this ontology configuration, if there is one -->
    <xsl:variable name="classIRI" as="xs:string"
        select="if (exists(//owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI)) then //owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI else ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="classId" as="xs:string" select="replace(substring($classIRI,2),':','-')"/>




    <!-- === Expressions are either conditions or calculations. ===
     They are assocaited with #ISO-13606:Section, #ISO-13606:Entry or #ISO-13606:Element and are represented in the ontology by assertions of the form:
     
     <DataPropertyAssertion>
        <DataProperty IRI="#hasConditions"/>
        <NamedIndividual IRI="#ISO-13606:Entry:gpdxaresults"/>
        <Literal xml:lang="en-gb" datatypeIRI="&amp;rdf;PlainLiteral">xs:string(dxa/dxadte)</Literal>
     </DataPropertyAssertion>
     
     The DataPropery IRIs for expresstions are:
     
     #hasCalculatedValue
     #hasConditions
     #hasConstraints
     #hasDefaultValue
     #hasPreConditions
       
-->

    <xsl:template
        match="owl:DataPropertyAssertion[owl:DataProperty/@IRI = ('#hasCalculatedValue','#hasConditions','#hasConstraints','#hasDefaultValue','#hasPreConditions')]">
        <xsl:variable name="context" select="owl:NamedIndividual/@IRI"/>
        <xsl:variable name="property" select="owl:DataProperty/@IRI"/>


        <xsl:variable name="expressionType" select="if ($property=('#hasConditions','#hasPreConditions')) then 'condition' else 'calculation'"/>

        <!-- contextEntryIRI  is blank for Section, and for Entry, except for PreConditions.
             For Element, is the containing EntryIRI, so need to find all Entries containing the Element and iterate through them. 
        
            <ObjectPropertyAssertion>
                <ObjectProperty IRI="#hasContent"/>
                <NamedIndividual IRI="#ISO-13606:Entry:gpletterencs"/>
                <NamedIndividual IRI="#ISO-13606:Element:gpletterencs"/>
            </ObjectPropertyAssertion>  
         -->
        <xsl:variable name="contextEntryIRISet"
            select="if (starts-with($context,'#ISO-13606:Element')) then ancestor::owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasContent'][owl:NamedIndividual[2]/@IRI=$context]/owl:NamedIndividual[1]/@IRI else ('')"/>

        <!-- contextContentIRI -->
        <xsl:variable name="contextContentIRI" select="$context"/>

        <!-- Form entries - just assume there are none for this exercise -->
        <xsl:variable name="formRecordedEntries" select="()"/>

        <xsl:variable name="evaluationContext" select="''"/>
        <xsl:variable name="expression" select="owl:Literal"/>

        <xsl:for-each select="$contextEntryIRISet">

            <!-- Expand the expression -->
            <xsl:variable name="contextEntryIRI" select="."/>
            <xsl:variable name="expression">
                <xsl:call-template name="expandExpression">
                    <xsl:with-param name="expressionType" select="$expressionType"/>
                    <xsl:with-param name="contextEntryIRI" select="$contextEntryIRI"/>
                    <xsl:with-param name="contextContentIRI" select="$contextContentIRI"/>
                    <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                    <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                    <xsl:with-param name="expression" select="$expression"/>
                </xsl:call-template>
            </xsl:variable>

            <!-- Check the expression for balanced ( ) " and ' 
                 Uses the character codepoints:
                 
                 ( 40
                 ) 41
                 " 34
                 ' 39
                 [ 91
                 ] 93
                -->
            <xsl:variable name="balanceCheck"
                select="(cityEHRFunction:checkBalance($expression,40,41,'bracket'),cityEHRFunction:checkBalance($expression,34,34,'doubleQuote'),cityEHRFunction:checkBalance($expression,39,39,'quote'),cityEHRFunction:checkBalance($expression,91,93,'squareBracket'))"/>
            <xsl:variable name="checkResults" select="string-join($balanceCheck[.!=''],' / ')"/>

            <expression context="{$context}" type="{$property}">
                <xsl:if test="$checkResults !=''">
                    <xsl:attribute name="error" select="$checkResults"/>
                </xsl:if>
                <xsl:value-of select="$expression"/>
            </expression>
        </xsl:for-each>
    </xsl:template>


</xsl:stylesheet>
