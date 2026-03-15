<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    telemedicine2Composition.xsl
    
    Generates a composition (form) for cityEHR HL7 CDA from telemedicine data from IDIS2GO
    
    Input paramater compositionIRI identifies the composition to be generated.    
    applicationIRI and specialtyIRI define the application and folder (specialty) for the composition.
       
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
    <xsl:variable name="rootNode" select="//observation"/>

    <!-- Set the Application -->
    <xsl:variable name="applicationIRI" as="xs:string"
        select="$rootNode/applicationInformation/applicationIRI"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="applicationId" as="xs:string"
        select="replace(substring($applicationIRI, 2), ':', '-')"/>

    <!-- Set the Specialty -->
    <xsl:variable name="specialtyIRI" as="xs:string"
        select="$rootNode/applicationInformation/specialtyIRI"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="specialtyId" as="xs:string"
        select="replace(substring($specialtyIRI, 2), ':', '-')"/>

    <!-- Set the patientId and other parameters-->
    <xsl:variable name="patientId" as="xs:string"
        select="$rootNode/applicationInformation/patientId"/>
    <xsl:variable name="compositionIRI" as="xs:string"
        select="$rootNode/applicationInformation/compositionIRI"/>
    <xsl:variable name="compositionTypeIRI" as="xs:string"
        select="$rootNode/applicationInformation/compositionTypeIRI"/>
    <xsl:variable name="compositionDisplayNameTerm" as="xs:string"
        select="$rootNode/applicationInformation/compositionDisplayNameTerm"/>
    <xsl:variable name="compositionId" as="xs:string"
        select="$rootNode/applicationInformation/compositionId"/>
    <xsl:variable name="effectiveTime" as="xs:string"
        select="$rootNode/applicationInformation/effectiveTime"/>
    <xsl:variable name="handleId" as="xs:string" select="$rootNode/applicationInformation/handleId"/>

    <!-- Match document element - observation
         This must be the only node -->
    <xsl:template match="observation">
        <ClinicalDocument xmlns="urn:hl7-org:v3" xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3"
            xmlns:cityEHR="http://openhealthinformatics.org/ehr">
            <!-- CDA Header -->
            <typeId root="{$compositionTypeIRI}" extension="{$compositionIRI}"/>

            <!-- Set the context for this composition (application and specialty for which it is relevant) -->
            <templateId root="{$applicationIRI}" extension="{$specialtyIRI}"/>

            <!-- The id of the CDA document created when the composition is published to the record.
                 This is used in the patientAccess recordNavigation, so don't change it. -->
            <id root="cityEHR" extension="{$handleId}"/>

            <!-- Set the displayname of the composition -->
            <code code="" codeSystem="cityEHR" displayName="{$compositionDisplayNameTerm}"/>

            <effectiveTime value="{$effectiveTime}"/>
            <recordTarget>
                <patientRole>
                    <id extension="{$patientId}"/>
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
                        <name/>
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
                        <softwareName/>
                    </authoringDevice>
                    <representedOrganization>
                        <id root="{$applicationIRI}"/>
                        <!-- Use the application owner name here -->
                        <name/>
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
                    <xsl:apply-templates/>
                </structuredBody>
            </component>

        </ClinicalDocument>
    </xsl:template>


    <!-- Match analyse element 
         Generates a section-->
    <xsl:template match="analyse">
        <component xmlns="urn:hl7-org:v3">
            <xsl:variable name="sectionId" select="analyseType"/>
            <section cityEHR:Sequence="Ranked" cityEHR:labelWidth="26"
                cityEHR:rendition="#CityEHR:EntryProperty:Form">
                <id root="cityEHR" extension="#ISO-13606:Section:{$sectionId}"/>
                <title><xsl:value-of select="$sectionId"/></title>
                <xsl:apply-templates/>
            </section>
        </component>
    </xsl:template>

    <!-- Match measurements element 
         Generates an entry-->
    <xsl:template match="measurements">
        <xsl:variable name="entryId" select="../analyseType"/>
        <entry xmlns="urn:hl7-org:v3" cityEHR:Sequence="Ranked"
            cityEHR:rendition="#CityEHR:EntryProperty:Hidden"
            cityEHR:initialValue="#CityEHR:EntryProperty:Default" cityEHR:labelWidth="26"
            cityEHR:Scope="#CityEHR:EntryProperty:Defined"
            cityEHR:CRUD="#CityEHR:Property:CRUD:CRUD"
            cityEHR:sortOrder="#CityEHR:EntryProperty:Ascending">
            <observation>
                <typeId root="cityEHR" extension="#HL7-CDA:Observation"/>
                <id root="#ISO-13606:Entry:{$entryId}"
                    extension="#ISO-13606:Entry:RegistrationConfiguration" cityEHR:origin=""/>
                <code code="" codeSystem="cityEHR" displayName="{$entryId}"/>
                <xsl:apply-templates/>
            </observation>
        </entry>
    </xsl:template>

    <!-- Match measure element 
         Generates an element-->
    <xsl:template match="measure">
        <xsl:variable name="elementId" select="./@type"/>
        <xsl:variable name="value" select="value"/>
        
        <value xmlns="urn:hl7-org:v3" root="#ISO-13606:Element:{$elementId}"
            extension="#ISO-13606:Element:{$elementId}" xsi:type="xs:string" value="{$value}"
            units="" code="" codeSystem="" displayName="{$value}" cityEHR:elementDisplayName="{$elementId}"
            cityEHR:elementType="#CityEHR:ElementProperty:enumeratedValue" cityEHR:focus=""
            cityEHR:RequiredValue="Optional" cityEHR:Scope="#CityEHR:ElementProperty:Defined"
            cityEHR:defaultValue="for $entry in ancestor::cda:entry[1] return 'registrationconfig'"
        />
    </xsl:template>



    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>

</xsl:stylesheet>
