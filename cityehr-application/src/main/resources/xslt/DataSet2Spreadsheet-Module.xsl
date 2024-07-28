<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    DataSet2Spreadsheet-Module.xsl
    Input is a patient cohort (set) in either HL7 CDA or ISO-13606 format
    
    HL7 CDA format is:
        <patientSet>
            <patientInfo>
               HL7 CDA entry elements
            </patientInfo>   
            <patientData>
                HL7 CDA entry elements
            </patientData>
        </patientSet>
        
    ISO-13606 format is:
    
    Generates XML spreadhseet in ODF spreadsheet format or an aggregated instance for MS Office Open spreadsheet
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:iso-13606="http://www.iso.org/iso-13606" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
    xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0"
    xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0"
    xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" xmlns:math="http://www.w3.org/1998/Math/MathML"
    xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0"
    xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc"
    xmlns:dom="http://www.w3.org/2001/xml-events" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:rpt="http://openoffice.org/2005/report"
    xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" xmlns:grddl="http://www.w3.org/2003/g/data-view#"
    xmlns:tableooo="http://openoffice.org/2009/table" xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0"
    office:version="1.2" grddl:transformation="http://docs.oasis-open.org/office/1.2/xslt/odf2rdf.xsl"
    xmlns:content-types="http://schemas.openxmlformats.org/package/2006/content-types"
    xmlns:r="http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:spreadsheetml="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
    xmlns:extended-properties="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
    xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">

    <!-- ========================
         Global variables
         ======================== -->

    <!-- Set the root node and output format -->
    <xsl:variable name="rootNode" select="//patientSet"/>
    <xsl:variable name="outputFormat" select="$parameters/exportDataFormat"/>
    <xsl:variable name="spreadsheetFormat" select="$parameters/spreadsheetFormat"/>
    <xsl:variable name="idSeparator" select="if (exists($parameters/idSeparator)) then $parameters/idSeparator else ''"/>

    <!-- Set entry and element lists for patientInfo (demographics)
         The output demographics has the patientId plus each entry in the list -->
    <xsl:variable name="entryList" select="tokenize($rootNode/@entryList,' ')"/>
    <xsl:variable name="entryListCount" select="count($entryList) + 1"/>
    <xsl:variable name="elementList" select="tokenize($rootNode/@elementList,' ')"/>

    <!-- Set longitudinalDataOutput for patientData.
        If $longitudinalDataOutput is currentData then patientData only holds the current values (if any), otherwise it holds all values -->
    <xsl:variable name="longitudinalDataOutput" select="$rootNode/@longitudinalDataOutput"/>

    <!-- Set entry lists for reference data -->
    <xsl:variable name="referenceDataList" select="tokenize($rootNode/@referenceDataList,' ')"/>

    <!-- Number of reference columns in patientData sheets.
         Must have the patientId, plus effectiveTime if longitudinalDataOutput is allData, so minimum here is 1 -->
    <xsl:variable name="fixedReferenceColumnCount" as="xs:integer" select="if ($longitudinalDataOutput = 'allData') then 2 else 1"/>
    <xsl:variable name="referenceColumnCount" as="xs:integer" select="$fixedReferenceColumnCount + count($referenceDataList)"/>

    <!-- Set entry lists for patientData.
         Note that any iteration through dataSetEntryTemplateList will come out in document order in the dictionary -->
    <xsl:variable name="dataSetEntryList" select="tokenize($rootNode/@dataSetEntryList,' ')"/>
    <xsl:variable name="dataSetEntryTemplateList" select="cityEHRFunction:getEntryTemplates($dataSetEntryList)"/>

    <!-- Get sequences of entry and element counts -->
    <xsl:variable name="entryCountSequence" select="cityEHRFunction:getEntryCountSequence($dataSetEntryList)"/>
    <xsl:variable name="elementCountSequence" select="cityEHRFunction:getElementCountSequence($dataSetEntryList)"/>

    <xsl:variable name="patientList" select="distinct-values($rootNode/patientInfo/@patientId)"/>

    <!-- Number of sheets -->
    <xsl:variable name="sheetCount" select="if ($spreadsheetFormat='singleSheet') then 2 else count($dataSetEntryList) + 1"/>


    <!-- ========================
         Keys
         ======================== -->
    <!-- Observations 
         Key is patientId/entryIRI/effectiveTime
         Note that if longitudinalDataOutput is firstData or currentData then all effectiveTime values will be those keywords, not the effectiveTime of the observation -->
    <xsl:key name="observationSet"
        match="//patientData/cda:entry/cda:observation | 
        //patientData/cda:entry/cda:organizer[@classCode='MultipleEntry']/cda:component[2]/cda:organizer/cda:component/cda:observation | 
        //patientData/cda:entry/cda:organizer[@classCode='MultipleEntry']/cda:component[2]/cda:organizer/cda:component/cda:organizer[@classCode='EnumeratedClassEntry']/cda:component[1]/cda:observation |
        //patientData/cda:entry/cda:organizer[@classCode='EnumeratedClassEntry']/cda:component[1]/cda:observation"
        use="concat(ancestor::patientData/@patientId,ancestor::cda:entry/descendant::cda:id[1]/@extension,ancestor::cda:entry/@effectiveTime)"/>


    <!-- ========================
         Generate MS Spreadsheet
         ======================== -->

    <!-- Aggregated contents. 
         This is split into separate documents, stored within the .xlsx zip
         
         We are interested in:
            docProps/app.xml
            xl/_rels/workbook.xml.rels
            xl/worksheets/sheet1.xml
            xl/workbook.xml
            [Content_Types].xml
            
         The templates for these have been aggregated in the spreadsheetML root element of the template   
        -->
    <xsl:template name="generate-ms-spreadsheet">
        <spreadsheetML>
            <!-- Document properties -->
            <xsl:call-template name="generate-ms-docProps"/>

            <!-- Workbook relationships -->
            <xsl:call-template name="generate-ms-workbookRels"/>

            <!-- Worksheets -->
            <xsl:call-template name="generate-ms-demographics"/>
            <xsl:call-template name="generate-ms-dataSets"/>

            <!-- Workbook -->
            <xsl:call-template name="generate-ms-workbook"/>

            <!-- Content types -->
            <xsl:call-template name="generate-ms-contentType"/>

        </spreadsheetML>
    </xsl:template>

    <!-- Document properties.
         Has the number of sheets and the name for each one
         -->
    <xsl:template name="generate-ms-docProps">
        <xsl:variable name="docPropsTemplate" select="$template/spreadsheetML/extended-properties:Properties"/>

        <file name="docProps/app.xml">
            <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
                xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">

                <!-- Front matter -->
                <xsl:copy-of select="$docPropsTemplate/extended-properties:DocSecurity"/>
                <xsl:copy-of select="$docPropsTemplate/extended-properties:ScaleCrop"/>

                <HeadingPairs>
                    <vt:vector size="2" baseType="variant">
                        <vt:variant>
                            <vt:lpstr>Worksheets</vt:lpstr>
                        </vt:variant>
                        <vt:variant>
                            <vt:i4>
                                <xsl:value-of select="$sheetCount"/>
                            </vt:i4>
                        </vt:variant>
                    </vt:vector>
                </HeadingPairs>

                <TitlesOfParts>
                    <vt:vector size="{$sheetCount}" baseType="lpstr">
                        <!-- Demographics -->
                        <vt:lpstr>
                            <xsl:value-of select="$parameters/demographicsDisplayName"/>
                        </vt:lpstr>
                        <!-- Single sheet -->
                        <xsl:if test="$spreadsheetFormat='singleSheet'">
                            <vt:lpstr>
                                <xsl:value-of select="$parameters/dataSetDisplayName"/>
                            </vt:lpstr>
                        </xsl:if>
                        <!-- Multiple sheet -->
                        <xsl:if test="$spreadsheetFormat!='singleSheet'">
                            <xsl:for-each select="$dataSetEntryList">
                                <xsl:variable name="dataSetEntryIRI" select="."/>
                                <vt:lpstr>
                                    <xsl:value-of select="substring-after($dataSetEntryIRI,'#ISO-13606:Entry:')"/>
                                </vt:lpstr>
                            </xsl:for-each>
                        </xsl:if>
                    </vt:vector>
                </TitlesOfParts>

                <!-- Back matter -->
                <xsl:copy-of select="$docPropsTemplate/extended-properties:LinksUpToDate"/>
                <xsl:copy-of select="$docPropsTemplate/extended-properties:SharedDoc"/>
                <xsl:copy-of select="$docPropsTemplate/extended-properties:HyperlinksChanged"/>
                <xsl:copy-of select="$docPropsTemplate/extended-properties:AppVersion"/>
            </Properties>
        </file>
    </xsl:template>

    <!-- Workbook relationships.
         
    -->
    <xsl:template name="generate-ms-workbookRels">
        <xsl:variable name="workbookRelsTemplate" select="$template/spreadsheetML/r:Relationships"/>
        <file name="xl/_rels/workbook.xml.rels">
            <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">

                <!-- Copy all elements from template -->
                <!--
                <xsl:copy-of select="$workbookRelsTemplate/r:Relationship"/>
                -->
                <!-- sheet1 is always present (demographics) -->
                <xsl:copy-of select="$workbookRelsTemplate/r:Relationship[@Target='worksheets/sheet1.xml']"/>

                <!-- Template to use for Type attribute -->
                <xsl:variable name="typeTemplate" select="$workbookRelsTemplate/r:Relationship[@Target='worksheets/sheet1.xml']/@Type"/>

                <!-- Single sheet -->
                <xsl:if test="$spreadsheetFormat = 'singleSheet'">
                    <Relationship Id="rId2" Type="{$typeTemplate}" Target="worksheets/sheet2.xml"/>
                </xsl:if>

                <!-- If multipleSheets add an extra Relationship element for each additional sheet -->
                <xsl:if test="$spreadsheetFormat != 'singleSheet'">
                    <xsl:for-each select="$dataSetEntryList">
                        <xsl:variable name="dataSetNumber" select="position()"/>
                        <xsl:variable name="sheetNum" select="$dataSetNumber + 1"/>
                        <xsl:variable name="rIdNum" select="$dataSetNumber + 1"/>

                        <Relationship Id="rId{$rIdNum}" Type="{$typeTemplate}" Target="worksheets/sheet{$sheetNum}.xml"/>
                    </xsl:for-each>
                </xsl:if>

                <!-- Now write Relationship elements for the other items -->
                <Relationship Id="rId{$sheetCount + 3}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings"
                    Target="sharedStrings.xml"/>
                <Relationship Id="rId{$sheetCount + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"
                    Target="styles.xml"/>
                <Relationship Id="rId{$sheetCount + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme"
                    Target="theme/theme1.xml"/>
            </Relationships>
        </file>
    </xsl:template>


    <!-- Demographics
         Sheet with one row for each patientInfo element. 
         Demographics is always sheet1 -->
    <xsl:template name="generate-ms-demographics">
        <xsl:variable name="worksheetTemplate" select="$template/spreadsheetML/spreadsheetml:worksheet"/>
        <file name="xl/worksheets/sheet1.xml">
            <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
                xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
                <!-- Front matter -->
                <xsl:copy-of select="$worksheetTemplate/spreadsheetml:dimension"/>
                <xsl:copy-of select="$worksheetTemplate/spreadsheetml:sheetViews"/>
                <xsl:copy-of select="$worksheetTemplate/spreadsheetml:sheetFormatPr"/>

                <!-- Columns in spreadsheet -->
                <xsl:variable name="colCount" select="$entryListCount"/>
                <xsl:variable name="templateCols" select="$worksheetTemplate/spreadsheetml:cols"/>
                <cols>
                    <col min="1" max="{$colCount}" width="{$templateCols/spreadsheetml:col[1]/@width}" customWidth="1"/>
                </cols>

                <!-- Sheet data -->
                <sheetData>
                    <!-- Column Headers. 
                        These are the first row of the spreadsheet
                    -->
                    <row r="1" spans="1:{$colCount}">
                        <!-- First column is patientId -->
                        <c r="A1" s="1" t="inlineStr">
                            <is>
                                <t>
                                    <xsl:value-of select="$parameters/patientIdDisplayName"/>
                                </t>
                            </is>
                        </c>

                        <!-- Demographics entries 
                             Start at column 2 - first column is patientId-->
                        <xsl:for-each select="$entryList">
                            <xsl:variable name="entryIRI" select="."/>
                            <xsl:variable name="entryPosition" select="position()"/>
                            <xsl:variable name="elementIRI" select="$elementList[position()=$entryPosition]"/>

                            <xsl:variable name="displayName"
                                select="concat(substring-after($entryIRI,'#ISO-13606:Entry:'),'/',substring-after($elementIRI,'#ISO-13606:Element:'))"/>

                            <xsl:variable name="colNum" select="$entryPosition + 1"/>
                            <xsl:variable name="colRef" select="cityEHRFunction:getColumnReference($colNum)"/>
                            <xsl:variable name="cellRef" select="concat($colRef,'1')"/>

                            <c r="{$cellRef}" s="1" t="inlineStr">
                                <is>
                                    <t>
                                        <xsl:value-of select="$displayName"/>
                                    </t>
                                </is>
                            </c>
                        </xsl:for-each>
                    </row>

                    <!-- patientInfo elements -->
                    <xsl:apply-templates select="$rootNode/patientInfo" mode="ms-spreadsheet"/>

                </sheetData>

                <!-- Back matter -->
                <xsl:copy-of select="$worksheetTemplate/spreadsheetml:pageMargins"/>
                <xsl:copy-of select="$worksheetTemplate/spreadsheetml:pageSetup"/>
                <xsl:copy-of select="$worksheetTemplate/spreadsheetml:headerFooter"/>

            </worksheet>
        </file>
    </xsl:template>

    <!-- patientInfo for MS Spreadsheet.
         One cell for each entry in entryList -->
    <xsl:template match="patientInfo" mode="ms-spreadsheet">
        <xsl:variable name="patientInfo" select="."/>
        <xsl:variable name="patientId" select="$patientInfo/@patientId"/>
        <xsl:variable name="patientInfoCount" select="count($patientInfo/preceding-sibling::patientInfo)"/>
        <xsl:variable name="spreadsheetRow" select="$patientInfoCount + 2"/>
        <xsl:variable name="colCount" select="$entryListCount"/>

        <row r="{$spreadsheetRow}" spans="1:{$colCount}">
            <!-- Patient Id -->
            <xsl:variable name="firstCellRef" select="concat('A',$spreadsheetRow)"/>
            <c r="{$firstCellRef}" t="inlineStr">
                <is>
                    <t>
                        <xsl:value-of select="$patientId"/>
                    </t>
                </is>
            </c>


            <!-- Demographics entries.
                 Start at column 2 - first column is patientId
                 The demographics entries are assumed to use the first (should be the only) cda:value with specified elementIRI
                 -->
            <xsl:for-each select="$entryList">
                <xsl:variable name="entryIRI" select="."/>
                <xsl:variable name="entryPosition" select="position()"/>
                <xsl:variable name="elementIRI" select="$elementList[position()=$entryPosition]"/>                

                <xsl:variable name="colNum" select="position() + 1"/>
                <xsl:variable name="colRef" select="cityEHRFunction:getColumnReference($colNum)"/>
                <xsl:variable name="cellRef" select="concat($colRef,$spreadsheetRow)"/>

                <c r="{$cellRef}" t="inlineStr">
                    <is>
                        <t>
                            <xsl:value-of select="($patientInfo/descendant::cda:observation[cda:id/@extension=$entryIRI]/descendant::cda:value[@extension=$elementIRI])[1]/@value"/>
                        </t>
                    </is>
                </c>

            </xsl:for-each>
        </row>
    </xsl:template>

    <!-- Data sets
         singleSheet - all data on sheet2
         multipleSheets - one sheet for each entry in the data set, starts at sheet2 -->
    <xsl:template name="generate-ms-dataSets">
        <xsl:variable name="worksheetTemplate" select="$template/spreadsheetML/spreadsheetml:worksheet"/>
        <xsl:variable name="templateCols" select="$worksheetTemplate/spreadsheetml:cols"/>

        <!-- Single sheet -->
        <xsl:if test="$spreadsheetFormat = 'singleSheet'">
            <xsl:variable name="sheetPath" select="'xl/worksheets/sheet2.xml'"/>

            <file name="{$sheetPath}">
                <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
                    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">

                    <!-- Total columns for dataSet -->
                    <xsl:variable name="dataSetColumnCount" select="sum(cityEHRFunction:sequenceProduct($entryCountSequence,$elementCountSequence))"/>
                    <xsl:variable name="colCount" select="$dataSetColumnCount + $referenceColumnCount"/>

                    <!-- Column headers for dataSet -->
                    <xsl:variable name="columnHeaders" select="cityEHRFunction:getColumnHeaders($dataSetEntryList,$entryCountSequence)"/>

                    <!-- Front matter -->
                    <xsl:copy-of select="$worksheetTemplate/spreadsheetml:dimension"/>
                    <xsl:copy-of select="$worksheetTemplate/spreadsheetml:sheetViews"/>
                    <xsl:copy-of select="$worksheetTemplate/spreadsheetml:sheetFormatPr"/>

                    <!-- Columns in spreadsheet -->
                    <cols>
                        <col min="1" max="{$colCount}" width="{$templateCols/spreadsheetml:col[1]/@width}" customWidth="1"/>
                    </cols>

                    <!-- Sheet data -->
                    <sheetData>
                        <!-- Columns Headers.
                            These are the first row of the spreadsheet
                            Assume all cda:entry in the data set have the same values (not true if the information model has changed TDB) 
                            Cell for each value (include values in clusters, but not clusters themselves) -->

                        <row r="1" spans="1:{$colCount}">

                            <xsl:call-template name="outputReferenceDataHeaders"/>

                            <!-- Data set values 
                                 Start after reference columns -->
                            <xsl:for-each select="$columnHeaders">
                                <xsl:variable name="colDisplayName" select="."/>

                                <xsl:variable name="colNum" select="position() + $referenceColumnCount"/>
                                <xsl:variable name="colRef" select="cityEHRFunction:getColumnReference($colNum)"/>
                                <xsl:variable name="cellRef" select="concat($colRef,'1')"/>

                                <c r="{$cellRef}" s="1" t="inlineStr">
                                    <is>
                                        <t>
                                            <xsl:value-of select="$colDisplayName"/>
                                        </t>
                                    </is>
                                </c>
                            </xsl:for-each>
                        </row>

                        <!-- patientData elements
                             There is one row in the spreadsheet for each patient/effectiveTime combination
                             So iterate through these to find observations to output
                             The iteration is made by calling the (recursive) template outputPatientDataRows so that the rowNum can be set correctly
                             Need to process simple entries and multiple entries 
                             This does not yet handle supplementary data sets (they appear as blank lines) ***TBD -->

                        <!-- Iterate through patients to output patientData rows -->
                        <xsl:call-template name="outputPatientDataRows">
                            <xsl:with-param name="patientListIteration" select="$patientList"/>
                            <xsl:with-param name="currentRowNum" as="xs:integer" select="1"/>
                            <xsl:with-param name="colCount" as="xs:integer" select="$colCount"/>
                            <xsl:with-param name="columnHeaders" select="$columnHeaders"/>
                        </xsl:call-template>

                    </sheetData>

                    <!-- Back matter -->
                    <xsl:copy-of select="$worksheetTemplate/spreadsheetml:pageMargins"/>
                    <xsl:copy-of select="$worksheetTemplate/spreadsheetml:pageSetup"/>
                    <xsl:copy-of select="$worksheetTemplate/spreadsheetml:headerFooter"/>

                </worksheet>
            </file>

        </xsl:if>

        <!-- If multipleSheets add a sheet for each dataSetEntry -->
        <xsl:if test="$spreadsheetFormat != 'singleSheet'">
            <xsl:for-each select="$dataSetEntryList">
                <xsl:variable name="entryIRI" select="."/>
                <xsl:variable name="dataSetEntryCount" select="position()"/>
                <xsl:variable name="sheetNum" select="$dataSetEntryCount + 1"/>
                <xsl:variable name="sheetPath" select="concat('xl/worksheets/sheet',$sheetNum,'.xml')"/>

                <!-- The entryTemplate is found from the list created from $dictionary.
                     This is the current model for the entry - note that the recored data may have used a different model -->
                <xsl:variable name="entryTemplate" select="$dataSetEntryTemplateList[descendant::cda:id[1]/@extension = $entryIRI]"/>
                <xsl:variable name="dataSetEntryValues" select="$entryTemplate/descendant::cda:value[@value]"/>
                <xsl:variable name="dataSetEntryValueCount" select="count($dataSetEntryValues)"/>
                <xsl:variable name="colCount" select="$dataSetEntryValueCount + $referenceColumnCount"/>

                <file name="{$sheetPath}">
                    <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
                        xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">

                        <!-- Front matter -->
                        <xsl:copy-of select="$worksheetTemplate/spreadsheetml:dimension"/>
                        <xsl:copy-of select="$worksheetTemplate/spreadsheetml:sheetViews"/>
                        <xsl:copy-of select="$worksheetTemplate/spreadsheetml:sheetFormatPr"/>

                        <!-- Columns in spreadsheet -->
                        <cols>
                            <col min="1" max="{$colCount}" width="{$templateCols/spreadsheetml:col[1]/@width}" customWidth="1"/>
                        </cols>

                        <!-- Sheet data -->
                        <sheetData>
                            <row r="1" spans="1:{$colCount}">
                                <!-- Columns Headers.          
                                    Reference data in first $referenceColumnCount columns
                                    Cell for each value (include values in clusters, but not clusters themselves)
                                    Do not assume all cda:entry in the data set have the same values (i.e. not true if the information model has changed) 
                                -->

                                <!-- Output reference data headers -->
                                <xsl:call-template name="outputReferenceDataHeaders"/>

                                <!-- Data set values 
                                    Start at column $referenceColumnCount + 1 -->
                                <xsl:for-each select="$dataSetEntryValues">
                                    <xsl:variable name="value" select="."/>

                                    <xsl:variable name="colNum" select="$referenceColumnCount +1"/>
                                    <xsl:variable name="colRef" select="cityEHRFunction:getColumnReference($colNum)"/>
                                    <xsl:variable name="cellRef" select="concat($colRef,'1')"/>

                                    <c r="{$cellRef}" s="1" t="inlineStr">
                                        <is>
                                            <t>
                                                <xsl:variable name="colDisplayName"
                                                    select="if ($value/@cityEHR:elementDisplayName != '') then $value/@cityEHR:elementDisplayName else substring-after($value/@extension,'#ISO-13606:Element:')"/>
                                                <xsl:value-of select="$colDisplayName"/>
                                            </t>
                                        </is>
                                    </c>
                                </xsl:for-each>
                            </row>

                            <!-- patientData elements
                             Need to process simple entries, multiple entries and enumeratedClass entries
                             This does not yet handle supplementary data sets  ***TBD -->
                            <xsl:apply-templates
                                select="$rootNode/patientData/cda:entry[descendant::cda:id/@extension=$entryIRI]/cda:observation | 
                                $rootNode/patientData/cda:entry[descendant::cda:id/@extension=$entryIRI]/cda:organizer[@classCode='MultipleEntry']/cda:component[2]/cda:organizer/cda:component/cda:observation | 
                                $rootNode/patientData/cda:entry[descendant::cda:id/@extension=$entryIRI]/cda:organizer[@classCode='MultipleEntry']/cda:component[2]/cda:organizer/cda:component/cda:organizer[@classCode='EnumeratedClassEntry']/cda:component[1]/cda:observation |
                                $rootNode/patientData/cda:entry[descendant::cda:id/@extension=$entryIRI]/cda:organizer[@classCode='EnumeratedClassEntry']/cda:component[1]/cda:observation"
                                mode="ms-spreadsheet"/>
                        </sheetData>

                        <!-- Back matter -->
                        <xsl:copy-of select="$worksheetTemplate/spreadsheetml:pageMargins"/>
                        <xsl:copy-of select="$worksheetTemplate/spreadsheetml:pageSetup"/>
                        <xsl:copy-of select="$worksheetTemplate/spreadsheetml:headerFooter"/>

                    </worksheet>
                </file>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <!-- cda:observation in patientData for MS Spreadsheet.
         One row for each entry
         Reference data in first $referenceColumnCount columns
         One cell for each value (include values in clusters, but not clusters themselves) -->
    <xsl:template match="cda:observation" mode="ms-spreadsheet">
        <xsl:variable name="observation" select="."/>
        <xsl:variable name="entryCount" select="position()"/>

        <xsl:variable name="entry" select="$observation/ancestor::cda:entry"/>
        <xsl:variable name="entryIRI" select="$observation/cda:id[1]/@extension"/>

        <!-- The entryTemplate is found from the list created from $dictionary.
            This is the current model for the entry - note that the recored data may have used a different model -->
        <xsl:variable name="entryTemplate" select="$dataSetEntryTemplateList[descendant::cda:id[1]/@extension = $entryIRI]"/>
        <xsl:variable name="dataSetEntryValues" select="$entryTemplate/descendant::cda:value[@value]"/>
        <xsl:variable name="dataSetEntryValueCount" select="count($dataSetEntryValues)"/>
        <xsl:variable name="colCount" select="$dataSetEntryValueCount + $referenceColumnCount"/>

        <!-- Does this give position in matched node set? -->
        <xsl:variable name="rowNum" select="$entryCount + 1"/>

        <xsl:variable name="patientId" select="$entry/ancestor::patientData/@patientId"/>
        <xsl:variable name="effectiveTime" select="$entry/@effectiveTime"/>

        <!-- Get patientInfo for output of reference data -->
        <xsl:variable name="patientInfo" select="$rootNode/patientInfo[@patientId=$patientId]"/>

        <!-- Output the row in the spreadsheet -->
        <row r="{$rowNum}" spans="1:{$colCount}">

            <xsl:call-template name="outputPatientReferenceData">
                <xsl:with-param name="patientInfo" select="$patientInfo"/>
                <xsl:with-param name="effectiveTime" select="$effectiveTime"/>
                <xsl:with-param name="rowNum" as="xs:integer" select="$rowNum"/>
            </xsl:call-template>

            <!-- Data set values 
                 Start at column $referenceColumnCount + 1
                 Iteration needs to be through the entryTemplate, then match the value id
                 So that any differences in the data model or order of recorded values are handled -->
            <xsl:for-each select="$dataSetEntryValues">
                <xsl:variable name="templateValue" select="."/>
                <xsl:variable name="templateValueIteration" select="position()"/>

                <xsl:variable name="value" select="cityEHRFunction:getObservationValue($observation,$templateValue)"/>

                <xsl:variable name="colNum" select="$templateValueIteration + $referenceColumnCount"/>
                <xsl:variable name="colRef" select="cityEHRFunction:getColumnReference($colNum)"/>

                <c r="{$colRef}{$rowNum}" t="inlineStr">
                    <is>
                        <t>
                            <xsl:value-of select="$value"/>
                        </t>
                    </is>
                </c>
            </xsl:for-each>

        </row>
    </xsl:template>

    <!-- Workbook.
        
    -->
    <xsl:template name="generate-ms-workbook">
        <xsl:variable name="workbookTemplate" select="$template/spreadsheetML/spreadsheetml:workbook"/>
        <file name="xl/workbook.xml">
            <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
                xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
                <!-- Front matter -->
                <xsl:copy-of select="$workbookTemplate/spreadsheetml:fileVersion"/>
                <xsl:copy-of select="$workbookTemplate/spreadsheetml:workbookPr"/>
                <xsl:copy-of select="$workbookTemplate/spreadsheetml:bookViews"/>

                <!-- Sheets
                 Demographics is sheet1, which is already set up in relationships, etc
                 Other sheets for data set entries (if they exist) start at sheet2 / rId5 -->
                <sheets>
                    <!-- Demographics -->
                    <sheet name="{$parameters/demographicsDisplayName}" sheetId="1" r:id="rId1"/>

                    <!-- singleSheet -->
                    <xsl:if test="$spreadsheetFormat = 'singleSheet'">
                        <sheet name="{$parameters/dataSetDisplayName}" sheetId="2" r:id="rId2"/>
                    </xsl:if>

                    <!-- multipleSheets - one sheet for each data set entry -->
                    <xsl:if test="$spreadsheetFormat != 'singleSheet'">
                        <xsl:variable name="rIdPrefix" select="'rId'"/>
                        <xsl:for-each select="$dataSetEntryList">
                            <xsl:variable name="dataSetEntryIRI" select="."/>
                            <xsl:variable name="dataSetNumber" select="position()"/>

                            <xsl:variable name="sheetName" select="substring-after($dataSetEntryIRI,'#ISO-13606:Entry:')"/>
                            <xsl:variable name="sheetNum" select="$dataSetNumber + 1"/>

                            <xsl:variable name="rIdNum" select="$dataSetNumber + 1"/>
                            <xsl:variable name="rId" select="concat($rIdPrefix,$rIdNum)"/>

                            <sheet name="{$sheetName}" sheetId="{$sheetNum}" r:id="{$rId}"/>
                        </xsl:for-each>
                    </xsl:if>

                </sheets>

                <!-- Back matter -->
                <xsl:copy-of select="$workbookTemplate/spreadsheetml:calcPr"/>
            </workbook>
        </file>
    </xsl:template>

    <!-- Content types.
        
    -->
    <xsl:template name="generate-ms-contentType">
        <xsl:variable name="contentTypesTemplate" select="$template/spreadsheetML/content-types:Types"/>
        <file name="[Content_Types].xml">
            <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                <!-- Copy all elements from template -->
                <xsl:copy-of select="$contentTypesTemplate/*"/>

                <xsl:variable name="overrideTemplateContentType"
                    select="$contentTypesTemplate/content-types:Override[@PartName='/xl/worksheets/sheet1.xml']/@ContentType"/>

                <!-- singleSheet - add one more element -->
                <xsl:if test="$spreadsheetFormat = 'singleSheet'">
                    <Override PartName="/xl/worksheets/sheet2.xml" ContentType="{$overrideTemplateContentType}"/>
                </xsl:if>

                <!-- multipleSheet - add an extra element override element for each additional sheet -->
                <xsl:if test="$spreadsheetFormat != 'singleSheet'">
                    <xsl:for-each select="$dataSetEntryList">
                        <xsl:variable name="dataSetNumber" select="position()"/>
                        <xsl:variable name="sheetNum" select="$dataSetNumber + 1"/>

                        <Override PartName="/xl/worksheets/sheet{$sheetNum}.xml" ContentType="{$overrideTemplateContentType}"/>
                    </xsl:for-each>
                </xsl:if>
            </Types>
        </file>
    </xsl:template>


    <!-- ========================
         Generate ODF Spreadsheet
         ======================== -->

    <!-- Spreadsheet -->
    <xsl:template name="generate-odf-spreadsheet">
        <office:document-content>
            <!-- Copy attributes (including namespace declarations) from template -->
            <xsl:copy-of select="$template/@*"/>

            <!-- Output front matter of the spreadsheet -->
            <xsl:copy-of select="$template//office:scripts"/>
            <xsl:copy-of select="$template//office:font-face-decls"/>
            <xsl:copy-of select="$template//office:automatic-styles"/>

            <!-- Output the body of the spreadsheet -->
            <office:body>
                <office:spreadsheet>
                    <xsl:call-template name="generate-odf-demographics"/>
                    <xsl:call-template name="generate-odf-dataSets"/>
                </office:spreadsheet>
            </office:body>

        </office:document-content>
    </xsl:template>

    <!-- Demographics
         Sheet with one row for each patientInfo element-->
    <xsl:template name="generate-odf-demographics">
        <table:table table:name="{$parameters/demographicsDisplayName}" table:style-name="ta1" table:print="false">
            <!-- Column Headers -->
            <table:table-row table:style-name="ro1">
                <!-- Patient Id -->
                <table:table-cell office:value-type="string">
                    <text:p>
                        <xsl:value-of select="$parameters/patientIdDisplayName"/>
                    </text:p>
                </table:table-cell>
                <!-- Demographics entries -->
                <xsl:for-each select="$entryList">
                    <xsl:variable name="entryIRI" select="."/>
                    <xsl:variable name="entryPosition" select="position()"/>
                    <xsl:variable name="elementIRI" select="$elementList[position()=$entryPosition]"/>
                    
                    <xsl:variable name="displayName"
                        select="concat(substring-after($entryIRI,'#ISO-13606:Entry:'),'/',substring-after($elementIRI,'#ISO-13606:Element:'))"/>
                    
                    <table:table-cell office:value-type="string">
                        <text:p>
                            <xsl:value-of select="$displayName"/>
                        </text:p>
                    </table:table-cell>
                </xsl:for-each>
            </table:table-row>
            <!-- patientInfo elements -->
            <xsl:apply-templates select="$rootNode/patientInfo" mode="odf-spreadsheet"/>
        </table:table>
    </xsl:template>

    <!-- patientInfo for ODF Spreadsheet.
         One cell for each entry in entryList -->
    <xsl:template match="patientInfo" mode="odf-spreadsheet">
        <xsl:variable name="patientInfo" select="."/>
        <xsl:variable name="patientId" select="$patientInfo/@patientId"/>
        <table:table-row>
            <!-- Patient Id -->
            <table:table-cell office:value-type="string">
                <text:p>
                    <xsl:value-of select="$patientId"/>
                </text:p>
            </table:table-cell>
            <!-- Demographics entries.
                The demographics entries are assumed to use the first (should be the only) cda:value with specified elementIRI -->
            <xsl:for-each select="$entryList">
                <xsl:variable name="entryIRI" select="."/>
                <xsl:variable name="entryPosition" select="position()"/>
                <xsl:variable name="elementIRI" select="$elementList[position()=$entryPosition]"/>
                                
                <table:table-cell office:value-type="string">
                    <text:p>
                        <xsl:value-of select="($patientInfo/descendant::cda:observation[cda:id/@extension=$entryIRI]/descendant::cda:value[@extension=$elementIRI])[1]/@value"/>
                    </text:p>
                </table:table-cell>
            </xsl:for-each>
        </table:table-row>
    </xsl:template>


    <!-- Data sets.
         One sheet for each data entry -->
    <xsl:template name="generate-odf-dataSets">
        <xsl:for-each select="$dataSetEntryList">
            <xsl:variable name="entryIRI" select="."/>
            <table:table table:name="{substring-after($entryIRI,'#ISO-13606:Entry:')}" table:style-name="ta1" table:print="false">
                <!-- Columns Headers.
                     Cell for each value (include values in clusters, but not clusters themselves) -->
                <xsl:variable name="entryTemplate" select="$dataSetEntryTemplateList[descendant::cda:id[1]/@extension = $entryIRI]"/>
                <table:table-row table:style-name="ro1">
                    <!-- First column is patientId -->
                    <table:table-cell office:value-type="string">
                        <text:p>
                            <xsl:value-of select="$parameters/patientIdDisplayName"/>
                        </text:p>
                    </table:table-cell>
                    <!-- Second column is effectiveTime -->
                    <table:table-cell office:value-type="string">
                        <text:p>
                            <xsl:value-of select="$parameters/effectiveTimeDisplayName"/>
                        </text:p>
                    </table:table-cell>
                    <!-- Values -->
                    <xsl:for-each select="$entryTemplate/descendant::cda:value[@value]">
                        <xsl:variable name="value" select="."/>
                        <table:table-cell office:value-type="string">
                            <text:p>
                                <xsl:variable name="colDisplayName"
                                    select="if ($value/@cityEHR:elementDisplayName != '') then $value/@cityEHR:elementDisplayName else substring-after($value/@extension,'#ISO-13606:Element:')"/>
                                <xsl:value-of select="$colDisplayName"/>
                            </text:p>
                        </table:table-cell>
                    </xsl:for-each>
                </table:table-row>
                <!-- patientData elements -->
                <xsl:apply-templates select="$rootNode/patientData/cda:entry[descendant::cda:id/@extension=$entryIRI]" mode="odf-spreadsheet"/>
            </table:table>
        </xsl:for-each>
    </xsl:template>

    <!-- cda:entry in patientData for ODF Spreadsheet.
         One row for each entry
         One cell for each value (include values in clusters, but not clusters themselves) -->
    <xsl:template match="cda:entry" mode="odf-spreadsheet">
        <xsl:variable name="entry" select="."/>
        <xsl:variable name="patientId" select="$entry/ancestor::patientData/@patientId"/>
        <xsl:variable name="effectiveTime" select="$entry/@effectiveTime"/>
        <table:table-row>
            <!-- PatientId and effectiveTime -->
            <table:table-cell office:value-type="string">
                <text:p>
                    <xsl:value-of select="$patientId"/>
                </text:p>
            </table:table-cell>
            <table:table-cell office:value-type="string">
                <text:p>
                    <xsl:value-of select="$effectiveTime"/>
                </text:p>
            </table:table-cell>
            <!-- Values -->
            <xsl:for-each select="$entry/descendant::cda:value[@value]">
                <table:table-cell office:value-type="string">
                    <text:p>
                        <xsl:value-of select="./@value"/>
                    </text:p>
                </table:table-cell>
            </xsl:for-each>
        </table:table-row>
    </xsl:template>


    <!-- ===================================================================
     Utility Functions
     =================================================================== -->

    <!-- Function to return AAA reference to number
     e.g. 1 = A, 2 = B, 26 = Z
          27 = AA, 28 = AB
          53 = BA, 54 = BB
          676 = ZZ, 677 = AAA, 678 = AAB 

    Unicode for A is 65, Z is 80 (i.e. 64 plus position in alphabet -->

    <xsl:function name="cityEHRFunction:getColumnReference">
        <xsl:param name="colNum"/>

        <!-- Only return reference if a colNum is passed in -->
        <xsl:if test="$colNum castable as xs:integer">
            <xsl:variable name="colNumSequence" select="cityEHRFunction:getModulusSequence($colNum,26)"/>
            <xsl:variable name="colCodepoints" select="for $n in $colNumSequence return $n+64"/>
            <xsl:variable name="colReference" select="codepoints-to-string($colCodepoints)"/>

            <xsl:value-of select="$colReference"/>
        </xsl:if>

        <xsl:if test="not($colNum castable as xs:integer)">
            <xsl:value-of select="'error'"/>
        </xsl:if>

    </xsl:function>


    <!-- Function to return sequence of division modulus.         
         Recursive call generates the sequence -->
    <xsl:function name="cityEHRFunction:getModulusSequence">
        <xsl:param name="number" as="xs:integer"/>
        <xsl:param name="base" as="xs:integer"/>

        <!-- Number greater than the base -->
        <xsl:if test="$number gt $base">
            <xsl:variable name="remainder" select="$number mod $base"/>
            <xsl:variable name="offset" select="if ($remainder = 0) then $base else $remainder"/>
            <xsl:variable name="nextNumber" select="($number - $offset) div $base"/>

            <!-- Recursive call first, so that sequence comes out in the correct order -->
            <xsl:if test="$nextNumber != 0">
                <xsl:sequence select="cityEHRFunction:getModulusSequence($nextNumber,$base)"/>
            </xsl:if>

            <xsl:sequence select="$offset"/>
        </xsl:if>

        <!-- Number less than or equal to base, just return it in the sequence -->
        <xsl:if test="$number le $base">
            <xsl:sequence select="$number"/>
        </xsl:if>

    </xsl:function>


    <!-- Function to return sequence of maximum entries for each entry in dataSetEntryList.
         Recursive call generates the sequence -->
    <xsl:function name="cityEHRFunction:getEntryCountSequence">
        <xsl:param name="dataSetEntryList"/>

        <xsl:variable name="nextDataSetEntryList" select="$dataSetEntryList[position() != 1]"/>
        <xsl:variable name="entryIRI" select="$dataSetEntryList[1]"/>

        <xsl:sequence select="cityEHRFunction:getEntryCount($entryIRI)"/>

        <!-- Recursive call second, so that sequence is returned in the same order as the dataSetEntryList -->
        <xsl:if test="not(empty($nextDataSetEntryList))">
            <xsl:sequence select="cityEHRFunction:getEntryCountSequence($nextDataSetEntryList)"/>
        </xsl:if>

    </xsl:function>


    <!-- Function to return the maximum count of an entry in any patientId/effectiveTime combination.
         Note that if there are no entries for any patient, then entryCountSequenceForPatients will be empty
         If the maximum is zero (i.e. there are no entries for this entryIRI in the patient data), then returns 1 -->
    <xsl:function name="cityEHRFunction:getEntryCount">
        <xsl:param name="entryIRI"/>

        <xsl:variable name="entryCountSequenceForPatients" select="cityEHRFunction:getEntryCountForPatients($entryIRI,$patientList)"/>

        <xsl:variable name="maxEntries" select="if (empty($entryCountSequenceForPatients)) then 0 else max($entryCountSequenceForPatients)"/>

        <xsl:value-of select="if ($maxEntries = 0) then 1 else $maxEntries"/>

    </xsl:function>

    <!-- Function to return sequence of entry count for every patientId/effectiveTime combination.
         Recursive call iterates through the patients -->
    <xsl:function name="cityEHRFunction:getEntryCountForPatients">
        <xsl:param name="entryIRI"/>
        <xsl:param name="patientListForCount"/>

        <xsl:variable name="nextPatientList" select="$patientListForCount[position() != 1]"/>
        <xsl:variable name="patientId" select="$patientListForCount[1]"/>

        <xsl:variable name="effectiveTimeList" select="distinct-values($rootNode/patientData[@patientId=$patientId]/cda:entry/@effectiveTime)"/>

        <!-- Output the number of entries at each effectiveTime -->
        <xsl:for-each select="$effectiveTimeList">
            <xsl:variable name="effectiveTime" select="."/>
            <xsl:variable name="lookUpKey" select="concat($patientId,$entryIRI,$effectiveTime)"/>

            <xsl:variable name="entrySet" select="key('observationSet',$lookUpKey,$rootNode)"/>

            <xsl:sequence select="if (empty($entrySet)) then 0 else count($entrySet)"/>
        </xsl:for-each>

        <xsl:if test="not(empty($nextPatientList))">
            <xsl:sequence select="cityEHRFunction:getEntryCountForPatients($entryIRI,$nextPatientList)"/>
        </xsl:if>

    </xsl:function>


    <!-- Function to return sequence of element count for each entry in dataSetEntryList.
         Recursive call generates the sequence -->
    <xsl:function name="cityEHRFunction:getElementCountSequence">
        <xsl:param name="dataSetEntryList"/>

        <xsl:variable name="nextDataSetEntryList" select="$dataSetEntryList[position() != 1]"/>

        <xsl:variable name="entryIRI" select="$dataSetEntryList[1]"/>

        <!-- For the entry template we need extension and root to match entryIRI (i.e. no aliases)
            There should only be one of these in the dictionary, but take the first one, just in case -->
        <xsl:variable name="entryTemplate"
            select="($dictionary/iso-13606:EHR_Extract/iso-13606:entryCollection/descendant::cda:observation[cda:id/@extension=$entryIRI][cda:id/@root=$entryIRI])[1]"/>

        <!-- Note that the entry may no longer exist in the dictionary, so in that case return 0 for the element count -->
        <xsl:variable name="dataSetEntryValues" select="if (exists($entryTemplate)) then $entryTemplate/descendant::cda:value[@value] else ()"/>
        <xsl:variable name="dataSetEntryValueCount" select="count($dataSetEntryValues)"/>

        <!-- Output the element count -->
        <xsl:sequence select="$dataSetEntryValueCount"/>

        <!-- Recusrive call to generate the full sequence
             Call this after outputing the dataSetEntryValueCount so that the sequence is returned in the same order as dataSetEntryTemplateList -->
        <xsl:if test="not(empty($nextDataSetEntryList))">
            <xsl:sequence select="cityEHRFunction:getElementCountSequence($nextDataSetEntryList)"/>
        </xsl:if>

    </xsl:function>


    <!-- Function to return sequence of product of two sequences.
         The sequences may not be the same length, so stop as soon as one is empty
         Need to use the first number of each sequence for the product (in case sequences are different lengths)
         Recursive call generates the sequence -->
    <xsl:function name="cityEHRFunction:sequenceProduct">
        <xsl:param name="firstSequence"/>
        <xsl:param name="secondSequence"/>

        <xsl:variable name="nextFirstSequence" select="$firstSequence[position() != 1]"/>
        <xsl:variable name="nextSecondSequence" select="$secondSequence[position() != 1]"/>

        <xsl:variable name="firstNumber" as="xs:integer" select="if (not(empty($firstSequence))) then $firstSequence[position() = 1] else 0"/>
        <xsl:variable name="secondNumber" as="xs:integer" select="if (not(empty($secondSequence))) then $secondSequence[position() = 1] else 0"/>

        <!-- Only iterate if both sequences have values left.
             Iterate before returning product, so that sequence is returned in correct order -->
        <xsl:if test="not(empty($nextFirstSequence)) and not(empty($nextSecondSequence))">
            <xsl:sequence select="cityEHRFunction:sequenceProduct($nextFirstSequence,$nextSecondSequence)"/>
        </xsl:if>

        <xsl:sequence select="$firstNumber * $secondNumber"/>

    </xsl:function>


    <!-- Function to return sequence of entry templates.
         The templates are found in the $dictionary that is an input to this transformation
         Recursive call generates the sequence -->
    <xsl:function name="cityEHRFunction:getEntryTemplates">
        <xsl:param name="dataSetEntryList"/>

        <xsl:variable name="nextDataSetEntryList" select="$dataSetEntryList[position() != 1]"/>
        <xsl:variable name="entryIRI" select="$dataSetEntryList[1]"/>

        <!-- For the entry template we need extension and root to match entryIRI (i.e. no aliases)
             There should only be one of these in the dictionary, but take the first one, just in case -->
        <xsl:variable name="entryTemplate"
            select="($dictionary/iso-13606:EHR_Extract/iso-13606:entryCollection/descendant::cda:observation[cda:id/@extension=$entryIRI][cda:id/@root=$entryIRI])[1]"/>

        <!-- Return the template -->
        <xsl:sequence select="$entryTemplate"/>

        <xsl:if test="not(empty($nextDataSetEntryList))">
            <xsl:sequence select="cityEHRFunction:getEntryTemplates($nextDataSetEntryList)"/>
        </xsl:if>

    </xsl:function>

    <!-- Function to return sequence of integers, up to the count.
         If the count is zero then returns the empty sequence () -->
    <xsl:function name="cityEHRFunction:getCountSequence">
        <xsl:param name="count" as="xs:integer"/>

        <xsl:variable name="nextCount" as="xs:integer" select="$count - 1"/>

        <xsl:if test="$nextCount gt 0">
            <xsl:sequence select="cityEHRFunction:getCountSequence($nextCount)"/>
        </xsl:if>

        <!-- This comes after recursive call so that the sequence comes out in the right order (ascending) -->
        <xsl:if test="$count gt 0">
            <xsl:sequence select="$count"/>
        </xsl:if>

    </xsl:function>


    <!-- Function to return sequence of column headers.
         Iterates through the dataSetEntryList
         Recursive call generates the sequence -->
    <xsl:function name="cityEHRFunction:getColumnHeaders">
        <xsl:param name="dataSetEntryList"/>
        <xsl:param name="entryCountSequence"/>

        <xsl:variable name="entryIRI" select="$dataSetEntryList[1]"/>
        <xsl:variable name="entryId" select="substring-after($entryIRI,'#ISO-13606:Entry:')"/>
        <xsl:variable name="entryTemplate" select="$dataSetEntryTemplateList[descendant::cda:id[1]/@extension = $entryIRI]"/>

        <xsl:variable name="nextDataSetEntryList" select="$dataSetEntryList[position() != 1]"/>

        <xsl:variable name="nextEntryCountSequence" select="$entryCountSequence[position() != 1]"/>
        <xsl:variable name="entryCount" select="$entryCountSequence[position() = 1]"/>

        <!-- Only generate headers if the entryTemplate exists.
        If the data entry no longer exists in the dictionary, then nothing is exported -->

        <xsl:if test="exists($entryTemplate)">
            <!-- getCountSequence returns () if there are no entries, otherwise the sequence from 1 to the number of entries.
                 Note that the entryCount should never contain zeros - 
                 if an entry has no instances in the patient data then the entryCountSequence will contain 1 -->
            <xsl:variable name="countSequence" select="cityEHRFunction:getCountSequence($entryCount)"/>

            <!-- Elements (vlaues) for this entry -->
            <xsl:variable name="dataSetEntryValues" select="$entryTemplate/descendant::cda:value[@value]"/>

            <!-- Output one set of headers for each number in the cntryCount - 1,2,3, etc -->
            <xsl:for-each select="$countSequence">
                <xsl:variable name="countString" select="xs:string(.)"/>
                <xsl:sequence
                    select="$dataSetEntryValues/string-join(($entryId,ancestor-or-self::cda:value/substring-after(@extension,'#ISO-13606:Element:'),$countString),$idSeparator)"
                />
            </xsl:for-each>
        </xsl:if>

        <!-- Recursive call second, so that headers come out in same order as dataSetEntryList
            Sequences should be of the same length but test both, just in case -->
        <xsl:if test="not(empty($nextDataSetEntryList)) and not(empty($nextEntryCountSequence))">
            <xsl:sequence select="cityEHRFunction:getColumnHeaders($nextDataSetEntryList,$nextEntryCountSequence)"/>
        </xsl:if>

    </xsl:function>

    <!-- Template to output reference data headers in MS spreadsheet.
         These are the first row of the spreadsheet
         The first cell is the patientId, then the reference data entries, then the effectiveTime -->
    <xsl:template name="outputReferenceDataHeaders">

        <!-- First column is patientId -->
        <c r="A1" s="1" t="inlineStr">
            <is>
                <t>
                    <xsl:value-of select="$parameters/patientIdDisplayName"/>
                </t>
            </is>
        </c>

        <!-- Iterate through the $referenceDataList to get headers -->
        <xsl:for-each select="$referenceDataList">
            <xsl:variable name="referenceDataIRI" select="."/>
            <xsl:variable name="colNum" select="position() + 1"/>
            <xsl:variable name="colRef" select="cityEHRFunction:getColumnReference($colNum)"/>

            <c r="{$colRef}1" s="1" t="inlineStr">
                <is>
                    <t>
                        <xsl:value-of select="substring-after($referenceDataIRI,'#ISO-13606:Entry:')"/>
                    </t>
                </is>
            </c>
        </xsl:for-each>

        <!-- Final column of reference data is effectiveTime.
             But only if longitudinalDataOutput is 'allData' -->
        <xsl:if test="$longitudinalDataOutput = 'allData'">
            <xsl:variable name="finalColRef" select="cityEHRFunction:getColumnReference($referenceColumnCount)"/>
            <c r="{$finalColRef}1" t="inlineStr">
                <is>
                    <t>
                        <xsl:value-of select="$parameters/effectiveTimeDisplayName"/>
                    </t>
                </is>
            </c>
        </xsl:if>
    </xsl:template>


    <!-- Template to output reference data cells in MS spreadsheet.
         The first cell is the patientId, then the reference data entries, then the effectiveTime -->
    <xsl:template name="outputPatientReferenceData">
        <xsl:param name="patientInfo"/>
        <xsl:param name="effectiveTime"/>
        <xsl:param name="rowNum"/>

        <!-- First column is patientId -->
        <c r="A{$rowNum}" t="inlineStr">
            <is>
                <t>
                    <xsl:value-of select="$patientInfo/@patientId"/>
                </t>
            </is>
        </c>

        <!-- Iterate through reference data.
             These must all be in patientInfo, so get the value from there -->
        <xsl:for-each select="$referenceDataList">
            <xsl:variable name="referenceDataIRI" select="."/>
            <xsl:variable name="colNum" select="position() + 1"/>
            <xsl:variable name="colRef" select="cityEHRFunction:getColumnReference($colNum)"/>

            <c r="{$colRef}{$rowNum}" t="inlineStr">
                <is>
                    <t>
                        <xsl:value-of select="$patientInfo/descendant::cda:observation[cda:id/@extension=$referenceDataIRI]/cda:value[1]/@value"/>
                    </t>
                </is>
            </c>
        </xsl:for-each>

        <!-- Final column of reference data is effectiveTime.
            But only if longitudinalDataOutput is 'allData' -->
        <xsl:if test="$longitudinalDataOutput = 'allData'">
            <xsl:variable name="finalColRef" select="cityEHRFunction:getColumnReference($referenceColumnCount)"/>
            <c r="{$finalColRef}{$rowNum}" t="inlineStr">
                <is>
                    <t>
                        <xsl:value-of select="$effectiveTime"/>
                    </t>
                </is>
            </c>
        </xsl:if>
    </xsl:template>



    <!-- Template to output rows of patientData in MS spreadsheet.
         Recursive call to perform iteration through patientList and keep track of the rowNum -->
    <xsl:template name="outputPatientDataRows">
        <xsl:param name="patientListIteration"/>
        <xsl:param name="currentRowNum" as="xs:integer"/>
        <xsl:param name="colCount" as="xs:integer"/>
        <xsl:param name="columnHeaders"/>


        <xsl:variable name="patientId" select="$patientListIteration[1]"/>
        <xsl:variable name="effectiveTimeList" select="distinct-values($rootNode/patientData[@patientId=$patientId]/cda:entry/@effectiveTime)"/>

        <!-- Iterate through each effectiveTime for this patient -->
        <xsl:for-each select="$effectiveTimeList">
            <xsl:variable name="effectiveTime" select="."/>
            <xsl:variable name="dataEntryNum" as="xs:integer" select="position()"/>
            <xsl:variable name="rowNum" select="$currentRowNum + $dataEntryNum"/>

            <!-- Get patientInfo for output of reference data -->
            <xsl:variable name="patientInfo" select="$rootNode/patientInfo[@patientId=$patientId]"/>

            <!-- Output the row in the spreadsheet -->
            <row r="{$rowNum}" spans="1:{$colCount}">

                <xsl:call-template name="outputPatientReferenceData">
                    <xsl:with-param name="patientInfo" select="$patientInfo"/>
                    <xsl:with-param name="effectiveTime" select="$effectiveTime"/>
                    <xsl:with-param name="rowNum" as="xs:integer" select="$rowNum"/>
                </xsl:call-template>

                <!-- Iterate through the dataSetEntryList.
                     (Need this one - iteration through dataSetEntryTemplateList will go in document order in the dictionary, which will be wrong)
                     Get the entries for the patientId/entryIRI/effectiveTime.
                     Output into the correct column, leaving blanks as necessary -->
                <xsl:for-each select="$dataSetEntryList">
                    <xsl:variable name="entryIRI" select="."/>
                    <xsl:variable name="entryPosition" as="xs:integer" select="position()"/>

                    <xsl:variable name="entryTemplate" select="$dataSetEntryTemplateList[descendant::cda:id[1]/@extension = $entryIRI]"/>

                    <!-- Get the observations for this patient/entry/effectiveTime -->
                    <xsl:variable name="lookUpKey" select="concat($patientId,$entryIRI,$effectiveTime)"/>
                    <xsl:variable name="observationSet" select="key('observationSet',$lookUpKey,$rootNode)"/>

                    <!-- Get the number of columns preceeding the current entry.
                         Just need the previous data set columns, not the first reference columns -->
                    <xsl:variable name="preceedingEntryCountSequence" select="$entryCountSequence[position() lt $entryPosition]"/>
                    <xsl:variable name="preceedingColumnCount" as="xs:integer"
                        select="sum(cityEHRFunction:sequenceProduct($preceedingEntryCountSequence,$elementCountSequence))"/>

                    <!-- Element count for the current entry 
                         This is found from the elementCountSequence at entryPosition -->
                    <xsl:variable name="elementCount" select="$elementCountSequence[position() = $entryPosition]"/>

                    <!-- Iteration is now through the max number of entries for this entryIRI.
                         This is found from the entryCountSequence at entryPosition -->
                    <xsl:variable name="entryCount" select="$entryCountSequence[position() = $entryPosition]"/>
                    <xsl:variable name="entryIterationSequence" select="cityEHRFunction:getCountSequence($entryCount)"/>

                    <xsl:for-each select="$entryIterationSequence">
                        <xsl:variable name="entryIteration" as="xs:integer" select="."/>
                        <xsl:variable name="observation" select="$observationSet[position()=$entryIteration]"/>

                        <!-- Starting position in entryIteration -->
                        <xsl:variable name="entryIterationOffset" select="($entryIteration - 1) * $elementCount"/>

                        <!-- Observation may not exist, since we are iterating through the maximum number across all patients.
                             If there isn't an observation then need to output blank cells.
                             The iteration through values is made on the entryTemplate, in case the model has changed since the observation was recorded -->
                        <xsl:for-each select="$entryTemplate/descendant::cda:value[@value]">
                            <xsl:variable name="templateValue" select="."/>
                            <xsl:variable name="templateValueIteration" select="position()"/>

                            <!-- Get value in observation that matches the template -->
                            <xsl:variable name="value" select="cityEHRFunction:getObservationValue($observation,$templateValue)"/>

                            <!-- dataSetColumnNum must be calculated, based on:
                                 The number of preceeding entries and their elements
                                 The number of preceeding columns in this iteration through the current entry
                                 The count of the current element
                            -->
                            <xsl:variable name="dataSetColumnNum" select="$preceedingColumnCount + $entryIterationOffset + $templateValueIteration"/>

                            <!-- Check the header for this dataSetColumnNum
                                 It should match the current entry/element - if not then something is wrong -->
                            <xsl:variable name="columnHeader" select="$columnHeaders[position()=$dataSetColumnNum]"/>

                            <xsl:variable name="colNum" select="$dataSetColumnNum + $referenceColumnCount"/>
                            <xsl:variable name="colRef" select="cityEHRFunction:getColumnReference($colNum)"/>

                            <c r="{$colRef}{$rowNum}" t="inlineStr">
                                <is>
                                    <t>
                                        <xsl:value-of select="$value"/>
                                        <!-- Debugging -->
                                        <!--
                                        <xsl:value-of select="$columnHeader"/>
                                        <xsl:value-of select="' / '"/>
                                        <xsl:value-of select="$entryCountSequence" separator="-"/>
                                        <xsl:value-of select="' / '"/>
                                        <xsl:value-of select="$elementCountSequence" separator="-"/>
                                        <xsl:value-of select="' / '"/>
                                        <xsl:value-of select="$entryIterationSequence" separator="-"/>
                                        <xsl:value-of select="' / '"/>
                                        <xsl:value-of select="$dataSetEntryList" separator="-"/>
                                        <xsl:value-of
                                            select="concat(' | ',$entryIRI,' | ',$entryCount,'-',$elementCount,'-',count($entryTemplate/descendant::cda:value[@value]))"/>
                                        <xsl:value-of
                                            select="concat(' / ',$entryPosition,'-',$preceedingColumnCount,'-',$entryIterationOffset,'-',$templateValueIteration)"/>
                                        -->

                                    </t>
                                </is>
                            </c>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:for-each>

            </row>
        </xsl:for-each>

        <!-- Recursive call iterates through the patientList.
             Keeps going until nextPatientListIteration is empty -->
        <xsl:variable name="nextPatientListIteration" select="$patientListIteration[position() != 1]"/>
        <xsl:variable name="nextRowNum" as="xs:integer" select="$currentRowNum + count($effectiveTimeList)"/>

        <xsl:if test="not(empty($nextPatientListIteration))">
            <xsl:call-template name="outputPatientDataRows">
                <xsl:with-param name="patientListIteration" select="$nextPatientListIteration"/>
                <xsl:with-param name="currentRowNum" as="xs:integer" select="$nextRowNum"/>
                <xsl:with-param name="colCount" as="xs:integer" select="$colCount"/>
                <xsl:with-param name="columnHeaders" select="$columnHeaders"/>
            </xsl:call-template>
        </xsl:if>

    </xsl:template>


    <!-- Function to return value in observation that matches the templateValue -->
    <xsl:function name="cityEHRFunction:getObservationValue">
        <xsl:param name="observation"/>
        <xsl:param name="templateValue"/>

        <!-- Only if observation and template exist -->
        <xsl:if test="exists($observation) and exists($templateValue)">
            <!-- Get id of the template value, allowing for clusters -->
            <xsl:variable name="templateValueId" select="string-join($templateValue/ancestor-or-self::cda:value/@extension,$idSeparator)"/>

            <!-- Get matching value in the observation -->
            <xsl:variable name="value"
                select="$observation/descendant::cda:value[string-join(ancestor-or-self::cda:value/@extension,$idSeparator) = $templateValueId]"/>

            <xsl:value-of select="$value/@value"/>

        </xsl:if>

        <!-- If observation or template don't exist -->
        <xsl:if test="not(exists($observation) and exists($templateValue))">
            <xsl:value-of select="''"/>
        </xsl:if>

    </xsl:function>

</xsl:stylesheet>
