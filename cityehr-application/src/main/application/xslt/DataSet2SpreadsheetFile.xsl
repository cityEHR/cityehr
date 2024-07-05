<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    DataSet2SpreadsheetFile.xsl
    Input is a patient cohort with patientInfo and patientData elements
    PLUS view-parameters.xml is passed in on parameters input
    
    Produces XML spreadsheet file in MS SpreadsheetML (2003) format or ODF Format
       
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
    xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
    xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"
    xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0"
    xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
    xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0"
    xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0"
    xmlns:math="http://www.w3.org/1998/Math/MathML"
    xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0"
    xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0"
    xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer"
    xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:rpt="http://openoffice.org/2005/report"
    xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2"
    xmlns:grddl="http://www.w3.org/2003/g/data-view#"
    xmlns:tableooo="http://openoffice.org/2009/table"
    xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0"
    office:version="1.2"
    grddl:transformation="http://docs.oasis-open.org/office/1.2/xslt/odf2rdf.xsl">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Get the template content for the generated spreadsheet -->
    <xsl:variable name="template"
        select="if ($outputFormat='odf-spreadsheet') then document('../examples/export/exportDataSet-content.xml')/office:document-content else if ($outputFormat='ms-spreadsheet') then document('../examples/export/spreadsheetMLComponents.xml') else ()"/>

    <!-- Set the parameters from the view-parameters -->
    <xsl:variable name="parameters" select="document('../view-parameters.xml')/parameters/exportPipeline"/>
    
    <!-- Set the dictionary from the existSandBox - note that this one is set for cityEHR application, FeatureDemo specialty  -->
    <xsl:variable name="dictionary" select="document('../existSandBox/ISO-13606-EHR_Extract-cityEHR/systemConfiguration/ISO-13606-Folder-FeatureDemo/dictionary/ISO-13606-Folder-FeatureDemo.xml')"/>
    
    <!-- Templates to generate the spreadsheet -->
    <xsl:include href="DataSet2Spreadsheet-Module.xsl"/>

    <!-- Match root node - set up output file and call template to generate the spreadsheet -->
    <xsl:template match="/">
        <!-- Redirect output to file, in the examples directory -->
        <xsl:variable name="filename" as="xs:string"
            select="concat('../examples/export/',$outputFormat,'.xml')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">

            <!-- ODF Spreadsheet -->
            <xsl:if test="$outputFormat='odf-spreadsheet'">
                <xsl:call-template name="generate-odf-spreadsheet"/>
            </xsl:if>

            <!-- MS Spreadsheet -->
            <xsl:if test="$outputFormat='ms-spreadsheet'">
                <xsl:call-template name="generate-ms-spreadsheet"/>
            </xsl:if>

        </xsl:result-document>

    </xsl:template>

    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
