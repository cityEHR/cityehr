<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    ODFSpreadsheet2PatientSet-Module.xsl
    Input is a spreadsheet (content.xml file from the ODF .ods zip) with data for a set of patients
    Generates an ISO-13606 representation of the patient data, suitable for import to cityEHR.
       
    This module is designed to be called from ODFSpreadsheet2PatientSet.xsl or ODFSpreadsheet2PatientSetFile.xsl.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->


<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:html="http://www.w3.org/TR/REC-html40" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
    xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0"
    xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0"
    xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" xmlns:math="http://www.w3.org/1998/Math/MathML"
    xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0"
    xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc"
    xmlns:dom="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rpt="http://openoffice.org/2005/report"
    xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:grddl="http://www.w3.org/2003/g/data-view#" xmlns:tableooo="http://openoffice.org/2009/table"
    xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <!-- Output formatted XML -->
    <xsl:output method="xml" indent="yes" name="xml" use-character-maps="entityOutput"/>


    <!-- ==============================================
        Global variables 
        ============================================== -->

    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="/"/>

    <!-- Set the configuration variables -->
    <xsl:variable name="configurationSheet" select="office:document-content/office:body/office:spreadsheet/table:table[@table:name='Configuration']"/>

    <xsl:variable name="applicationId"
        select="$configurationSheet/table:table-row[table:table-cell[1]/text:p='Application']/table:table-cell[2]/text:p"/>
    <xsl:variable name="specialtyId" select="$configurationSheet/table:table-row[table:table-cell[1]/text:p='Specialty']/table:table-cell[2]/text:p"/>
    <xsl:variable name="userId" select="$configurationSheet/table:table-row[table:table-cell[1]/text:p='User']/table:table-cell[2]/text:p"/>
    <xsl:variable name="patientSetDate" select="$configurationSheet/table:table-row[table:table-cell[1]/text:p='Date']/table:table-cell[2]/text:p"/>
    <xsl:variable name="patientSetTime" select="$configurationSheet/table:table-row[table:table-cell[1]/text:p='Time']/table:table-cell[2]/text:p"/>
    

    <!-- Can only process spreadsheet if applicationId and specialtyId are defined -->
    <xsl:variable name="processError" as="xs:string" select="if ($applicationId !='' and $specialtyId !='') then 'false' else 'true'"/>


    <!-- ==============================================
        Set header variables for the patient data sheet
        ============================================== -->

    <xsl:variable name="patientDataSheet" select="office:document-content/office:body/office:spreadsheet/table:table[@table:name='PatientData']"/>
    <xsl:variable name="compositionIdList"
        select="$patientDataSheet/table:table-row[table:table-cell[1]/text:p='CompositionId']/table:table-cell[position() gt 1]/normalize-space(text:p)[.!='']"/>
    <xsl:variable name="entryIdList"
        select="$patientDataSheet/table:table-row[table:table-cell[1]/text:p='EntryId']/table:table-cell[position() gt 1]/normalize-space(text:p)[.!='']"/>
    <xsl:variable name="elementIdList"
        select="$patientDataSheet/table:table-row[table:table-cell[1]/text:p='ElementId']/table:table-cell[position() gt 1]/normalize-space(text:p)[.!='']"/>

    <!-- Key for Contents    
        contentsList returns data element of ISO-13606 component for matched id.
        Used to check that contents list refer to defined ISO-13606 components
    -->
    <xsl:key name="contentsList"
        match="/office:document-content/office:body/office:spreadsheet/table:table[@table:name='Contents']/table:table-row/table:table-cell[text:p!='']"
        use="normalize-space(text:p)"/>


    <!-- === 
         Generate XML patient data       
         === -->
    <xsl:template name="generatePatientSetData">
        <patientSet xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:iso-13606="http://www.iso.org/iso-13606"
            date="" time="" userId="" applicationIRI="" specialtyIRI=""> </patientSet>
    </xsl:template>


</xsl:stylesheet>
