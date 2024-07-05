<!-- ====================================================================
    OWL2DataDictionary-Module.xsl
    Module to convert OWL to CityEHR Data Dictionary
    Pulled in from main stylesheets for conversion of a full ontology
    
    Create the dictionary for the specified application/specialty set in the variables:
    
    applicationIRI
    specialtyIRI
 
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

    <!-- Set up the XSLT keys for the OWL ontology -->
    <xsl:include href="OWLKeys-Module.xsl"/>

    <!-- General utilities -->
    <xsl:include href="OWL2ModelUtilities.xsl"/>

    <!-- === Global Variables === 
         ======================== -->
    <!-- Set the root node (the instance may be wrapped in a container element, so this finds the ontology root) -->
    <xsl:variable name="rootNode" select="//owl:Ontology"/>

    <!-- Set the Application for this ontology configuration.
        Use the first one found, in case the ontology has more than one application declared. -->
    <xsl:variable name="applicationIRI" as="xs:string"
        select="
            if (exists($rootNode/owl:ClassAssertion[owl:Class/@IRI = '#ISO-13606:EHR_Extract'][1]/owl:NamedIndividual/@IRI)) then
                $rootNode/owl:ClassAssertion[owl:Class/@IRI = '#ISO-13606:EHR_Extract'][1]/owl:NamedIndividual/@IRI
            else
                ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="applicationId" as="xs:string" select="replace(substring($applicationIRI, 2), ':', '-')"/>

    <!-- Set the Specialty for this ontology configuration -->
    <xsl:variable name="specialtyIRI" as="xs:string"
        select="
            if (exists($rootNode/owl:SubClassOf[owl:Class[2]/@IRI = '#ISO-13606:Folder']/owl:Class[1]/@IRI[1])) then
                $rootNode/owl:SubClassOf[owl:Class[2]/@IRI = '#ISO-13606:Folder']/owl:Class[1]/@IRI[1]
            else
                ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="specialtyId" as="xs:string" select="replace(substring($specialtyIRI, 2), ':', '-')"/>

    <!-- Set the type of dictionary - class or specialty -->
    <xsl:variable name="informationModelType"
        select="
            if (exists($rootNode/owl:SubClassOf[owl:Class[2]/@IRI = '#CityEHR:Class']/owl:Class[1]/@IRI)) then
                'Class'
            else
                'Specialty'"/>

    <!-- Set the Class for this ontology (if there is one, otherwise its a specialty ontology) -->
    <xsl:variable name="classIRI" as="xs:string"
        select="
            if ($informationModelType = 'Class') then
                $rootNode/owl:SubClassOf[owl:Class[2]/@IRI = '#CityEHR:Class']/owl:Class[1]/@IRI
            else
                ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="classId" as="xs:string"
        select="
            if ($classIRI != '') then
                replace(substring($classIRI, 2), ':', '-')
            else
                ''"/>


    <!-- === Create the data dictionary 
        The EHR_Extract is for the specified Specialty, with specialtyIRI and displayName
        The information model may also contain one or more class hierarchies
        === -->

    <xsl:template name="generateDataDictionary">
        <xsl:param name="rootNode"/>
        <xsl:param name="applicationIRI"/>
        <xsl:param name="specialtyIRI"/>
        <xsl:param name="classIRI"/>

        <!-- Check that parameters are set - if not, then something is wrong -->
        <xsl:variable name="status" as="xs:string"
            select="
                if (exists($rootNode) and $applicationIRI != '' and $specialtyIRI != '') then
                    'ok'
                else
                    'error'"/>

        <!-- Something wrong, so don't generate dictionary -->
        <xsl:if test="$status = 'error'">
            <EHR_Extract xmlns="http://www.iso.org/iso-13606" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" code="#CityEHR:Error"
                codeSystem="cityEHR" displayName="Failed to generate dictionary"/>
        </xsl:if>

        <!-- Good to generate dictionary -->
        <xsl:if test="$status = 'ok'">

            <!-- Get specialty displayName -->
            <xsl:variable name="specialtyDisplayNameTermIRI" as="xs:string"
                select="
                    if (exists(key('termIRIList', $specialtyIRI))) then
                        key('termIRIList', $specialtyIRI)[1]
                    else
                        ''"/>
            <xsl:variable name="specialtyDisplayNameTerm" as="xs:string"
                select="
                    if (exists(key('termDisplayNameList', $specialtyDisplayNameTermIRI))) then
                        key('termDisplayNameList', $specialtyDisplayNameTermIRI)[1]
                    else
                        ''"/>

            <EHR_Extract xmlns="http://www.iso.org/iso-13606" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" code="{$specialtyIRI}"
                commonModelCode="" codeSystem="cityEHR" displayName="{$specialtyDisplayNameTerm}">

                <!-- === 
                 Generate the contents for every folder in the model.
                 === -->

                <folderCollection>
                    <!-- == First generate the contents of the specialty folder.
                        This is all the compositions in the model:
                        
                        Views
                        Forms
                        Messages
                        Orders
                        Pathways
                        
                        <SubClassOf>
                            <Class IRI="#CityEHR:Form"/>
                            <Class IRI="#ISO-13606:Composition"/>
                        </SubClassOf>
                        
                        <ClassAssertion>
                            <Class IRI="#CityEHR:Form"/>
                            <NamedIndividual IRI="#CityEHR:Form:Fractures"/>
                        </ClassAssertion>
                        
                        For views, also output the set of compositions it contains and the type of the view.
                        == -->

                    <folder code="{$specialtyIRI}" codeSystem="cityEHR" displayName="{$specialtyDisplayNameTerm}">

                        <xsl:for-each select="//owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI = '#ISO-13606:Composition']/owl:Class[1]/@IRI">
                            <xsl:variable name="compositionTypeIRI" as="xs:string" select="."/>

                            <xsl:for-each select="key('individualIRIList', $compositionTypeIRI)">
                                <xsl:variable name="compositionIRI" as="xs:string" select="."/>
                                <xsl:variable name="compositionDisplayNameTermIRI" as="xs:string"
                                    select="
                                        if (exists(key('termIRIList', $compositionIRI))) then
                                            key('termIRIList', $compositionIRI)[1]
                                        else
                                            ''"/>
                                <xsl:variable name="compositionDisplayNameTerm" as="xs:string"
                                    select="
                                        if (exists(key('termDisplayNameList', $compositionDisplayNameTermIRI))) then
                                            key('termDisplayNameList', $compositionDisplayNameTermIRI)[1]
                                        else
                                            ''"/>

                                <!-- Get all the sections in this composition -->
                                <xsl:variable name="allFormSections" select="cityEHRFunction:getFormSections($rootNode, $compositionIRI)"/>
                                <xsl:variable name="formSections" select="distinct-values($allFormSections)"/>

                                <!-- Get all the entries on this form -->
                                <xsl:variable name="allFormEntries" select="cityEHRFunction:getFormEntries($rootNode, $formSections)"/>
                                <xsl:variable name="formEntries" select="distinct-values($allFormEntries)"/>


                                <!-- Get data property for #hasRank -->
                                <xsl:variable name="compositionRank" as="xs:string"
                                    select="
                                        if (exists(key('specifiedDataPropertyList', concat('#hasRank', $compositionIRI), $rootNode))) then
                                            key('specifiedDataPropertyList', concat('#hasRank', $compositionIRI), $rootNode)
                                        else
                                            '0'"/>

                                <composition typeId="{$compositionTypeIRI}" code="{$compositionIRI}" codeSystem="cityEHR"
                                    displayName="{$compositionDisplayNameTerm}" cityEHR:rank="{$compositionRank}">
                                    <!-- If the composition is a view then add attribute to specify its type and list the compositions it contains -->
                                    <xsl:if test="$compositionTypeIRI = '#CityEHR:View'">
                                        <!-- In V1 viewType is in the dataProperty hasType in V2 is in the objectProperty hasViewType -->
                                        <xsl:variable name="viewTypeDataProperty" as="xs:string"
                                            select="
                                                if (exists(key('specifiedDataPropertyList', concat('#hasType', $compositionIRI), $rootNode))) then
                                                    key('specifiedDataPropertyList', concat('#hasType', $compositionIRI), $rootNode)
                                                else
                                                    ''"/>
                                        <xsl:variable name="viewTypeObjectProperty" as="xs:string"
                                            select="cityEHRFunction:getObjectPropertyValue($rootNode, $compositionIRI, 'EntryProperty', '#hasViewType')"/>
                                        <xsl:variable name="viewTypeObjectPropertyValue" as="xs:string"
                                            select="tokenize($viewTypeObjectProperty, ':')[last()]"/>

                                        <xsl:variable name="viewType" as="xs:string"
                                            select="
                                                if ($viewTypeDataProperty != '') then
                                                    $viewTypeDataProperty
                                                else
                                                    $viewTypeObjectPropertyValue"/>
                                        <xsl:attribute name="cityEHR:viewType">
                                            <xsl:value-of select="$viewType"/>
                                        </xsl:attribute>
                                        <xsl:for-each select="key('contentsIRIList', $compositionIRI)">
                                            <xsl:variable name="viewCompositionIRI" as="xs:string" select="."/>
                                            <composition>
                                                <xsl:value-of select="$viewCompositionIRI"/>
                                            </composition>
                                        </xsl:for-each>
                                    </xsl:if>

                                    <!-- If the composition is not a view then list the entries it contains.
                                         These are used when checking for alerts -->
                                    <xsl:if test="$compositionTypeIRI != '#CityEHR:View'">

                                        <xsl:for-each select="$formEntries">
                                            <xsl:variable name="entryIRI" as="xs:string" select="."/>
                                            <entry>
                                                <xsl:value-of select="$entryIRI"/>
                                            </entry>
                                        </xsl:for-each>
                                    </xsl:if>
                                </composition>
                            </xsl:for-each>

                        </xsl:for-each>

                    </folder>


                    <!-- === Iterate through folders, if there are any
                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasContent"/>
                            <NamedIndividual IRI="#ISO-13606:EHR_Extract:Base"/>
                            <NamedIndividual IRI="#ISO-13606:Folder:FeatureDemo"/>
                        </ObjectPropertyAssertion>
                        
                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasContent"/>
                            <NamedIndividual IRI="#ISO-13606:Folder:FeatureDemo"/>
                            <NamedIndividual IRI="#ISO-13606:Folder:Administration"/>
                        </ObjectPropertyAssertion>
                        
                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasDisplayName"/>
                            <NamedIndividual IRI="#ISO-13606:Folder:Administration"/>
                            <NamedIndividual IRI="#CityEHR:Term:Patient%20Administration"/>
                        </ObjectPropertyAssertion>
                        === -->
                    <xsl:if test="exists(key('contentsIRIList', $specialtyIRI))">

                        <xsl:for-each select="key('contentsIRIList', $specialtyIRI)">
                            <xsl:variable name="folderIRI" as="xs:string" select="."/>

                            <xsl:variable name="folderDisplayNameTermIRI" as="xs:string"
                                select="
                                    if (exists(key('termIRIList', $folderIRI))) then
                                        key('termIRIList', $folderIRI)[1]
                                    else
                                        ''"/>
                            <xsl:variable name="folderDisplayNameTerm" as="xs:string"
                                select="
                                    if (exists(key('termDisplayNameList', $folderDisplayNameTermIRI))) then
                                        key('termDisplayNameList', $folderDisplayNameTermIRI)[1]
                                    else
                                        ''"/>

                            <folder code="{$folderIRI}" codeSystem="cityEHR" displayName="{$folderDisplayNameTerm}">

                                <!-- Iterate through compositions in this folder (can be forms or views)
                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasContent"/>
                            <NamedIndividual IRI="#ISO-13606:Folder:Administration"/>
                            <NamedIndividual IRI="#CityEHR:Form:BaseRegistration"/>
                         </ObjectPropertyAssertion> -->
                                <xsl:for-each select="key('contentsIRIList', $folderIRI)">
                                    <xsl:variable name="compositionIRI" as="xs:string" select="."/>
                                    <xsl:variable name="compositionTypeIRI" as="xs:string"
                                        select="
                                            if (exists(key('classIRIList', $compositionIRI))) then
                                                key('classIRIList', $compositionIRI)[1]
                                            else
                                                ''"/>

                                    <xsl:variable name="compositionDisplayNameTermIRI" as="xs:string"
                                        select="
                                            if (exists(key('termIRIList', $compositionIRI))) then
                                                key('termIRIList', $compositionIRI)[1]
                                            else
                                                ''"/>
                                    <xsl:variable name="compositionDisplayNameTerm" as="xs:string"
                                        select="
                                            if (exists(key('termDisplayNameList', $compositionDisplayNameTermIRI))) then
                                                key('termDisplayNameList', $compositionDisplayNameTermIRI)[1]
                                            else
                                                ''"/>

                                    <!-- Get data property for #hasRank -->
                                    <xsl:variable name="compositionRank" as="xs:string"
                                        select="
                                            if (exists(key('specifiedDataPropertyList', concat('#hasRank', $compositionIRI), $rootNode))) then
                                                key('specifiedDataPropertyList', concat('#hasRank', $compositionIRI), $rootNode)
                                            else
                                                '0'"/>

                                    <composition typeId="{$compositionTypeIRI}" code="{$compositionIRI}" codeSystem="cityEHR"
                                        displayName="{$compositionDisplayNameTerm}" cityEHR:rank="{$compositionRank}"/>
                                </xsl:for-each>
                            </folder>
                        </xsl:for-each>
                    </xsl:if>
                </folderCollection>


                <!-- Iterate through entries, if there are any.
                
                Until 2019-02-13
                Entry classes are sub-classes of #ISO-13606:Entry, which should be (be don't assume)
                #HL7-CDA:Act
                #HL7-CDA:Encounter
                #HL7-CDA:Observation
                #HL7-CDA:Procedure
                #HL7-CDA:RegionOfInterest
                #HL7-CDA:SubstanceAdministration
                #HL7-CDA:Supply
                
                <Declaration>
                    <Class IRI="#HL7-CDA:Observation"/>
                </Declaration>
                
                <SubClassOf>
                    <Class IRI="#HL7-CDA:Observation"/>
                    <Class IRI="#ISO-13606:Entry"/>
                </SubClassOf>
                
                <ClassAssertion>
                <Class IRI="#HL7-CDA:Observation"/>
                    <NamedIndividual IRI="#ISO-13606:Entry:NHSNumber"/>
                </ClassAssertion>
                <ObjectPropertyAssertion>
                    <ObjectProperty IRI="#hasDisplayName"/>
                    <NamedIndividual IRI="#ISO-13606:Entry:NHSNumber"/>
                    <NamedIndividual IRI="#CityEHR:Term:NHS%20number"/>
                </ObjectPropertyAssertion>
                
                From 2019-02-13, there is just #ISO-13606:Entry, with #hasEntryType
                
                <ObjectPropertyAssertion>
                    <ObjectProperty IRI="#hasEntryType"/>
                    <NamedIndividual IRI="#ISO-13606:Entry:Demographics"/>
                    <NamedIndividual IRI="#CityEHR:Property:EntryType:Observation"/>
                </ObjectPropertyAssertion>
            -->

                <entryCollection>
                    <!-- Before 2019-02-13 Iterate through entry sub-classes.
                         Could be done if the data dictionary needed to contain all entries.
                         Currently only observations are needed. 
                
                         The structure of each CDA entry type is different, so would need different output XML for each CDA entry type 
                    
                        After 2019-02-13 just use #ISO-13606:Entry
                    -->

                    <xsl:variable name="entryClassIRI"
                        select="
                            if (exists($rootNode/owl:Declaration[owl:Class/@IRI = '#HL7-CDA:Observation'])) then
                                '#HL7-CDA:Observation'
                            else
                                '#ISO-13606:Entry'"/>

                    <!-- Iterate through each entry for the class -->
                    <xsl:for-each select="key('individualIRIList', $entryClassIRI)">
                        <xsl:variable name="entryIRI" as="xs:string" select="."/>

                        <xsl:variable name="entryDisplayNameTermIRI" as="xs:string"
                            select="
                                if (exists(key('termIRIList', $entryIRI))) then
                                    key('termIRIList', $entryIRI)[1]
                                else
                                    ''"/>
                        <xsl:variable name="entryDisplayNameTerm" as="xs:string"
                            select="
                                if (exists(key('termDisplayNameList', $entryDisplayNameTermIRI))) then
                                    key('termDisplayNameList', $entryDisplayNameTermIRI)[1]
                                else
                                    ''"/>

                        <!-- Get property for #hasCohortSearch -->
                        <!--
                        <xsl:variable name="cohortSearch" as="xs:string"
                            select="if (exists(key('specifiedObjectPropertyList',concat('#hasCohortSearch',$entryIRI),$rootNode))) then key('specifiedObjectPropertyList',concat('#hasCohortSearch',$entryIRI),$rootNode)[1] else ''"/>
 -->
                        <xsl:variable name="cohortSearch" as="xs:string"
                            select="cityEHRFunction:getObjectPropertyValue($rootNode, $entryIRI, 'EntryProperty', '#hasCohortSearch')"/>

                        <!-- Get property for #hasRendition -->
                        <!--
                        <xsl:variable name="entryRendition" as="xs:string"
                            select="if (exists(key('specifiedObjectPropertyList',concat('#hasRendition',$entryIRI),$rootNode))) then key('specifiedObjectPropertyList',concat('#hasRendition',$entryIRI),$rootNode)[1] else '#CityEHR:Property:Rendition:Form'"/>
-->
                        <xsl:variable name="entryRendition" as="xs:string"
                            select="cityEHRFunction:getObjectPropertyValue($rootNode, $entryIRI, 'EntryProperty', '#hasRendition')"/>

                        <!-- Get property for #hasCRUD -->
                        <!--
                        <xsl:variable name="entryCRUD" as="xs:string"
                            select="if (exists(key('specifiedObjectPropertyList',concat('#hasCRUD',$entryIRI),$rootNode))) then key('specifiedObjectPropertyList',concat('#hasCRUD',$entryIRI),$rootNode)[1] else '#CityEHR:Property:CRUD:R'"/>
-->
                        <xsl:variable name="entryCRUD" as="xs:string"
                            select="cityEHRFunction:getObjectPropertyValue($rootNode, $entryIRI, 'EntryProperty', '#hasCRUD')"/>

                        <!-- Get property for #hasSortOrder -->
                        <!--
                        <xsl:variable name="entrySortOrder" as="xs:string"
                            select="if (exists(key('specifiedObjectPropertyList',concat('#hasSortOrder',$entryIRI),$rootNode))) then key('specifiedObjectPropertyList',concat('#hasSortOrder',$entryIRI),$rootNode)[1] else ''"/>
                        -->
                        <xsl:variable name="entrySortOrder" as="xs:string"
                            select="cityEHRFunction:getObjectPropertyValue($rootNode, $entryIRI, 'EntryProperty', '#hasSortOrder')"/>

                        <!-- Get property for #hasSortCriteria.
                             This is just an elementIRI, so doesn't need cityEHRFunction:getObjectPropertyValue -->
                        <xsl:variable name="entrySortCriteria" as="xs:string"
                            select="
                                if (exists(key('specifiedObjectPropertyList', concat('#hasSortCriteria', $entryIRI), $rootNode))) then
                                    key('specifiedObjectPropertyList', concat('#hasSortCriteria', $entryIRI), $rootNode)[1]
                                else
                                    ''"/>

                        <!-- Generate entry -->
                        <entry cityEHR:cohortSearch="{$cohortSearch}" cityEHR:rendition="{$entryRendition}" cityEHR:CRUD="{$entryCRUD}"
                            cityEHR:labelWidth="{cityEHRFunction:getEntryLabelWidth($entryIRI)}">
                            <!-- Add attribute if the entry has sort order set -->
                            <xsl:if test="string-length($entrySortOrder) &gt; 0">
                                <xsl:attribute name="cityEHR:sortOrder">
                                    <xsl:value-of select="$entrySortOrder"/>
                                </xsl:attribute>
                            </xsl:if>
                            <!-- Add attribute if the entry has sort criteria set -->
                            <xsl:if test="string-length($entrySortCriteria) &gt; 0">
                                <xsl:attribute name="cityEHR:sortCriteria">
                                    <xsl:value-of select="$entrySortCriteria"/>
                                </xsl:attribute>
                            </xsl:if>
                            <!-- From 2014-09-11 need to have usingExpressions=true 
                                 so that directory entries in dictionary are the same as in the directory itself.
                            
                                 generateEntry is defined in OWL2ModelUtilities -->
                            <component xmlns="urn:hl7-org:v3">
                                <xsl:call-template name="generateEntry">
                                    <xsl:with-param name="rootNode" select="$rootNode"/>
                                    <xsl:with-param name="entryIRI" select="$entryIRI"/>
                                    <xsl:with-param name="displayName" select="$entryDisplayNameTerm"/>
                                    <xsl:with-param name="usingExpressions" select="'true'"/>
                                </xsl:call-template>
                            </component>
                        </entry>
                    </xsl:for-each>
                    <!-- Ended loop through entries -->
                </entryCollection>



                <elementCollection>
                    <!-- Iterate through elements 
                        <ClassAssertion>
                        <Class IRI="#ISO-13606:Element"/>
                        <NamedIndividual IRI="#ISO-13606:Element:elementIRI"/>
                        </ClassAssertion>
                        
                        
                        This is the displayName for the element
                        <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasDisplayName"/>
                        <NamedIndividual IRI="{$dataValueIRI}"/>
                        <NamedIndividual IRI="{$termIRI}"/>
                        </ObjectPropertyAssertion>
                    -->
                    <xsl:for-each select="key('individualIRIList', '#ISO-13606:Element')">
                        <xsl:variable name="elementIRI" as="xs:string" select="."/>

                        <!-- Get the properties needed for the data dictionary -->

                        <!-- Get property for #hasElementType -->
                        <!--
                        <xsl:variable name="elementType" as="xs:string"
                            select="if (exists(key('specifiedObjectPropertyList',concat('#hasElementType',$elementIRI),$rootNode))) then key('specifiedObjectPropertyList',concat('#hasElementType',$elementIRI),$rootNode)[1] else ''"/>
-->
                        <xsl:variable name="elementType" as="xs:string"
                            select="cityEHRFunction:getObjectPropertyValue($rootNode, $elementIRI, 'ElementProperty', '#hasElementType')"/>

                        <!-- Get property for #hasDataType
                             Properties are of the form #CityEHR:Property:DataType:string or #CityEHR:DataType:string
                             Depending on whether 2018 or 2017 ontologyVersion -->
                        <!--
                        <xsl:variable name="elementDataType" as="xs:string"
                            select="if (exists(key('specifiedObjectPropertyList',concat('#hasDataType',$elementIRI),$rootNode))) then key('specifiedObjectPropertyList',concat('#hasDataType',$elementIRI),$rootNode)[1] else ''"/>
                        -->
                        <xsl:variable name="elementDataType" as="xs:string"
                            select="cityEHRFunction:getObjectPropertyValue($rootNode, $elementIRI, 'ElementProperty', '#hasDataType')"/>
                        <xsl:variable name="dataType" as="xs:string"
                            select="
                                if (string-length(substring-after($elementDataType, 'DataType:')) > 0) then
                                    concat('xs:', substring-after($elementDataType, 'DataType:'))
                                else
                                    'xs:string'"/>

                        <!-- Get property for #hasPrecision -->
                        <xsl:variable name="elementFieldLength" as="xs:string"
                            select="
                            if (exists(key('specifiedDataPropertyList', concat('#hasPrecision', $elementIRI), $rootNode))) then
                            key('specifiedDataPropertyList', concat('#hasPrecision', $elementIRI), $rootNode)[1]
                                else
                                    ''"/>

                        <!-- Get property for #hasScope -->
                        <!--
                        <xsl:variable name="elementScope" as="xs:string"
                            select="if (exists(key('specifiedObjectPropertyList',concat('#hasScope',$elementIRI),$rootNode))) then key('specifiedObjectPropertyList',concat('#hasScope',$elementIRI),$rootNode)[1] else ''"/>
-->
                        <xsl:variable name="elementScope" as="xs:string"
                            select="cityEHRFunction:getObjectPropertyValue($rootNode, $elementIRI, 'ElementProperty', '#hasScope')"/>

                        <!-- Get element displayName -->
                        <xsl:variable name="elementDisplayNameTermIRI" as="xs:string"
                            select="
                                if (exists(key('termIRIList', $elementIRI))) then
                                    key('termIRIList', $elementIRI)[1]
                                else
                                    ''"/>
                        <xsl:variable name="elementDisplayNameTerm" as="xs:string"
                            select="
                                if (exists(key('termDisplayNameList', $elementDisplayNameTermIRI))) then
                                    key('termDisplayNameList', $elementDisplayNameTermIRI)[1]
                                else
                                    ''"/>

                        <!-- Check whether this element is the root of another (i.e. is a proxy element).
                         The root of the element in the CDA is always the elementIRI.
                         If this e;ement is the root of another then the extension records that element, otherwise the extension is the same as the root. -->
                        <!-- Get property for #isRootOf or #hasExtension (from 2019-02-13).
                              2019-02-13 - the specialisationProperty changed from isRootOf to hasExtension -->
                        <xsl:variable name="specialisationProperty" as="xs:string"
                            select="
                                if (exists($rootNode/owl:Declaration[owl:ObjectProperty/@IRI = '#hasRoot'])) then
                                    '#isRootOf'
                                else
                                    '#hasExtension'"/>

                        <xsl:variable name="recordedElementIRI" as="xs:string"
                            select="
                                if (exists(key('specifiedObjectPropertyList', concat($specialisationProperty, $elementIRI), $rootNode))) then
                                    key('specifiedObjectPropertyList', concat($specialisationProperty, $elementIRI), $rootNode)[1]
                                else
                                    $elementIRI"/>


                        <!-- Now output the dictionary elements -->

                        <!-- Experiment putting in other element types.
                    Needed for patient search configuration and for finding enumerated directory elements -->
                        <!-- Now done below for all elements
                    <xsl:if test="not($elementType=('#CityEHR:ElementProperty:enumeratedValue','#CityEHR:ElementProperty:calculatedValue','#CityEHR:ElementProperty:range'))">

                        <element root="{$elementIRI}" extension="{$recordedElementIRI}" xsi:type="{$dataType}" displayName="{$elementDisplayNameTerm}" cityEHR:elementType="{$elementType}" cityEHR:Scope="{$elementScope}" cityEHR:fieldLength="{$elementFieldLength}"/>

                    </xsl:if>
                    -->
                        <xsl:if test="not($elementType = ('#CityEHR:ElementProperty:enumeratedClass', '#CityEHR:Property:ElementType:enumeratedClass'))">
                            <element root="{$elementIRI}" extension="{$recordedElementIRI}" xsi:type="{$dataType}"
                                displayName="{$elementDisplayNameTerm}" cityEHR:elementType="{$elementType}" cityEHR:Scope="{$elementScope}"
                                cityEHR:fieldLength="{$elementFieldLength}">

                                <!-- Element only needs a full entry in elementCollection if it is of the following types:
                                enumeratedValue
                                enumeratedCalculatedValue
                                enumeratedDirectory
                                calculatedValue
                                range                        
                    -->
                                <xsl:if
                                    test="$elementType = ('#CityEHR:ElementProperty:enumeratedValue', '#CityEHR:ElementProperty:enumeratedCalculatedValue', '#CityEHR:ElementProperty:enumeratedDirectory', '#CityEHR:ElementProperty:calculatedValue', '#CityEHR:ElementProperty:range', '#CityEHR:Property:ElementType:enumeratedValue', '#CityEHR:Property:ElementType:enumeratedCalculatedValue', '#CityEHR:Property:ElementType:enumeratedDirectory', '#CityEHR:Property:ElementType:calculatedValue', '#CityEHR:Property:ElementType:range')">

                                    <!-- Iterate through enumerated values for an element 
                            Can be for elements of type enumeratedValue, enumeratedDirectory, calculatedValue or range
                         
                         This is the value of the element.
                         The value will also have a displayName - either the term of the element value, or explicitly set using the #hasDisplayName property
                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasData"/>
                            <NamedIndividual IRI="{$elementIRI}"/>
                            <NamedIndividual IRI="{$dataValueIRI}"/>
                        </ObjectPropertyAssertion>
 
                         This is the displayName of the elementValue
                         <ObjectPropertyAssertion>
                             <ObjectProperty IRI="#hasDisplayName"/>
                             <NamedIndividual IRI="{$dataValueIRI}"/>
                             <NamedIndividual IRI="{$termIRI}"/>
                         </ObjectPropertyAssertion>
 
                         This is the literal value of the elementValue
                         <DataPropertyAssertion>
                             <DataProperty IRI="#hasValue"/>
                             <NamedIndividual IRI="{$dataValueIRI}"/>
                             <Literal xml:lang="en" datatypeIRI="&rdf;PlainLiteral">Literal text for this term</Literal>
                         </DataPropertyAssertion>
                                              
                        This is the value of the displayName (for element or elementValue)
                        <DataPropertyAssertion>
                            <DataProperty IRI="#hasValue"/>
                            <NamedIndividual IRI="#CityEHR:Term:$termIRI"/>
                            <Literal xml:lang="en" datatypeIRI="&rdf;PlainLiteral">Literal text for this term</Literal>
                        </DataPropertyAssertion>
                    -->
                                    <xsl:for-each select="key('dataValueIRIList', $elementIRI)">

                                        <xsl:variable name="dataValueIRI" select="."/>
                                        <xsl:variable name="elementValue" as="xs:string"
                                            select="
                                                if (exists(key('termDisplayNameList', $dataValueIRI))) then
                                                    key('termDisplayNameList', $dataValueIRI)[1]
                                                else
                                                    ''"/>

                                        <xsl:variable name="elementValueDisplayNameTermIRI" as="xs:string"
                                            select="
                                                if (exists(key('termIRIList', $dataValueIRI))) then
                                                    key('termIRIList', $dataValueIRI)[1]
                                                else
                                                    ''"/>
                                        <xsl:variable name="elementValueDisplayName" as="xs:string"
                                            select="
                                                if (exists(key('termDisplayNameList', $elementValueDisplayNameTermIRI))) then
                                                    key('termDisplayNameList', $elementValueDisplayNameTermIRI)[1]
                                                else
                                                    ''"/>

                                        <data code="{$dataValueIRI}" codeSystem="cityEHR" value="{$elementValue}"
                                            displayName="{$elementValueDisplayName}"/>

                                    </xsl:for-each>
                                </xsl:if>
                                <!-- End Element is not of type enumeratedClass -->
                            </element>
                        </xsl:if>

                        <!-- Element of type 'enumeratedClass'
                            
                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasDataClass"/>
                        <NamedIndividual IRI="#ISO-13606:Element:Diagnosis"/>
                        <NamedIndividual IRI="#CityEHR:Class:Diagnosis"/>
                    </ObjectPropertyAssertion>
                                                              
                    <Declaration>
                        <NamedIndividual IRI="#ISO-13606:Data:DiagnosisDiagnosisInfection"/>
                    </Declaration>
                    
                    <ClassAssertion>
                        <Class IRI="#ISO-13606:Data"/>
                        <NamedIndividual IRI="#ISO-13606:Data:DiagnosisDiagnosisInfection"/>
                    </ClassAssertion>
                    
                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasData"/>
                        <NamedIndividual IRI="#ISO-13606:Element:Diagnosis"/>
                        <NamedIndividual IRI="##ISO-13606:Data:DiagnosisDiagnosisInfection"/>
                    </ObjectPropertyAssertion>               
                    
                    <DataPropertyAssertion>
                        <DataProperty IRI="#hasValue"/>
                        <NamedIndividual IRI="#ISO-13606:Data:DiagnosisDiagnosisInfection"/>
                        <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">#CityEHR:Class:Diagnosis:Infection</Literal>
                    </DataPropertyAssertion>
                    
                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasDisplayName"/>
                        <NamedIndividual IRI="#ISO-13606:Data:DiagnosisDiagnosisInfection"/>
                        <NamedIndividual IRI="#CityEHR:Term:Diagnosis"/>
                    </ObjectPropertyAssertion>
                    
                    -->
                        <xsl:if test="$elementType = ('#CityEHR:ElementProperty:enumeratedClass', '#CityEHR:Property:ElementType:enumeratedClass')">

                            <element root="{$elementIRI}" extension="{$recordedElementIRI}" displayName="{$elementDisplayNameTerm}"
                                cityEHR:elementType="{$elementType}">
                                                               
                                <!-- Get property for #hasDataClass -->
                                <xsl:variable name="elementValueClass" as="xs:string"
                                    select="
                                    if (exists(key('specifiedObjectPropertyList', concat('#hasDataClass', $elementIRI), $rootNode))) then
                                    key('specifiedObjectPropertyList', concat('#hasDataClass', $elementIRI), $rootNode)[1]
                                    else
                                    ''"/>
                                
                                <!-- Iterate through enumerated values for an element.
                                     The values specified are the nodes of the class to select from. -->
                                <xsl:for-each select="key('dataValueIRIList', $elementIRI)">
                                    <xsl:variable name="dataValueIRI" select="."/>

                                    <!-- Get data property for #hasValue -->
                                    <xsl:variable name="elementValue" as="xs:string"
                                        select="
                                            if (exists(key('specifiedDataPropertyList', concat('#hasValue', $dataValueIRI), $rootNode))) then
                                                key('specifiedDataPropertyList', concat('#hasValue', $dataValueIRI))[1]
                                            else
                                                ''"/>

                                    <xsl:variable name="elementValueDisplayNameTermIRI" as="xs:string"
                                        select="
                                            if (exists(key('termIRIList', $dataValueIRI))) then
                                                key('termIRIList', $dataValueIRI)[1]
                                            else
                                                ''"/>
                                    <xsl:variable name="elementValueDisplayName" as="xs:string"
                                        select="
                                            if (exists(key('termDisplayNameList', $elementValueDisplayNameTermIRI))) then
                                                key('termDisplayNameList', $elementValueDisplayNameTermIRI)[1]
                                            else
                                                ''"/>

                                    <!-- The value here denotes the class:node that is used for the element selection.
                                         The code is the class of the node -->
                                    <data code="{$elementValueClass}" codeSystem="CityEHR" value="{$elementValue}"
                                        displayName="{$elementValueDisplayName}"/>

                                </xsl:for-each>
                            </element>

                        </xsl:if>
                        <!-- Element is of type enumeratedClass -->

                    </xsl:for-each>



                    <!-- If this ontology contains class hierarchies, walk through each hierarchy, getting the values for the element.
                         The class hierarchy is represented in the ontology as (e.g. for Diagnosis class):
                    
                    <ClassAssertion>
                        <Class IRI="#CityEHR:Class"/>
                        <NamedIndividual IRI="#CityEHR:Class:Diagnosis"/>
                    </ClassAssertion>
                    
                    <ClassAssertion>
                        <Class IRI="#CityEHR:Class:Diagnosis"/>
                        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Trauma"/>
                    </ClassAssertion>
                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasDisplayName"/>
                        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Trauma"/>
                        <NamedIndividual IRI="#CityEHR:Term:Trauma"/>
                    </ObjectPropertyAssertion>
                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasSuppDataSet"/>
                        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Trauma"/>
                        <NamedIndividual IRI="#ISO-13606:Entry:Trauma"/>
                    </ObjectPropertyAssertion>
                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasType"/>
                        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Trauma"/>
                        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Fracture"/>
                    </ObjectPropertyAssertion> 
                    
                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasUnit"/>
                        <NamedIndividual IRI="#CityEHR:Class:LabTest:Sodium"/>
                        <NamedIndividual IRI="#CityEHR:Unit:millimolperL"/>
                    </ObjectPropertyAssertion>
                
                -->
                    <xsl:if test="$classIRI != ''">

                        <xsl:variable name="classDisplayNameTermIRI" as="xs:string"
                            select="
                                if (exists(key('termIRIList', $classIRI, $rootNode))) then
                                    key('termIRIList', $classIRI, $rootNode)[1]
                                else
                                    ''"/>
                        <xsl:variable name="classDisplayNameTerm" as="xs:string"
                            select="
                                if (exists(key('termDisplayNameList', $classDisplayNameTermIRI, $rootNode))) then
                                    key('termDisplayNameList', $classDisplayNameTermIRI, $rootNode)[1]
                                else
                                    ''"/>

                        <xsl:variable name="classNodeList"
                            select="distinct-values($rootNode/owl:ClassAssertion[owl:Class/@IRI = $classIRI]/owl:NamedIndividual/data(@IRI))"/>
                        <xsl:variable name="childNodeList"
                            select="distinct-values($rootNode/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI = '#hasType']/owl:NamedIndividual[2]/data(@IRI))"/>
                        <xsl:variable name="rootNodeList"
                            select="
                                for $n in $classNodeList
                                return
                                    if ($n = $childNodeList) then
                                        ()
                                    else
                                        $n"/>
                        <!--
                        <xsl:variable name="parentNodeList"
                            select="distinct-values($rootNode/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasType']/owl:NamedIndividual[1]/data(@IRI))"/>                        
                        <xsl:variable name="leafNodeList"
                            select="for $n in $classNodeList return if ($n = $parentNodeList) then () else $n"/>
                            -->

                        <!-- Generate dictionary entry for the nested class hierarchy -->
                        <element root="cityEHR" extension="{$classIRI}" displayName="{$classDisplayNameTerm}"
                            cityEHR:elementType="#CityEHR:Property:ElementType:enumeratedClass">

                            <!-- Iterate through the root nodes. -->
                            <xsl:for-each select="$rootNodeList">
                                <xsl:variable name="nodeIRI" as="xs:string" select="."/>

                                <xsl:variable name="suppDataSetIRI"
                                    select="
                                        if (exists(key('specifiedObjectPropertyList', concat('#hasSuppDataSet', $nodeIRI), $rootNode))) then
                                            key('specifiedObjectPropertyList', concat('#hasSuppDataSet', $nodeIRI), $rootNode)[1]
                                        else
                                            ''"/>
                                <xsl:variable name="unitIRI"
                                    select="
                                        if (exists(key('specifiedObjectPropertyList', concat('#hasUnit', $nodeIRI), $rootNode))) then
                                            key('specifiedObjectPropertyList', concat('#hasUnit', $nodeIRI), $rootNode)[1]
                                        else
                                            ''"/>

                                <xsl:call-template name="generateNode">
                                    <xsl:with-param name="rootNode" select="$rootNode"/>
                                    <xsl:with-param name="nodeIRI" select="$nodeIRI"/>
                                    <xsl:with-param name="suppDataSetIRI" select="$suppDataSetIRI"/>
                                    <xsl:with-param name="unitIRI" select="$unitIRI"/>
                                    <xsl:with-param name="loopPath" select="''"/>
                                </xsl:call-template>

                            </xsl:for-each>
                        </element>

                        <!-- This one has a flat list of all values in the class -->
                        <!--
                    <element root="cityEHR" extension="{$classIRI}"
                        displayName="{$classDisplayNameTerm}"
                        cityEHR:elementType="#CityEHR:ElementProperty:enumeratedValue">

                        <xsl:for-each select=" key('individualIRIList',$classIRI)">
                            <xsl:variable name="nodeIRI" as="xs:string" select="."/>
                            <xsl:variable name="suppDataSetIRI" as="xs:string"
                                select="if (exists(key('specifiedObjectPropertyList',concat('#hasSuppDataSet',$nodeIRI)))) then key('specifiedObjectPropertyList',concat('#hasSuppDataSet',$nodeIRI))[1] else ''"/>
                            <xsl:variable name="unitIRI" as="xs:string"
                                select="if (exists(key('specifiedObjectPropertyList',concat('#hasUnit',$nodeIRI)))) then key('specifiedObjectPropertyList',concat('#hasUnit',$nodeIRI))[1] else ''"/>

                            <xsl:call-template name="generateNodeList">
                                <xsl:with-param name="nodeIRI" select="$nodeIRI"/>
                                <xsl:with-param name="suppDataSetIRI" select="$suppDataSetIRI"/>
                                <xsl:with-param name="unitIRI" select="$unitIRI"/>
                                <xsl:with-param name="loopPath" select="''"/>
                                <xsl:with-param name="output" select="'all'"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </element>
                    -->


                    </xsl:if>
                    <!-- End iteration through classes -->

                </elementCollection>
            </EHR_Extract>

        </xsl:if>
    </xsl:template>

    <!-- Generate node
         Includes a recursive call to generate child nodes
         This is used to generate value elements for nodes of a class hierarchy
         
         value and displayName of the element are both the $displayNameTerm for the node.
         
         Generates cliincal codes for the node, found in the data properties:
         
         hasSNOMEDCode
         hasICD-10Code
         hasOPCS-4Code
    -->
    <xsl:template name="generateNode">
        <xsl:param name="rootNode"/>
        <xsl:param name="nodeIRI"/>
        <xsl:param name="suppDataSetIRI"/>
        <xsl:param name="unitIRI"/>
        <xsl:param name="loopPath"/>
        <xsl:if test="$nodeIRI != '' and not(contains($loopPath, $nodeIRI))">
            <xsl:variable name="displayNameTermIRI" as="xs:string"
                select="
                    if (exists(key('termIRIList', $nodeIRI, $rootNode))) then
                        key('termIRIList', $nodeIRI, $rootNode)[1]
                    else
                        ''"/>
            <xsl:variable name="displayNameTerm" as="xs:string"
                select="
                    if (exists(key('termDisplayNameList', $displayNameTermIRI, $rootNode))) then
                        key('termDisplayNameList', $displayNameTermIRI, $rootNode)[1]
                    else
                        ''"/>

            <xsl:variable name="unitTermIRI" as="xs:string"
                select="
                    if (exists(key('termIRIList', $unitIRI, $rootNode))) then
                        key('termIRIList', $unitIRI, $rootNode)[1]
                    else
                        ''"/>
            <xsl:variable name="unitTerm" as="xs:string"
                select="
                    if (exists(key('termDisplayNameList', $unitTermIRI, $rootNode))) then
                        key('termDisplayNameList', $unitTermIRI, $rootNode)[1]
                    else
                        ''"/>

            <xsl:variable name="newLoopPath" as="xs:string" select="concat($loopPath, '@@@', $nodeIRI)"/>

            <data code="{$nodeIRI}" codeSystem="CityEHR" value="{$nodeIRI}" displayName="{$displayNameTerm}" units="{$unitTerm}"
                cityEHR:suppDataSet="{$suppDataSetIRI}">
                <!-- Record the clinical codes -->
                <xsl:for-each select="('SNOMED', 'ICD-10', 'OPCS-4')">
                    <xsl:variable name="codeSystem" as="xs:string" select="."/>
                    <xsl:variable name="dataProperty" as="xs:string" select="concat('#has', $codeSystem, 'Code')"/>
                    <xsl:for-each select="key('specifiedDataPropertyList', concat($dataProperty, $nodeIRI), $rootNode)">
                        <xsl:variable name="code" as="xs:string" select="."/>
                        <code code="{$code}" codeSystem="{$codeSystem}"/>
                    </xsl:for-each>
                </xsl:for-each>


                <!-- Process the child nodes -->
                <xsl:for-each select="key('typeIRIList', $nodeIRI, $rootNode)">
                    <xsl:variable name="childNodeIRI" as="xs:string" select="."/>
                    <xsl:variable name="childNodeSuppDataSetIRI" as="xs:string"
                        select="
                            if (exists(key('specifiedObjectPropertyList', concat('#hasSuppDataSet', $childNodeIRI), $rootNode))) then
                                key('specifiedObjectPropertyList', concat('#hasSuppDataSet', $childNodeIRI), $rootNode)[1]
                            else
                                ''"/>
                    <xsl:variable name="childUnitIRI" as="xs:string"
                        select="
                            if (exists(key('specifiedObjectPropertyList', concat('#hasUnit', $childNodeIRI), $rootNode))) then
                                key('specifiedObjectPropertyList', concat('#hasUnit', $childNodeIRI), $rootNode)[1]
                            else
                                ''"/>

                    <!-- Supplementary data set is inherited from parent, unless overriden by assertion for this node -->
                    <xsl:variable name="inheritedSuppDataSetIRI"
                        select="
                            if ($childNodeSuppDataSetIRI = '') then
                                $suppDataSetIRI
                            else
                                $childNodeSuppDataSetIRI"/>

                    <xsl:call-template name="generateNode">
                        <xsl:with-param name="rootNode" select="$rootNode"/>
                        <xsl:with-param name="nodeIRI" select="$childNodeIRI"/>
                        <xsl:with-param name="suppDataSetIRI" select="$inheritedSuppDataSetIRI"/>
                        <xsl:with-param name="unitIRI" select="$childUnitIRI"/>
                        <xsl:with-param name="loopPath" select="$newLoopPath"/>
                    </xsl:call-template>

                </xsl:for-each>

            </data>
        </xsl:if>

    </xsl:template>


    <!-- Generate node list
        Includes a recursive call to generate list of child nodes
        This is used to generate value elements for nodes of a class hierarchy
        Identical to GenerateNode except that <data> element is empty, not nested (could do some refactoring of this)
        
        The output parameter determines if all values are to be output ('all') or just the leaf nodes ('leaf').
        If a leaf node has multiple parents then it must only appear once in the list of child nodes.
        To do this we need to keep a list of all the nodes in the nodeList parameter
    -->
    <xsl:template name="generateNodeList">
        <xsl:param name="nodeIRI"/>
        <xsl:param name="suppDataSetIRI"/>
        <xsl:param name="unitIRI"/>
        <xsl:param name="loopPath"/>
        <xsl:param name="output"/>

        <xsl:if test="not(contains($loopPath, $nodeIRI))">

            <xsl:variable name="displayNameTermIRI" as="xs:string"
                select="
                    if (exists(key('termIRIList', $nodeIRI))) then
                        key('termIRIList', $nodeIRI)[1]
                    else
                        ''"/>
            <xsl:variable name="displayNameTerm" as="xs:string"
                select="
                    if (exists(key('termDisplayNameList', $displayNameTermIRI))) then
                        key('termDisplayNameList', $displayNameTermIRI)[1]
                    else
                        ''"/>

            <xsl:variable name="unitTermIRI" as="xs:string"
                select="
                    if (exists(key('termIRIList', $unitIRI))) then
                        key('termIRIList', $unitIRI)[1]
                    else
                        ''"/>
            <xsl:variable name="unitTerm" as="xs:string"
                select="
                    if (exists(key('termDisplayNameList', $unitTermIRI))) then
                        key('termDisplayNameList', $unitTermIRI)[1]
                    else
                        ''"/>

            <xsl:variable name="newLoopPath" as="xs:string" select="concat($loopPath, '@@@', $nodeIRI)"/>
            <xsl:variable name="leafNode" as="xs:string"
                select="
                    if (exists(key('typeIRIList', $nodeIRI))) then
                        'non-leaf'
                    else
                        'leaf'"/>

            <!-- Leaf node - output the value -->
            <xsl:if test="$leafNode = 'leaf' or $output = 'all'">
                <data code="{$nodeIRI}" codeSystem="CityEHR" value="{$nodeIRI}" displayName="{$displayNameTerm}" units="{$unitTerm}"
                    cityEHR:suppDataSet="{$suppDataSetIRI}"/>
            </xsl:if>

            <!-- Non-leaf node - process the children -->
            <xsl:if test="$leafNode = 'non-leaf'">
                <xsl:for-each select="key('typeIRIList', $nodeIRI)">
                    <xsl:variable name="childNodeIRI" as="xs:string" select="."/>
                    <xsl:variable name="childNodeSuppDataSetIRI" as="xs:string"
                        select="
                            if (exists(key('specifiedObjectPropertyList', concat('#hasSuppDataSet', $childNodeIRI)))) then
                                key('specifiedObjectPropertyList', concat('#hasSuppDataSet', $childNodeIRI))[1]
                            else
                                ''"/>
                    <xsl:variable name="childUnitIRI" as="xs:string"
                        select="
                            if (exists(key('specifiedObjectPropertyList', concat('#hasUnit', $childNodeIRI)))) then
                                key('specifiedObjectPropertyList', concat('#hasUnit', $childNodeIRI))[1]
                            else
                                ''"/>

                    <!-- Supplementary data set is inherited from parent, unless overriden by assertion for this node -->
                    <xsl:variable name="inheritedSuppDataSetIRI"
                        select="
                            if ($childNodeSuppDataSetIRI = '') then
                                $suppDataSetIRI
                            else
                                $childNodeSuppDataSetIRI"/>

                    <xsl:call-template name="generateNodeList">
                        <xsl:with-param name="nodeIRI" select="$childNodeIRI"/>
                        <xsl:with-param name="suppDataSetIRI" select="$inheritedSuppDataSetIRI"/>
                        <xsl:with-param name="unitIRI" select="$childUnitIRI"/>
                        <xsl:with-param name="loopPath" select="$newLoopPath"/>
                        <xsl:with-param name="output" select="$output"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:if>

        </xsl:if>

    </xsl:template>

</xsl:stylesheet>
