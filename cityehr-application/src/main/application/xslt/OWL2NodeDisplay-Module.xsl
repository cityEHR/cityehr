<!-- ====================================================================
    OWL2NodeDisplay-Module.xsl
    Module to convert cityEHR OWL to HTML displays of the nodes
    
    Specified type of the model and display required set in the variables:
    
    informationModelType
    informationModelDisplay
 
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

    <!-- Set the Application for this ontology configuration -->
    <xsl:variable name="applicationIRI" as="xs:string"
        select="/owl:Ontology/owl:ClassAssertion[owl:Class/@IRI='#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an file Id suitable for eXist -->
    <xsl:variable name="applicationFileId" as="xs:string"
        select="replace(substring($applicationIRI,2),':','-')"/>
    <xsl:variable name="applicationId" as="xs:string"
        select="substring-after($applicationFileId,'ISO-13606-EHR_Extract-')"/>

    <!-- Set the Specialty for this ontology configuration -->
    <xsl:variable name="specialtyIRI" as="xs:string"
        select="/owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Folder']/owl:Class[1]/@IRI[1]"/>
    <!-- Strip the leading # from the IRI and replace : with - to get a file Id suitable for eXist -->
    <xsl:variable name="specialtyFileId" as="xs:string"
        select="replace(substring($specialtyIRI,2),':','-')"/>
    <xsl:variable name="specialtyId" as="xs:string"
        select="substring-after($specialtyFileId,'ISO-13606-Folder-')"/>

    <!-- Set the Class for this ontology configuration, if there is one -->
    <xsl:variable name="classIRI" as="xs:string"
        select="if (exists(/owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI)) then /owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI else ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get a file Id suitable for eXist -->
    <xsl:variable name="classFileId" as="xs:string" select="replace(substring($classIRI,2),':','-')"/>
    <xsl:variable name="classId" as="xs:string"
        select="substring-after($classFileId,'CityEHR-Class-')"/>

    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="/owl:Ontology"/>

    <!-- Set up the XSLT keys for the OWL ontology -->
    <xsl:include href="OWLKeys-Module.xsl"/>


    <!-- Template to generate node display, according to informationModelType/informationModelDisplay:
            Class/allNodes
            Class/nodeIRIs and Class/nodeIds
            Specialty/dataDictionary
            Specialty/compositionSummary
    -->
    <xsl:template name="generateNodeDisplay">
        <!-- Class model -->
        <xsl:if test="$parameters/informationModelType='Class'">
            <!-- Generate nodes by level if not showing all nodes -->
            <xsl:if test="$parameters/informationModelDisplay!='allNodes'">
                <xsl:call-template name="generateClassNodesByLevelDisplay"/>
            </xsl:if>

            <!-- Generate all nodes -->
            <xsl:if test="$parameters/informationModelDisplay='allNodes'">
                <xsl:call-template name="generateClassAllNodesDisplay"/>
            </xsl:if>
        </xsl:if>

        <!-- Specialty model - Generate data dictionary -->
        <xsl:if test="$parameters/informationModelType=('Specialty','Combined')">
            <!-- Generate data dictionary -->
            <xsl:if test="$parameters/informationModelDisplay='dataDictionary'">
                <xsl:call-template name="generateDataDictionaryDisplay"/>
            </xsl:if>

            <!-- Generate summary of compositions -->
            <xsl:if test="$parameters/informationModelDisplay='compositionSummary'">
                <xsl:call-template name="generateCompositionSummaryDisplay"/>
            </xsl:if>
        </xsl:if>

    </xsl:template>



    <!-- Template to generate the Class Nodes by Level display 
         Nodes in each class are declared as:
        <ClassAssertion>
        <Class IRI="#CityEHR:Class:Diagnosis:Level-3"/>
        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Dermatomyositis"/>
        </ClassAssertion>
        
        The id for each node is the part of the IRI after the last :
        
        The displayName for each node is found in
        
        <ObjectPropertyAssertion>
        <ObjectProperty IRI="#hasDisplayName"/>
        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Dermatomyositis"/>
        <NamedIndividual IRI="#CityEHR:Term:Dermatomyositis"/>
        </ObjectPropertyAssertion>
        
        <DataPropertyAssertion>
        <DataProperty IRI="#hasValue"/>
        <NamedIndividual IRI="#CityEHR:Term:Dermatomyositis"/>
        <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">Dermatomyositis</Literal>
        </DataPropertyAssertion>
    -->

    <xsl:template name="generateClassNodesByLevelDisplay">
        <!-- Set up the class IRIs -->
        <xsl:variable name="classIRI"
            select="$rootNode/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI"/>

        <xsl:variable name="childNodeList"
            select="distinct-values($rootNode/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasType']/owl:NamedIndividual[2]/data(@IRI))"/>
        <xsl:variable name="parentNodeList"
            select="distinct-values($rootNode/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasType']/owl:NamedIndividual[1]/data(@IRI))"/>

        <xsl:variable name="level1Nodes"
            select="for $n in $parentNodeList return if ($n = $childNodeList) then () else $n"/>
        <xsl:variable name="level2Nodes"
            select="for $n in $parentNodeList return if ($n = $childNodeList) then $n else ()"/>
        <xsl:variable name="level3Nodes"
            select="for $n in $childNodeList return if ($n = $parentNodeList) then () else $n"/>

        <xsl:variable name="headers"
            select="$parameters/staticParameters/cityEHRAdmin/printHeaders/displayList[@type='classLevelNodes']/header"/>
        <table class="displayList">
            <thead>
                <!-- There should be three headers for this displayList -->
                <tr>
                    <xsl:for-each select="$headers">
                        <td>
                            <xsl:value-of select="."/>
                        </td>
                    </xsl:for-each>
                </tr>
            </thead>
            <tbody valign="top">
                <tr>
                    <td>
                        <ol>
                            <xsl:for-each select="$level1Nodes">
                                <xsl:sort select="."/>
                                <li>
                                    <xsl:variable name="nodeIRI" select="."/>
                                    <xsl:variable name="nodeId"
                                        select="substring-after(substring-after(substring-after($nodeIRI,':'),':'),':')"/>
                                   <xsl:variable name="displayNameTerm" as="xs:string"
                                        select="cityEHRFunction:getDisplayName($nodeIRI)"/>
                                    <xsl:value-of
                                        select="if ($informationModelDisplay='nodeDisplayNames') then $displayNameTerm else if ($informationModelDisplay='nodeIRIs') then $nodeIRI else $nodeId"
                                    />
                                </li>
                            </xsl:for-each>
                        </ol>
                    </td>
                    <td>
                        <ol>
                            <xsl:for-each select="$level2Nodes">
                                <xsl:sort select="."/>
                                <li>
                                    <xsl:variable name="nodeIRI" select="."/>
                                    <xsl:variable name="nodeId"
                                        select="substring-after(substring-after(substring-after($nodeIRI,':'),':'),':')"/>
                                    <xsl:variable name="displayNameTerm" as="xs:string"
                                        select="cityEHRFunction:getDisplayName($nodeIRI)"/>
                                    <xsl:value-of
                                        select="if ($informationModelDisplay='nodeDisplayNames') then $displayNameTerm else if ($informationModelDisplay='nodeIRIs') then $nodeIRI else $nodeId"
                                    />
                                </li>
                            </xsl:for-each>
                        </ol>
                    </td>
                    <td>
                        <ol>
                            <xsl:for-each select="$level3Nodes">
                                <xsl:sort select="."/>
                                <li>
                                    <xsl:variable name="nodeIRI" select="."/>
                                    <xsl:variable name="nodeId"
                                        select="substring-after(substring-after(substring-after($nodeIRI,':'),':'),':')"/>
                                    <xsl:variable name="displayNameTerm" as="xs:string"
                                        select="cityEHRFunction:getDisplayName($nodeIRI)"/>
                                    <xsl:value-of
                                        select="if ($informationModelDisplay='nodeDisplayNames') then $displayNameTerm else if ($informationModelDisplay='nodeIRIs') then $nodeIRI else $nodeId"
                                    />
                                </li>
                            </xsl:for-each>
                        </ol>
                    </td>
                </tr>
            </tbody>
        </table>

    </xsl:template>


    <!-- Template to generate all Class Nodes display 

        Nodes in each class are declared as:
        <ClassAssertion>
        <Class IRI="#CityEHR:Class:Diagnosis:Level-3"/>
        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Dermatomyositis"/>
        </ClassAssertion>
        
        The id for each node is the part of the IRI after the last :
        
        The displayName for each node is found in
        
        <ObjectPropertyAssertion>
        <ObjectProperty IRI="#hasDisplayName"/>
        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Dermatomyositis"/>
        <NamedIndividual IRI="#CityEHR:Term:Dermatomyositis"/>
        </ObjectPropertyAssertion>
        
        <DataPropertyAssertion>
        <DataProperty IRI="#hasValue"/>
        <NamedIndividual IRI="#CityEHR:Term:Dermatomyositis"/>
        <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">Dermatomyositis</Literal>
        </DataPropertyAssertion>
    -->
    <xsl:template name="generateClassAllNodesDisplay">
        <!-- Set up the class IRIs -->
        <xsl:variable name="classIRI"
            select="$rootNode/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI"/>

        <xsl:variable name="allNodes"
            select="distinct-values($rootNode/owl:ClassAssertion[owl:Class/@IRI=$classIRI]/owl:NamedIndividual/@IRI)"/>

        <xsl:variable name="headers"
            select="$parameters/staticParameters/cityEHRAdmin/printHeaders/displayList[@type='allNodes']/header"/>
        <table class="displayList">
            <thead>
                <!-- There should be three headers for this displayList -->
                <tr>
                    <xsl:for-each select="$headers">
                        <td>
                            <xsl:value-of select="."/>
                        </td>
                    </xsl:for-each>
                </tr>
            </thead>
            <tbody valign="top">
                <tr>
                    <td>
                        <ol>
                            <xsl:for-each select="$allNodes">
                                <xsl:sort select="."/>
                                <li>
                                    <xsl:value-of select="."/>
                                </li>
                            </xsl:for-each>
                        </ol>
                    </td>
                    <td>
                        <ol>
                            <xsl:for-each select="$allNodes">
                                <xsl:sort select="."/>
                                <li>
                                    <xsl:variable name="nodeIRI" select="."/>
                                    <xsl:variable name="nodeId"
                                        select="substring-after(substring-after(substring-after($nodeIRI,':'),':'),':')"/>
                                    <xsl:value-of select="$nodeId"/>
                                </li>
                            </xsl:for-each>
                        </ol>
                    </td>
                    <td>
                        <ol>
                            <xsl:for-each select="$allNodes">
                                <xsl:sort select="."/>
                                <li>
                                    <xsl:variable name="nodeIRI" select="."/>
                                    <xsl:value-of select="cityEHRFunction:getDisplayName($nodeIRI)"/>
                                </li>
                            </xsl:for-each>
                        </ol>
                    </td>
                </tr>
            </tbody>
        </table>

    </xsl:template>


    <!-- Template to generate the Data Dictionary display 
    -->
    <xsl:template name="generateDataDictionaryDisplay">
        <!-- Get the set of entries in the dictionary.
        
             Entries are the following subclasses of #ISO-13606:Entry
        
                #HL7-CDA:Observation
                #HL7-CDA:Encounter
                etc 
        -->

        <xsl:variable name="entryClassIRI"
            select="$rootNode/owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Entry']/owl:Class[1]/@IRI"/>

        <xsl:variable name="entrySet" select="key('individualIRIList',$entryClassIRI,$rootNode)"/>

        <xsl:variable name="headers"
            select="$parameters/staticParameters/cityEHRAdmin/printHeaders/displayList[@type='dataDictionary']/header"/>

        <table class="displayList">
            <thead>
                <tr>
                    <td><xsl:value-of select="$headers[1]"/>(<xsl:value-of select="count($entrySet)"
                        />)</td>
                    <td>
                        <xsl:value-of select="$headers[2]"/>
                    </td>
                    <td>
                        <xsl:value-of select="$headers[3]"/>
                    </td>
                </tr>
            </thead>
            <tbody valign="top">
                <xsl:for-each select="$entrySet">
                    <xsl:sort select="."/>
                    <xsl:variable name="entryIRI" select="."/>
                    <xsl:variable name="elementSet"
                        select="key('contentsIRIList',$entryIRI,$rootNode)"/>
                    <xsl:variable name="elementCount" select="count($elementSet)"/>
                    <tr>
                        <!-- Entry -->
                        <td>
                           <xsl:value-of select="cityEHRFunction:getDisplayName($entryIRI)"/> (<xsl:value-of
                                select="$elementCount"/>) <br/> (<xsl:value-of select="$entryIRI"/>) </td>
                        <!-- List of elements, one on each line.
                             Watch out for clusters. -->
                        <td>
                            <ul>
                                <xsl:for-each select="$elementSet">
                                    <xsl:variable name="elementIRI" select="."/>
                                    <xsl:variable name="displayNameTerm" as="xs:string"
                                        select="cityEHRFunction:getDisplayName($elementIRI)"/>
                                    <xsl:variable name="elementType"
                                        select="substring-after(key('specifiedObjectPropertyList',concat('#hasElementType',$elementIRI),$rootNode) ,'#CityEHR:ElementProperty:')"/>
                                    <li><xsl:value-of select="$displayNameTerm"/> (<xsl:value-of
                                            select="if ($elementType!='') then $elementType else 'cluster'"
                                        />) </li>
                                    <!-- Add lines to match the same number of values in enumeratedValues -->
                                    <xsl:variable name="elementValueSet"
                                        select="key('specifiedObjectPropertyList',concat('#hasValue',$elementIRI),$rootNode)"/>
                                    <xsl:for-each select="$elementValueSet">
                                        <li>&#160;</li>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </ul>
                        </td>
                        <!-- Value(s) for each element -->
                        <td>
                            <ul>
                                <xsl:for-each select="$elementSet">
                                    <xsl:variable name="elementIRI" select="."/>
                                    <!-- Data type -->
                                    <xsl:variable name="elementDataType"
                                        select="substring-after(key('specifiedObjectPropertyList',concat('#hasDataType',$elementIRI),$rootNode) ,'#CityEHR:DataType:')"/>
                                    <li> (<xsl:value-of
                                            select="if ($elementDataType!='') then $elementDataType else 'cluster'"
                                        />) </li>
                                    <!-- List of enumerated values, if applicable -->
                                    <xsl:variable name="elementValueSet"
                                        select="key('specifiedObjectPropertyList',concat('#hasValue',$elementIRI),$rootNode)"/>
                                    <xsl:for-each select="$elementValueSet">
                                        <xsl:variable name="valueIRI" select="."/>
                                        <xsl:variable name="displayNameTerm" as="xs:string"
                                            select="cityEHRFunction:getDisplayName($valueIRI)"/>
                                        <li>
                                            <xsl:value-of select="$displayNameTerm"/>
                                            <xsl:variable name="value"
                                                select="key('specifiedDataPropertyList',concat('#hasValue',$valueIRI),$rootNode)"/>
                                            <xsl:if
                                                test="exists($value) and $value!=$displayNameTerm">
                                                  (<xsl:value-of select="$value"/>) </xsl:if>
                                        </li>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </ul>
                        </td>
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>


    </xsl:template>


    <!-- Template to generate summary of compositions
         Three columns show Entry/Cluster/Element, Enumerated values, Hint
    -->
    <xsl:template name="generateCompositionSummaryDisplay">
        <!-- Get the set of entries in the dictionary.
            
            Entries are the following subclasses of #ISO-13606:Entry
            
            #HL7-CDA:Observation
            #HL7-CDA:Encounter
            etc 
        -->

        <xsl:variable name="compositionClassIRI"
            select="$rootNode/owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Composition']/owl:Class[1]/@IRI"/>

        <xsl:variable name="compositionSet"
            select="key('individualIRIList',$compositionClassIRI,$rootNode)"/>

        <xsl:variable name="headers"
            select="$parameters/staticParameters/cityEHRAdmin/printHeaders/displayList[@type='compositionSummary']/header"/>
        <table class="displayList">
            <thead>
                <!-- There should be three headers for this displayList -->
                <tr>
                    <xsl:for-each select="$headers">
                        <td>
                            <xsl:value-of select="."/>
                        </td>
                    </xsl:for-each>
                </tr>
            </thead>
            <tbody valign="top">
                <xsl:for-each select="$compositionSet">
                    <xsl:sort select="."/>
                    <xsl:variable name="compositionIRI" select="."/>
                    <xsl:variable name="sectionSet"
                        select="key('contentsIRIList',$compositionIRI,$rootNode)"/>
                    <!-- Composition -->
                    <tr>
                        <td colspan="3">
                           <xsl:value-of select="cityEHRFunction:getDisplayName($compositionIRI)"/>
                        </td>
                    </tr>
                    <!-- Sections -->
                    <xsl:for-each select="$sectionSet">
                        <xsl:call-template name="outputSection">
                            <xsl:with-param name="sectionIRI" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>

                </xsl:for-each>
            </tbody>
        </table>
    </xsl:template>

    <!-- Template to output section and its contents
         Can be called recursively for sub-sections -->
    <xsl:template name="outputSection">
        <xsl:param name="sectionIRI"/>
        <tr>
            <td colspan="3">
                <xsl:value-of select="cityEHRFunction:getDisplayName($sectionIRI)"/>
            </td>
        </tr>
        <!-- Contents may be sub-sections or entries -->
        <xsl:variable name="contentsSet" select="key('contentsIRIList',$sectionIRI,$rootNode)"/>
        <xsl:for-each select="$contentsSet">
            <xsl:variable name="contentIRI" select="."/>
            <!-- Section -->
            <xsl:if test="starts-with($contentIRI,'#ISO-13606:Section')">
                <xsl:call-template name="outputSection">
                    <xsl:with-param name="sectionIRI" select="$contentIRI"/>
                </xsl:call-template>
            </xsl:if>
            <!-- Entry -->
            <xsl:if test="starts-with($contentIRI,'#ISO-13606:Entry')">
                <!-- Contents of entry can be elements or clusters.
                     Assume that cluster has more than one element (altough this still works with only one) -->
                <xsl:variable name="elementsSet"
                    select="key('contentsIRIList',$contentIRI,$rootNode)"/>
                <xsl:variable name="singleElement"
                    select="if (starts-with($elementsSet[1],'#ISO-13606:Element') and not(exists($elementsSet[2])) ) then $elementsSet[1] else ''"/>
                <tr>
                    <!-- Displayname -->
                    <td> </td>
                    <!-- Values, but only if there is only one element -->
                    <td> </td>
                    <!-- Hint, but only if there is only one element -->
                    <td> </td>
                </tr>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>


    <!-- Function to output displayName -->
    <xsl:function name="cityEHRFunction:getDisplayName">
        <xsl:param name="nodeIRI"/>
        <xsl:variable name="displayNameTermIRI" as="xs:string"
            select="if (exists(key('termIRIList',$nodeIRI,$rootNode))) then key('termIRIList',$nodeIRI,$rootNode)[1] else ''"/>
        <xsl:variable name="displayNameTerm" as="xs:string"
            select="if (exists(key('termDisplayNameList',$displayNameTermIRI,$rootNode))) then key('termDisplayNameList',$displayNameTermIRI,$rootNode)[1] else ''"/>
        <xsl:value-of select="$displayNameTerm"/>
    </xsl:function>

</xsl:stylesheet>
