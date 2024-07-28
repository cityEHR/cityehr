<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWL2GraphML-Module.xsl
    Included as a module in OWL2GraphML.xsl and OWL2GraphML-File.xsl
        
    applicationIRI, specialtyIRI and classIRI define the application, folder (specialty) and class for the graph.
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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>
    
    <!-- === Global Variables === -->
    
    <!-- Set the root node -->
    <xsl:variable name="rootNode"
        select="/owl:Ontology"/> 
    
    <!-- Set the Application for this ontology configuration -->
    <xsl:variable name="applicationIRI" as="xs:string"
        select="/owl:Ontology/owl:ClassAssertion[owl:Class/@IRI='#ISO-13606:EHR_Extract']/owl:NamedIndividual/@IRI"/>
    
    <!-- Set the Specialty for this ontology configuration -->
    <xsl:variable name="specialtyIRI" as="xs:string"
    select="owl:SubClassOf[owl:Class[2]/@IRI='#ISO-13606:Folder']/owl:Class[1]/@IRI[1]"/>
    
    <!-- Set the Class for this ontology configuration, if there is one -->
    <xsl:variable name="classIRI" as="xs:string"
        select="if (exists(/owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI)) then /owl:Ontology/owl:SubClassOf[owl:Class[2]/@IRI='#CityEHR:Class']/owl:Class[1]/@IRI else ''"/>
    
    
    <!-- === Template to generate the GraphML === 
        applicationIRI, specialtyIRI and classIRI define the application, folder (specialty) and class for the graph.
        rootNode is the document root of the input ontology
    -->
    <xsl:template name="generateGraphML">
        <xsl:param name="rootNode"/>
        <xsl:param name="applicationIRI"/>
        <xsl:param name="specialtyIRI"/>
        <xsl:param name="classIRI"/>
        
        <!-- Set variables for IDs of application, specialty, class -->        
        <xsl:variable name="applicationId" as="xs:string" select="substring-after($applicationIRI,'ISO-13606:EHR_Extract:')"/>
        <xsl:variable name="specialtyId" as="xs:string" select="substring-after($specialtyIRI,'ISO-13606:Folder:')"/>       
        <xsl:variable name="classId" as="xs:string" select="substring-after($classIRI,'CityEHR:Class:')"/>
        
        <!-- Create keys for node number, term, displayName 
            
            Node number is the position of the node declaration in the OWL file
            
            <ClassAssertion>
                <Class IRI="#CityEHR:Class:Diagnosis"/>
                <NamedIndividual IRI="#CityEHR:Class:Diagnosis:ReactivearthritisNeisseria"/>
            </ClassAssertion>
            
            <ObjectPropertyAssertion>
                <ObjectProperty IRI="#hasDisplayName"/>
                <NamedIndividual IRI="#CityEHR:Class:Diagnosis:ReactivearthritisNeisseria"/>
                <NamedIndividual IRI="#CityEHR:Term:Reactive%20arthritis-Neisseria"/>
            </ObjectPropertyAssertion>
            
            <DataPropertyAssertion>
                <DataProperty IRI="#hasValue"/>
                <NamedIndividual IRI="#CityEHR:Term:Reactive%20arthritis-Neisseria"/>
                <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">Reactive arthritis-Neisseria</Literal>
            </DataPropertyAssertion>
            
            -->
        
        <graphml xmlns="http://graphml.graphdrawing.org/xmlns" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:y="http://www.yworks.com/xml/graphml" xmlns:yed="http://www.yworks.com/xml/yed/3" xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns http://www.yworks.com/xml/schema/graphml/1.1/ygraphml.xsd">
            
            <key for="graphml" id="d0" yfiles.type="resources"/>
            <key for="port" id="d1" yfiles.type="portgraphics"/>
            <key for="port" id="d2" yfiles.type="portgeometry"/>
            <key for="port" id="d3" yfiles.type="portuserdata"/>
            
            <key for="node" id="d7" yfiles.type="nodegraphics"/>
            
            <key attr.name="application" attr.type="string" for="graph" id="d8">
                <default><xsl:value-of select="$applicationId"></xsl:value-of></default>
            </key>
            <key attr.name="specialty" attr.type="string" for="graph" id="d9">
                <default><xsl:value-of select="$specialtyId"></xsl:value-of></default>
            </key>
            <key attr.name="class" attr.type="string" for="graph" id="d10">
                <default><xsl:value-of select="$classId"></xsl:value-of></default>
            </key>

            <key for="edge" id="d13" yfiles.type="edgegraphics"/>
            
            <graph edgedefault="directed" id="G">
                
                <!-- Create node element for each node in the hierarchy 
                                 
                <node id="n0">
                    <data key="d7">
                        <y:GenericNode configuration="com.yworks.bpmn.Activity.withShadow">
                        <y:Geometry height="55.0" width="85.0" x="234.5" y="-100.5"/>
                        <y:Fill color="#FFFFFF" color2="#FF3300" transparent="false"/>
                        <y:BorderStyle color="#FF6600" type="line" width="1.0"/>
                        <y:NodeLabel alignment="center" autoSizePolicy="content" fontFamily="Dialog" fontSize="11" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" height="16.955078125" modelName="internal" modelPosition="c" textColor="#000000" visible="true" width="45.2822265625" x="19.85888671875" y="19.0224609375">LEVEL 1</y:NodeLabel>
                        <y:StyleProperties>
                        <y:Property class="com.yworks.yfiles.bpmn.view.BPMNTypeEnum" name="com.yworks.bpmn.type" value="ACTIVITY_TYPE_STATELESS_TASK_PLAIN"/>
                        <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.line.color" value="#000000"/>
                        <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.fill" value="#ffffff"/>
                        <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.fill2" value="#d4d4d4"/>
                        </y:StyleProperties>
                        </y:GenericNode>
                    </data>
                </node>
                -->
                <node id="n0">
                    <data key="d7">
                        <y:GenericNode configuration="com.yworks.bpmn.Activity.withShadow">
                            <y:Geometry height="55.0" width="85.0" x="234.5" y="-100.5"/>
                            <y:Fill color="#FFFFFF" color2="#FF3300" transparent="false"/>
                            <y:BorderStyle color="#FF6600" type="line" width="1.0"/>
                            <y:NodeLabel alignment="center" autoSizePolicy="content" fontFamily="Dialog" fontSize="11" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" height="16.955078125" modelName="internal" modelPosition="c" textColor="#000000" visible="true" width="45.2822265625" x="19.85888671875" y="19.0224609375">LEVEL 1</y:NodeLabel>
                            <y:StyleProperties>
                                <y:Property class="com.yworks.yfiles.bpmn.view.BPMNTypeEnum" name="com.yworks.bpmn.type" value="ACTIVITY_TYPE_STATELESS_TASK_PLAIN"/>
                                <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.line.color" value="#000000"/>
                                <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.fill" value="#ffffff"/>
                                <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.fill2" value="#d4d4d4"/>
                            </y:StyleProperties>
                        </y:GenericNode>
                    </data>
                </node>
                <node id="n1">
                    <data key="d7">
                        <y:GenericNode configuration="com.yworks.bpmn.Activity.withShadow">
                            <y:Geometry height="55.0" width="85.0" x="234.5" y="42.0"/>
                            <y:Fill color="#FFFFFF" color2="#FFFF00" transparent="false"/>
                            <y:BorderStyle color="#FFFF00" type="line" width="1.0"/>
                            <y:NodeLabel alignment="center" autoSizePolicy="content" fontFamily="Dialog" fontSize="11" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" height="16.955078125" modelName="internal" modelPosition="c" textColor="#000000" visible="true" width="45.2822265625" x="19.85888671875" y="19.0224609375">LEVEL 2</y:NodeLabel>
                            <y:StyleProperties>
                                <y:Property class="com.yworks.yfiles.bpmn.view.BPMNTypeEnum" name="com.yworks.bpmn.type" value="ACTIVITY_TYPE_STATELESS_TASK_PLAIN"/>
                                <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.line.color" value="#000000"/>
                                <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.fill" value="#ffffff"/>
                                <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.fill2" value="#d4d4d4"/>
                            </y:StyleProperties>
                        </y:GenericNode>
                    </data>
                </node>
                <node id="n2">
                    <data key="d7">
                        <y:GenericNode configuration="com.yworks.bpmn.Activity.withShadow">
                            <y:Geometry height="55.0" width="85.0" x="234.5" y="168.5"/>
                            <y:Fill color="#FFFFFFE6" color2="#0099FFCC" transparent="false"/>
                            <y:BorderStyle color="#33CCFF" type="line" width="1.0"/>
                            <y:NodeLabel alignment="center" autoSizePolicy="content" fontFamily="Dialog" fontSize="11" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" height="16.955078125" modelName="internal" modelPosition="c" textColor="#000000" visible="true" width="45.2822265625" x="19.85888671875" y="19.0224609375">LEVEL 3</y:NodeLabel>
                            <y:StyleProperties>
                                <y:Property class="com.yworks.yfiles.bpmn.view.BPMNTypeEnum" name="com.yworks.bpmn.type" value="ACTIVITY_TYPE_STATELESS_TASK_PLAIN"/>
                                <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.line.color" value="#000000"/>
                                <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.fill" value="#ffffff"/>
                                <y:Property class="java.awt.Color" name="com.yworks.bpmn.icon.fill2" value="#d4d4d4"/>
                            </y:StyleProperties>
                        </y:GenericNode>
                    </data>
                </node>
                <edge id="e0" source="n0" target="n1">
                    <data key="d13">
                        <y:BezierEdge>
                            <y:Path sx="0.0" sy="0.0" tx="0.0" ty="0.0"/>
                            <y:LineStyle color="#C0C0C0" type="line" width="3.0"/>
                            <y:Arrows source="none" target="delta"/>
                        </y:BezierEdge>
                    </data>
                </edge>
                <edge id="e1" source="n1" target="n2">
                    <data key="d13">
                        <y:BezierEdge>
                            <y:Path sx="0.0" sy="0.0" tx="0.0" ty="0.0"/>
                            <y:LineStyle color="#C0C0C0" type="line" width="3.0"/>
                            <y:Arrows source="none" target="delta"/>
                        </y:BezierEdge>
                    </data>
                </edge>
            </graph>
            <data key="d0">
                <y:Resources/>
            </data>
        </graphml>

    </xsl:template>

</xsl:stylesheet>
