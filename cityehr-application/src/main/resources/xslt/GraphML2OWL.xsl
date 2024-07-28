<!-- 
  *********************************************************************************************************
  cityEHR
  GraphML2OWL.xsl
  
  Input is a GraphML file from Yed with a class hierarchy for the specialty
  
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
<xsl:stylesheet version="2.0" exclude-result-prefixes="Math g graphml xs y svg protege" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Math="java:java.lang.Math" xmlns:g="http://graphml.graphdrawing.org/xmlns/graphml" xmlns:y="http://www.yworks.com/xml/graphml" xmlns:svg="http://www.w3.org/2000/svg" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:graphml="http://graphml.graphdrawing.org/xmlns" xmlns:funct="text:p:,funct" xmlns="http://www.w3.org/2002/07/owl#" xmlns:xml="http://www.w3.org/XML/1998/namespace" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:protege="http://protege.stanford.edu/plugins/owl/protege#" xpath-default-namespace="http://graphml.graphdrawing.org/xmlns/graphml" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <xsl:output method="xml" indent="yes"/>

  <!-- Get the cityEHR architecture OWL/XML for inclusion in the generated ontology -->
  <xsl:variable name="cityEHRarchitecture" select="document('../resources/templates/cityEHRarchitecture.xml')"/>

  <!-- Import module that generates OWL ontology from graphML -->
  <xsl:include href="GraphML2OWL-Module.xsl"/>

  <!-- Can only process graph if applicationId, specialtyId and classId are defined -->
  <xsl:variable name="processError" as="xs:string" select="if ($applicationId !='' and $specialtyId !='' and $classId !='') then 'false' else 'true'"/>
  
  <!-- Match root node and call template to generate the ontology -->
  <xsl:template match="/">
    <xsl:if test="$processError='false'">
      <xsl:call-template name="generateOWL"/>
    </xsl:if>
    <xsl:if test="$processError='true'">
      <xsl:call-template name="generateOWLError">
        <xsl:with-param name="context">cityEHR Information Model cannot be processed.</xsl:with-param>
        <xsl:with-param name="message">applicationId, specialtyId and classId must be defined in the model.</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
