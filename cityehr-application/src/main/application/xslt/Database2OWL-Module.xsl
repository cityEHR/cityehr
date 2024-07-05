<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    Database2OWL-Module.xsl
    Input is a cityEHR database (from spreadsheet in .ods, .xlsx or msxml format) with data dictionary and forms or class hierarchy for a specialty
    Plus the static ontology shell passed in on the cityEHRarchitecture input
    Generates an OWL/XML ontology as per the City EHR architecture.
    
    Any errors found are reported using the generateError template defined in OWLUtilities.xsl
    
    This module is designed to be called from Database2OWL.xsl or Database2OWLFile.xsl.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<!-- === Note: This version uses &amp;rdf;PlainLiteral with a character map to output &rdf;PlainLiteral.
    2016-04-21 Could change to output &amp;rdf;PlainLiteral - this seems to be more normal, even though Protege uses &rdf;PlainLiteral
    &rdf; is an entity and only works if the entity is declared in the document prologue. 
    
    So we now use: datatypeIRI="&amp;rdf;PlainLiteral"
    To put back to the Protege way, make a global replace on datatypeIRI="&amp;rdf;PlainLiteral"
-->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <!-- Output formatted XML -->
    <xsl:output method="xml" indent="yes" name="xml" use-character-maps="entityOutput"/>

    <!-- Import OWL Utilities -->
    <xsl:include href="OWLUtilities.xsl"/>

    <!-- === 
        Character maps - allows the output of &rdf; in data property attributes       
        === -->
    <xsl:character-map name="entityOutput">
        <xsl:output-character character="&amp;" string="&amp;"/>
    </xsl:character-map>


    <!-- ==============================================
        Global variables 
        ============================================== -->

    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="/"/>

    <!-- Set the prefix used for propertyIRIs (for properties defined on the sheet named 'Properties' -->
    <xsl:variable name="propertyIRI" select="'#CityEHR:Property'"/>

    <!-- Set the configuration sheet -->
    <xsl:variable name="configurationSheet" select="/database/table[@id = 'Configuration']"/>

    <!-- Set the Application for this Information Model -->
    <xsl:variable name="applicationId" select="$configurationSheet/record[field[1] = 'ApplicationId']/field[2]"/>
    <xsl:variable name="applicationOwner" select="$configurationSheet/record[field[1] = 'ApplicationOwner']/field[2]"/>


    <!-- Set the Specialty for this Information Model -->
    <xsl:variable name="specialtyId" select="$configurationSheet/record[field[1] = 'SpecialtyId']/field[2]"/>
    <xsl:variable name="specialtyDisplayName" select="$configurationSheet/record[field[1] = 'SpecialtyDisplayName']/field[2]"/>

    <!-- Set the Class for this Information Model.
         This will only get set for a class model - specialty model will leave these empty -->
    <xsl:variable name="classId"
        select="
            if (exists($configurationSheet/record[field[1] = 'ClassId'])) then
                $configurationSheet/record[field[1] = 'ClassId']/field[2]
            else
                ()"/>
    <xsl:variable name="classDisplayName"
        select="
            if (exists($configurationSheet/record[field[1] = 'ClassDisplayName'])) then
                $configurationSheet/record[field[1] = 'ClassDisplayName']/field[2]
            else
                ()"/>

    <!-- Set the Base Language for this Information Model - this should be in OETF language code format ll-cc -->
    <xsl:variable name="specifiedLanguageCode" select="$configurationSheet/record[field[1] = 'LanguageCode']/field[2]"/>
    <xsl:variable name="baseLanguageCode"
        select="
            if ($specifiedLanguageCode != '') then
                $specifiedLanguageCode
            else
                'en-gb'"/>

    <!-- Set the pathSeparator for this Information Model -->
    <xsl:variable name="specifiedPathSeparator" select="$configurationSheet/record[field[1] = 'PathSeparator']/field[2]"/>
    <xsl:variable name="pathSeparator"
        select="
            if ($specifiedPathSeparator != '') then
                $specifiedPathSeparator
            else
                '/'"/>

    <!-- Can only process spreadsheet if applicationId and specialtyId are defined -->
    <xsl:variable name="processError" as="xs:string"
        select="
            if ($applicationId != '' and $specialtyId != '') then
                'false'
            else
                'true'"/>

    <!-- ==============================================
         Variables for displayNames
         ============================================== -->

    <!-- Specialty and class have display names -->
    <xsl:variable name="specialtyTerms" select="$specialtyDisplayName | $classDisplayName"/>

    <!-- In all tables except Configuration, Properties and Contents
         The displayName is in field position 2, only for records where there is an Identifier in the first field
         And not on the first record, which has the field headers -->
    <xsl:variable name="modelComponentSheets" select="database/table[not(@id = ('Configuration', 'Properties', 'Contents'))]"/>
    <xsl:variable name="displayNameTerms" select="$modelComponentSheets/record[position() gt 1][field[1] != '']/field[2][normalize-space(.) != '']"/>

    <!-- Element value displayNames are in the Data of the Element sheet.
         But only for elements with an Id and of enumeratedValue, enumeratedClass or enumeratedDirectory type -->
    <xsl:variable name="elementTable" select="database/table[@id = 'Element']"/>
    <xsl:variable name="typePosition" select="$elementTable/record[1]/field[. = 'ElementType']/count(preceding-sibling::*) + 1"/>
    <xsl:variable name="elementTableRecords"
        select="$elementTable/record[position() gt 1][field[1] != ''][field[position() = $typePosition] = ('enumeratedValue', 'enumeratedClass', 'enumeratedDirectory')]"/>
    <xsl:variable name="valuePosition" select="$elementTable/record[1]/field[. = 'Data']/count(preceding-sibling::*) + 1"/>
    <xsl:variable name="elementValueTerms" select="cityEHRFunction:GetValueDisplayNames($elementTableRecords, $valuePosition)"/>

    <xsl:variable name="allTerms" select="$specialtyTerms/normalize-space(.), $displayNameTerms/normalize-space(.), $elementValueTerms"/>


    <!-- ==============================================
        Define Keys  
        ============================================== -->

    <!-- Key for Properties    
         propertySetFields returns set of fields for a cityEHR property.
         The properties are dfined on the sheet named 'Properties'
    -->
    <xsl:key name="propertySetFields" match="/database/table[@id = 'Properties']/record[position() gt 1][field[1]/normalize-space(.) != '']/field"
        use="normalize-space(../field[1])"/>

    <!-- === 
         Generate OWL/XML with the full cityEHR ontology for this information model       
         === -->
    <xsl:template match="database">

        <!-- === Output the DOCTYPE and document type declaration subset with entity definitions.
            Plus the root document node for the Ontology -->

        <!-- This would be required to make identical to the format Protege uses.
            Then use &rdf;PlainLiteral
            But xforms processing doesn't like document prologue, so we are not using it -->
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
            <!-- Copy attributes (including namespace declarations) from template -->
            <xsl:copy-of select="$cityEHRarchitecture/owl:Ontology/@*"/>

            <!-- === The City EHR ontology architecture - static XML === 
                Copy the assertions from cityEHRarchitecture.xml
                This includes the necessary prefix declarations and some standard annotations
                plus all assertions for the cityEHR architecture
                ============================================================== -->
            <xsl:copy-of select="$cityEHRarchitecture/owl:Ontology/*"/>


            <!-- Process the sheets to build the model -->
            <xsl:apply-templates/>

        </Ontology>
    </xsl:template>

    <!-- Table for configuration
         The parameters in this table are recorded as annotations in the ontology
         -->
    <xsl:template match="table[@id = 'Configuration']">
        <xsl:call-template name="generateAnnotations"/>
        <xsl:call-template name="generateApplicationDeclarations"/>
    </xsl:template>

    <!-- Table for properties.
         The cityEHR properties for this ontology
         These are cityEHR specific properties applied to the model components
        -->
    <xsl:template match="table[@id = 'Properties']">
        <!-- Each property in a separate record, except for the header record -->
        <xsl:for-each select="record[position() gt 1][field[1] != '']">

            <xsl:variable name="propertyType" select="normalize-space(field[1])"/>
            <xsl:variable name="propertyValues" select="field[position() gt 1]/normalize-space(.)"/>

            <xsl:call-template name="generatePropertySet">
                <xsl:with-param name="propertyType" select="$propertyType"/>
                <xsl:with-param name="propertyValues" select="$propertyValues"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- Table for contents - does not need to be processed
         But use it to output the declarations for value, displayName and term -->
    <xsl:template match="table[@id = 'Contents']">
        <!-- Generate assertions for the terms -->
        <xsl:call-template name="generateTerms">
            <xsl:with-param name="terms" select="distinct-values($allTerms)"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Table for class hierarchy - 
    -->
    <xsl:template match="table[@id = 'Class']">
        <!-- The class for this ontology
                Single individual as a member of the root class.
                
                The class must be present on the Configuration sheet.                
                $classId and $classDisplayName are set in the XSL that calls this module.
                
                Assert the individual
                Set its class to CityEHR:Class
                Set its displayName
            -->
        <xsl:call-template name="generateClass"/>


        <!-- The set of properties is in the first record.
             May contain blank fields after the final property, but not before -->
        <xsl:variable name="propertySet" select="record[1]/field[. != '']"/>

        <!-- The adjacency matrix is all the other rows -->
        <xsl:variable name="matrix" select="record[position() > 1]"/>


        <xsl:call-template name="generateClassHierarchy">
            <xsl:with-param name="propertySet" select="$propertySet"/>
            <xsl:with-param name="matrix" select="$matrix"/>
        </xsl:call-template>

    </xsl:template>


    <!-- Table for clinical codes - 
    -->
    <xsl:template match="table[@id = 'Codes']">
        <!-- TBD -->
    </xsl:template>

    <!-- Table for synonyms  - 
    -->
    <xsl:template match="table[@id = 'Synonyms']">
        <!-- TBD -->
    </xsl:template>

    <!-- Table for supplementary data sets - ignore
    -->
    <xsl:template match="table[@id = 'sdsEntry']"/>


    <!-- All other tables are for components in the model.
         Output the property assertions for each component (record) -->
    <xsl:template match="table">
        <xsl:variable name="componentType" select="@id"/>

        <!-- Only output for tables that have a name -->
        <xsl:if test="$componentType != ''">
            <!-- Set the IRI for the component - prefix is either ISO-13606 or CityEHR-->
            <xsl:variable name="componentTypeIRI" select="cityEHRFunction:GetComponentTypeIRI($componentType)"/>

            <!-- The set of properties is in the first record.
                 May contain blank fields after the final property, but not before -->
            <xsl:variable name="propertySet" select="record[1]/field[. != '']"/>
            <xsl:variable name="identifierProperty" select="$propertySet[1]"/>

            <!-- Generate an error if identifier property is bad -->
            <xsl:if test="$identifierProperty != 'Identifier'"> </xsl:if>

            <!-- Only continue if the sheet has an identifier property -->
            <xsl:if test="$identifierProperty = 'Identifier'">

                <!-- Check that the identifiers are unique -->
                <xsl:variable name="identifierSet" select="record[position() gt 1]/field[1][. != '']"/>
                <xsl:variable name="repeatIdentifiers" select="cityEHRFunction:getRepeatIdentifiers($identifierSet)"/>

                <!-- Output assertions for each identified component (record)
                     But only if identifiers are OK -->
                <xsl:if test="empty($repeatIdentifiers)">
                    <xsl:for-each select="record[position() gt 1][field[1] != '']">
                        <xsl:variable name="propertyValues" select="field/normalize-space(.)"/>

                        <xsl:call-template name="generateComponentAssertions">
                            <xsl:with-param name="componentTypeIRI" select="$componentTypeIRI"/>
                            <xsl:with-param name="propertySet" select="$propertySet"/>
                            <xsl:with-param name="propertyValues" select="$propertyValues"/>
                        </xsl:call-template>

                    </xsl:for-each>
                </xsl:if>

                <!-- Output errors for any repeat identifiers -->
                <xsl:for-each select="$repeatIdentifiers">
                    <xsl:variable name="identifier" select="."/>
                    <xsl:call-template name="generateError">
                        <xsl:with-param name="node" select="$identifier"/>
                        <xsl:with-param name="context" select="$componentType"/>
                        <xsl:with-param name="message" select="'Identifier not unique'"/>
                    </xsl:call-template>
                </xsl:for-each>

            </xsl:if>
        </xsl:if>
    </xsl:template>


    <!-- ====================================================================
        cityEHRFunction:GetFieldPosition
        Get the position of a field with a specified value in a propertySet
        Find the first matching value only.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:GetFieldPosition">
        <xsl:param name="propertySet"/>
        <xsl:param name="value"/>

        <xsl:value-of select="count($propertySet[normalize-space(.) = $value][1]/preceding-sibling::*) + 1"/>

    </xsl:function>


    <!-- ====================================================================
        cityEHRFunction:GetPropertyValue
        Get the value in a valueSet for a property in a propertySet
        Find the first matching value only.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:GetPropertyValue">
        <xsl:param name="propertySet"/>
        <xsl:param name="propertyValueSet"/>
        <xsl:param name="property"/>

        <xsl:variable name="propertyPosition" as="xs:integer" select="cityEHRFunction:GetFieldPosition($propertySet, $property)"/>

        <xsl:value-of select="$propertyValueSet[position() = $propertyPosition]"/>

    </xsl:function>


    <!-- ====================================================================
        cityEHRFunction:GetDefaultPropertyValue
        Get the default value in a valueSet for a property.
        If no special case, then gets the first value in the propertyValueSet
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:GetDefaultPropertyValue">
        <xsl:param name="propertyTypeId"/>
        <xsl:param name="propertyValueSet"/>

        <xsl:value-of select="$propertyValueSet[1]"/>

    </xsl:function>


    <!-- ====================================================================
        cityEHRFunction:GetDataPropertyValue
        Get the value for a data property, including any default
        If no special case, then gets the value passed
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:GetDataPropertyValue">
        <xsl:param name="propertyTypeId"/>
        <xsl:param name="propertyValue"/>

        <!-- Get default, if property value is not set -->
        <xsl:if test="$propertyValue = ''">
            <xsl:value-of
                select="
                    if ($propertyTypeId = 'Rank') then
                        '1'
                    else
                        ''"
            />
        </xsl:if>

        <!-- Just return the property value, if it is set -->
        <xsl:if test="$propertyValue != ''">
            <xsl:value-of select="$propertyValue"/>
        </xsl:if>

    </xsl:function>



    <!-- ====================================================================
        cityEHRFunction:GetValueDisplayNames
        Get the set of displayNames for the Values in the Element table
        Finds displayNames for all the records
        
        Starting from valuePosition, each record has pairs of displayName,value - this is the valueSet
        Need to return all the displayNames from valueSet, which is all elements at odd-numbered positions.
        But not the blank ones.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:GetValueDisplayNames">
        <xsl:param name="elementTableRecords"/>
        <xsl:param name="valuePosition"/>

        <xsl:for-each select="$elementTableRecords">
            <xsl:variable name="valueSet" select="field[position() ge $valuePosition]"/>
            <xsl:sequence select="cityEHRFunction:GetDisplayNames($valueSet)[. != '']"/>
        </xsl:for-each>

    </xsl:function>


    <!-- ====================================================================
        cityEHRFunction:GetValues
        Get the set of Values from the set of fields with dsiplayName,value pairs
        Each dsiplayName,value pair must have a displayName, but may not have a value
        
        Starting from valuePosition, each record has pairs of displayName,value - this is the valueSet
        Need to return all the values from valueSet, which is all elements at even-numbered positions.
        If the value is not set, then it defaults to the displaName (even if displayName is blank)
       
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:GetValues">
        <xsl:param name="valueSet"/>

        <!-- Iterate through all displayNames (these are in odd-numbered positions)
             The iteration must be through displayNames, since these always exist -->
        <xsl:for-each select="$valueSet">
            <xsl:variable name="position" select="position()"/>
            <xsl:variable name="displayName" select="normalize-space(.)"/>
            <xsl:if test="cityEHRFunction:isOdd($position)">
                <xsl:variable name="value" select="normalize-space($valueSet[position() = $position + 1])"/>
                <xsl:sequence
                    select="
                        if (exists($value) and $value != '') then
                            $value
                        else
                            $displayName"
                />
            </xsl:if>
        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        cityEHRFunction:GetDisplayNames
        Get the set of displayNames from the set of values with dsiplayName,value pairs
        
        Starting from valuePosition, each record has pairs of displayName,value - this is the valueSet
        Need to return all the displayNames from valueSet, which is all elements at odd-numbered positions.
        Always returns the displayName (even if it is blank)
        
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:GetDisplayNames">
        <xsl:param name="valueSet"/>

        <!-- Iterate through all displayNames (these are in odd-numbered positions) -->
        <xsl:for-each select="$valueSet">
            <xsl:variable name="position" select="position()"/>
            <xsl:variable name="displayName" select="normalize-space(.)"/>
            <xsl:if test="cityEHRFunction:isOdd($position)">
                <xsl:sequence select="$displayName"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        cityEHRFunction:isOdd
        Returns true() if the number is odd, false if it is even
        (mod 2 is either 1 or 0, if odd/even, which correspond to true/false)
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:isOdd" as="xs:boolean">
        <xsl:param name="number"/>
        <xsl:value-of
            select="
                if ($number castable as xs:integer) then
                    ($number mod 2)
                else
                    false()"
        />
    </xsl:function>


    <!-- ====================================================================
        cityEHRFunction:isEven
        Returns true() if the number is even, false if it is odd
        (mod 2 is either 1 or 0, if odd/even, which correspond to true/false)
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:isEven" as="xs:boolean">
        <xsl:param name="number"/>
        <xsl:value-of
            select="
                if ($number castable as xs:integer) then
                    not(($number mod 2))
                else
                    false()"
        />
    </xsl:function>


    <!-- ====================================================================
         cityEHRFunction:getSequence
         Get sequence of $value, repeated $occurenceCount times.
         This is a tail recursive function.
        -->
    <xsl:function name="cityEHRFunction:getSequence">
        <xsl:param name="value" as="xs:string"/>
        <xsl:param name="occurenceCount"/>

        <xsl:sequence select="$value"/>

        <xsl:variable name="nextOccurenceCount" select="$occurenceCount - 1"/>
        <xsl:if test="$nextOccurenceCount gt 0">
            <xsl:sequence select="cityEHRFunction:getSequence($value, $nextOccurenceCount)"/>
        </xsl:if>

    </xsl:function>

    <!-- === 
        cityEHRFunction:getRepeatIdentifiers
        Check that a set of identifiers is unique  
        Returns the set of non-unique identifiers (so empty sequence if all are unique).
        This is a tail recursive function.
        === -->
    <xsl:function name="cityEHRFunction:getRepeatIdentifiers">
        <xsl:param name="identifierSet"/>

        <xsl:variable name="identifier" select="$identifierSet[1]"/>
        <xsl:variable name="nextIdentifierSet" select="$identifierSet[position() gt 1]"/>

        <!-- Return repeat, if it exists -->
        <xsl:if test="$identifier = $nextIdentifierSet">
            <xsl:sequence select="$identifier"/>
        </xsl:if>

        <!-- Process rest of the identifiers -->
        <xsl:if test="not(empty($nextIdentifierSet))">
            <xsl:sequence select="cityEHRFunction:getRepeatIdentifiers($nextIdentifierSet)"/>
        </xsl:if>

    </xsl:function>


    <!-- === 
        cityEHRFunction:GetComponentTypeIRI
        Get the IRI for a component type (append either ISO-13606: or CityEHR:)
        
        Could just compare componentType with the set of ISO-13606 components (Folder,Composition,Section,Entry,Cluster,Element) 
        === -->
    <xsl:function name="cityEHRFunction:GetComponentTypeIRI">
        <xsl:param name="componentType"/>

        <!-- Component is either ISO-13606 or CityEHR -->
        <xsl:variable name="componentTypeIRI-ISO-13606" select="concat('#ISO-13606:', $componentType)"/>
        <xsl:variable name="componentTypeIRI-CityEHR" select="concat('#CityEHR:', $componentType)"/>

        <!-- Find a declaration for ISO-13606 in the cityEHRarchitecture -->
        <xsl:variable name="ISO-13606Declaration"
            select="$cityEHRarchitecture/owl:Ontology/owl:Declaration/owl:Class[@IRI = $componentTypeIRI-ISO-13606]"/>

        <!-- Return either componentTypeIRI-ISO-13606 or componentTypeIRI-CityEHR -->
        <xsl:variable name="componentTypeIRI"
            select="
                if (exists($ISO-13606Declaration)) then
                    $componentTypeIRI-ISO-13606
                else
                    $componentTypeIRI-CityEHR"/>
        <xsl:value-of select="$componentTypeIRI"/>
    </xsl:function>

    <!-- === 
        cityEHRFunction:GetComponentIRI
        Get the IRI for a component, 
        given a componentId of the form type:id (append either ISO-13606: or CityEHR:)

        === -->
    <xsl:function name="cityEHRFunction:GetComponentIRI">
        <xsl:param name="componentId"/>

        <xsl:variable name="componentType" select="substring-before($componentId, ':')"/>
        <xsl:variable name="componentTypeIRI" select="cityEHRFunction:GetComponentTypeIRI($componentType)"/>

        <xsl:value-of select="concat($componentTypeIRI, ':', $componentId)"/>

    </xsl:function>

    <!-- === 
        cityEHRFunction:GetComponentIRIList
        Get list of componentIRI for a list of componentId, 
        given componentIds of the form type:id (append either ISO-13606: or CityEHR:)
        The componentIdList may contain blanks ('') so these need to be ignored
        === -->
    <xsl:function name="cityEHRFunction:GetComponentIRIList">
        <xsl:param name="componentIdList"/>

        <xsl:for-each select="$componentIdList[. != '']">
            <xsl:variable name="componentId" select="."/>
            <xsl:variable name="componentType" select="substring-before($componentId, ':')"/>
            <xsl:variable name="componentTypeIRI" select="cityEHRFunction:GetComponentTypeIRI($componentType)"/>

            <xsl:sequence select="concat($componentTypeIRI, ':', substring-after($componentId, ':'))"/>
        </xsl:for-each>
    </xsl:function>

    <!-- === 
        Generate Application Declarations
        Application, Specialty, Class (for a class model)
        === -->
    <xsl:template name="generateApplicationDeclarations" xmlns="http://www.w3.org/2002/07/owl#">
        <!--The application for this ontology
            Corresponds to a top-level ISO-13606:EHR_Extract.
            
            The application must be present on the Configuration sheet.                
            $applicationId and $applicationDisplayName are set in the XSL that calls this module.
            
            Assert the individual
            Set its class to ISO-13606:EHR_Extract
            Set its displayName
            
        -->
        <Declaration>
            <NamedIndividual IRI="{$applicationIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="#ISO-13606:EHR_Extract"/>
            <NamedIndividual IRI="{$applicationIRI}"/>
        </ClassAssertion>

        <!-- The Language for this ontology -->
        <DataPropertyAssertion>
            <DataProperty IRI="#hasBaseLanguage"/>
            <NamedIndividual IRI="{$applicationIRI}"/>
            <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$baseLanguageCode"/>
            </Literal>
        </DataPropertyAssertion>

        <!-- The specialty for this ontology
            Corresponds to a top-level ISO-13606:Folder
            
            The specialty must be present on the Configuration sheet.                
            $specialtyId and $specialtyDisplayName are set in the XSL that calls this module.
            Note that $specialtyDisplayName is blank for class models, so does not need assertions.
            
            Assert the individual
            Set its class to ISO-13606:EHR_Folder
            Set the Folder as content of the EHR_Extract
            Set its displayName
        -->
        <Declaration>
            <Class IRI="{$specialtyIRI}"/>
        </Declaration>

        <SubClassOf>
            <Class IRI="{$specialtyIRI}"/>
            <Class IRI="#ISO-13606:Folder"/>
        </SubClassOf>

        <Declaration>
            <NamedIndividual IRI="{$specialtyIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="#ISO-13606:Folder"/>
            <NamedIndividual IRI="{$specialtyIRI}"/>
        </ClassAssertion>

        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasContent"/>
            <NamedIndividual IRI="{$applicationIRI}"/>
            <NamedIndividual IRI="{$specialtyIRI}"/>
        </ObjectPropertyAssertion>

        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasDisplayName"/>
            <NamedIndividual IRI="{$specialtyIRI}"/>
            <NamedIndividual IRI="{$specialtyTermIRI}"/>
        </ObjectPropertyAssertion>

        <!-- No need to declare the term, as it is picked up in the general declarations later on -->

    </xsl:template>


    <!-- === 
        Generate Property Set
        $propertyIRI is defined as a global variable
        === -->
    <xsl:template name="generatePropertySet" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="propertyType"/>
        <xsl:param name="propertyValues"/>

        <xsl:variable name="propertyTypeIRI" select="concat($propertyIRI, ':', $propertyType)"/>

        <!-- Declaration of subclass for propertyType -->
        <Declaration>
            <Class IRI="{$propertyTypeIRI}"/>
        </Declaration>
        <SubClassOf>
            <Class IRI="{$propertyTypeIRI}"/>
            <Class IRI="{$propertyIRI}"/>
        </SubClassOf>

        <!-- Declaration and assertion for each property value -->
        <xsl:for-each select="$propertyValues">
            <xsl:variable name="propertyValue" select="normalize-space(.)"/>
            <xsl:variable name="propertyValueIRI" select="concat($propertyTypeIRI, ':', $propertyValue)"/>

            <Declaration>
                <NamedIndividual IRI="{$propertyValueIRI}"/>
            </Declaration>
            <ClassAssertion>
                <Class IRI="{$propertyTypeIRI}"/>
                <NamedIndividual IRI="{$propertyValueIRI}"/>
            </ClassAssertion>
        </xsl:for-each>
    </xsl:template>


    <!-- === 
         generateComponentAssertions
         Generate assertions for a component of specified componentTypeIRI
         The propertySet and propertyValues are matching sets of property/value normalized-space strings
         Uses global variables $rootNode and $propertyIRI
         
         Iterate through propertySet - assertions then depend on the property
         
         'Identifier'       is the unique Id for the component
         'DisplayName'      is a displayName for which a term has already been asserted - just needs an objectProperty assertion 
         '-'                is a spacer that is ignored
         'Content'          the remaining values in propertyValues are references to the content of the component
         'Data'             the remaining values in propertyValues are displayName/data pairs (the component is an element)        
          Anything else     is an object property assertion or data property assertion for the corresponding value
          
          For these other properties:
            Get the type of property from the $cityEHRarchitecture
            If a dataProperty assertion, then just use the value
            If an objectProperty assertion, then the value is either
                A property as defined in the propertySet key
                Or a reference to an ISO-13606 or cityEHR component 
         
        === -->
    <xsl:template name="generateComponentAssertions" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="componentTypeIRI"/>
        <xsl:param name="propertySet"/>
        <xsl:param name="propertyValues"/>

        <!-- The first property must be the identifier -->
        <xsl:if test="$propertySet[1] = 'Identifier' and $propertyValues[1] != ''">
            <!-- Set the componentId and componentIRI-->
            <xsl:variable name="componentId" select="$propertyValues[1]"/>
            <xsl:variable name="componentIRI" select="cityEHRFunction:getIRI($componentTypeIRI, $componentId)"/>

            <!-- Iterate through the properties -->
            <xsl:for-each select="$propertySet">
                <xsl:variable name="propertyTypeId" select="."/>
                <xsl:variable name="propertyPosition" select="position()"/>
                <xsl:variable name="propertyValueRecorded" select="$propertyValues[position() = $propertyPosition]"/>

                <!-- There may be no field in the record for the propertyType.
                     This can happen at the end of the record -->
                <xsl:variable name="propertyValue"
                    select="
                        if (exists($propertyValueRecorded)) then
                            $propertyValueRecorded
                        else
                            ''"/>

                <!-- Assertions depend on the type of property -->
                <xsl:choose>
                    <!-- Identifier - the unique Id for the component -->
                    <xsl:when test="$propertyTypeId = 'Identifier'">
                        <Declaration>
                            <NamedIndividual IRI="{$componentIRI}"/>
                        </Declaration>
                        <ClassAssertion>
                            <Class IRI="{$componentTypeIRI}"/>
                            <NamedIndividual IRI="{$componentIRI}"/>
                        </ClassAssertion>
                    </xsl:when>

                    <!-- DisplayName for which a term has already been asserted -->
                    <xsl:when test="$propertyTypeId = 'DisplayName'">
                        <!-- Only if there is a displayName -->
                        <xsl:if test="$propertyValue != ''">
                            <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:', $propertyValue)"/>

                            <ObjectPropertyAssertion>
                                <ObjectProperty IRI="#hasDisplayName"/>
                                <NamedIndividual IRI="{$componentIRI}"/>
                                <NamedIndividual IRI="{$termIRI}"/>
                            </ObjectPropertyAssertion>
                        </xsl:if>
                    </xsl:when>

                    <!-- spacer that is ignored -->
                    <xsl:when test="$propertyTypeId = '-'"/>

                    <!-- references to the content of the component -->
                    <xsl:when test="$propertyTypeId = 'Content'">
                        <!-- The contents list is all the remaining property values in the set -->
                        <xsl:variable name="contentsList" select="$propertyValues[position() ge $propertyPosition]"/>
                        <xsl:call-template name="generateComponentContents">
                            <xsl:with-param name="componentIRI" select="$componentIRI"/>
                            <xsl:with-param name="contentsList" select="$contentsList"/>
                        </xsl:call-template>
                    </xsl:when>

                    <!-- displayName/value pairs (the component is an element) -->
                    <xsl:when test="$propertyTypeId = 'Data'">
                        <!-- The values list (pairs of displayName/value) is all the remaining property values in the set -->
                        <xsl:variable name="valuesList" select="$propertyValues[position() ge $propertyPosition]"/>

                        <!-- Get the list of element values and displayNames -->
                        <xsl:variable name="elementValues" select="cityEHRFunction:GetValues($valuesList)"/>
                        <xsl:variable name="elementDisplayNames" select="cityEHRFunction:GetDisplayNames($valuesList)"/>

                        <!-- Get the type of this element -->
                        <xsl:variable name="ElementType" select="cityEHRFunction:GetPropertyValue($propertySet, $propertyValues, 'ElementType')"/>

                        <!-- Generate assertions for the values, but only if they are distinct -->
                        <xsl:if test="count($elementValues) = count(distinct-values($elementValues))">

                            <!-- For enumeratedClass, the values are the class and subclass(es)
                                 The first value is of the form class or class:subclass.
                                 There may be further class:subclass values, when the enumeratedClass is used for categorization -->
                            <xsl:if test="$ElementType = 'enumeratedClass'">
                                <xsl:variable name="firstDataClass" select="tokenize($elementValues[1], ':')[1]"/>

                                <!-- Assert the data class for the element -->
                                <xsl:if test="$firstDataClass != ''">
                                    <xsl:variable name="classIRI" select="cityEHRFunction:getIRI('#CityEHR:Class:', $firstDataClass)"/>
                                    <ObjectPropertyAssertion>
                                        <ObjectProperty IRI="#hasDataClass"/>
                                        <NamedIndividual IRI="{$componentIRI}"/>
                                        <NamedIndividual IRI="{$classIRI}"/>
                                    </ObjectPropertyAssertion>
                                </xsl:if>

                                <!-- Warning if no data class is specified -->
                                <xsl:if test="$firstDataClass = ''">
                                    <xsl:variable name="context" select="concat('Element: ', $componentIRI)"/>
                                    <xsl:variable name="message" select="'No class set for enumeratedClass element'"/>
                                    <xsl:call-template name="generateWarning">
                                        <xsl:with-param name="node" select="$propertyTypeId"/>
                                        <xsl:with-param name="context" select="$context"/>
                                        <xsl:with-param name="message" select="$message"/>
                                    </xsl:call-template>
                                </xsl:if>

                                <!-- Assert data for any subclasses.
                                     This is done for all values, including the first -->
                                <xsl:for-each select="$elementValues">
                                    <xsl:variable name="elementValueDeclared" select="."/>
                                    <xsl:variable name="valueClassDeclared" select="tokenize($elementValueDeclared, ':')[1]"/>
                                    <xsl:variable name="valueSubClassDeclared" select="tokenize($elementValueDeclared, ':')[2]"/>

                                    <xsl:variable name="position" select="position()"/>
                                    <xsl:variable name="elementValueDisplayName" select="$elementDisplayNames[position() = $position]"/>

                                    <xsl:variable name="elementValue" select="concat('#CityEHR:Class:', $elementValueDeclared)"/>

                                    <!-- Only need assertions for values that are the correct class and are not blank.
                                         But note that the subclass can be balnk -->
                                    <xsl:if test="$valueClassDeclared = $firstDataClass and $elementValueDeclared != ''">

                                        <xsl:variable name="elementDataIRI"
                                            select="cityEHRFunction:getIRI('#ISO-13606:Data', concat($componentId, $elementValueDeclared))"/>

                                        <xsl:call-template name="generateValueAssertions">
                                            <xsl:with-param name="elementIRI" select="$componentIRI"/>
                                            <xsl:with-param name="elementDataIRI" select="$elementDataIRI"/>
                                            <xsl:with-param name="elementValue" select="$elementValue"/>
                                            <xsl:with-param name="elementValueDisplayName" select="$elementValueDisplayName"/>
                                        </xsl:call-template>
                                    </xsl:if>

                                    <!-- Warning for values that are the correct class and are not blank.-->
                                    <xsl:if test="$valueClassDeclared != $firstDataClass and $elementValueDeclared != ''">
                                        <xsl:variable name="context" select="concat('Element: ', $componentId)"/>
                                        <xsl:variable name="message" select="'Values set for enumeratedClass element must all be of same class'"/>
                                        <xsl:call-template name="generateWarning">
                                            <xsl:with-param name="node" select="$propertyTypeId"/>
                                            <xsl:with-param name="context" select="$context"/>
                                            <xsl:with-param name="message" select="$message"/>
                                        </xsl:call-template>
                                    </xsl:if>

                                </xsl:for-each>

                            </xsl:if>

                            <!-- For enumeratedClass, the values are the class and subclass(es)
                                 For anything else, then element values -->
                            <xsl:if test="not($ElementType = 'enumeratedClass')">
                                <xsl:for-each select="$elementValues">
                                    <xsl:variable name="elementValue" select="."/>
                                    <xsl:variable name="position" select="position()"/>

                                    <!-- Only need assertions for values that are not blank.
                                     For -->
                                    <xsl:if test="$elementValue != ''">
                                        <xsl:variable name="elementDataIRI"
                                            select="cityEHRFunction:getIRI('#ISO-13606:Data', concat($componentId, $elementValue))"/>
                                        <xsl:variable name="elementValueDisplayName" select="$elementDisplayNames[position() = $position]"/>

                                        <xsl:call-template name="generateValueAssertions">
                                            <xsl:with-param name="elementIRI" select="$componentIRI"/>
                                            <xsl:with-param name="elementDataIRI" select="$elementDataIRI"/>
                                            <xsl:with-param name="elementValue" select="$elementValue"/>
                                            <xsl:with-param name="elementValueDisplayName" select="$elementValueDisplayName"/>
                                        </xsl:call-template>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:if>

                        </xsl:if>

                    </xsl:when>

                    <!-- Anything else is an object property assertion or data property assertion -->
                    <xsl:otherwise>
                        <!-- The OWL/XML property -->
                        <xsl:variable name="owlPropertyIRI" select="concat('#has', $propertyTypeId)"/>

                        <!-- Get the type of the property in the cityEHRarchitecture -->
                        <xsl:variable name="propertyDeclarationType"
                            select="$cityEHRarchitecture/owl:Ontology/owl:Declaration/(owl:ObjectProperty | owl:DataProperty)[@IRI = $owlPropertyIRI]/name()"/>

                        <xsl:variable name="dataPropertyValue" select="cityEHRFunction:GetDataPropertyValue($propertyTypeId, $propertyValue)"/>

                        <!-- Data property - just make the assertion, unless the value is blank -->
                        <xsl:if test="$propertyDeclarationType = 'DataProperty' and $dataPropertyValue != ''">
                            <DataPropertyAssertion>
                                <DataProperty IRI="{$owlPropertyIRI}"/>
                                <NamedIndividual IRI="{$componentIRI}"/>
                                <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="&amp;rdf;PlainLiteral">
                                    <xsl:value-of select="$dataPropertyValue"/>
                                </Literal>
                            </DataPropertyAssertion>
                        </xsl:if>

                        <!-- Object property - is either a property or reference to a component -->
                        <xsl:if test="$propertyDeclarationType = 'ObjectProperty'">

                            <xsl:variable name="propertySetFields" select="key('propertySetFields', $propertyTypeId, $rootNode)"/>

                            <!-- A cityEHR property will have a key with the set of value options -->
                            <xsl:if test="exists($propertySetFields)">
                                <!-- Get the property values - the value for this component should be one of them.
                                     If not, assert an error -->
                                <xsl:variable name="propertyValueSet" select="$propertySetFields[. != ''][position() gt 1]"/>

                                <!-- Property is valid or is not set (blank)  -->
                                <xsl:if test="$propertyValue = $propertyValueSet or $propertyValue = ''">
                                    <!-- If property value is not set, then use default (first value in propertyValueSet) -->
                                    <xsl:variable name="assertedPropertyValue"
                                        select="
                                            if ($propertyValue = '') then
                                                cityEHRFunction:GetDefaultPropertyValue($propertyTypeId, $propertyValueSet)
                                            else
                                                $propertyValue"/>
                                    <xsl:variable name="propertyTypeIRI" select="concat($propertyIRI, ':', $propertyTypeId)"/>
                                    <xsl:variable name="propertyIRI" select="concat($propertyTypeIRI, ':', $assertedPropertyValue)"/>
                                    <ObjectPropertyAssertion>
                                        <ObjectProperty IRI="{$owlPropertyIRI}"/>
                                        <NamedIndividual IRI="{$componentIRI}"/>
                                        <NamedIndividual IRI="{$propertyIRI}"/>
                                    </ObjectPropertyAssertion>
                                </xsl:if>

                                <!-- Property not valid -->
                                <xsl:if test="not($propertyValue = $propertyValueSet or $propertyValue = '')">
                                    <xsl:call-template name="generateError">
                                        <xsl:with-param name="node" select="$rootNode"/>
                                        <xsl:with-param name="context" select="concat($componentIRI, ' / ', $owlPropertyIRI)"/>
                                        <xsl:with-param name="message"
                                            select="concat('Property value (defined cityEHR property) not valid: ', $propertyValue)"/>
                                    </xsl:call-template>
                                </xsl:if>

                            </xsl:if>

                            <!-- Other object properties must be references to model components.
                                 Don't assert anything if the property is blank
                                 Need then to get the type of the component - either ISO-13606 or CityEHR.
                                 The propertyValue is of the form ComponentType:ComponentId (if not, assert an error) -->
                            <xsl:if test="not(exists($propertySetFields))">
                                <!-- Only if there is a value -->
                                <xsl:if test="$propertyValue != ''">
                                    <xsl:variable name="referencedComponentType" select="tokenize($propertyValue, ':')[1]"/>
                                    <xsl:variable name="referencedComponentId" select="tokenize($propertyValue, ':')[2]"/>

                                    <!-- Referenced component value must be valid -->
                                    <xsl:if test="$referencedComponentType != '' and $referencedComponentId != ''">
                                        <!-- Set the IRI for the referenced component -->
                                        <xsl:variable name="referencedComponentTypeIRI"
                                            select="cityEHRFunction:GetComponentTypeIRI($referencedComponentType)"/>
                                        <!-- Form the referenced component IRI -->
                                        <xsl:variable name="referencedComponentIRI"
                                            select="concat($referencedComponentTypeIRI, ':', $referencedComponentId)"/>

                                        <ObjectPropertyAssertion>
                                            <ObjectProperty IRI="{$owlPropertyIRI}"/>
                                            <NamedIndividual IRI="{$componentIRI}"/>
                                            <NamedIndividual IRI="{$referencedComponentIRI}"/>
                                        </ObjectPropertyAssertion>
                                    </xsl:if>

                                    <!-- Error if referenced component value not valid. -->
                                    <xsl:if test="$referencedComponentType = '' or $referencedComponentId = ''">
                                        <xsl:call-template name="generateError">
                                            <xsl:with-param name="node" select="$propertyValue"/>
                                            <xsl:with-param name="context" select="$owlPropertyIRI"/>
                                            <xsl:with-param name="message" select="'Property value (component reference) not valid'"/>
                                        </xsl:call-template>
                                    </xsl:if>
                                </xsl:if>
                            </xsl:if>
                        </xsl:if>


                    </xsl:otherwise>
                </xsl:choose>

            </xsl:for-each>


        </xsl:if>

    </xsl:template>

    <!-- === 
        generateComponentContents
        Generate assertions for the contentsList for a component of specified componentIRI
        The components in the contentsList are strings of the form type:id
        They need to be prefixed by #cityEHR: or #ISO-13606: to create their componentIRI
        === -->
    <xsl:template name="generateComponentContents" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="componentIRI"/>
        <xsl:param name="contentsList"/>

        <xsl:variable name="contentsIRIList" select="cityEHRFunction:GetComponentIRIList($contentsList)"/>
        <!-- #hasContentsList assertion is a literal with the componentIRIs for each component in the contentsList, separated by spaces -->
        <DataPropertyAssertion>
            <DataProperty IRI="#hasContentsList"/>
            <NamedIndividual IRI="{$componentIRI}"/>
            <Literal xml:lang="en-gb" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="string-join($contentsIRIList, ' ')"/>
            </Literal>
        </DataPropertyAssertion>

        <!-- #hasContent assertion is made of each component in the contentsList -->
        <xsl:for-each select="$contentsIRIList">
            <xsl:variable name="contentsComponentIRI" select="."/>

            <ObjectPropertyAssertion>
                <ObjectProperty IRI="#hasContent"/>
                <NamedIndividual IRI="{$componentIRI}"/>
                <NamedIndividual IRI="{$contentsComponentIRI}"/>
            </ObjectPropertyAssertion>

        </xsl:for-each>
    </xsl:template>


    <!-- === 
        generateValueAssertions
        Generate assertions for the value of an element of specified elementIRI
        The parameters for the assertions are elementDataIRI, elementValue and elementValueDisplayName
        === -->
    <xsl:template name="generateValueAssertions" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="elementIRI"/>
        <xsl:param name="elementDataIRI"/>
        <xsl:param name="elementValue"/>
        <xsl:param name="elementValueDisplayName"/>

        <Declaration>
            <NamedIndividual IRI="{$elementDataIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="#ISO-13606:Data"/>
            <NamedIndividual IRI="{$elementDataIRI}"/>
        </ClassAssertion>

        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasData"/>
            <NamedIndividual IRI="{$elementIRI}"/>
            <NamedIndividual IRI="{$elementDataIRI}"/>
        </ObjectPropertyAssertion>

        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="{$elementDataIRI}"/>
            <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$elementValue"/>
            </Literal>
        </DataPropertyAssertion>

        <!-- Declare the displayName, if there is one.
             No need to declare the term, as it is picked up in the general declarations above-->
        <xsl:if test="$elementValueDisplayName != ''">
            <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:', $elementValueDisplayName)"/>
            <ObjectPropertyAssertion>
                <ObjectProperty IRI="#hasDisplayName"/>
                <NamedIndividual IRI="{$elementDataIRI}"/>
                <NamedIndividual IRI="{$termIRI}"/>
            </ObjectPropertyAssertion>
        </xsl:if>
    </xsl:template>


    <!-- === The Class hierarchy for this ontology === 
                generateClassHierarchy
                
                propertySet is the first record in the table
                matrix is all the other reocrds
                
                The Class hierarchy is represented as an adjacency matrix
                For each row in the matrix we need to:
                
                Declare an individual
                Assert the individual as a member of the Class 
                Set the display name for the Individual using the hasDisplayName object property
                Set sub-types for the Individual using the hasType object property
                
                In the spreadhsheet, each row represents an Individual in the class, with the following cells:
                (So in the database, each record represents an Individual in the class, with the following fields:)
                
                [1] The Id of the individual
                [2] Display Name for the Entry
                [3] The associated Supplementary Data Set (if any)
                [4] The level in the Class hierarchy
                [>4] The adjanency matrix
                
                The Adjaceny Matrix has Individuals along the Y-axis and Children along the X-Axis
                If there is a 1 in the cell of the adjacency matrix then the Individual has a Child node in the hierarchy.
                The child node is found from corresponding heading in Row 1 of the sheet and is asserted using the hasType object property
                
                .    I1  I2  I3  I4  I5
                I1    x
                I2        x
                I3            x
                I4                x
                I5                    x
                
                The current row number of the adjancency matrix is specifed in $matrixRow
                The matrix for any row starts at position $matrixColumnStartPosition (different for each row)
                
                The current column number of the adjancency matrix is specified in $matrixColumn
                The list of (child) Individuals for the columns starts at position $matrixColumnOffset  (fixed)
                
                **NOTE**
                If the spreadhseet is not being used to define the class hierarchy (i.e. the adjacency matrix is redundant)
                then this section of processing should be skipped.
                
                This is the case when the spreadsheet is just being used to define supplementary data sets for a hierarchy that has been 
                defined elsewhere (e.g. in a Yed).
                
                To test this, the row is only processed if the class level is 1-3 (i.e. not zero)
                
                ==================================== -->
    <xsl:template name="generateClassHierarchy" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="propertySet"/>
        <xsl:param name="matrix"/>

        <xsl:if test="$classId">
            <xsl:variable name="classIRI" select="cityEHRFunction:getIRI('#CityEHR:Class:', $classId)"/>

            <xsl:variable name="identifierProperty" select="$propertySet[1]"/>

            <!-- Field positions for DisplayName, sdsEntry and Level -->
            <xsl:variable name="DisplayNamePosition" as="xs:integer" select="cityEHRFunction:GetFieldPosition($propertySet, 'DisplayName')"/>
            <xsl:variable name="sdsEntryPosition" as="xs:integer" select="cityEHRFunction:GetFieldPosition($propertySet, 'sdsEntry')"/>
            <xsl:variable name="levelPosition" as="xs:integer" select="cityEHRFunction:GetFieldPosition($propertySet, 'Level')"/>

            <!-- Generate an error if identifier property is bad -->
            <xsl:if test="$identifierProperty != 'Identifier'"> </xsl:if>

            <!-- Only continue if the sheet has an identifier property -->
            <xsl:if test="$identifierProperty = 'Identifier'"> </xsl:if>

            <xsl:for-each select="$matrix">
                <!-- Row and index in the adjacency matrix.
                     Note that position() returns the position in the for-each results set -->
                <xsl:variable name="matrixRow" select="."/>
                <xsl:variable name="matrixRowIndex" select="position()"/>

                <!-- individualId is in the first column - must not have a ss:Index attribute -->
                <xsl:variable name="individualId" select="normalize-space($matrixRow/field[1])"/>

                <!-- Only process rows that have an individualId -->
                <xsl:if test="$individualId != ''">

                    <xsl:variable name="individualIRI" select="cityEHRFunction:getIRI(concat($classIRI, ':'), $individualId)"/>

                    <!-- The entry for the supplementary data set is in sdsEntryPosition -->
                    <xsl:variable name="suppDataSet" select="normalize-space($matrixRow/field[position() = $sdsEntryPosition])"/>

                    <!-- Set the assertion of the supplementary data set for the class node -->
                    <xsl:if test="$suppDataSet != ''">
                        <xsl:variable name="suppDataSetIRI" select="concat('#ISO-13606:', $suppDataSet)"/>
                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasSuppDataSet"/>
                            <NamedIndividual IRI="{$individualIRI}"/>
                            <NamedIndividual IRI="{$suppDataSetIRI}"/>
                        </ObjectPropertyAssertion>
                    </xsl:if>

                    <!-- Get the class level -->
                    <xsl:variable name="classLevel" select="normalize-space($matrixRow/field[position() = $levelPosition])"/>

                    <!-- The rest of this processing is for the class hiererchy
                        Only process rows that have a class level 1-3 (i.e. not 0 which means the adjacency matrix is not being used for the class hierarchy).                          
                    -->
                    <xsl:if test="$classLevel = ('1', '2', '3')">
                        <!-- Declare the individual -->
                        <Declaration>
                            <NamedIndividual IRI="{$individualIRI}"/>
                        </Declaration>

                        <!-- Assert membership of class -->
                        <ClassAssertion>
                            <Class IRI="{$classIRI}"/>
                            <NamedIndividual IRI="{$individualIRI}"/>
                        </ClassAssertion>

                        <!-- Assert the displayName for the individual -->
                        <xsl:variable name="displayName" select="normalize-space($matrixRow/field[position() = $DisplayNamePosition])"/>

                        <xsl:if test="$displayName != ''">
                            <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:', $displayName)"/>
                            <ObjectPropertyAssertion>
                                <ObjectProperty IRI="#hasDisplayName"/>
                                <NamedIndividual IRI="{$individualIRI}"/>
                                <NamedIndividual IRI="{$termIRI}"/>
                            </ObjectPropertyAssertion>
                        </xsl:if>

                        <!-- The list of children in the adjacency matrix starts in column after the Class level (levelPosition) -->
                        <xsl:variable name="matrixFieldStartPosition" as="xs:integer" select="$levelPosition + 1"/>

                        <!-- Iterate through the list of children which start in childListPosition
                            0 indicates that the node in that position is not a child
                            1 indicates that node in that position is a chiild
                            This is an acyclic graph - nodes cannot be children of themselves, so don't look to assert a child when 
                        -->
                        <xsl:for-each select="$matrixRow/field[position() >= $matrixFieldStartPosition]">
                            <xsl:variable name="matrixField" select="."/>
                            <xsl:variable name="matrixFieldIndex" select="position()"/>
                            <!-- Note that position() returns the position in the for-each results set, not the position of the field in the record -->
                            <xsl:variable name="matrixFieldPosition" as="xs:integer" select="$matrixFieldStartPosition + $matrixFieldIndex - 1"/>

                            <!-- Asert child unless the parent and child are same individual (shouldn't happen, but check just in case)
                                 That is, the matrix field index is the same as the row index
                                 The childId is from the matrixFieldPosition in the propertySet -->
                            <xsl:if test="$matrixFieldIndex != $matrixRowIndex and ./normalize-space($matrixField) = '1'">
                                <xsl:variable name="childId" select="normalize-space($propertySet[position() = $matrixFieldPosition])"/>

                                <!-- Final check that childId is different from individualId -->
                                <xsl:if test="$childId != $individualId">
                                    <xsl:variable name="childIRI" select="cityEHRFunction:getIRI(concat($classIRI, ':'), $childId)"/>
                                    <ObjectPropertyAssertion>
                                        <ObjectProperty IRI="#hasType"/>
                                        <NamedIndividual IRI="{$individualIRI}"/>
                                        <NamedIndividual IRI="{$childIRI}"/>
                                    </ObjectPropertyAssertion>
                                </xsl:if>
                            </xsl:if>

                        </xsl:for-each>

                    </xsl:if>
                    <!-- Only process rows with class level 1-3 -->

                </xsl:if>
                <!-- Only process rows with a valid individualId -->

            </xsl:for-each>
        </xsl:if>
        <!-- Process each row in the matrix -->
    </xsl:template>

</xsl:stylesheet>
