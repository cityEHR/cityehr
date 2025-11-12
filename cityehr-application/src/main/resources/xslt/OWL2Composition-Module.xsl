<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWL2Composition-Module.xsl
    Included as a module in OWL2CompositionSet.xsl 
    Uses OWL2ModelUtilities.xsl (also included in OWL2CompositionSet.xsl)
    
    Generates a composition (form, letter, order, etc) specification for the system configuration of cityEHR
    
    Input paramater compositionIRI identifies the composition to be generated.    
    applicationIRI and specialtyIRI define the application and folder (specialty) for the composition.
    rootNode - the document root of the input ontology - is set as a global variable in the modules that include this one.
       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- === Global Variables === -->

    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="//owl:Ontology"/>

    <!-- Set the Application for this ontology configuration -->
    <xsl:variable name="applicationIRI" as="xs:string"
        select="//owl:Ontology/owl:ClassAssertion[owl:Class/@IRI = '#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="applicationId" as="xs:string"
        select="replace(substring($applicationIRI, 2), ':', '-')"/>

    <!-- Set the Specialty for this ontology configuration -->
    <xsl:variable name="specialtyIRI" as="xs:string"
        select="
            if (count(//owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI = '#ISO-13606:Folder']/owl:Class[1]/@IRI) = 1) then
                //owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI = '#ISO-13606:Folder']/owl:Class[1]/@IRI
            else
                ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="specialtyId" as="xs:string"
        select="replace(substring($specialtyIRI, 2), ':', '-')"/>

    <!-- Set the Class for this ontology configuration, if there is one -->
    <xsl:variable name="classIRI" as="xs:string"
        select="
            if (exists(//owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI = '#CityEHR:Class']/owl:Class[1]/@IRI)) then
                //owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI = '#CityEHR:Class']/owl:Class[1]/@IRI
            else
                ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="classId" as="xs:string" select="replace(substring($classIRI, 2), ':', '-')"/>

    <!-- === Template to generate the Composition === 
        Input parameter is the compositionIRI
    -->
    <xsl:template name="generateComposition">
        <xsl:param name="rootNode"/>
        <xsl:param name="compositionIRI"/>
        <xsl:param name="applicationIRI"/>
        <xsl:param name="specialtyIRI"/>

        <!-- === Set basic information about the application === 
        -->
        <xsl:variable name="applicationDisplayNameTermIRI" as="xs:string"
            select="
                if (exists(key('termIRIList', $applicationIRI))) then
                    key('termIRIList', $applicationIRI)[1]
                else
                    ''"/>
        <xsl:variable name="applicationDisplayNameTerm" as="xs:string"
            select="
                if (exists(key('termDisplayNameList', $applicationDisplayNameTermIRI))) then
                    key('termDisplayNameList', $applicationDisplayNameTermIRI)[1]
                else
                    ''"/>

        <xsl:variable name="modelOwner" as="xs:string"
            select="
                if (exists($rootNode/owl:DataPropertyAssertion[owl:NamedIndividual/@IRI = $applicationIRI][owl:DataProperty/@IRI = '#hasOwner']/owl:Literal)) then
                    $rootNode/owl:DataPropertyAssertion[owl:NamedIndividual/@IRI = $applicationIRI][owl:DataProperty/@IRI = '#hasOwner']/owl:Literal
                else
                    ''"/>


        <!-- === Set basic information about the composition === 
        -->
        <!-- Type of composition -->
        <xsl:variable name="compositionTypeIRI" as="xs:string"
            select="
                if (exists(key('classIRIList', $compositionIRI, $rootNode))) then
                    key('classIRIList', $compositionIRI, $rootNode)[1]
                else
                    '#HL7-CDA:ClinicalDocument'"/>

        <!-- displayName -->
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


        <!-- Document node - ClinicalDocument
             (was compositionDefinition until 2023-11-25)
             2021-04-02 removed xmlns:mif="urn:hl7-org:v3/mif" -->

        <!-- === Create the HL7 CDA composition document 
                     Don't need to create CDA for views, since these use the associated form as specified in the data dictionary
                     === -->
        <xsl:if test="$compositionTypeIRI != '#CityEHR:View'">
            <ClinicalDocument xmlns="urn:hl7-org:v3" xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3"
                xmlns:cityEHR="http://openhealthinformatics.org/ehr">
                <!-- CDA Header -->
                <typeId root="{$compositionTypeIRI}" extension="{$compositionIRI}"/>

                <!-- Set the context for this composition (application and specialty for which it is relevant) -->
                <templateId root="{$applicationIRI}" extension="{$specialtyIRI}"/>

                <!-- Placeholder for the id of the CDA document created when the composition is published to the record.
                     This is initially set to be the same as the compositionIRI set in the typeId (i.e. identifies the type of the composition.
                     This is used in the patientAccess recordNavigation, so don't change it. -->
                <id root="cityEHR" extension="{$compositionIRI}"/>

                <!-- Set the displayname of the composition -->
                <code code="" codeSystem="cityEHR" displayName="{$compositionDisplayNameTerm}"/>

                <effectiveTime value=""/>
                <recordTarget>
                    <patientRole>
                        <id extension=""/>
                        <patient>
                            <name>
                                <prefix/>
                                <given/>
                                <family/>
                            </name>
                            <administrativeGenderCode code="" codeSystem="" displayName=""/>
                            <birthTime value=""/>
                        </patient>
                        <providerOrganization>
                            <id extension="" root="{$applicationIRI}"/>
                            <name>
                                <xsl:value-of select="$modelOwner"/>
                            </name>
                        </providerOrganization>
                    </patientRole>
                </recordTarget>

                <!-- This is set when the document is created -->
                <author>
                    <time value=""/>
                    <assignedAuthor>
                        <id extension="" root="{$applicationIRI}"/>
                        <assignedPerson>
                            <name/>
                        </assignedPerson>
                        <authoringDevice>
                            <!-- Use the application display name here -->
                            <softwareName>
                                <xsl:value-of select="$applicationDisplayNameTerm"/>
                            </softwareName>
                        </authoringDevice>
                        <representedOrganization>
                            <id root="{$applicationIRI}"/>
                            <!-- Use the application owner name here -->
                            <name>
                                <xsl:value-of select="$modelOwner"/>
                            </name>
                        </representedOrganization>
                    </assignedAuthor>
                </author>

                <!-- This is used to link documents to pathway actions -->
                <documentationOf>
                    <serviceEvent classCode="">
                        <id extension="" root="cityEHR"/>
                        <code code="" codeSystem="" codeSystemName="" displayName=""/>
                    </serviceEvent>
                </documentationOf>

                <!-- CDA Body -->
                <component>
                    <structuredBody>
                        <!-- Hidden section for Built-in entries (e.g age, etc) 2016-05-07 - Is this still needed?
                             Removed (commented out) 2016-06-24
                             These are represented in OWL/XML as entries which have the Entry Property has_InitialValue of Built-in   
                             
                             <ObjectPropertyAssertion>
                                 <ObjectProperty IRI="#hasInitialValue"/>
                                 <NamedIndividual IRI="#ISO-13606:Entry:Age"/>
                                 <NamedIndividual IRI="#CityEHR:EntryProperty:Built-in"/>
                             </ObjectPropertyAssertion>                          
                        -->
                        <!--
                        <component xmlns="urn:hl7-org:v3">
                            <section cityEHR:visibility="alwaysHidden">
                                <xsl:for-each select="$rootNode/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasInitialValue'][owl:NamedIndividual[2]/@IRI='#CityEHR:EntryProperty:Built-in']">
                                    <xsl:variable name="entryIRI" as="xs:string" select="./owl:NamedIndividual[1]/@IRI"/>

                                    <xsl:variable name="entryDisplayNameTermIRI" as="xs:string" select="if (exists(key('termIRIList',$entryIRI))) then key('termIRIList',$entryIRI)[1] else ''"/>
                                    <xsl:variable name="entryDisplayNameTerm" as="xs:string" select="if (exists(key('termDisplayNameList',$entryDisplayNameTermIRI))) then key('termDisplayNameList',$entryDisplayNameTermIRI)[1] else ''"/>

                                    <entry cityEHR:initialValue="#CityEHR:EntryProperty:Built-in">
                                        <xsl:call-template name="generateEntry">
                                            <xsl:with-param name="rootNode" select="$rootNode"/>
                                            <xsl:with-param name="entryIRI" select="$entryIRI"/>
                                            <xsl:with-param name="displayName" select="$entryDisplayNameTerm"/>
                                            <xsl:with-param name="usingExpressions" select="'true'"/>
                                        </xsl:call-template>
                                    </entry>
                                </xsl:for-each>
                            </section>
                        </component>
-->

                        <!-- Section to hold the trash for this form. This section is initially hidden and contains an empty MultipleEntry.
                             That entry is then filled with components that are removed from any other MultipleEntries on the form.
                             Entries can be restored from the Trash by:
                             
                                    1) The user views the trash and selects to restore the entry
                                    2) Default conditions on a MultipleEntry are satisfied by the entry in the trash
                                    
                             2016-06-24 Not using Trash yet, so commented out
                        -->
                        <!--
                        <component xmlns="urn:hl7-org:v3">
                            <section cityEHR:visibility="alwaysHidden">
                                <id root="cityEHR" extension="trash"/>
                                <title>Trash</title>
                                <entry>
                                    <organizer xmlns="urn:hl7-org:v3" moodCode="EVN" classCode="MultipleEntry">
                                        <component/>
                                        <component>
                                            <organizer/>
                                        </component>
                                    </organizer>
                                </entry>
                            </section>
                            </component>
                            -->

                        <!-- Lists of sections, entries and elements for the composition -->

                        <!-- Get all the sections on this form -->
                        <xsl:variable name="allFormSections"
                            select="cityEHRFunction:getFormSections($rootNode, $compositionIRI)"/>
                        <xsl:variable name="formSections" select="distinct-values($allFormSections)"/>

                        <!-- Get all the entries on this form.
                                The formRecordedEntries is the list of entries recorded (in @extension) from an aliased entry -->
                        <xsl:variable name="allFormEntries"
                            select="cityEHRFunction:getFormEntries($rootNode, $formSections)"/>
                        <xsl:variable name="formEntries" select="distinct-values($allFormEntries)"/>
                        <xsl:variable name="formRecordedEntries"
                            select="distinct-values(cityEHRFunction:getRecordedEntries($rootNode, $formEntries))"/>

                        <!-- Get all the elements on this form -->
                        <xsl:variable name="allFormElements"
                            select="cityEHRFunction:getElements($rootNode, $formEntries)"/>
                        <xsl:variable name="formElements" select="distinct-values($allFormElements)"/>


                        <!-- Generate hidden sections 
                                 A stub for externally referenced entries (used for wordprocessor attachments)
                                 and                                
                                 A section for entries used in expressions (conditions, calculations or default values) 
                                 But not used elsewhere on the composition (i.e. need to be pre-filled from the record)
                              -->
                        <xsl:call-template name="generateHiddenSections">
                            <xsl:with-param name="rootNode" select="$rootNode"/>
                            <xsl:with-param name="compositionIRI" select="$compositionIRI"/>
                            <xsl:with-param name="formSections" select="$formSections"/>
                            <xsl:with-param name="formEntries" select="$formEntries"/>
                            <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"
                            />
                        </xsl:call-template>


                        <!-- Generate header section - represented in OWL/XML as
                            
                            <ObjectPropertyAssertion>
                                <ObjectProperty IRI="#hasHeader"/>
                                <NamedIndividual IRI="$compositionIRI"/>
                                <NamedIndividual IRI="$headerIRI"/>
                            </ObjectPropertyAssertion>
                        -->

                        <xsl:if
                            test="exists($rootNode/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI = '#hasHeader'][owl:NamedIndividual[1]/@IRI = $compositionIRI])">

                            <xsl:variable name="headerIRI" as="xs:string"
                                select="$rootNode/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI = '#hasHeader'][owl:NamedIndividual[1]/@IRI = $compositionIRI]/owl:NamedIndividual[2]/@IRI"/>

                            <!-- Set property for layout.
                                     This makes sure that the section is rendered as a header in CDA2XForm and CDA2HTML
                                     2019-02-13 Note that 'Header' is not a well-formed property - may want to refactor this. -->
                            <xsl:variable name="sectionSequence" as="xs:string" select="'Header'"/>

                            <!-- Call template to generate section.
                                usingExpressions is 'true' because this is a composition -->
                            <xsl:call-template name="generateSection">
                                <xsl:with-param name="rootNode" select="$rootNode"/>
                                <xsl:with-param name="compositionTypeIRI"
                                    select="$compositionTypeIRI"/>
                                <xsl:with-param name="sectionIRI" select="$headerIRI"/>
                                <xsl:with-param name="sectionSequence" select="$sectionSequence"/>
                                <xsl:with-param name="formRecordedEntries"
                                    select="$formRecordedEntries"/>
                                <xsl:with-param name="usingExpressions" select="'true'"/>
                            </xsl:call-template>

                        </xsl:if>


                        <!-- Iterate through sections - represented in OWL/XML as
                                
                                <ObjectPropertyAssertion>
                                    <ObjectProperty IRI="#hasContent"/>
                                    <NamedIndividual IRI="$compositionIRI"/>
                                    <NamedIndividual IRI="sectionIRI"/>
                                </ObjectPropertyAssertion>
                                
                             Sections are sorted in the order defined by the hasContentsList data attribute.
                             The position order is determined by the length of the string before the section is matched in the list
                        -->

                        <!-- Get data property for #hasContentsList -->
                        <xsl:variable name="contentsList" as="xs:string"
                            select="
                                if (exists(key('specifiedDataPropertyList', concat('#hasContentsList', $compositionIRI), $rootNode))) then
                                    key('specifiedDataPropertyList', concat('#hasContentsList', $compositionIRI), $rootNode)
                                else
                                    ''"/>

                        <!-- Now iterate through the list, sorted by position in the contentsList -->
                        <xsl:for-each select="key('contentsIRIList', $compositionIRI, $rootNode)">
                            <!--
                        <xsl:for-each select="$rootNode/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasContent'][owl:NamedIndividual[1]/@IRI=$compositionIRI]">
-->
                            <xsl:sort select="string-length(substring-before($contentsList, .))"/>

                            <xsl:variable name="sectionIRI" as="xs:string" select="."/>
                            <!-- Top level sections are always Ranked -->

                            <!-- Get data property for #hasSequence
                                     2019-02-13 This is now an objectProperty, so need to handle both (data property or object property)-->
                            <xsl:variable name="sectionSequenceProperty" as="xs:string"
                                select="
                                    if (exists(key('specifiedDataPropertyList', concat('#hasSequence', $sectionIRI), $rootNode))) then
                                        key('specifiedDataPropertyList', concat('#hasSequence', $sectionIRI), $rootNode)
                                    else
                                        if (exists(key('specifiedObjectPropertyList', concat('#hasSequence', $sectionIRI), $rootNode))) then
                                            key('specifiedObjectPropertyList', concat('#hasSequence', $sectionIRI), $rootNode)[1]
                                        else
                                            'Ranked'"/>

                            <xsl:variable name="sectionSequence" as="xs:string"
                                select="
                                    if (contains($sectionSequenceProperty, 'Unranked')) then
                                        'Unranked'
                                    else
                                        'Ranked'"/>

                            <!-- Call template to generate section.
                                 usingExpressions is 'true' because this is a composition -->
                            <xsl:call-template name="generateSection">
                                <xsl:with-param name="rootNode" select="$rootNode"/>
                                <xsl:with-param name="compositionTypeIRI"
                                    select="$compositionTypeIRI"/>
                                <xsl:with-param name="sectionIRI" select="$sectionIRI"/>
                                <xsl:with-param name="sectionSequence" select="$sectionSequence"/>
                                <xsl:with-param name="formRecordedEntries"
                                    select="$formRecordedEntries"/>
                                <xsl:with-param name="usingExpressions" select="'true'"/>
                            </xsl:call-template>

                        </xsl:for-each>

                    </structuredBody>
                </component>

            </ClinicalDocument>
        </xsl:if>

    </xsl:template>

</xsl:stylesheet>
