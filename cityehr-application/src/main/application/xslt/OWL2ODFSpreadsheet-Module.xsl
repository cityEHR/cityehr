<!-- ====================================================================
    OWL2ODFSpreadsheet-Module.xsl
    Module to convert cityEHR OWL to ODF spreadsheet content file that can be zipped to create .ods
        
    informationModelType vraiable is et to specialty or class, depending on the type of model
 
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
    xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0">
    
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
    
    <!-- Set the type of model - specialty or class -->
    <xsl:variable name="informationModelType" as="xs:string" select="if ($classIRI='') then 'specialty' else 'class'"/>

    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="/owl:Ontology"/>

    <!-- Set up the XSLT keys for the OWL ontology -->
    <xsl:include href="OWLKeys-Module.xsl"/>


    <!-- Template to generate spreadsheet content
    -->
    <xsl:template name="generateSpreadsheetContent">
        <office:document-content>
            <!-- Copy attributes on document element -->
            <xsl:copy-of select="$template/office:document-content/@*" copy-namespaces="yes"/>
            
            <!-- Copy preamble elements up to office:body -->
            <xsl:copy-of select="$template/office:document-content/*[name() != 'office:body']" copy-namespaces="yes"/>
            
            <!-- office:body -->
            <office:body>
                <office:spreadsheet>
                    <xsl:copy-of select="$template/office:document-content/office:body/office:spreadsheet/table:content-validations"/>
                    <xsl:copy-of select="$template/office:document-content/office:body/office:spreadsheet/table:table"/>
                </office:spreadsheet>
            </office:body>
        </office:document-content>
    </xsl:template>



 

</xsl:stylesheet>
