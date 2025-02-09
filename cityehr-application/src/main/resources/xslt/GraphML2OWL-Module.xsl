<!-- 
  *********************************************************************************************************
  cityEHR
  GraphML2OWL.xsl
  
  Transforms GraphML from Yed to OWL Ontology for cityEHR Information Model.  
  
  Copyright (C) 2013-2021 John Chelsom.
  
  This program is free software; you can redistribute it and/or modify it under the terms of the
  GNU Lesser General Public License as published by the Free Software Foundation; either version
  2.1 of the License, or (at your option) any later version.
  
  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the GNU Lesser General Public License for more details.
  
  The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
  **********************************************************************************************************
-->

<!DOCTYPE stylesheet [
<!ENTITY rdf 
"&amp;rdf;">
]>
<xsl:stylesheet version="2.0" exclude-result-prefixes="Math g graphml xs y svg protege"
  xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:Math="java:java.lang.Math" xmlns:g="http://graphml.graphdrawing.org/xmlns/graphml"
  xmlns:y="http://www.yworks.com/xml/graphml" xmlns:svg="http://www.w3.org/2000/svg"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
  xmlns:graphml="http://graphml.graphdrawing.org/xmlns" xmlns:funct="text:p:,funct"
  xmlns="http://www.w3.org/2002/07/owl#" xmlns:xml="http://www.w3.org/XML/1998/namespace"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:protege="http://protege.stanford.edu/plugins/owl/protege#"
  xpath-default-namespace="http://graphml.graphdrawing.org/xmlns/graphml"
  xmlns:cityEHR="http://openhealthinformatics.org/ehr"
  xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3">

  <xsl:output method="xml" indent="yes"/>

  <!-- Import OWL Utilities -->
  <xsl:include href="OWLUtilities.xsl"/>


  <!-- === Global Variables === -->
  <!-- Root node of the graphML (not the root node of the hierarchy.
  Needed for errors/warnings in OWLUtilities -->

  <xsl:variable name="rootNode" select="/graphml:graphml"/>

  <!-- Set the Application for this Information Model -->
  <xsl:variable name="defaultApplicationId"
    select="normalize-space(/graphml:graphml/graphml:key[@attr.name='application']/graphml:default)"/>
  <xsl:variable name="applicationKeyId"
    select="normalize-space(/graphml:graphml/graphml:key[@attr.name='application']/@id)"/>
  <xsl:variable name="setApplicationId"
    select="normalize-space(/graphml:graphml/graphml:graph/graphml:data[@key=$applicationKeyId])"/>

  <xsl:variable name="applicationId"
    select="if (exists($setApplicationId) and $setApplicationId!='') then $setApplicationId else $defaultApplicationId"/>
  <xsl:variable name="applicationDisplayName" select="$applicationId"/>
  <xsl:variable name="modelOwner" select="$applicationId"/>

  <!-- Set the Specialty for this Information Model -->
  <xsl:variable name="defaultSpecialtyId"
    select="normalize-space(/graphml:graphml/graphml:key[@attr.name='specialty']/graphml:default)"/>
  <xsl:variable name="specialtyKeyId"
    select="normalize-space(/graphml:graphml/graphml:key[@attr.name='specialty']/@id)"/>
  <xsl:variable name="setSpecialtyId"
    select="normalize-space(/graphml:graphml/graphml:graph/graphml:data[@key=$specialtyKeyId])"/>

  <xsl:variable name="specialtyId"
    select="if (exists($setSpecialtyId) and $setSpecialtyId!='') then $setSpecialtyId else $defaultSpecialtyId"/>
  <xsl:variable name="specialtyDisplayName" select="$specialtyId"/>

  <!-- Set the Class for this Information Model -->
  <xsl:variable name="defaultClassId"
    select="normalize-space(/graphml:graphml/graphml:key[@attr.name='class']/graphml:default)"/>
  <xsl:variable name="classKeyId"
    select="normalize-space(/graphml:graphml/graphml:key[@attr.name='class']/@id)"/>
  <xsl:variable name="setClassId"
    select="normalize-space(/graphml:graphml/graphml:graph/graphml:data[@key=$classKeyId])"/>

  <xsl:variable name="classId"
    select="if (exists($setClassId) and $setClassId!='') then $setClassId else $defaultClassId"/>
  <xsl:variable name="classDisplayName" select="$classId"/>

  <!-- Set the languageCode for this Information Model -->
  <xsl:variable name="defaultLanguageCode"
    select="normalize-space(/graphml:graphml/graphml:key[@attr.name='languageCode']/graphml:default)"/>
  <xsl:variable name="languageCodeKeyId"
    select="normalize-space(/graphml:graphml/graphml:key[@attr.name='languageCode']/@id)"/>
  <xsl:variable name="setLanguageCode"
    select="normalize-space(/graphml:graphml/graphml:graph/graphml:data[@key=$languageCodeKeyId])"/>

  <xsl:variable name="baseLanguageCode"
    select="if (exists($setLanguageCode) and $setLanguageCode!='') then $setLanguageCode else $defaultLanguageCode"/>

  <!-- To output a carriage return -->
  <xsl:variable name="line-break">
    <xsl:text>
    </xsl:text>
  </xsl:variable>


  <!-- ==============================================
    Define Keys  
    ============================================== -->

  <xsl:key name="node" match="//graphml:node" use="@id"/>
  <xsl:key name="nodeLabel" match="//graphml:node/graphml:data/*/y:NodeLabel" use="../../../@id"/>
  <xsl:key name="sourceNode" match="//graphml:edge" use="@source"/>
  <xsl:key name="targetNode" match="//graphml:edge" use="@target"/>

  <!-- ==============================================
    Templates
    ============================================== -->

  <!-- Ignore these elements -->
  <xsl:template match="desc|key|data"/>


  <!-- Named template to generate OWL -->
  <xsl:template name="generateOWL">

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

    <!-- === The City EHR ontology architecture - static XML === 
      Copy the assertions from cityEHRarchitecture.xml
      This includes the necessary prefix declarations and some standard annotations
      plus all assertions for the cityEHR architecture
      ============================================================== -->

    <Ontology xmlns="http://www.w3.org/2002/07/owl#">
      <!-- Copy attributes (including namespace declarations) from template -->
      <xsl:copy-of select="$cityEHRarchitecture/owl:Ontology/@*" copy-namespaces="no"/>

      <!-- Copy assertions from template -->
      <xsl:copy-of select="$cityEHRarchitecture/owl:Ontology/*" copy-namespaces="no"/>


      <!-- === Annotations for the Information Model being processed. -->

      <Annotation>
        <AnnotationProperty abbreviatedIRI="rdfs:applicationId"/>
        <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral">
          <xsl:value-of select="$applicationId"/>
        </Literal>
      </Annotation>
      <Annotation>
        <AnnotationProperty abbreviatedIRI="rdfs:specialtyId"/>
        <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral">
          <xsl:value-of select="$specialtyId"/>
        </Literal>
      </Annotation>
      <Annotation>
        <AnnotationProperty abbreviatedIRI="rdfs:copyright"/>
        <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral">Copyright (c)
            <xsl:value-of select="year-from-date(current-date())"/>
          <xsl:value-of select="$modelOwner"/>
        </Literal>
      </Annotation>


      <!-- === The application for this ontology === 
        Corresponds to a top-level ISO-13606:EHR_Extract.
        
        The application must be present on the Configuration sheet.                
        $applicationId and $applicationDisplayName are set in the XSL that calls this module.
        
        Assert the individual
        Set its class to ISO-13606:EHR_Extract
        Set its displayName
        
      -->

      <xsl:variable name="applicationIRI"
        select="cityEHRFunction:getIRI('#ISO-13606:EHR_Extract:',$applicationId)"/>
      <xsl:variable name="applicationTermIRI"
        select="cityEHRFunction:getIRI('#CityEHR:Term:',$applicationDisplayName)"/>

      <xsl:comment> ===== Assertions related to the application for this ontology ===== </xsl:comment>
      <xsl:text disable-output-escaping="yes">           
      </xsl:text>

      <Declaration>
        <NamedIndividual IRI="{$applicationIRI}"/>
      </Declaration>

      <ClassAssertion>
        <Class IRI="#ISO-13606:EHR_Extract"/>
        <NamedIndividual IRI="{$applicationIRI}"/>
      </ClassAssertion>

      <ObjectPropertyAssertion>
        <ObjectProperty IRI="#hasDisplayName"/>
        <NamedIndividual IRI="{$applicationIRI}"/>
        <NamedIndividual IRI="{$applicationTermIRI}"/>
      </ObjectPropertyAssertion>

      <DataPropertyAssertion>
        <DataProperty IRI="#hasOwner"/>
        <NamedIndividual IRI="{$applicationIRI}"/>
        <Literal xml:lang="en" datatypeIRI="&rdf;PlainLiteral">
          <xsl:value-of select="$modelOwner"/>
        </Literal>
      </DataPropertyAssertion>

      <!-- No need to declare the term, as it is picked up in the general declarations later on -->


      <!-- === The Language for this ontology -->
      <DataPropertyAssertion>
        <DataProperty IRI="#hasBaseLanguage"/>
        <NamedIndividual IRI="{$applicationIRI}"/>
        <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral">
          <xsl:value-of select="$baseLanguageCode"/>
        </Literal>
      </DataPropertyAssertion>

      <!-- === The specialty for this ontology === 
        Corresponds to a top-level ISO-13606:Folder
        
        The specialty must be present on the Configuration sheet.                
        $specialtyId and $specialtyDisplayName are set in the XSL that calls this module.
        
        Assert the individual
        Set its class to ISO-13606:EHR_Folder
        Set the Folder as content of the EHR_Extract
        Set its displayName
      -->

      <xsl:variable name="specialtyIRI"
        select="cityEHRFunction:getIRI('#ISO-13606:Folder:',$specialtyId)"/>
      <xsl:variable name="specialtyTermIRI"
        select="cityEHRFunction:getIRI('#CityEHR:Term:',$specialtyDisplayName)"/>

      <xsl:comment> ===== Assertions related to the clinical specialty for this ontology ===== </xsl:comment>
      <xsl:text disable-output-escaping="yes">           
      </xsl:text>

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


      <!-- === The class for this ontology === 
        Single individual as a member of the root class.
        
        The class must be present on the Configuration sheet.                
        $classId and $classDisplayName are set in the XSL that includes this module.
        
        $classIRI has been declared as a variable above.
        
        Assert the individual
        Set its class to CityEHR:Class:$ClassId
        Set its displayName
      -->

      <xsl:variable name="classIRI" select="concat('#CityEHR:Class:',$classId)"/>
      <xsl:variable name="classTermIRI"
        select="cityEHRFunction:getIRI('#CityEHR:Term:',$classDisplayName)"/>

      <xsl:comment> ===== Assertions related to the class for this ontology ===== </xsl:comment>
      <xsl:text disable-output-escaping="yes">           
      </xsl:text>

      <Declaration>
        <Class IRI="{$classIRI}"/>
      </Declaration>

      <SubClassOf>
        <Class IRI="{$classIRI}"/>
        <Class IRI="#CityEHR:Class"/>
      </SubClassOf>

      <Declaration>
        <NamedIndividual IRI="{$classIRI}"/>
      </Declaration>

      <ClassAssertion>
        <Class IRI="#CityEHR:Class"/>
        <NamedIndividual IRI="{$classIRI}"/>
      </ClassAssertion>

      <ObjectPropertyAssertion>
        <ObjectProperty IRI="#hasDisplayName"/>
        <NamedIndividual IRI="{$classIRI}"/>
        <NamedIndividual IRI="{$classTermIRI}"/>
      </ObjectPropertyAssertion>

      <!-- No need to declare the term, as it is picked up in the general declarations later on -->


      <!-- === Declare all terms used in the ontology ======= 
        ============================================== -->
      <!-- Named individuals for each term 
        Only want one unique individual for each term, so need to test that there aren't duplicates.
        $allTerms will contain all term nodes, including any duplicates
        As we step through each term, output the declaration of a Named Individual only if there are no duplicates 
        for that term left in the sequence.
        
        The terms are formed from the displayNames of the graph nodes
      -->
      <xsl:comment> ===== Assertions related to the terms used in this ontology ===== </xsl:comment>
      <xsl:text disable-output-escaping="yes">           
      </xsl:text>

      <xsl:variable name="specialtyTerms"
        select="($applicationDisplayName,$specialtyDisplayName,$classDisplayName)"/>

      <!-- The displayName the label of each node in the graph -->
      <xsl:variable name="displayNameTerms" select="//graphml:node/graphml:data/*/y:NodeLabel"/>

      <xsl:variable name="allTerms" select="$displayNameTerms/normalize-space(.) , $specialtyTerms "/>
      <!--
      <xsl:variable name="allTerms" select="$specialtyTerms"/>
 -->
      <xsl:for-each select="distinct-values($allTerms)">
        <xsl:variable name="term" select="."/>
        <xsl:if test="$term != ''">

          <xsl:variable name="termId" select="cityEHRFunction:CreateID($term)"/>
          <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$termId)"/>

          <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="{$termIRI}"/>
            <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral">
              <xsl:value-of select="$term"/>
            </Literal>
          </DataPropertyAssertion>
        </xsl:if>
      </xsl:for-each>



      <!-- === Check integrity of the graph ======= 
           Must be an acyclic directed graph.
           This check looks for cycles in the nodes of the graph.
           
           <edge id="e1" source="n58" target="n59">
           ...
           </edge>
           ============================================== -->

      <xsl:for-each select="//graphml:edge">
        <xsl:call-template name="checkAcyclicGraph">
          <xsl:with-param name="path" select="''"/>
          <xsl:with-param name="edge" select="."/>
        </xsl:call-template>
      </xsl:for-each>

      <!-- === Representation of the class hierarchy === 
           ============================================= -->

      <!-- Declare the nodes in the graph -->
      <xsl:for-each select="//graphml:node[graphml:data/*/y:NodeLabel]">
        <xsl:call-template name="declareNode">
          <xsl:with-param name="classIRI" select="$classIRI"/>
          <xsl:with-param name="node" select="."/>
        </xsl:call-template>
      </xsl:for-each>

      <!-- Relationships in the graph -->
      <xsl:for-each select="//graphml:edge">
        <xsl:call-template name="assertNodeRelationship">
          <xsl:with-param name="edge" select="."/>
        </xsl:call-template>
      </xsl:for-each>


    </Ontology>
  </xsl:template>


  <!-- === Template to declare individual and term for each node ======= 
       -->

  <xsl:template name="declareNode">
    <xsl:param name="classIRI"/>
    <xsl:param name="node"/>

    <xsl:variable name="term" select="graphml:data/*/y:NodeLabel"/>
    <xsl:variable name="termId" select="cityEHRFunction:CreateID($term)"/>
    <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$termId)"/>

    <xsl:variable name="nodeId" select="$termId"/>
    <xsl:variable name="nodeClass" select="concat('#CityEHR:Class:',$classId)"/>
    <xsl:variable name="nodeIRI" select="cityEHRFunction:getIRI($nodeClass,$nodeId)"/>

    <xsl:variable name="nodeLevel" select="cityEHRFunction:getNodeLevel($nodeId)"/>

    <!-- Declare individual for node -->
    <Declaration xmlns="http://www.w3.org/2002/07/owl#">
      <NamedIndividual IRI="{$nodeIRI}"/>
    </Declaration>

    <!-- Assert membership of class -->
    <ClassAssertion xmlns="http://www.w3.org/2002/07/owl#">
      <Class IRI="{$classIRI}"/>
      <NamedIndividual IRI="{$nodeIRI}"/>
    </ClassAssertion>

    <!-- Set the assertion of the term for the node -->
    <ObjectPropertyAssertion xmlns="http://www.w3.org/2002/07/owl#">
      <ObjectProperty IRI="#hasDisplayName"/>
      <NamedIndividual IRI="{$nodeIRI}"/>
      <NamedIndividual IRI="{$termIRI}"/>
    </ObjectPropertyAssertion>
  </xsl:template>


  <xsl:template match="graphml:node" mode="ClassAssertion">
    <xsl:variable name="node" select="."/>
    <xsl:variable name="nodeId" select="./@id"/>
    <xsl:variable name="nodeDisplayName" select="./graphml:data/y:GenericNode/y:NodeLabel[1]"/>

    <xsl:variable name="nodeLevel" select="cityEHRFunction:getNodeLevel($nodeId)"/>

    <xsl:if test="$nodeLevel != 'orphan' and $nodeDisplayName!=''">
      <ClassAssertion xmlns="http://www.w3.org/2002/07/owl#">
        <!--<Class IRI="#CityEHR:Class:Diagnosis:Level-1"/>-->
        <xsl:element name="Class">
          <xsl:attribute name="IRI">
            <xsl:text>#CityEHR:Class:</xsl:text>
            <xsl:value-of select="$classId"/>
            <!-- Not differentiating levels 2015-07-12 -->
            <!--
            <xsl:text>:</xsl:text>
            <xsl:value-of select="$nodeLevel"/>
            -->
          </xsl:attribute>
        </xsl:element>
        <!--<NamedIndividual IRI="#CityEHR:Class:Diagnosis:Trauma"/>-->
        <xsl:element name="NamedIndividual">
          <xsl:attribute name="IRI">
            <xsl:text>#CityEHR:Class:</xsl:text>
            <xsl:value-of select="$classId"/>
            <xsl:text>:</xsl:text>
            <xsl:value-of select="cityEHRFunction:CreateID($nodeDisplayName)"/>
          </xsl:attribute>
        </xsl:element>
      </ClassAssertion>
    </xsl:if>

    <!-- Warning if node is an orphan -->
    <xsl:if test="$nodeLevel = 'orphan'">
      <xsl:variable name="context"
        select="concat('Node id: ',$nodeId,' displayName: ',$nodeDisplayName)"/>
      <xsl:variable name="message" select="'Orphan node - has no parent or children'"/>
      <xsl:call-template name="generateWarning">
        <xsl:with-param name="node" select="$node"/>
        <xsl:with-param name="context" select="$context"/>
        <xsl:with-param name="message" select="$message"/>
      </xsl:call-template>
    </xsl:if>

    <!-- Warning if node has no label (displayName) -->
    <xsl:if test="$nodeDisplayName = ''">
      <xsl:variable name="context" select="concat('Node id: ',$nodeId)"/>
      <xsl:variable name="message" select="'Node has no label in graph - cannot create individual'"/>
      <xsl:call-template name="generateWarning">
        <xsl:with-param name="node" select="$node"/>
        <xsl:with-param name="context" select="$context"/>
        <xsl:with-param name="message" select="$message"/>
      </xsl:call-template>
    </xsl:if>

    <!-- Warning if node has more than one label (displayName) -->
    <xsl:if test="exists(./graphml:data/y:GenericNode/y:NodeLabel[2])">
      <xsl:variable name="context" select="concat('Node id: ',$nodeId)"/>
      <xsl:variable name="message" select="'Node has more than one label in graph'"/>
      <xsl:call-template name="generateWarning">
        <xsl:with-param name="node" select="$node"/>
        <xsl:with-param name="context" select="$context"/>
        <xsl:with-param name="message" select="$message"/>
      </xsl:call-template>
    </xsl:if>

  </xsl:template>


  <!-- Assert node relationship for edge
       Expressed by <edge source="n1" target="n2">
       
      <ObjectPropertyAssertion>
        <ObjectProperty IRI="#hasType"/>
        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Trauma"/>
        <NamedIndividual IRI="#CityEHR:Class:Diagnosis:Fracture"/>
      </ObjectPropertyAssertion>
-->

  <xsl:template name="assertNodeRelationship">
    <xsl:param name="edge"/>

    <xsl:variable name="source" select="$edge/@source"/>
    <xsl:variable name="target" select="$edge/@target"/>

    <xsl:variable name="nodeClass" select="concat('#CityEHR:Class:',$classId)"/>

    <xsl:variable name="sourceId" select="cityEHRFunction:CreateID(key('nodeLabel',$source))"/>
    <xsl:variable name="sourceIRI" select="cityEHRFunction:getIRI($nodeClass,$sourceId)"/>

    <xsl:variable name="targetId" select="cityEHRFunction:CreateID(key('nodeLabel',$target))"/>
    <xsl:variable name="targetIRI" select="cityEHRFunction:getIRI($nodeClass,$targetId)"/>

    <xsl:if test="$sourceId!='' and $targetId!=''">
      <ObjectPropertyAssertion xmlns="http://www.w3.org/2002/07/owl#">
        <ObjectProperty IRI="#hasType"/>
        <NamedIndividual IRI="{$sourceIRI}"/>
        <NamedIndividual IRI="{$targetIRI}"/>
      </ObjectPropertyAssertion>
    </xsl:if>

    <!-- Warning if link is to non-existant node -->
    <xsl:if test="$targetId = ''">
      <xsl:variable name="context" select="concat('Node id: ',$source)"/>
      <xsl:variable name="message" select="concat('Link to non-existant node ',$target)"/>
      <xsl:call-template name="generateWarning">
        <xsl:with-param name="node" select="$edge"/>
        <xsl:with-param name="context" select="$context"/>
        <xsl:with-param name="message" select="$message"/>
      </xsl:call-template>
    </xsl:if>

    <!-- Warning if link is from non-existant node -->
    <xsl:if test="$sourceId=''">
      <xsl:variable name="context" select="concat('Node id: ',$target)"/>
      <xsl:variable name="message" select="concat('Link from non-existant node ',$source)"/>
      <xsl:call-template name="generateWarning">
        <xsl:with-param name="node" select="$edge"/>
        <xsl:with-param name="context" select="$context"/>
        <xsl:with-param name="message" select="$message"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>


  <!-- === Function to get the level of a node in the graph
  
     Level-1 is the source of an edge, but not the target
     Level-2 is the source and the target of an edge
     Level-3 is the target of an edge, but not the source
     
     === -->
  <xsl:function name="cityEHRFunction:getNodeLevel">
    <xsl:param name="nodeId"/>

    <xsl:value-of
      select="if (exists(key('nodeSource',$nodeId)) and not(exists(key('nodeTarget',$nodeId)))) then 'Level-1'
      else if (exists(key('nodeSource',$nodeId)) and exists(key('nodeTarget',$nodeId))) then 'Level-2'
      else if (not(exists(key('nodeSource',$nodeId))) and exists(key('nodeTarget',$nodeId))) then 'Level-3'
      else 'orphan'"
    />
  </xsl:function>


  <!-- === Template to check that the graph is acyclic
       Generates an error if a cycle is found.
       
       Node is of the form:
       
       <edge id="e4" source="n3" target="n4">
       ...
       </edge>
       
       If the cycle is caused by a self-referential edge (<edge id="e4" source="n3" target="n3">) then a warning is raised, rather than an error.
       === -->

  <xsl:template name="checkAcyclicGraph">
    <xsl:param name="path"/>
    <xsl:param name="edge"/>
    
    <xsl:variable name="separator" select="'/'"/>

    <xsl:variable name="source" select="data($edge/@source)"/>
    <xsl:variable name="target" select="data($edge/@target)"/>    

    <!-- Need both separators so that the path is formed as /n0//n1//n2/ etc,
         This means check is for /n1/ rather than /n1 which would match with /n10, /n11 etc -->
    <xsl:variable name="sourcePath" select="concat($separator,$source,$separator)"/>
    <xsl:variable name="targetCheck" select="if ($target=($source,'')) then 'failed' else 'ok'"/>

    <!-- If target is blank or same as the source then generate a warning and stop checking -->
    <xsl:if test="$targetCheck='failed'">
      <xsl:variable name="context" select="concat('Node path: ',$path)"/>
      <xsl:variable name="nodeDisplayName" select="key('nodeLabel',$source)"/>
      <xsl:variable name="linkWarning"
        select="if ($target='') then 'Link with no target' else 'Self referential link'"/>
      <xsl:variable name="message"
        select="concat($linkWarning,' found at node: ',$source,' - ',$nodeDisplayName)"/>
      <xsl:call-template name="generateWarning">
        <xsl:with-param name="node" select="$edge"/>
        <xsl:with-param name="context" select="$context"/>
        <xsl:with-param name="message" select="$message"/>
      </xsl:call-template>
    </xsl:if>

    <!-- If the path contains the source then generate an error and stop checking -->
    <xsl:if test="$targetCheck='ok' and contains($path,$sourcePath)">
      <xsl:variable name="context" select="concat('Node path: ',$path)"/>
      <xsl:variable name="nodeDisplayName" select="key('nodeLabel',$source)"/>
      <xsl:variable name="message"
        select="concat('Cyclic graph found adding node: ',$source,' - ',$nodeDisplayName)"/>
      <xsl:call-template name="generateError">
        <xsl:with-param name="node" select="$edge"/>
        <xsl:with-param name="context" select="$context"/>
        <xsl:with-param name="message" select="$message"/>
      </xsl:call-template>
    </xsl:if>

    <!-- If path does not contain the target then call the check recursively -->
    <xsl:if test="$targetCheck='ok' and not(contains($path,$sourcePath))">
      <xsl:variable name="nextPath" select="concat($path,$sourcePath)"/>
      <xsl:for-each select="key('sourceNode',$target)">
        <xsl:call-template name="checkAcyclicGraph">
          <xsl:with-param name="path" select="$nextPath"/>
          <xsl:with-param name="edge" select="."/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>

  </xsl:template>

</xsl:stylesheet>
