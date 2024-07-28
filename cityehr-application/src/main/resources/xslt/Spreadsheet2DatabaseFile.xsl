<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    Spreadsheet2DatabaseFile.xsl
    Input is a spreadsheet (MS Office .xslx or open office calc (ODF) format)
    Generates an XML document in the standard cityEHR database format.
    
    This format is of the form:
    
    <database>
        <table id="name1">
            <record>
                <field>r1c1</field>
                ...
            </record>
        </table>
        <table id="name2">
            <record>
                <field>r1c1</field>
                ...
            </record>
        </table>
        ...
    </database>
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs"
    version="2.0" xmlns:c="urn:schemas-microsoft-com:office:component:spreadsheet" xmlns:html="http://www.w3.org/TR/REC-html40"
    xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:office2003Spreadsheet="urn:schemas-microsoft-com:office:spreadsheet" xmlns:x2="http://schemas.microsoft.com/office/excel/2003/xml"
    xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" xmlns:x="urn:schemas-microsoft-com:office:excel"
    xmlns:msexcel="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
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
    xmlns:rpt="http://openoffice.org/2005/report" xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:grddl="http://www.w3.org/2003/g/data-view#" xmlns:tableooo="http://openoffice.org/2009/table"
    xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0">

    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Import module that generates patientSet XML from spreadsheet -->
    <xsl:include href="Spreadsheet2Database-Module.xsl"/>


    <!-- Match root and call template to generate the database format -->
    <!-- MS Excel (aggregated), ODF (OO Calc), MS 2003 XML -->
    <xsl:template match="/spreadsheetML | /office:document-content | /office2003Spreadsheet:Workbook">
        <!-- Redirect output to file -->
        <xsl:variable name="filename" as="xs:string" select="'../existSandBox/database.xml'"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">
            <xsl:variable name="source"
                select="if (name()='spreadsheetML') then 'xlsx' else if (name()='office:document-content') then 'ods' else 'msxml'"/>
            <database source="{$source}">
                <xsl:apply-templates/>
            </database>
        </xsl:result-document>
    </xsl:template>

    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
