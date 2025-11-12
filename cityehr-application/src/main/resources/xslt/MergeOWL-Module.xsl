<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    MergeOWL-Module.xsl
    Included as a module in MergeOWL.xsl and MergeOWLFile.xsl
    
    Contains named templates used to copy and merge OWL ontologies.
    The master ontology for the merge is the standard document input to the transformation
    All assertions from the master ontology are copied through to the output
    The $merge input holds the ontology to be merged into the master
    Any assertions in $merge that are not in the master are added to the output
    
    When used with a common (bse) model, this is passed as the $merge
    
    Note the use of xsl:for-each-group which forms groups of elements matching the xpath in the @select
    grouped by the @group-by xpath. 
    The group is the a sequence of elements accessed by the current-group() function which returns the sequence of elements in the group
    
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

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- === Set global variables that are used in this module ========== 
         ================================================================ -->

    <!-- Set the root nodes.
        Use descendant axis so that aggregated ontologies can be used as input -->
    <xsl:variable name="rootNode" select="//owl:Ontology[1]"/>
    <xsl:variable name="mergeRootNode" select="$merge//owl:Ontology[1]"/>

    <xsl:variable name="testAssertion">
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasProperty"/>
            <NamedIndividual IRI="#TestIndividual#1"/>
            <NamedIndividual IRI="#TestIndividual#2"/>
        </ObjectPropertyAssertion>
    </xsl:variable>


    <!-- === 
        Generate merged cityEHR ontology        
        === -->
    <xsl:template name="generateMergedCityEHROWL">
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
        <Ontology xmlns:office2003Spreadsheet="urn:schemas-microsoft-com:office:spreadsheet"
            xmlns:x2="http://schemas.microsoft.com/office/excel/2003/xml"
            xmlns="http://www.w3.org/2002/07/owl#"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3"
            xmlns:owl="http://www.w3.org/2002/07/owl#"
            xmlns:x="urn:schemas-microsoft-com:office:excel"
            xmlns:c="urn:schemas-microsoft-com:office:component:spreadsheet"
            xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
            xmlns:html="http://www.w3.org/TR/REC-html40"
            xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
            xmlns:o="urn:schemas-microsoft-com:office:office"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
            xml:base="http://www.elevenllp.com/owl/2011/2/16/Ontology1300280377354.owl"
            ontologyIRI="http://www.elevenllp.com/owl/2011/2/16/Ontology1300280377354.owl">

            <xsl:if test="exists($rootNode) and exists($mergeRootNode)">
                <xsl:call-template name="copyOWLAssertions"/>
                <xsl:call-template name="mergeOWLAssertions"/>
            </xsl:if>

        </Ontology>

    </xsl:template>


    <!-- === Template to copy assertions in an OWL ontology ===
         rootNode is already set as the root owl:ontology element
         
         The assertions copied are:
         Prefix
         Annotation
         Declaration
         SubClassOf
         InverseObjectProperties
         SubDataPropertyOf
         ClassAssertion
         ObjectPropertyAssertion
         DataPropertyAssertion
         
         ====================================================== -->
    <xsl:template name="copyOWLAssertions">
        <xsl:copy-of select="$rootNode/owl:Prefix" copy-namespaces="no"/>
        <xsl:copy-of select="$rootNode/owl:Annotation" copy-namespaces="no"/>
        
        <xsl:copy-of select="$rootNode/owl:Declaration" copy-namespaces="no"/>
        <xsl:copy-of select="$rootNode/owl:SubClassOf" copy-namespaces="no"/>
        <xsl:copy-of select="$rootNode/owl:InverseObjectProperties" copy-namespaces="no"/>
        <xsl:copy-of select="$rootNode/owl:SubDataPropertyOf" copy-namespaces="no"/>

        <xsl:copy-of select="$rootNode/owl:ClassAssertion" copy-namespaces="no"/>
        <xsl:copy-of select="$rootNode/owl:ObjectPropertyAssertion" copy-namespaces="no"/>
        <xsl:copy-of select="$rootNode/owl:DataPropertyAssertion" copy-namespaces="no"/>
    </xsl:template>



    <!-- === Template to merge assertions in an OWL ontology ===
        
         The assertions merged are:
         
         Declaration
         SubClassOf
         InverseObjectProperties
         SubDataPropertyOf
         ClassAssertion
         ObjectPropertyAssertion
         DataPropertyAssertion
         
         Prefix *
         Annotation *
         Declaration
         SubClassOf
         InverseObjectProperties
         SubDataPropertyOf
         ClassAssertion
         ObjectPropertyAssertion
         DataPropertyAssertion
         
         Note that SubClassOf is not merged for sub classes of #CityEHR:Class or #ISO-13606:Folder
         These are the sub class declarations for the class and specialty (which are the only 'dynamic' sub classes used)
         
         These use xsl:for-each-group so that repeats are eliminated.
         ======================================================= -->
    <xsl:template name="mergeOWLAssertions">
        <!-- Declaration -->
        <xsl:for-each-group select="$mergeRootNode/owl:Declaration" group-by="*/@IRI">
            <xsl:if test="empty(key('DeclarationList', */@IRI, $rootNode))">
                <xsl:copy-of select="." copy-namespaces="no"/>
            </xsl:if>
        </xsl:for-each-group>

        <!-- SubClassOf
             Until 2021-11-20 Not merged for sub classes of #CityEHR:Class or #ISO-13606:Folder.
                <xsl:if test="not(owl:Class[2]/@IRI=('#CityEHR:Class','#ISO-13606:Folder'))">
             This was to stop ,ultiple declarations when specialty or class models are merged with the common model.
             But the duplicates are now removed after merging, so that the merge operation can be applied to any ontology -->
        <xsl:for-each-group select="$mergeRootNode/owl:SubClassOf" group-by="*[1]/@IRI">
            <xsl:for-each-group select="current-group()" group-by="*[2]/@IRI">
                <xsl:if test="empty(key('SubClassOfList', concat(*[1]/@IRI, *[2]/@IRI), $rootNode))">
                    <xsl:copy-of select="."/>
                </xsl:if>
            </xsl:for-each-group>
        </xsl:for-each-group>

        <!-- InverseObjectProperties -->
        <xsl:for-each-group select="$mergeRootNode/owl:InverseObjectProperties" group-by="*[1]/@IRI">
            <xsl:for-each-group select="current-group()" group-by="*[2]/@IRI">
                <xsl:if
                    test="empty(key('InverseObjectPropertiesList', concat(*[1]/@IRI, *[2]/@IRI), $rootNode))">
                    <xsl:copy-of select="." copy-namespaces="no"/>
                </xsl:if>
            </xsl:for-each-group>
        </xsl:for-each-group>

        <!-- SubDataPropertyOf -->
        <xsl:for-each-group select="$mergeRootNode/owl:SubDataPropertyOf" group-by="*[1]/@IRI">
            <xsl:for-each-group select="current-group()" group-by="*[2]/@IRI">
                <xsl:if
                    test="empty(key('SubDataPropertyOfList', concat(*[1]/@IRI, *[2]/@IRI), $rootNode))">
                    <xsl:copy-of select="." copy-namespaces="no"/>
                </xsl:if>
            </xsl:for-each-group>
        </xsl:for-each-group>

        <!-- ClassAssertion -->
        <xsl:for-each-group select="$mergeRootNode/owl:ClassAssertion" group-by="*[1]/@IRI">
            <xsl:for-each-group select="current-group()" group-by="*[2]/@IRI">
                <xsl:if
                    test="empty(key('ClassAssertionList', concat(*[1]/@IRI, *[2]/@IRI), $rootNode))">
                    <xsl:copy-of select="." copy-namespaces="no"/>
                </xsl:if>
            </xsl:for-each-group>
        </xsl:for-each-group>

        <!-- ObjectPropertyAssertion.
             There is only one object property assertion for most citEHR properties.
             Except hasData and hasContent (and their inverses isDataOf and isContnetOf, but these are not recorded)
        
            <ObjectPropertyAssertion>
                <ObjectProperty IRI="#hasData"/>
                <NamedIndividual IRI="#ISO-13606:Element:gender"/>
                <NamedIndividual IRI="#ISO-13606:Data:genderMale"/>
            </ObjectPropertyAssertion>
        
            <ObjectPropertyAssertion>
                <ObjectProperty IRI="#hasContent"/>
                <NamedIndividual IRI="#ISO-13606:Cluster:dischargedfromservice"/>
                <NamedIndividual IRI="#ISO-13606:Element:dischargecomment"/>
            </ObjectPropertyAssertion>
        -->
        <!-- This one means only one assertion is made for regular properties (not hasData or hasContent) -->
        <xsl:for-each-group
            select="$mergeRootNode/owl:ObjectPropertyAssertion[not(owl:ObjectProperty/@IRI = ('#hasContent', '#hasData'))]"
            group-by="*[1]/@IRI">
            <xsl:for-each-group select="current-group()" group-by="*[2]/@IRI">
                <xsl:if
                    test="empty(key('ObjectPropertyAssertionList', concat(*[1]/@IRI, *[2]/@IRI), $rootNode))">
                    <xsl:copy-of select="." copy-namespaces="no"/>
                </xsl:if>
            </xsl:for-each-group>
        </xsl:for-each-group>

        <!-- This one means that multiple assertions can be made for hasData or hasContent properties. -->
        <xsl:for-each-group
            select="$mergeRootNode/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI = ('#hasContent', '#hasData')]"
            group-by="*[1]/@IRI">
            <xsl:for-each-group select="current-group()" group-by="*[2]/@IRI">
                <xsl:for-each-group select="current-group()" group-by="*[3]/@IRI">
                    <xsl:if
                        test="empty(key('ObjectPropertyAssertionValue', concat(*[1]/@IRI, *[2]/@IRI, *[3]/@IRI), $rootNode))">
                        <xsl:copy-of select="." copy-namespaces="no"/>
                    </xsl:if>
                </xsl:for-each-group>
            </xsl:for-each-group>
        </xsl:for-each-group>


        <!-- DataPropertyAssertion -->
        <xsl:for-each-group select="$mergeRootNode/owl:DataPropertyAssertion" group-by="*[1]/@IRI">
            <xsl:for-each-group select="current-group()" group-by="*[2]/@IRI">
                <xsl:if
                    test="empty(key('DataPropertyAssertionList', concat(*[1]/@IRI, *[2]/@IRI), $rootNode))">
                    <xsl:copy-of select="." copy-namespaces="no"/>
                </xsl:if>
            </xsl:for-each-group>
        </xsl:for-each-group>

    </xsl:template>



</xsl:stylesheet>
