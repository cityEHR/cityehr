<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    Spreadsheet2PatientList-Module.xsl
    Input is a spreadsheet (MS Office .xslx format or open office calc) with data for a cohort of patients
    Generates an XML document for the patient set.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0"
    xmlns:msexcel="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
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
    xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:rpt="http://openoffice.org/2005/report"
    xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:grddl="http://www.w3.org/2003/g/data-view#"
    xmlns:tableooo="http://openoffice.org/2009/table"
    xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0">
    
    <!-- Set the column to read the patient id in each row.
         This is the first column where there is some content. -->
    

    <!-- Generate the patientSet -->
    <xsl:template name="generatePatientSet">
        <patientSet>
            <xsl:apply-templates/>
        </patientSet>
    </xsl:template>

    <!-- patient Ids are in the first cell of each row.-->
    <!-- MS Excel - Need to look up the value in the sharedStrings table.
         Shared string is used if cell is c with attribute t="s" -->
    <xsl:template match="spreadsheetML/msexcel:worksheet/msexcel:sheetData/msexcel:row">
        <!-- Using shared strings -->
        <xsl:variable name="keyValue" select="msexcel:c[1][@t='s']/msexcel:v"/>
        <xsl:if test="exists($keyValue)">
            <xsl:variable name="key" as="xs:integer"
                select="if (exists($keyValue) and $keyValue castable as xs:integer) then xs:integer(msexcel:c[1]/msexcel:v) + 1 else 0"/>
            <xsl:variable name="patientId"
                select="normalize-space(/spreadsheetML/msexcel:sst/msexcel:si[position()=$key]/msexcel:t)"/>
            <xsl:if test="exists($patientId)">
                <patient id="{$patientId}"/>
            </xsl:if>
        </xsl:if>
        <!-- Using inline strings for -->
        <xsl:variable name="inlineValue" select="msexcel:c[1]/msexcel:is/msexcel:t | msexcel:c[1][not(@t) or @t='inlineStr']/msexcel:v"/>
        <xsl:if test="exists($inlineValue)">
            <xsl:variable name="patientId" select="normalize-space($inlineValue)"/>
            <xsl:if test="exists($patientId)">
                <patient id="{$patientId}"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <!-- ODF (OO Calc) -->
    <xsl:template match="office:body/office:spreadsheet/table:table[1]">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="table:table-row">
        <xsl:variable name="patientId" select="normalize-space(table:table-cell[1]/text:p)"/>
        <patient id="{$patientId}"/>
    </xsl:template>

</xsl:stylesheet>
