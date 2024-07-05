<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    MergeOWL.xsl
    Input is a master OWL ontology and a second ontology to merge with it, on the merge input
    PLUS view-parameters.xml is passed in on parameters input
    
    Produces the merged OWL ontology using a copy of the master and 
    any assertions from the merged ontology that are not present in the master.
       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet version="2.0" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xxf="http://orbeon.org/oxf/xml/xforms" xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:cda="urn:hl7-org:v3" xmlns:iso-13606="http://www.iso.org/iso-13606" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" xmlns:saxon="http://saxon.sf.net/" xmlns:owl="http://www.w3.org/2002/07/owl#">
    <xsl:output method="xml" indent="yes"/>
    
    <!-- Ontology to merge is passed in on merge input -->
    <!--    <xsl:variable name="merge" select="document('input:merge')"/> -->
    <xsl:variable name="merge" select="document('../examples/owl/classOWLforMerge.owl')"/>


    <!-- Set up the XSLT keys for the OWL ontology -->
    <xsl:include href="OWLStandardKeys-Module.xsl"/>

    <!-- Main templates for copy and merge of OWL -->
    <xsl:include href="MergeOWL-Module.xsl"/>
      

    <!-- === Match root node and do the merge ========== 
        ================================================ -->
    <xsl:template match="/">

        <!-- Redirect output to file, using a fixed sample location (for testing purposes only) -->
        <xsl:variable name="filename" as="xs:string" select="'../examples/owl/mergedOntology.owl'"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">         
            <xsl:call-template name="generateMergedCityEHROWL"/>
        </xsl:result-document>

    </xsl:template>
    
    
    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>

</xsl:stylesheet>
