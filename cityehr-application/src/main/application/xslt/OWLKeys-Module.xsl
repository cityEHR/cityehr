<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWLKeys-Module.xsl
    Included as a module in OWL2DataDictionary, OWL2Runtime.xsl, OWL2Composition.xsl, etc
    Generates the XSLT keys for looking up elements in an OWL ontology
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Keys for ClassAssertion
        <ClassAssertion>
            <Class IRI="#CityEHR:Form"/>
            <NamedIndividual IRI="#CityEHR:Form:Fractures"/>
        </ClassAssertion>
        
        individualIRIList returns IRIs of individuals in matched class (usually more than one)
        classIRIList returns IRI of class for matched individual (should only be one)
    -->
    <xsl:key name="individualIRIList" match="//owl:Ontology/owl:ClassAssertion/owl:NamedIndividual/@IRI" use="../../owl:Class/@IRI"/>
    <xsl:key name="classIRIList" match="//owl:Ontology/owl:ClassAssertion/owl:Class/@IRI" use="../../owl:NamedIndividual/@IRI"/>

    <!-- Key for DisplayName (Term) IRI
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasDisplayName"/>
            <NamedIndividual IRI="#CityEHR:Order:Radiology"/>
            <NamedIndividual IRI="#CityEHR:Term:Radiological%20Examinations"/>
        </ObjectPropertyAssertion>
        
        termIRIList returns IRI of term that is displayName for matched individual
    -->
    <xsl:key name="termIRIList" match="//owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasDisplayName']/owl:NamedIndividual[2]/@IRI" use="../../owl:NamedIndividual[1]/@IRI"/>

    <!-- Key for Term value (displayName string)
        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="#CityEHR:Term:Radiological%20Examinations"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">Radiological Examinations</Literal>
        </DataPropertyAssertion>
        
        termDisplayNameList retruns the string displayName for the matched individual (which is a term)
    -->
    <xsl:key name="termDisplayNameList" match="//owl:Ontology/owl:DataPropertyAssertion[owl:DataProperty/@IRI='#hasValue']/owl:Literal" use="../owl:NamedIndividual/@IRI"/>


    <!-- Key for component contents
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasContent"/>
            <NamedIndividual IRI="#CityEHR:Order:Pathology"/>
            <NamedIndividual IRI="#ISO-13606:Section:PathologyTest"/>
        </ObjectPropertyAssertion>
    -->
    <xsl:key name="contentsIRIList" match="//owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasContent']/owl:NamedIndividual[2]/@IRI" use="../../owl:NamedIndividual[1]/@IRI"/>


    <!-- Key for  class types (i.e. child nodes)
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasType"/>
            <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Bonedisorders"/>
            <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Osteomalaciarickets"/>
        </ObjectPropertyAssertion>
    -->
    <xsl:key name="typeIRIList" match="//owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasType']/owl:NamedIndividual[2]/@IRI" use="../../owl:NamedIndividual[1]/@IRI"/>
    

    <!-- Key for searchable entry.
         This one is a bit different - only add to the list if the #CityEHR:EntryProperty:Searchable is set
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasCohortSearch"/>
            <NamedIndividual IRI="#ISO-13606:Entry:Age"/>
            <NamedIndividual IRI="#CityEHR:EntryProperty:NotSearchable"/>
        </ObjectPropertyAssertion>
    -->
    <!-- Not needed any more - use specifiedObjectPropertyList since using PrimarySearch 29/01/2014
    <xsl:key name="searchableEntryIRIList" match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasCohortSearch']/owl:NamedIndividual[2][@IRI='#CityEHR:EntryProperty:Searchable']" use="../owl:NamedIndividual[1]/@IRI"/>
    -->
    
  
    <!-- Key for Element datatype
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasDataType"/>
            <NamedIndividual IRI="#ISO-13606:Element:Boolean"/>
            <NamedIndividual IRI="#CityEHR:DataType:boolean"/>
        </ObjectPropertyAssertion>
    -->
    <!--
    <xsl:key name="elementDataTypeIRIList" match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasDataType']/owl:NamedIndividual[2]/@IRI" use="../../owl:NamedIndividual[1]/@IRI"/>
-->
    <!-- Key for Element type
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasElementType"/>
            <NamedIndividual IRI="#ISO-13606:Element:Boolean"/>
            <NamedIndividual IRI="#CityEHR:ElementProperty:simpleType"/>
        </ObjectPropertyAssertion>
    -->
    <!--
    <xsl:key name="elementTypeIRIList" match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasElementType']/owl:NamedIndividual[2]/@IRI" use="../../owl:NamedIndividual[1]/@IRI"/>
    -->
    
    <!-- Key for Data value
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasData"/>
            <NamedIndividual IRI="{$elementIRI}"/>
            <NamedIndividual IRI="{$elementDataIRI}"/>
        </ObjectPropertyAssertion>
        -->
    <xsl:key name="dataValueIRIList" match="//owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasData']/owl:NamedIndividual[2]/@IRI" use="../../owl:NamedIndividual[1]/@IRI"/>


    <!-- Key for any DataProperty
        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="#CityEHR:Term:Radiological%20Examinations"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">Radiological Examinations</Literal>
        </DataPropertyAssertion>
        
        dataPropertyList retruns the IRIs for the DataProperty that are held matched individual
    -->
    <xsl:key name="dataPropertyList" match="//owl:Ontology/owl:DataPropertyAssertion/owl:Literal" use="../owl:DataProperty/@IRI"/>
    

    <!-- Key for specified ObjectProperty
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasDataType"/>
            <NamedIndividual IRI="#ISO-13606:Element:Boolean"/>
            <NamedIndividual IRI="#CityEHR:DataType:boolean"/>
        </ObjectPropertyAssertion>
        
        specifiedObjectPropertyList returns the IRI for the specified property of the matched individual
    -->
    <xsl:key name="specifiedObjectPropertyList" match="//owl:Ontology/owl:ObjectPropertyAssertion/owl:NamedIndividual[2]/@IRI" use="concat(../../owl:ObjectProperty/@IRI,../../owl:NamedIndividual[1]/@IRI)"/>
    

    <!-- Key for specified DataProperty
        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="#CityEHR:Term:Radiological%20Examinations"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">Radiological Examinations</Literal>
        </DataPropertyAssertion>
        
        specifiedDataPropertyList returns the string Literal for the specicifed property of the matched individual
    -->
    <xsl:key name="specifiedDataPropertyList" match="//owl:Ontology/owl:DataPropertyAssertion/owl:Literal" use="concat(../owl:DataProperty/@IRI,../owl:NamedIndividual/@IRI)"/>
    
    
    <!-- Key for sections in a composition
         dataPropertyList retruns the IRIs for the DataProperty that are held matched individual
    -->
    <xsl:key name="compositionSections" match="//owl:Ontology/owl:DataPropertyAssertion/owl:Literal" use="../owl:DataProperty/@IRI"/>
    
</xsl:stylesheet>
