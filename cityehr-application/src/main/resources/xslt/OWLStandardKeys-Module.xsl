<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWLStandardKeys-Module.xsl
    Included as a module in MergeOWL, etc
    Generates the XSLT keys for looking up elements in a standard OWL ontology
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<!-- === Summary of keys in standard OWL ontology 
     Keys are created for the following OWL assertions, using the IRIs from the assertion as look-up(s)
     
     Declaration
     SubClassOf
     InverseObjectProperties
     SubDataPropertyOf
     ClassAssertion
     ObjectPropertyAssertion
     DataPropertyAssertion
     
     All keys return the assertion element, except for DataPropertyAssertion which returns the Literal child element.

<Declaration>
    <Class IRI="#CityEHR:DataType"/>
</Declaration>

<SubClassOf>
    <Class IRI="#CityEHR:Form"/>
    <Class IRI="#ISO-13606:Composition"/>
</SubClassOf>

<InverseObjectProperties>
    <ObjectProperty IRI="#hasContent"/>
    <ObjectProperty IRI="#isContentOf"/>
</InverseObjectProperties>

<SubDataPropertyOf>
    <DataProperty IRI="#hasICD-10Code"/>
    <DataProperty IRI="#hasClinicalCode"/>
</SubDataPropertyOf>

<ClassAssertion>
    <Class IRI="#ISO-13606:EHR_Extract"/>
    <NamedIndividual IRI="#ISO-13606:EHR_Extract:cityEHR"/>
</ClassAssertion>

<ObjectPropertyAssertion>
    <ObjectProperty IRI="#hasDisplayName"/>
    <NamedIndividual IRI="#ISO-13606:EHR_Extract:cityEHR"/>
    <NamedIndividual IRI="#CityEHR:Term:CityEHR"/>
</ObjectPropertyAssertion>

<DataPropertyAssertion>
    <DataProperty IRI="#hasValue"/>
    <NamedIndividual IRI="#CityEHR:Term:CityEHR"/>
    <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">City EHR</Literal>
</DataPropertyAssertion>

-->


<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Key for Declaration
        <Declaration>
            <Class IRI="#CityEHR:DataType"/>
        </Declaration>
    -->
    <xsl:key name="DeclarationList" match="/owl:Ontology/owl:Declaration" use="*[1]/@IRI"/>
    
    <!-- Key for SubClassOf
        <SubClassOf>
            <Class IRI="#CityEHR:Form"/>
            <Class IRI="#ISO-13606:Composition"/>
        </SubClassOf>
    -->
    <xsl:key name="SubClassOfList" match="/owl:Ontology/owl:SubClassOf" use="concat(*[1]/@IRI,*[2]/@IRI)"/>
    
    <!-- Key for InverseObjectProperties
        <InverseObjectProperties>
            <ObjectProperty IRI="#hasContent"/>
            <ObjectProperty IRI="#isContentOf"/>
        </InverseObjectProperties>
    -->
    <xsl:key name="InverseObjectPropertiesList" match="/owl:Ontology/owl:InverseObjectProperties" use="concat(*[1]/@IRI,*[2]/@IRI)"/>
    
    <!-- Key for SubDataPropertyOf
        <SubDataPropertyOf>
            <DataProperty IRI="#hasICD-10Code"/>
            <DataProperty IRI="#hasClinicalCode"/>
        </SubDataPropertyOf>
    -->
    <xsl:key name="SubDataPropertyOfList" match="/owl:Ontology/owl:SubDataPropertyOf" use="concat(*[1]/@IRI,*[2]/@IRI)"/>
    
    <!-- Key for ClassAssertion
        <ClassAssertion>
            <Class IRI="#ISO-13606:EHR_Extract"/>
            <NamedIndividual IRI="#ISO-13606:EHR_Extract:cityEHR"/>
        </ClassAssertion>
    -->
    <xsl:key name="ClassAssertionList" match="/owl:Ontology/owl:ClassAssertion" use="concat(*[1]/@IRI,*[2]/@IRI)"/>
    
    <!-- Key for ObjectPropertyAssertion
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasDisplayName"/>
            <NamedIndividual IRI="#ISO-13606:EHR_Extract:cityEHR"/>
            <NamedIndividual IRI="#CityEHR:Term:CityEHR"/>
        </ObjectPropertyAssertion>
    -->
    <xsl:key name="ObjectPropertyAssertionList" match="/owl:Ontology/owl:ObjectPropertyAssertion" use="concat(*[1]/@IRI,*[2]/@IRI,*[3]/@IRI)"/>
    
    <!-- Key for DataPropertyAssertion
        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="#CityEHR:Term:RODNAN"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">RODNAN</Literal>
        </DataPropertyAssertion>
    -->
    <xsl:key name="DataPropertyAssertionList" match="/owl:Ontology/owl:DataPropertyAssertion/owl:Literal" use="concat(../*[1]/@IRI,../*[2]/@IRI)"/>

</xsl:stylesheet>
