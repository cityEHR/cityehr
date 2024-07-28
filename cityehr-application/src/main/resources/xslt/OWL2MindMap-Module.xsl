<!-- ====================================================================
    OWL2MindMap-Module.xsl
    Module to convert cityEHR OWL to Mind Map .mm XML representation
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

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions"  xmlns:iso-13606="http://www.iso.org/iso-13606">
    <xsl:output method="xml" indent="yes" name="xml"/>
    
    
    <!-- ========================================================================
        Keys
        ======================================================================== -->
    
    <!-- Keys for ClassAssertion
        <ClassAssertion>
        <Class IRI="#CityEHR:Form"/>
        <NamedIndividual IRI="#CityEHR:Form:Fractures"/>
        </ClassAssertion>
        
        individualIRIList returns IRIs of individuals in matched class (usually more than one)
        classIRIList returns IRI of class for matched individual (should only be one)
    -->
    <xsl:key name="individualIRIList" match="/owl:Ontology/owl:ClassAssertion/owl:NamedIndividual/@IRI" use="../../owl:Class/@IRI"/>
    <xsl:key name="classIRIList" match="/owl:Ontology/owl:ClassAssertion/owl:Class/@IRI" use="../../owl:NamedIndividual/@IRI"/>
    <xsl:key name="subClassIRIList" match="/owl:Ontology/owl:SubClassOf/owl:Class[2]/@IRI" use="../../owl:Class[1]/@IRI"/>  
    
    <!-- Key for class types
        <ObjectPropertyAssertion>
        <ObjectProperty IRI="#hasType"/>
        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Bonedisorders"/>
        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Osteomalaciarickets"/>
        </ObjectPropertyAssertion>
    -->
    <xsl:key name="typeIRIList" match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasType']/owl:NamedIndividual[2]/@IRI" use="../../owl:NamedIndividual[1]/@IRI"/>
    
    
    <!-- Key for component contents
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasContent"/>
            <NamedIndividual IRI="#CityEHR:Order:Pathology"/>
            <NamedIndividual IRI="#ISO-13606:Section:PathologyTest"/>
        </ObjectPropertyAssertion>
        -->
    <xsl:key name="contentsList" match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasContent']/owl:NamedIndividual[2]/@IRI" use="../../owl:NamedIndividual[1]/@IRI"/>

    <!-- Key for Term IRI
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasDisplayName"/>
            <NamedIndividual IRI="#CityEHR:Order:Radiology"/>
            <NamedIndividual IRI="#CityEHR:Term:Radiological%20Examinations"/>
        </ObjectPropertyAssertion>
-->
    <xsl:key name="termIRIList" match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasDisplayName']/owl:NamedIndividual[2]/@IRI" use="../../owl:NamedIndividual[1]/@IRI"/>

    <!-- Key for Term displayName
        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="#CityEHR:Term:Radiological%20Examinations"/>
            <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">Radiological Examinations</Literal>
        </DataPropertyAssertion>
    -->
    <xsl:key name="termDisplayNameList" match="/owl:Ontology/owl:DataPropertyAssertion[owl:DataProperty/@IRI='#hasValue']/owl:Literal" use="../owl:NamedIndividual/@IRI"/>

    <!-- Key for Element datatype
    <ObjectPropertyAssertion>
        <ObjectProperty IRI="#hasDataType"/>
        <NamedIndividual IRI="#ISO-13606:Element:Boolean"/>
        <NamedIndividual IRI="#CityEHR:DataType:boolean"/>
    </ObjectPropertyAssertion>
    -->
    <xsl:key name="elementDataTypeList" match="/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasDataType']/owl:NamedIndividual[2]/@IRI" use="../../owl:NamedIndividual[1]/@IRI"/>


<!-- ========================================================================
     Global Variables
     ======================================================================== -->
    
    <!-- Set the root node (the instance may be wrapped in a container element, so this finds the ontology root) -->
    <xsl:variable name="rootNode" select="//owl:Ontology"/>

    <!-- Set the Application for this ontology configuration -->
    <xsl:variable name="applicationIRI" as="xs:string"
        select="$rootNode/owl:ClassAssertion[owl:Class/@IRI='#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI"/>
    <!-- Strip the leading # from the IRI and replace : with - to get an file Id suitable for eXist -->                                           
    <xsl:variable name="applicationFileId" as="xs:string"
        select="replace(substring($applicationIRI,2),':','-')"/> 
    <xsl:variable name="applicationId" as="xs:string"
        select="substring-after($applicationFileId,'ISO-13606-EHR_Extract-')"/>
    
    <!-- Set the Specialty for this ontology configuration -->
    <xsl:variable name="specialtyIRI" as="xs:string"
        select="if (exists($rootNode/owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Folder']/owl:Class[1]/@IRI)) then ($rootNode/owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Folder']/owl:Class[1]/@IRI)[1] else ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get a file Id suitable for eXist -->                                           
    <xsl:variable name="specialtyFileId" as="xs:string"
        select="replace(substring($specialtyIRI,2),':','-')"/> 
    <xsl:variable name="specialtyId" as="xs:string"
        select="substring-after($specialtyFileId,'ISO-13606-Folder-')"/>
    
    <!-- Set the Class for this ontology configuration, if there is one -->
    <xsl:variable name="classIRI" as="xs:string"
        select="if (exists($rootNode/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI)) then $rootNode/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI else ''"/>
    <!-- Strip the leading # from the IRI and replace : with - to get a file Id suitable for eXist -->                                           
    <xsl:variable name="classFileId" as="xs:string"
        select="replace(substring($classIRI,2),':','-')"/>
    <xsl:variable name="classId" as="xs:string"
        select="substring-after($classFileId,'CityEHR-Class-')"/>

    <!-- Set the Base Language for this ontology -->
    <xsl:variable name="baseLanguage" as="xs:string"
        select="if (exists($rootNode/owl:DataPropertyAssertion[owl:DataProperty/@IRI='#hasBaseLanguage']/owl:Literal)) then $rootNode/owl:DataPropertyAssertion[owl:DataProperty/@IRI='#hasBaseLanguage']/owl:Literal else ''"/>
    
    <xsl:variable name="pathSeparator" as="xs:string" select="'@@@'"/>



    <!-- Template to generate the ISO-13606 model 
         Nested iso-13606:component structure
        <iso-13606:component iso-13606:type="Folder" code="#ISO-13606:Folder:FeatureDemo" codeSystem="cityEHR" displayName="cityEHR Feature Demo">
    -->
    <xsl:template name="generateMindMap">
        <xsl:param name="applicationIRI"/>
        <xsl:param name="specialtyIRI"/>
        <xsl:param name="classIRI"/>
        <xsl:param name="baseLanguageCode"/>

        <!-- === Create the Mind Map 
             The map is for the specified Specialty, with specialtyIRI and displayName
             OR for the specified Class, with classIRI and displayName
             === -->

        <!-- Get application displayName -->
        <xsl:variable name="applicationDisplayNameTermIRI" as="xs:string" select="if (exists(key('termIRIList',$applicationIRI))) then key('termIRIList',$applicationIRI)[1] else ''"/>
        <xsl:variable name="applicationDisplayNameTerm" as="xs:string" select="if ($applicationDisplayNameTermIRI='') then '' else key('termDisplayNameList',$applicationDisplayNameTermIRI)"/>

        <!-- Get specialty displayName -->
        <xsl:variable name="specialtyDisplayNameTermIRI" as="xs:string" select="if (exists(key('termIRIList',$specialtyIRI))) then key('termIRIList',$specialtyIRI)[1] else ''"/>
        <xsl:variable name="specialtyDisplayNameTerm" as="xs:string" select="if ($specialtyDisplayNameTermIRI='') then '' else key('termDisplayNameList',$specialtyDisplayNameTermIRI)"/>

        <map  version="0.9.0">

            <!-- This is a specialty model.
                 So there is no classIRI set -->
            <xsl:if test="$classIRI =''">
                <node TEXT="ISO-13606:EHR_Extract: {$applicationDisplayNameTerm}">

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

                    <node TEXT="ISO-13606:Folder: {$specialtyDisplayNameTerm}">
                        <xsl:for-each select="/owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Composition']/owl:Class[1]/@IRI">
                            <xsl:variable name="compositionIRI" as="xs:string" select="."/>
                            <xsl:for-each select="key('individualIRIList',$compositionIRI)">
                                <xsl:call-template name="generateComponent">
                                    <xsl:with-param name="nodeIRI" select="."/>
                                    <xsl:with-param name="nodePath" select="."/>
                                </xsl:call-template>
                            </xsl:for-each>
                        </xsl:for-each>
                    </node>


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


                    <!-- == Now iterate through each folder specified as contents of the specialty folder.
                    == -->
                    <xsl:for-each select="key('contentsList',$specialtyIRI)">
                        <xsl:call-template name="generateComponent">
                            <xsl:with-param name="nodeIRI" select="."/>
                            <xsl:with-param name="nodePath" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                </node>

            </xsl:if>

            <!-- This is a class model.
                 So there is a classIRI set -->
            <xsl:if test="$classIRI !=''">
                <xsl:variable name="classDisplayNameTermIRI" as="xs:string" select="if (exists(key('termIRIList',$classIRI))) then key('termIRIList',$classIRI)[1] else ''"/>
                <xsl:variable name="classDisplayNameTerm" as="xs:string" select="if (exists(key('termDisplayNameList',$classDisplayNameTermIRI))) then key('termDisplayNameList',$classDisplayNameTermIRI)[1] else ''"/>
                
                <!-- Get the list of root nodes in the class hierarchy -->
                <xsl:variable name="childNodeList"
                    select="distinct-values(/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasType']/owl:NamedIndividual[2]/data(@IRI))"/>
                <xsl:variable name="parentNodeList"
                    select="distinct-values(/owl:Ontology/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI='#hasType']/owl:NamedIndividual[1]/data(@IRI))"/>
                <xsl:variable name="rootNodeList"
                    select="for $n in $parentNodeList return if ($n = $childNodeList) then () else $n"/>
                
                <!-- Root node is the class -->
                <node TEXT="{$applicationDisplayNameTerm} : {$applicationId} :: {$specialtyDisplayNameTerm} : {$specialtyId} :: {$classDisplayNameTerm} : {$classId}">
                    <edge COLOR="#7f7f7f"/>
                    <font NAME="Arial" SIZE="11"/>
                    <!-- Generate  the nested class hierarchy.
                         Start with the list of level 1 nodes and the recursively call the generateNode template -->

                    <xsl:for-each select="$rootNodeList">
                            <xsl:variable name="nodeIRI" as="xs:string" select="."/>                                                      
                            <xsl:call-template name="generateNode">
                                <xsl:with-param name="nodeIRI" select="$nodeIRI"/>
                                <xsl:with-param name="loopPath" select="''"/>
                                <xsl:with-param name="level" select="'root'"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    
                </node>
                
            </xsl:if>
            
        </map>

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
        <xsl:variable name="classIRI" as="xs:string" select="if (exists(key('classIRIList',$nodeIRI,$rootNode))) then key('classIRIList',$nodeIRI,$rootNode)[1] else ''"/>
        <xsl:variable name="class" as="xs:string" select="if ($classIRI != '') then substring-after($classIRI,':') else ''"/>

        <!-- The class in cityEHR may be a sub-class of the ISO-13606 class -->
        <xsl:variable name="parentClassIRI" as="xs:string" select="if (exists(key('subClassIRIList',$classIRI,$rootNode))) then key('subClassIRIList',$classIRI,$rootNode)[1] else ''"/>
        <xsl:variable name="parentClass" as="xs:string" select="if ($parentClassIRI != '') then substring-after($parentClassIRI,':') else ''"/>

        <xsl:variable name="iso13606Class" as="xs:string" select="if ($parentClass != '') then $parentClass else $class"/>

        <xsl:variable name="nodeDisplayNameTermIRI" as="xs:string" select="if (exists(key('termIRIList',$nodeIRI,$rootNode))) then key('termIRIList',$nodeIRI,$rootNode) else ''"/>
        <xsl:variable name="nodeDisplayNameTerm" as="xs:string" select="if (exists(key('termDisplayNameList',$nodeDisplayNameTermIRI,$rootNode))) then key('termDisplayNameList',$nodeDisplayNameTermIRI,$rootNode)[1] else ''"/>

        <xsl:variable name="displayName" as="xs:string" select="if ($parentClass = '') then $nodeDisplayNameTerm else concat('(',$class,') ',$nodeDisplayNameTerm)"/>

        <xsl:variable name="elementDataType" as="xs:string" select="if (exists(key('elementDataTypeList',$nodeIRI,$rootNode))) then key('elementDataTypeList',$nodeIRI,$rootNode) else ''"/>

        <node TEXT="ISO-13606:{$iso13606Class}: {$displayName}">
            <xsl:for-each select="key('contentsList',$nodeIRI,$rootNode)">
                <xsl:variable name="contentNodeIRI" as="xs:string" select="."/>
                <xsl:if test="not(contains($nodePath,$contentNodeIRI))">
                    <xsl:variable name="nextNodePath" as="xs:string" select="concat($nodePath,$pathSeparator,$contentNodeIRI)"/>
                    <xsl:call-template name="generateComponent">
                        <xsl:with-param name="nodeIRI" select="$contentNodeIRI"/>
                        <xsl:with-param name="nodePath" select="$nextNodePath"/>
                    </xsl:call-template>
                </xsl:if>
                <xsl:if test="contains($nodePath,$contentNodeIRI)">
                    <node TEXT="Recursive"/>
                </xsl:if>
            </xsl:for-each>
        </node>

    </xsl:template>



    <!-- Generate node
         Includes a recursive call to generate child nodes
         This is used to generate node elements for nodes of a class hierarchy
       
    -->
    <xsl:template name="generateNode">
        <xsl:param name="nodeIRI"/>
        <xsl:param name="loopPath"/>
        <xsl:param name="level"/>
        <xsl:if test="not(contains($loopPath,$nodeIRI))">
            <!-- Get the first classIRI - should only be one, but just in case -->
            <xsl:variable name="classIRI" as="xs:string" select="if (exists(key('classIRIList',$nodeIRI,$rootNode))) then key('classIRIList',$nodeIRI,$rootNode)[1] else ''"/>
            <xsl:variable name="class" as="xs:string" select="if ($classIRI != '') then substring-after($classIRI,':') else ''"/>
            
            <xsl:variable name="displayNameTermIRI" as="xs:string" select="if (exists(key('termIRIList',$nodeIRI,$rootNode))) then key('termIRIList',$nodeIRI,$rootNode)[1] else ''"/>
            <xsl:variable name="displayNameTerm" as="xs:string" select="if (exists(key('termDisplayNameList',$displayNameTermIRI,$rootNode))) then key('termDisplayNameList',$displayNameTermIRI,$rootNode)[1] else ''"/>
                        
            <xsl:variable name="newLoopPath" as="xs:string" select="concat($loopPath,'@@@',$nodeIRI)"/>
            
            <node TEXT="{$displayNameTerm}">
                <font NAME="Arial" SIZE="11"/>
                <!-- Set the colour of the node, depending on whether level 1, 2 or 3 -->
                <!-- Level 1 (root) -->
                <xsl:if test="$level='root'">
                    <edge COLOR="#7f7f7f"/>
                </xsl:if>
                <xsl:if test="$level!='root'">
                    <!-- Level 2 (intermediate) node -->
                    <xsl:if test="exists(key('typeIRIList',$nodeIRI,$rootNode))">
                        <edge COLOR="#ffcc66"/>
                    </xsl:if>
                    <!-- Level 3 (leaf) node -->
                    <xsl:if test="not(exists(key('typeIRIList',$nodeIRI,$rootNode)))">
                        <edge COLOR="#cc66ff"/>
                    </xsl:if>                    
                </xsl:if>
                
                <!-- Process the child nodes -->
                <xsl:for-each select="key('typeIRIList',$nodeIRI,$rootNode)">
                    <xsl:variable name="childNodeIRI" as="xs:string" select="."/>
                     
                    <xsl:call-template name="generateNode">
                        <xsl:with-param name="nodeIRI" select="$childNodeIRI"/>
                        <xsl:with-param name="loopPath" select="$newLoopPath"/>
                        <xsl:with-param name="level" select="'child'"/>
                    </xsl:call-template>    
                </xsl:for-each>               
            </node>
        </xsl:if>
        
    </xsl:template>
    
    


</xsl:stylesheet>
