<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    Spreadsheet2Database-Module.xsl   
    Input is a spreadsheet (MS Office .xslx or open office calc (ODF) format)
    Generates an XML document in the standard cityEHR database format.
    
    This format is of the database is:
    
    <database>
        <table id="name1">
            <record>
                <field>r1c1</field>
                ...
            </record>
            ...
        </table>
        <table id="name2">
            <record>
                <field>r1c1</field>
                ...
            </record>
            ...
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
    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    xmlns:rp="http://schemas.openxmlformats.org/package/2006/relationships" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
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
    xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">


    <!-- === MS Excel xslx templates ===========================================
         Several files have been aggregated under the spreadsheetML document element.
         The format for the files is:
         <file name="filename">
            ...content (xml) of the file goes here
         </file>
         ======================================================================= -->

    <xsl:template match="spreadsheetML/file/msexcel:worksheet">
        <xsl:variable name="fileName" select="../@name"/>
        <xsl:variable name="sheetFileName" select="tokenize($fileName, '/')[last()]"/>

        <!-- Relationship id is found in the workbook.xml.rels file content -->
        <xsl:variable name="sheetRelationshipId"
            select="//spreadsheetML/file/rp:Relationships/rp:Relationship[ends-with(@Target, $sheetFileName)]/@Id"/>

        <!-- Sheet name is found in the workbook.xml file content -->
        <xsl:variable name="sheetName" select="//spreadsheetML/file/msexcel:workbook/msexcel:sheets/msexcel:sheet[@r:id = $sheetRelationshipId]/@name"/>

        <table id="{$sheetName}">
            <xsl:apply-templates/>
        </table>
    </xsl:template>

    <!-- Only include rows that have some content (other than '-' TBD)
         This content may be inline or shared -->
    <xsl:template match="msexcel:row[normalize-space() != '']">
        <record>
            <xsl:apply-templates/>
        </record>
    </xsl:template>
    <xsl:template match="msexcel:row[normalize-space() = '']"/>


    <!-- The cells in the xlsx format are numbered A1, B1, C1, D1 etc for row 1 
         If cells are skipped then the letter(s) are jumped - so A1, D1 skips two cells -->
    <xsl:template match="msexcel:c[(.,following-sibling::*)/normalize-space() != '']">
        <xsl:variable name="rowNumber" select="../@r"/>
        <xsl:variable name="cellReference" select="substring-before(@r, $rowNumber)"/>
        <xsl:variable name="previousCell" select="preceding-sibling::msexcel:c[1]"/>
        <xsl:variable name="previousCellReference"
            select="
                if (exists($previousCell)) then
                    substring-before($previousCell/@r, $rowNumber)
                else
                    ''"/>
        <!-- Output empty fields, if cells were skipped -->
        <xsl:variable name="cellPosition" select="cityEHRFunction:referenceToPosition($cellReference, 0, 1)"/>
        <xsl:variable name="previousCellPosition" select="cityEHRFunction:referenceToPosition($previousCellReference, 0, 1)"/>
        <xsl:variable name="skippedCells" as="xs:integer" select="xs:integer($cellPosition - $previousCellPosition - 1)"/>

        <xsl:if test="$skippedCells gt 0">
            <xsl:for-each select="1 to $skippedCells">
                <field/>
            </xsl:for-each>
        </xsl:if>

        <field>
            <xsl:value-of select="cityEHRFunction:getCellValue(//spreadsheetML,.)"/>

            <xsl:if test="false()">
                <!-- Using shared strings -->
                <xsl:variable name="keyValue" select=".[@t = 's']/msexcel:v"/>
                <xsl:if test="exists($keyValue)">
                    <xsl:variable name="key" as="xs:integer"
                        select="
                            if (exists($keyValue) and $keyValue castable as xs:integer) then
                                xs:integer($keyValue) + 1
                            else
                                0"/>
                    <xsl:variable name="sharedValue" select="//spreadsheetML/file/msexcel:sst/msexcel:si[position() = $key]/msexcel:t"/>
                    <xsl:if test="exists($sharedValue)">
                        <xsl:value-of select="$sharedValue"/>
                    </xsl:if>
                </xsl:if>
                <!-- Using inline strings or numbers -->
                <xsl:variable name="inlineValue" select="msexcel:is/msexcel:t | .[not(@t) or @t = ('inlineStr', 'n')]/msexcel:v"/>
                <xsl:if test="exists($inlineValue)">
                    <xsl:value-of select="$inlineValue"/>
                </xsl:if>
            </xsl:if>
        </field>
    </xsl:template>


    <!-- 
         cityEHRFunction:referenceToPosition
         Convert field reference to a position
         Reference is of the form ABCD, which is a base 27 number (1 to 26).
         Returns the decimal value of that number as the field position
         This is a tail recursive function.
        -->
    <xsl:function name="cityEHRFunction:referenceToPosition" as="xs:integer">
        <xsl:param name="referenceString"/>
        <xsl:param name="position" as="xs:integer"/>
        <xsl:param name="base" as="xs:integer"/>

        <!-- Done processing referenceString - return the position-->
        <xsl:if test="$referenceString = ''">
            <xsl:value-of select="$position"/>
        </xsl:if>

        <!-- Further processing required -->
        <xsl:if test="$referenceString != ''">
            <xsl:variable name="referenceCharacters" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
            <xsl:variable name="referenceStringSequence"
                select="
                    for $c in string-to-codepoints($referenceString)
                    return
                        codepoints-to-string($c)"/>
            <xsl:variable name="referenceCharacter" select="$referenceStringSequence[last()]"/>
            <xsl:variable name="referenceStringSequenceLength" select="count($referenceStringSequence)"/>

            <xsl:variable name="referenceCharacterLocation" select="substring-before($referenceCharacters, $referenceCharacter)"/>
            <xsl:variable name="referenceCharacterPosition" select="string-length($referenceCharacterLocation) + 1"/>

            <xsl:variable name="nextReferenceString" select="string-join($referenceStringSequence[position() lt $referenceStringSequenceLength], '')"/>

            <xsl:variable name="nextBase" select="$base * 26"/>


            <!-- Position increments by the last reference charcter, to the current base -->
            <xsl:variable name="nextPosition" select="$position + ($base * $referenceCharacterPosition)"/>

            <xsl:value-of select="cityEHRFunction:referenceToPosition($nextReferenceString, $nextPosition, $nextBase)"/>
        </xsl:if>

    </xsl:function>

    <!-- 
         cityEHRFunction:getCellValue
         Return the string value of a cell in the spreadsheet
        -->
    <xsl:function name="cityEHRFunction:getCellValue" as="xs:string">
        <xsl:param name="spreadsheetML"/>
        <xsl:param name="cell"/>

        <!-- Using shared strings -->
        <xsl:variable name="keyValue" select="$cell[@t = 's']/msexcel:v"/>
        <xsl:if test="exists($keyValue)">
            <xsl:variable name="key" as="xs:integer"
                select="
                    if (exists($keyValue) and $keyValue castable as xs:integer) then
                        xs:integer($keyValue) + 1
                    else
                        0"/>
            <xsl:variable name="sharedValue" select="$spreadsheetML/file/msexcel:sst/msexcel:si[position() = $key]/msexcel:t"/>
            <xsl:if test="exists($sharedValue)">
                <xsl:value-of select="$sharedValue"/>
            </xsl:if>
            <xsl:if test="not(exists($sharedValue))">
                <xsl:value-of select="''"/>
            </xsl:if>
        </xsl:if>
        
        <!-- Using inline strings or numbers -->
        <xsl:variable name="inlineValue" select="$cell/msexcel:is/msexcel:t | $cell[not(@t) or @t = ('inlineStr', 'n')]/msexcel:v"/>
        <xsl:if test="exists($inlineValue)">
            <xsl:value-of select="$inlineValue"/>
        </xsl:if>
        
        <!-- No value found -->
        <xsl:if test="not(exists($keyValue)) and not(exists($inlineValue))">
            <xsl:value-of select="''"/>
        </xsl:if>

    </xsl:function>



    <!-- === MS 2003 XML templates ===========================================
         ===================================================================== -->

    <xsl:template match="ss:Worksheet">
        <table id="{@ss:Name}">
            <xsl:apply-templates/>
        </table>
    </xsl:template>

    <!-- Only include rows that have some content other than '-' -->
    <xsl:template match="office2003Spreadsheet:Row[normalize-space(translate(., '-', '')) != '']">
        <xsl:variable name="cells" select="office2003Spreadsheet:Cell"/>
        <record>
            <xsl:call-template name="ms2003GenerateFields">
                <xsl:with-param name="cells" select="$cells"/>
                <xsl:with-param name="fieldPosition" select="1"/>
            </xsl:call-template>
        </record>
    </xsl:template>

    <!-- Template to generate fields for a record from ms 2003 XML spreadsheet cells -->
    <xsl:template name="ms2003GenerateFields">
        <xsl:param name="cells"/>
        <xsl:param name="fieldPosition" as="xs:integer"/>

        <xsl:variable name="cell" select="$cells[1]"/>
        <xsl:if test="exists($cell)">
            <xsl:variable name="index" select="$cell/@ss:Index"/>

            <!-- Cell skipped some blanks -->
            <xsl:if test="exists($index)">
                <xsl:variable name="blankCount" as="xs:integer" select="xs:integer($index) - $fieldPosition"/>
                <xsl:call-template name="generateFields">
                    <xsl:with-param name="fieldCount" select="$blankCount"/>
                    <xsl:with-param name="content" select="''"/>
                </xsl:call-template>
            </xsl:if>

            <!-- output the field -->
            <field>
                <xsl:value-of select="$cell/*"/>
            </field>

            <!-- Output the remaining fields -->
            <xsl:variable name="nextCells" select="$cells[position() gt 1]"/>
            <xsl:variable name="nextFieldPosition"
                select="
                    if (exists($index)) then
                        xs:integer($index) + 1
                    else
                        $fieldPosition + 1"/>
            <xsl:call-template name="ms2003GenerateFields">
                <xsl:with-param name="cells" select="$nextCells"/>
                <xsl:with-param name="fieldPosition" select="$nextFieldPosition"/>
            </xsl:call-template>

        </xsl:if>

    </xsl:template>



    <!-- === ODF (OO Calc) ods templates ====================================== 
         ====================================================================== -->

    <xsl:template match="office:body/office:spreadsheet/table:table">
        <table id="{@table:name}">
            <xsl:apply-templates/>
        </table>
    </xsl:template>

    <!-- Only include rows that have some content in the first cell -->
    <xsl:template match="table:table-row[table:table-cell[1]/text:p/normalize-space() != '']">
        <xsl:variable name="cells" select="table:table-cell"/>
        <record>
            <xsl:call-template name="odfGenerateFields">
                <xsl:with-param name="cells" select="$cells"/>
                <xsl:with-param name="fieldPosition" select="1"/>
            </xsl:call-template>
        </record>
    </xsl:template>

    <!-- Template to generate fields for a record from ods spreadsheet cells.
         Fields are output umtil there is no content left (i.e. trailing empty fields are not genertated) -->
    <xsl:template name="odfGenerateFields">
        <xsl:param name="cells"/>
        <xsl:param name="fieldPosition" as="xs:integer"/>

        <xsl:variable name="cell" select="$cells[1]"/>
        <xsl:if test="exists($cell)">
            <xsl:variable name="repeatedCells" select="$cell/@table:number-columns-repeated"/>

            <!-- Output multiple cells with same value -->
            <xsl:if test="exists($repeatedCells)">
                <xsl:call-template name="generateFields">
                    <xsl:with-param name="fieldCount" select="$repeatedCells"/>
                    <xsl:with-param name="content" select="data($cell/*)"/>
                </xsl:call-template>
            </xsl:if>

            <!-- Output single cell value -->
            <xsl:if test="not(exists($repeatedCells))">
                <field>
                    <xsl:value-of select="$cell/*"/>
                </field>
            </xsl:if>

            <!-- Output the remaining fields, but only if there is some content left somewhere -->
            <xsl:variable name="nextCells" select="$cells[position() gt 1]"/>
            <xsl:variable name="nextFieldPosition"
                select="
                    if (exists($repeatedCells)) then
                        $fieldPosition + xs:integer($repeatedCells)
                    else
                        $fieldPosition + 1"/>

            <xsl:if test="$nextCells/text:p/normalize-space() != ''">
                <xsl:call-template name="odfGenerateFields">
                    <xsl:with-param name="cells" select="$nextCells"/>
                    <xsl:with-param name="fieldPosition" select="$nextFieldPosition"/>
                </xsl:call-template>
            </xsl:if>

        </xsl:if>

    </xsl:template>


    <!-- === Utility templates ================================================ 
    ====================================================================== -->

    <!-- Template to generate fields 
         Outputs fieldCount fields, containing the specified content -->
    <xsl:template name="generateFields">
        <xsl:param name="fieldCount" as="xs:integer"/>
        <xsl:param name="content"/>

        <xsl:if test="$fieldCount gt 0">
            <field>
                <xsl:value-of select="$content"/>
            </field>
            <xsl:call-template name="generateFields">
                <xsl:with-param name="fieldCount" select="$fieldCount - 1"/>
                <xsl:with-param name="content" select="$content"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
