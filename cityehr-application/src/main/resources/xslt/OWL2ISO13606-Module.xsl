<!-- ====================================================================
    OWL2ISO13606-Module.xsl
    Module to convert cityEHR OWL to ISO-13606 XML representation
    Pulled in from main stylesheets for conversion of a full ontology
    
    Specified application, specialty and (if present) class set in the variables:
    
    applicationIRI
    specialtyIRI
    classIRI
 
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
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions"
    xmlns:iso-13606="http://www.iso.org/iso-13606">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- ========================================================================
        Keys
        ======================================================================== -->

    <!-- Context for using keys in functions -->
    <xsl:variable name="rootNode" select="/owl:Ontology"/>

    <!-- Key for component contents
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasContent"/>
            <NamedIndividual IRI="#CityEHR:Order:Pathology"/>
            <NamedIndividual IRI="#ISO-13606:Section:PathologyTest"/>
        </ObjectPropertyAssertion>
        -->
    <xsl:key name="contentsList"
        match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI = '#hasContent']/owl:NamedIndividual[2]/@IRI"
        use="../../owl:NamedIndividual[1]/@IRI"/>

    <!-- Key for component values 
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasData"/>
            <NamedIndividual IRI="#ISO-13606:Element:CurrentFracture"/>
            <NamedIndividual IRI="#ISO-13606:Data:CurrentFracture3AYes"/>
        </ObjectPropertyAssertion>
 -->
    <xsl:key name="valueList"
        match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI = '#hasData']/owl:NamedIndividual[2]/@IRI"
        use="../../owl:NamedIndividual[1]/@IRI"/>

    <!-- Key for Term IRI
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasDisplayName"/>
            <NamedIndividual IRI="#CityEHR:Order:Radiology"/>
            <NamedIndividual IRI="#CityEHR:Term:Radiological%20Examinations"/>
        </ObjectPropertyAssertion>
-->
    <xsl:key name="termIRIList"
        match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI = '#hasDisplayName']/owl:NamedIndividual[2]/@IRI"
        use="../../owl:NamedIndividual[1]/@IRI"/>

    <!-- Key for literals (for terms and element values)
        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="#CityEHR:Term:Radiological%20Examinations"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">Radiological Examinations</Literal>
        </DataPropertyAssertion>
    -->
    <xsl:key name="literalList"
        match="/owl:Ontology/owl:DataPropertyAssertion[owl:DataProperty/@IRI = '#hasValue']/owl:Literal"
        use="../owl:NamedIndividual/@IRI"/>

    <!-- Key for Element datatype
    <ObjectPropertyAssertion>
        <ObjectProperty IRI="#hasDataType"/>
        <NamedIndividual IRI="#ISO-13606:Element:Boolean"/>
        <NamedIndividual IRI="#CityEHR:DataType:boolean"/>
    </ObjectPropertyAssertion>
    -->
    <xsl:key name="elementDataTypeList"
        match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI = '#hasDataType']/owl:NamedIndividual[2]/@IRI"
        use="../../owl:NamedIndividual[1]/@IRI"/>

    <!-- Key for Element unit
    <ObjectPropertyAssertion>
        <ObjectProperty IRI="#hasUnit"/>
        <NamedIndividual IRI="#ISO-13606:Element:Systolic"/>
        <NamedIndividual IRI="#CityEHR:Unit:mmHg"/>
    </ObjectPropertyAssertion>
    -->
    <xsl:key name="elementUnitList"
        match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI = '#hasUnit']/owl:NamedIndividual[2]/@IRI"
        use="../../owl:NamedIndividual[1]/@IRI"/>


    <!-- Keys for ClassAssertion
        <ClassAssertion>
            <Class IRI="#CityEHR:Form"/>
            <NamedIndividual IRI="#CityEHR:Form:Fractures"/>
        </ClassAssertion>
        -->
    <xsl:key name="individualList" match="/owl:Ontology/owl:ClassAssertion/owl:NamedIndividual/@IRI"
        use="../../owl:Class/@IRI"/>
    <xsl:key name="classList" match="/owl:Ontology/owl:ClassAssertion/owl:Class/@IRI"
        use="../../owl:NamedIndividual/@IRI"/>
    <xsl:key name="subClassList" match="/owl:Ontology/owl:SubClassOf/owl:Class[2]/@IRI"
        use="../../owl:Class[1]/@IRI"/>


    <!-- ========================================================================
        Global Variables
        ======================================================================== -->

    <!-- Set the Application for this ontology configuration -->
    <xsl:variable name="applicationIRI" as="xs:string"
        select="
            if (exists(/owl:Ontology/owl:ClassAssertion[owl:Class/@IRI = '#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI)) then
                /owl:Ontology/owl:ClassAssertion[owl:Class/@IRI = '#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI
            else
                ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="applicationId" as="xs:string"
        select="replace(substring($applicationIRI, 2), ':', '-')"/>

    <!-- Set the Specialty for this ontology configuration -->
    <xsl:variable name="specialtyIRI" as="xs:string"
        select="
            if (count(/owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI = '#ISO-13606:Folder']/owl:Class[1]/@IRI) = 1) then
                /owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI = '#ISO-13606:Folder']/owl:Class[1]/@IRI
            else
                ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="specialtyId" as="xs:string"
        select="replace(substring($specialtyIRI, 2), ':', '-')"/>

    <!-- Set the Class for this ontology configuration, if there is one.
        Note that a combined ontology will have more than one #CityEHR:Class, so check that the count of these is one.
        (Specialty model has a count of zero, combined model has a count greater than one.) -->
    <xsl:variable name="classIRI" as="xs:string"
        select="
            if (count(/owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI = '#CityEHR:Class']/owl:Class[1]/@IRI) = 1) then
                /owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI = '#CityEHR:Class']/owl:Class[1]/@IRI
            else
                ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an Id suitable for eXist -->
    <xsl:variable name="classId" as="xs:string" select="replace(substring($classIRI, 2), ':', '-')"/>


    <xsl:variable name="pathSeparator" as="xs:string" select="'@@@'"/>


    <!-- Template to generate the ISO-13606 model 
         Nested iso-13606:component structure
        <iso-13606:component iso-13606:type="Folder" code="#ISO-13606:Folder:FeatureDemo" codeSystem="cityEHR" displayName="cityEHR Feature Demo">
    -->
    <xsl:template name="generateISO-13606Model">
        <xsl:param name="applicationIRI"/>
        <xsl:param name="specialtyIRI"/>
        <xsl:param name="classIRI"/>

        <!-- === Create the ISO-13606 model 
             The EHR_extract is for the specified Specialty, with specialtyIRI and displayName
             OR for the specified Class, with classIRI and displayName
             === -->

        <!-- Get specialty displayName -->
        <xsl:variable name="specialtyDisplayNameTermIRI" as="xs:string"
            select="
                if (exists(key('termIRIList', $specialtyIRI))) then
                    key('termIRIList', $specialtyIRI)
                else
                    ''"/>
        <xsl:variable name="specialtyDisplayNameTerm" as="xs:string"
            select="
                if ($specialtyDisplayNameTermIRI = '') then
                    ''
                else
                    key('literalList', $specialtyDisplayNameTermIRI)"/>

        <iso-13606:component iso-13606:type="EHR_Extract" xmlns="http://www.iso.org/iso-13606"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" code="{$specialtyIRI}"
            codeSystem="cityEHR" displayName="{$specialtyDisplayNameTerm}">

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
                    == -->


            <xsl:variable name="class" as="xs:string" select="'Folder'"/>

            <iso-13606:component iso-13606:type="{$class}" code="{$specialtyIRI}"
                codeSystem="cityEHR" displayName="{$specialtyDisplayNameTerm}">

                <xsl:for-each
                    select="/owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI = '#ISO-13606:Composition']/owl:Class[1]/@IRI">
                    <xsl:variable name="compositionIRI" as="xs:string" select="."/>
                    <xsl:for-each select="key('individualList', $compositionIRI)">
                        <xsl:call-template name="generateComponent">
                            <xsl:with-param name="nodeIRI" select="."/>
                            <xsl:with-param name="nodePath" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:for-each>

            </iso-13606:component>


            <!-- == Then iterate through each folder specified as contents of the specialty folder.
                    == -->
            <xsl:for-each select="key('contentsList', $specialtyIRI)">
                <xsl:call-template name="generateComponent">
                    <xsl:with-param name="nodeIRI" select="."/>
                    <xsl:with-param name="nodePath" select="."/>
                </xsl:call-template>
            </xsl:for-each>

        </iso-13606:component>

    </xsl:template>



    <!-- Generate component
        Includes a recursive call to generate the child components
        This is used to generate the nodes of the hierarchical representation of the ISO-13606 model.
        
        <ClassAssertion>
            <Class IRI="Namespace:Type"/>
            <NamedIndividual IRI="nodeIRI"/>
        </ClassAssertion>
        
    -->
    <xsl:template name="generateComponent">
        <xsl:param name="nodeIRI"/>
        <xsl:param name="nodePath"/>

        <!-- Get the first classIRI - should only be one, but just in case -->
        <xsl:variable name="classIRI" as="xs:string"
            select="
                if (exists(key('classList', $nodeIRI))) then
                    key('classList', $nodeIRI)[1]
                else
                    ''"/>
        <xsl:variable name="class" as="xs:string"
            select="
                if ($classIRI != '') then
                    substring-after($classIRI, ':')
                else
                    ''"/>

        <!-- The class in cityEHR may be a sub-class of the ISO-13606 class -->
        <xsl:variable name="parentClassIRI" as="xs:string"
            select="
                if (exists(key('subClassList', $classIRI))) then
                    key('subClassList', $classIRI)[1]
                else
                    ''"/>
        <xsl:variable name="parentClass" as="xs:string"
            select="
                if ($parentClassIRI != '') then
                    substring-after($parentClassIRI, ':')
                else
                    ''"/>

        <xsl:variable name="iso13606Class" as="xs:string"
            select="
                if ($parentClass != '') then
                    $parentClass
                else
                    $class"/>
        <xsl:variable name="subClass" as="xs:string"
            select="
                if ($parentClass = '') then
                    ''
                else
                    $class"/>

        <xsl:variable name="nodeDisplayNameTermIRI" as="xs:string"
            select="
                if (exists(key('termIRIList', $nodeIRI))) then
                    key('termIRIList', $nodeIRI)
                else
                    ''"/>
        <xsl:variable name="nodeDisplayNameTerm" as="xs:string"
            select="
                if (exists(key('literalList', $nodeDisplayNameTermIRI))) then
                    key('literalList', $nodeDisplayNameTermIRI)[1]
                else
                    ''"/>

        <xsl:variable name="elementDataType" as="xs:string"
            select="
                if (exists(key('elementDataTypeList', $nodeIRI))) then
                    key('elementDataTypeList', $nodeIRI)
                else
                    ''"/>

        <xsl:variable name="elementUnit" as="xs:string"
            select="
                if (exists(key('elementUnitList', $nodeIRI))) then
                    key('elementUnitList', $nodeIRI)
                else
                    ''"/>

        <xsl:variable name="valueList" select="key('valueList', $nodeIRI)"/>
        <xsl:variable name="valueListDisplayName"
            select="cityEHRFunction:getValueListDsiplayName($valueList)"/>

        <iso-13606:component iso-13606:type="{$iso13606Class}" subClass="{$subClass}"
            code="{$nodeIRI}" codeSystem="cityEHR" displayName="{$nodeDisplayNameTerm}"
            dataType="{$elementDataType}" unit="{$elementUnit}" values="{$valueListDisplayName}">
            <xsl:for-each select="key('contentsList', $nodeIRI)">
                <xsl:variable name="contentNodeIRI" as="xs:string" select="."/>
                <xsl:if test="not(contains($nodePath, $contentNodeIRI))">
                    <xsl:variable name="nextNodePath" as="xs:string"
                        select="concat($nodePath, $pathSeparator, $contentNodeIRI)"/>
                    <xsl:call-template name="generateComponent">
                        <xsl:with-param name="nodeIRI" select="$contentNodeIRI"/>
                        <xsl:with-param name="nodePath" select="$nextNodePath"/>
                    </xsl:call-template>
                </xsl:if>
                <xsl:if test="contains($nodePath, $contentNodeIRI)">
                    <iso-13606:component iso-13606:type="{$iso13606Class}" code="{$contentNodeIRI}"
                        codeSystem="cityEHR" displayName="Recursive" dataType="Recursive"/>
                </xsl:if>
            </xsl:for-each>
        </iso-13606:component>

    </xsl:template>

    <!-- Function to return displayName for a set of values  -->
    <xsl:function name="cityEHRFunction:getValueListDsiplayName">
        <xsl:param name="valueList"/>

        <xsl:value-of
            select="
                if (empty($valueList)) then
                    ''
                else
                    '/'"/>

        <xsl:for-each select="$valueList">
            <xsl:variable name="valueIRI" select="."/>
            <xsl:value-of select="key('literalList', $valueIRI, $rootNode)[1]"/>
            <xsl:value-of select="'/'"/>
        </xsl:for-each>
    </xsl:function>

</xsl:stylesheet>
