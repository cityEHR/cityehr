<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    CDA2OWL-Module.xsl
    Generates OWL/XML to the cityEHR architecture from a set of patient records in CDA
    The input format is the one created on export of a patient, or patient cohort, from cityEHR
    This is a set of iso-13606:EHR_Extract - one for each patient in the cohort
    Each iso-13606:EHR_Extract has a set of CDA documents which are the full record for that patient
    Root of the CDA document is cda:ClinicalDocument
       
    The ontology consists of an individual in the patient class with data properties for the CDA Header
    The object property hasRecord asserts the EHR_Extract which contains a single folder with the record contents.
    
    The folder has an IRI based on the patient id, so will be unique.
    
    The compositions use the cda:id/@extension as the IRI and IRIs for the contents that are based on the composition IRI and
    location of each component in the CDA document.
    
    Hence repeated generation of the OWL/XML will create the same assertions in the ontology (idempotent).
    
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
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:iso-13606="http://www.iso.org/iso-13606" xmlns:cda="urn:hl7-org:v3"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" 
    xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <xsl:output method="xml" indent="yes" name="xml" use-character-maps="entityOutput"/>
    
    <!-- Import OWL Utilities -->
    <xsl:include href="OWLUtilities.xsl"/>
    
    <!-- === 
         Character maps - allows the output of &rdf; in data property attributes       
        === -->
    <xsl:character-map name="entityOutput">
        <xsl:output-character character="&amp;" string="&amp;"/>
    </xsl:character-map>

    <!-- === 
        Global Variables       
        === -->

    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="/"/>

    <xsl:variable name="folderIRIBase" as="xs:string" select="'#ISO-13606:Folder'"/>
    <xsl:variable name="compositionIRIBase" as="xs:string" select="'#ISO-13606:Composition'"/>
    <xsl:variable name="sectionIRIBase" as="xs:string" select="'#ISO-13606:Section'"/>
    <xsl:variable name="entryIRIBase" as="xs:string" select="'#ISO-13606:Entry'"/>
    <xsl:variable name="clusterIRIBase" as="xs:string" select="'#ISO-13606:Cluster'"/>
    <xsl:variable name="elementIRIBase" as="xs:string" select="'#ISO-13606:Element'"/>

    <!-- === 
        Lookup table for CDA entry types       
        === -->

    <cityEHR:lookup>
        <cityEHR:owlCDAClass cdaElement="observation" owlClass="#HL7-CDA:Observation"/>
        <cityEHR:owlCDAClass cdaElement="act" owlClass="#HL7-CDA:Act"/>
    </cityEHR:lookup>

    <xsl:key name="owlClass-lookup" match="//cityEHR:owlCDAClass/@owlClass" use="../@cdaElement"/>

    <!-- Need to set this stylesheet as context before using the key to look up -->
    <xsl:function name="cityEHRFunction:lookUpOWLClass">
        <xsl:param name="cdaElement"/>
        <xsl:for-each select="document('')">
            <xsl:value-of select="key('owlClass-lookup', $cdaElement)"/>
        </xsl:for-each>
    </xsl:function>

    <!-- === 
        Generate OWL/XML with the full set of patients       
        === -->
    <xsl:template name="generateCityEHROWL">

        <!-- === The City EHR ontology architecture - static XML === 
            Copy the assertions from cityEHRarchitecture.xml
            This includes the necessary prefix declarations and some standard annotations
            plus all assertions for the cityEHR architecture
            ============================================================== -->
        
        <!-- Need to output DOCTYPE declaration so that entities can be declared -->
        <xsl:text disable-output-escaping="yes"><![CDATA[
            <!DOCTYPE Ontology [
            <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#" >
            <!ENTITY xml "http://www.w3.org/XML/1998/namespace" >
            <!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#" >
            <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
            ]> 
            ]]></xsl:text>
        
        <Ontology xmlns="http://www.w3.org/2002/07/owl#">            
            <!-- Copy attributes (including namespace declarations) from template -->
            <xsl:copy-of select="$cityEHRarchitecture/owl:Ontology/@*" copy-namespaces="yes"/>

            <!-- Copy assertions from template -->
            <xsl:copy-of select="$cityEHRarchitecture/owl:Ontology/*" copy-namespaces="no"/>


            <!-- === Annotations for the Information Model being processed.
            ============================================================== -->

            <Annotation>
                <AnnotationProperty abbreviatedIRI="rdfs:timeStamp"/>
                <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">
                    <xsl:value-of select="$timeStamp"/>
                </Literal>
            </Annotation>
            <Annotation>
                <AnnotationProperty abbreviatedIRI="rdfs:copyright"/>
                <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">Copyright (c) <xsl:value-of
                        select="year-from-date(current-date())"/>
                    <xsl:value-of select="'cityEHR'"/>
                </Literal>
            </Annotation>

            <xsl:apply-templates select="//iso-13606:EHR_Extract"/>

        </Ontology>

    </xsl:template>


    <!-- === 
        Generate OWL/XML for a patient       
        === -->
    <xsl:template match="iso-13606:EHR_Extract" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:variable name="patientId" as="xs:string" select="@patientId"/>
        <xsl:variable name="patientIRI" as="xs:string"
            select="concat('#CityEHR:Patient:',$patientId)"/>

        <xsl:variable name="extractIRI" as="xs:string"
            select="cityEHRFunction:getIRI('#ISO-13606:EHR_Extract',$patientId)"/>
        <xsl:variable name="folderIRI" as="xs:string"
            select="cityEHRFunction:getIRI($folderIRIBase,$patientId)"/>

        <xsl:variable name="compositionSet" select="cda:ClinicalDocument"/>
        <xsl:variable name="sortedCompositionSet"
            select="cityEHRFunction:sortCompositions($compositionSet)"/>

        <xsl:variable name="mostRecentComposition" select="$sortedCompositionSet[1]"/>

        <xsl:text disable-output-escaping="yes"> 
            
        </xsl:text>
        <xsl:comment> ===== Assertions related to patient <xsl:value-of select="$patientId"/> ===== </xsl:comment>
        <xsl:text disable-output-escaping="yes">           
        </xsl:text>

        <!-- Assertions for patient -->
        <Declaration>
            <NamedIndividual IRI="{$patientIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="#CityEHR:Patient"/>
            <NamedIndividual IRI="{$patientIRI}"/>
        </ClassAssertion>

        <!-- Assertion for the CDA Header.
             Get the most recent composition for the patient and use the details in its header -->
        <xsl:variable name="cdaHeader"
            select="$mostRecentComposition/cda:recordTarget/cda:patientRole"/>

        <DataPropertyAssertion>
            <DataProperty IRI="#hasIdentifier"/>
            <NamedIndividual IRI="{$patientIRI}"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$cdaHeader/cda:id/@extension"/>
            </Literal>
        </DataPropertyAssertion>

        <DataPropertyAssertion>
            <DataProperty IRI="#hasPrefix"/>
            <NamedIndividual IRI="{$patientIRI}"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$cdaHeader/cda:patient/cda:name/cda:prefix"/>
            </Literal>
        </DataPropertyAssertion>

        <DataPropertyAssertion>
            <DataProperty IRI="#hasGivenName"/>
            <NamedIndividual IRI="{$patientIRI}"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$cdaHeader/cda:patient/cda:name/cda:given"/>
            </Literal>
        </DataPropertyAssertion>

        <DataPropertyAssertion>
            <DataProperty IRI="#hasFamilyName"/>
            <NamedIndividual IRI="{$patientIRI}"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$cdaHeader/cda:patient/cda:name/cda:family"/>
            </Literal>
        </DataPropertyAssertion>

        <DataPropertyAssertion>
            <DataProperty IRI="#hasAdministrativeGenderCode"/>
            <NamedIndividual IRI="{$patientIRI}"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$cdaHeader/cda:patient/cda:administrativeGenderCode/@code"/>
            </Literal>
        </DataPropertyAssertion>

        <DataPropertyAssertion>
            <DataProperty IRI="#hasBirthTime"/>
            <NamedIndividual IRI="{$patientIRI}"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$cdaHeader/cda:patient/cda:birthTime/@value"/>
            </Literal>
        </DataPropertyAssertion>


        <!-- Assertions for patient record -->
        <Declaration>
            <NamedIndividual IRI="{$extractIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="#ISO-13606:EHR_Extract"/>
            <NamedIndividual IRI="{$extractIRI}"/>
        </ClassAssertion>

        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasRecord"/>
            <NamedIndividual IRI="{$patientIRI}"/>
            <NamedIndividual IRI="{$extractIRI}"/>
        </ObjectPropertyAssertion>

        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasContent"/>
            <NamedIndividual IRI="{$extractIRI}"/>
            <NamedIndividual IRI="{$folderIRI}"/>
        </ObjectPropertyAssertion>

        <xsl:apply-templates/>
    </xsl:template>



    <!-- ===  Match cda:ClinicalDocument to output the OWL ontology =========================================
        Iterates through the sections of the document calling template to render each one.
        There may be multiple cda:ClinicalDocument in a record extract.
        ===================================================================================================== -->
    <xsl:template match="cda:ClinicalDocument" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:variable name="composition" select="."/>

        <xsl:variable name="patientId" as="xs:string"
            select="descendant::cda:patientRole/cda:id/@extension"/>
        <xsl:variable name="folderIRI" as="xs:string"
            select="cityEHRFunction:getIRI($folderIRIBase,$patientId)"/>

        <xsl:variable name="compositionId" select="$composition/cda:id/@extension"/>
        <xsl:variable name="compositionIRI" as="xs:string"
            select="cityEHRFunction:getIRI($compositionIRIBase,$compositionId)"/>

        <!-- Assertions for the omposition -->
        <Declaration>
            <NamedIndividual IRI="{$compositionIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="#ISO-13606:Composition"/>
            <NamedIndividual IRI="{$compositionIRI}"/>
        </ClassAssertion>

        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasContent"/>
            <NamedIndividual IRI="{$folderIRI}"/>
            <NamedIndividual IRI="{$compositionIRI}"/>
        </ObjectPropertyAssertion>

        <!-- Process the sections in the composition -->
        <xsl:for-each select="$composition//cda:structuredBody/cda:component/cda:section">
            <xsl:call-template name="generateSection">
                <xsl:with-param name="patientId" select="$patientId"/>
                <xsl:with-param name="composition" select="$composition"/>
                <xsl:with-param name="containerIRI" select="$compositionIRI"/>
                <xsl:with-param name="section" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>


    <!-- ===
         Generate OWL/XML for cda:section 
         ================================ -->
    <xsl:template name="generateSection" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="patientId"/>
        <xsl:param name="composition"/>
        <xsl:param name="containerIRI"/>
        <xsl:param name="section"/>

        <xsl:variable name="compositionId" select="$composition/cda:id/@extension"/>
        <xsl:variable name="sectionId" as="xs:string"
            select="cityEHRFunction:generateId($composition/name(.),$section,'')"/>
        <xsl:variable name="sectionIRI" as="xs:string"
            select="cityEHRFunction:getIRI($sectionIRIBase,concat($patientId,$compositionId,$sectionId))"/>

        <!-- Assertions for the section -->
        <Declaration>
            <NamedIndividual IRI="{$sectionIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="#ISO-13606:Section"/>
            <NamedIndividual IRI="{$sectionIRI}"/>
        </ClassAssertion>

        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasContent"/>
            <NamedIndividual IRI="{$containerIRI}"/>
            <NamedIndividual IRI="{$sectionIRI}"/>
        </ObjectPropertyAssertion>

        <!-- Process the contents of the section
             Sections and entries handled separately
             Not recording the order of the contents (which means the generated ontology cannot be used to recreate the CDA) -->

        <!-- sub-sections -->
        <xsl:for-each select="$section/cda:component/cda:section">
            <xsl:call-template name="generateSection">
                <xsl:with-param name="patientId" select="$patientId"/>
                <xsl:with-param name="composition" select="$composition"/>
                <xsl:with-param name="containerIRI" select="$sectionIRI"/>
                <xsl:with-param name="section" select="."/>
            </xsl:call-template>
        </xsl:for-each>

        <!-- entries -->
        <xsl:for-each select="$section/cda:entry">
            <xsl:call-template name="processEntry">
                <xsl:with-param name="patientId" select="$patientId"/>
                <xsl:with-param name="composition" select="$composition"/>
                <xsl:with-param name="sectionIRI" select="$sectionIRI"/>
                <xsl:with-param name="entry" select="."/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>


    <!-- ===
        Process a cda:entry
        This may be a single or multiple entry
        There is one iso:13606 entry generated for each cda:observation, cda:act, etc 
        ================================ -->
    <xsl:template name="processEntry" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="patientId"/>
        <xsl:param name="composition"/>
        <xsl:param name="sectionIRI"/>
        <xsl:param name="entry"/>

        <!-- Simple entry (observation, act, etc) -->
        <xsl:variable name="simpleEntry" select="$entry/cda:observation|$entry/cda:act"/>
        <xsl:if test="exists($simpleEntry)">
            <xsl:call-template name="generateEntry">
                <xsl:with-param name="patientId" select="$patientId"/>
                <xsl:with-param name="composition" select="$composition"/>
                <xsl:with-param name="sectionIRI" select="$sectionIRI"/>
                <xsl:with-param name="entry" select="$simpleEntry"/>
            </xsl:call-template>
        </xsl:if>

        <!-- Multiple entry component.
             Entry has an orgnazier with one or two components (first component is template in legacy data, although is now removed on publish)
             The component containing multiple entries has a second organizer with components holding the observations -->
        <xsl:for-each
            select="$entry/cda:organizer[@classCode='MultipleEntry']/cda:component/cda:organizer[not(@classCode='EnumeratedClassEntry')]/cda:component/cda:observation">
            <xsl:call-template name="generateEntry">
                <xsl:with-param name="patientId" select="$patientId"/>
                <xsl:with-param name="composition" select="$composition"/>
                <xsl:with-param name="sectionIRI" select="$sectionIRI"/>
                <xsl:with-param name="entry" select="."/>
            </xsl:call-template>
        </xsl:for-each>

        <!-- Component for entry with supplementary data.
             Entry has an organizer with two components.
             First component is the observation, 
             second is an organizer with one or more components containing observations for supplementary data sets -->
        <xsl:for-each select="$entry/cda:organizer[@classCode='EnumeratedClassEntry']">
            <xsl:variable name="enumeratedClassEntry" select="."/>
            
            <xsl:call-template name="processEnumeratedClassEntry">
                <xsl:with-param name="patientId" select="$patientId"/>
                <xsl:with-param name="composition" select="$composition"/>
                <xsl:with-param name="sectionIRI" select="$sectionIRI"/>
                <xsl:with-param name="enumeratedClassEntry" select="$enumeratedClassEntry"/>
            </xsl:call-template>
            
        </xsl:for-each>


        <!-- Multiple entry component, including entry with supplementary data.
             Entry has an orgnazier with one or two components (first component is template in legacy data, although is now removed on publish)
             The component containing multiple entries has a second organizer with components holding the organizer for EnumeratedClassEntry -->
        <xsl:for-each
            select="$entry/cda:organizer[@classCode='MultipleEntry']/cda:component/cda:organizer[not(@classCode='EnumeratedClassEntry')]/cda:component/cda:organizer[@classCode='EnumeratedClassEntry']">
            <xsl:variable name="enumeratedClassEntry" select="."/>
            
            <xsl:call-template name="processEnumeratedClassEntry">
                <xsl:with-param name="patientId" select="$patientId"/>
                <xsl:with-param name="composition" select="$composition"/>
                <xsl:with-param name="sectionIRI" select="$sectionIRI"/>
                <xsl:with-param name="enumeratedClassEntry" select="$enumeratedClassEntry"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>


    <!-- ===
        Generate an iso-13606:entry
        One iso:13606 entry generated for each cda:observation, cda:act, etc 
        ================================ -->
    <xsl:template name="generateEntry" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="patientId"/>
        <xsl:param name="composition"/>
        <xsl:param name="sectionIRI"/>
        <xsl:param name="entry"/>

        <xsl:variable name="compositionId" select="$composition/cda:id/@extension"/>
        <xsl:variable name="entryId" as="xs:string"
            select="cityEHRFunction:generateId($composition/name(.),$entry,'')"/>
        <xsl:variable name="entryIRI" as="xs:string"
            select="cityEHRFunction:getIRI($entryIRIBase,concat($patientId,$compositionId,$entryId))"/>

        <!-- Get the OWL/XML class for the cda element -->
        <xsl:variable name="owlClass" select="cityEHRFunction:lookUpOWLClass($entry/name())"/>

        <!-- Assertions for the entry -->
        <Declaration>
            <NamedIndividual IRI="{$entryIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="{$owlClass}"/>
            <NamedIndividual IRI="{$entryIRI}"/>
        </ClassAssertion>

        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasContent"/>
            <NamedIndividual IRI="{$sectionIRI}"/>
            <NamedIndividual IRI="{$entryIRI}"/>
        </ObjectPropertyAssertion>

        <!-- Process the cda:value elements (iso-13606 clusters or elements) -->
        <xsl:for-each select="$entry/cda:value">
            <xsl:call-template name="generateClusterOrElement">
                <xsl:with-param name="patientId" select="$patientId"/>
                <xsl:with-param name="composition" select="$composition"/>
                <xsl:with-param name="containerIRI" select="$entryIRI"/>
                <xsl:with-param name="value" select="."/>
            </xsl:call-template>
        </xsl:for-each>

    </xsl:template>
    
    
    <!-- ===
        Process the organizer for an EnumeratedClassEntry  
        ================================ -->
    
    <xsl:template name="processEnumeratedClassEntry" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="patientId"/>
        <xsl:param name="composition"/>
        <xsl:param name="sectionIRI"/>
        <xsl:param name="enumeratedClassEntry"/>  

        <xsl:variable name="entry" select="$enumeratedClassEntry/cda:component[1]/cda:observation"/>
        
        <!-- Should just be one observation in the first component.
             Only process if this is found -->
        <xsl:if test="exists($entry)">
            <xsl:call-template name="generateEntry">
                <xsl:with-param name="patientId" select="$patientId"/>
                <xsl:with-param name="composition" select="$composition"/>
                <xsl:with-param name="sectionIRI" select="$sectionIRI"/>
                <xsl:with-param name="entry" select="$entry"/>
            </xsl:call-template>
            
            <!-- Need the IRI for the entry so that supplementary data can be asserted -->
            <xsl:variable name="compositionId" select="$composition/cda:id/@extension"/>
            <xsl:variable name="entryId" as="xs:string"
                select="cityEHRFunction:generateId($composition/name(.),$entry,'')"/>
            <xsl:variable name="entryIRI" as="xs:string"
                select="cityEHRFunction:getIRI($entryIRIBase,concat($patientId,$compositionId,$entryId))"/>
            
            <!-- Add supplementary data from the second component -->
            <xsl:for-each
                select="$enumeratedClassEntry/cda:component[2]/cda:organizer/cda:component/cda:observation">
                <xsl:variable name="supplementaryEntry" select="."/>
                
                <xsl:call-template name="generateSupplementaryEntry">
                    <xsl:with-param name="patientId" select="$patientId"/>
                    <xsl:with-param name="composition" select="$composition"/>
                    <xsl:with-param name="entryIRI" select="$entryIRI"/>
                    <xsl:with-param name="supplementaryEntry" select="$supplementaryEntry"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
        
    </xsl:template>
    
    
    <!-- ===
        Generate an iso-13606:entry for supplementary data set 
        ================================ -->
    <xsl:template name="generateSupplementaryEntry" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="patientId"/>
        <xsl:param name="composition"/>
        <xsl:param name="entryIRI"/>
        <xsl:param name="supplementaryEntry"/>
        
        <xsl:variable name="compositionId" select="$composition/cda:id/@extension"/>
        <xsl:variable name="supplementaryEntryId" as="xs:string"
            select="cityEHRFunction:generateId($composition/name(.),$supplementaryEntry,'')"/>
        <xsl:variable name="supplementaryEntryIRI" as="xs:string"
            select="cityEHRFunction:getIRI($entryIRIBase,concat($patientId,$compositionId,$supplementaryEntryId))"/>
        
        <!-- Get the OWL/XML class for the cda element -->
        <xsl:variable name="owlClass" select="cityEHRFunction:lookUpOWLClass($supplementaryEntry/name())"/>
        
        <!-- Assertions for the entry -->
        <Declaration>
            <NamedIndividual IRI="{$supplementaryEntryIRI}"/>
        </Declaration>
        
        <ClassAssertion>
            <Class IRI="{$owlClass}"/>
            <NamedIndividual IRI="{$supplementaryEntryIRI}"/>
        </ClassAssertion>
        
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasSuppDataSet"/>
            <NamedIndividual IRI="{$entryIRI}"/>
            <NamedIndividual IRI="{$supplementaryEntryIRI}"/>
        </ObjectPropertyAssertion>
        
        <!-- Process the cda:value elements (iso-13606 clusters or elements) -->
        <xsl:for-each select="$supplementaryEntry/cda:value">
            <xsl:call-template name="generateClusterOrElement">
                <xsl:with-param name="patientId" select="$patientId"/>
                <xsl:with-param name="composition" select="$composition"/>
                <xsl:with-param name="containerIRI" select="$supplementaryEntryIRI"/>
                <xsl:with-param name="value" select="."/>
            </xsl:call-template>
        </xsl:for-each>
        
    </xsl:template>

    <!-- ===
        Generate OWL/XML for cda:value
        Could be an element or a cluster
        ================================ -->
    <xsl:template name="generateClusterOrElement" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="patientId"/>
        <xsl:param name="composition"/>
        <xsl:param name="containerIRI"/>
        <xsl:param name="value"/>


        <xsl:variable name="compositionId" select="$composition/cda:id/@extension"/>
        <xsl:variable name="clusterOrElementId" as="xs:string"
            select="cityEHRFunction:generateId($composition/name(.),$value,'')"/>

        <!-- Can be a cluster or an element -->
        <xsl:variable name="classIRIBase"
            select="if (exists($value/cda:value)) then $clusterIRIBase else $elementIRIBase"/>

        <xsl:variable name="clusterOrElementIRI" as="xs:string"
            select="cityEHRFunction:getIRI($classIRIBase,concat($patientId,$compositionId,$clusterOrElementId))"/>

        <!-- Assertions for the cluster/element -->
        <Declaration>
            <NamedIndividual IRI="{$clusterOrElementIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="{$classIRIBase}"/>
            <NamedIndividual IRI="{$clusterOrElementIRI}"/>
        </ClassAssertion>

        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasContent"/>
            <NamedIndividual IRI="{$containerIRI}"/>
            <NamedIndividual IRI="{$clusterOrElementIRI}"/>
        </ObjectPropertyAssertion>

        <!-- If this is a cluster, then process the child cda:values (clsuters or elements) -->
        <xsl:if test="$classIRIBase=$clusterIRIBase">
            <xsl:for-each select="$value/cda:value">
                <xsl:call-template name="generateClusterOrElement">
                    <xsl:with-param name="patientId" select="$patientId"/>
                    <xsl:with-param name="composition" select="$composition"/>
                    <xsl:with-param name="containerIRI" select="$clusterOrElementIRI"/>
                    <xsl:with-param name="value" select="."/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>

        <!-- If this is am element, then make assertion for its value -->
        <xsl:if test="$classIRIBase=$elementIRIBase">
            <DataPropertyAssertion>
                <DataProperty IRI="#hasValue"/>
                <NamedIndividual IRI="{$clusterOrElementIRI}"/>
                <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">
                    <xsl:value-of select="$value/@value"/>
                </Literal>
            </DataPropertyAssertion>
        </xsl:if>

    </xsl:template>

    <!-- === 
         Function to sort a composition set by effectiveTime (most recent first) 
         ======================================================================= -->
    <xsl:function name="cityEHRFunction:sortCompositions">
        <xsl:param name="compositionSet"/>
        <xsl:for-each select="$compositionSet">
            <xsl:sort select="cda:effectiveTime/@value" order="descending"/>
            <xsl:sequence select="."/>
        </xsl:for-each>
    </xsl:function>


    <!-- === 
         Function to generate a unique node id within a certain root node (e.g. cda:ClinicalDocument)
         Is idempotent (will always generate the same id for a given node within the same document structure)
         ======================================================================= -->
    <xsl:function name="cityEHRFunction:generateId">
        <xsl:param name="rootNodeName"/>
        <xsl:param name="node"/>
        <xsl:param name="idBase"/>

        <xsl:if test="$node/name()=$rootNodeName">
            <xsl:value-of select="$idBase"/>
        </xsl:if>

        <xsl:if test="$node/name()!=$rootNodeName">
            <xsl:value-of
                select="cityEHRFunction:generateId($rootNodeName,$node/parent::*,concat('-',count($node/preceding-sibling::*),$idBase))"
            />
        </xsl:if>
    </xsl:function>


</xsl:stylesheet>
