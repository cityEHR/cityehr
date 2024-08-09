<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    WordProcessorReplaceVariables.xsl
    Input is the content from ODF (content.xml, styles.xml) or MS Word document (word/document.xml)
    Finds variables in the text content of the form #ISO-13606:Entry:letterheadLeft or #ISO-13606:Entry:Demographics/#ISO-13606:Element:Surname 
    Replaces variables with content generated from the input HTML document
       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
    xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
    xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0"
    xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0"
    xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0" xmlns:ooo="http://openoffice.org/2004/office"
    xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:rpt="http://openoffice.org/2005/report" xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2"
    xmlns:grddl="http://www.w3.org/2003/g/data-view#" xmlns:tableooo="http://openoffice.org/2009/table"
    xmlns:textooo="http://openoffice.org/2013/office" xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0"
    xmlns:ve="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office"
    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:wx="http://schemas.microsoft.com/office/word/2003/auxHint">

    <!-- === Inputs ==========================
         The data input is the XML content of either the MS Word or ODF template
         -->

    <!-- The combined parameters are passed in on parameters input -->
    <xsl:variable name="view-parameters" select="document('input:parameters')//parameters[@type = 'view']"/>
    <xsl:variable name="system-parameters" select="document('input:parameters')//parameters[@type = 'system']"/>
    <xsl:variable name="session-parameters" select="document('input:parameters')//parameters[@type = 'session']"/>

    <!-- The composition is passed as HTML in the html input -->
    <xsl:variable name="html" select="document('input:html')"/>

    <!-- The mode is either odf or msword, depending on the root node -->
    <xsl:variable name="mode"
        select="
            if (exists(/w:document)) then
                'msword'
            else
                if (exists(/office:document-content)) then
                    'odf'
                else
                    'bad-input'"/>

    <!-- Images files sizes are passed in from directory scan.
        image-file-info is of the form:
        
        <directory name="media"
            path="C:\cityEHR\tomcat7\webapps\orbeon\WEB-INF\resources\apps\ehr\resources\configuration\ISO-13606-EHR_Extract-Elfin\media">
            <file last-modified-ms="1368590738000" last-modified-date="2013-05-15T05:05:38.000"
                    size="16982"
                    path="alcoholgraphic.png"
                    name="alcoholgraphic.png">
                <image-metadata>
                    <basic-info>
                        <content-type>image/png</content-type>
                        <width>153</width>
                        <height>153</height>
                    </basic-info>
                </image-metadata>
            </file>
            ...
        </directory> 
    -->
    <xsl:variable name="image-file-info" select="document('input:image-file-info')/*[1]"/>



    <!-- ======================================================================================== 
         Transforming fragments of the HTML, located from variables in the wordprocessor content.
         The mode for this transformation is either odf or mwword
         ======================================================================================== -->


    <!-- === ODF document 
         Tramsform HTML fragments.
         These may be representation of:
            composition     <div class="ISO-13606:Composition">
            section         <ul class="ISO13606-Section #ISO-13606:Section:SectionId">
            entry           <ul class="ISO13606-Entry #ISO-13606:Entry:EntryId">
            element         <ul class="ISO13606-Element #ISO-13606:Entry:EntryId/ #ISO-13606:Element:ElementId">
         ========================== -->

    <!-- Composition -->
    <xsl:template mode="odf" match="div[contains(@class, 'ISO-13606:Composition')]">
        <xsl:apply-templates mode="odf"/>
    </xsl:template>


    <!-- Ranked and Unranked Section.
         Section header is a w:p, then process contents,
         But only process when there is some content (these are designated by the class emptySection) -->
    <xsl:template mode="odf" match="ul[contains(@class, 'ISO13606-Section')]">
        <!-- Check for emptySection before processing -->
        <xsl:if test="not(contains(@class, 'emptySection'))">
            <xsl:variable name="rendition"
                select="
                    if (contains(@class, 'Standalone')) then
                        'Standalone'
                    else
                        ''"/>
            <xsl:variable name="hasDisplayName" select="exists(li[@class = 'ISO13606-Section-DisplayName'][descendant::text()])"/>
            
            <!-- For debugging - output the class attribute -->
            <!--
            <w:p>
                    <w:r>
                        <xsl:value-of select="@class"/>
                    </w:r> 
            </w:p>
            -->

            <xsl:if test="$rendition = 'Standalone' or $hasDisplayName">
                <w:p>
                    <!-- Insert page break for standalone sections -->
                    <xsl:if test="$rendition = 'Standalone'">
                        <w:r>
                            <w:br w:type="page"/>
                        </w:r>
                    </xsl:if>
                    <!-- Output section displayName, if there is one.
                          Copy format for text run from the template -->
                    <xsl:if test="$hasDisplayName">
                        <w:r>
                            <xsl:apply-templates mode="odf" select="li[@class = 'ISO13606-Section-DisplayName']"/>
                        </w:r>
                    </xsl:if>
                </w:p>
            </xsl:if>

            <!-- Process contents of Ranked amd Unranked section.
             This is handled differently for Ranked amd Unranked sections -->
            <!-- Ranked -->
            <xsl:apply-templates mode="odf" select="li[@class = 'Ranked']"/>

            <!-- Unranked -->
            <xsl:variable name="contentList" select="li[@class = 'Unranked']"/>
            <xsl:variable name="contentCount" select="count($contentList)"/>
            <xsl:call-template name="odf-outputUnrankedSection">
                <xsl:with-param name="count" select="$contentCount"/>
                <xsl:with-param name="contentList" select="$contentList"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>


    <!-- Unranked Section 
         Output as a table -->
    <xsl:template name="odf-outputUnrankedSection">
        <xsl:param name="count"/>
        <xsl:param name="contentList"/>
        <!--
        <w:tbl>
            <w:tblPr>
                <w:tblW w:w="0" w:type="auto"/>
            </w:tblPr>                 
            <w:tr>
                <w:tc>
                    <w:p>
                        <w:pPr>
                            <w:spacing w:after="0"/>
                        </w:pPr>
                        <w:r>
                            <w:t>hello</w:t>
                        </w:r>
                    </w:p>
                </w:tc>
                <w:tc>
                    <w:p>
                        <w:pPr>
                            <w:spacing w:after="0"/>
                        </w:pPr>
                        <w:r>
                            <w:t>world</w:t>
                        </w:r>
                    </w:p>
                </w:tc>
            </w:tr>
        </w:tbl>
        -->

        <xsl:if test="not(empty($contentList)) and true()">
            <w:tbl>
                <w:tblPr>
                    <w:tblW w:w="0" w:type="auto"/>
                </w:tblPr>

                <w:tr>
                    <!-- Always need each cell, even if empty -->
                    <xsl:for-each select="$contentList">
                        <w:tc>
                            <xsl:apply-templates mode="odf" select="."/>
                        </w:tc>
                    </xsl:for-each>
                </w:tr>
            </w:tbl>
        </xsl:if>
    </xsl:template>


    <xsl:template mode="odf" match="*">
        <xsl:apply-templates mode="odf"/>
    </xsl:template>

    <xsl:template mode="odf" match="text()">
        <xsl:value-of select="."/>
    </xsl:template>




    <!-- === MS Word document 
         Tramsform HTML fragments
         ========================== -->

    <xsl:template mode="msword" match="*">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template mode="msword" match="text()">
        <xsl:value-of select="."/>
    </xsl:template>



    <!-- =========================================================================== 
         Transforming the input wordprocessor content
         =========================================================================== -->

    <!-- === Element nodes  ========================== -->
    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>


    <!-- === Text Nodes - Look for Variables ========================== -->
    <xsl:template match="text()">
        <xsl:variable name="regex" select="'(#ISO-13606:[^\s]*)'"/>

        <xsl:analyze-string select="." regex="{$regex}">
            <xsl:matching-substring>
                <xsl:variable name="variable" as="xs:string" select="regex-group(1)"/>

                <!-- Find only the first matching element in the HTML
                     Entries and elements will both have a class containging the mayched variable (element class starts with the entry class)
                     But elements are contained in entries, so taking the first one gets what we want-->
                <xsl:variable name="variableReplacement" select="($html//*[contains(@class, $variable)])[1]"/>

                <xsl:if test="$mode = 'odf'">
                    <xsl:apply-templates mode="odf" select="$variableReplacement"/>
                </xsl:if>

                <xsl:if test="$mode = 'msword'">
                    <xsl:apply-templates mode="msword" select="$variableReplacement"/>
                </xsl:if>

                <!--
                
                <xsl:value-of select="if (exists($variableReplacement)) then normalize-space($variableReplacement) else ''"/>
                
                -->
            </xsl:matching-substring>

            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>


        </xsl:analyze-string>
    </xsl:template>


    <!-- === Functions ========================== -->
    <!--
    <xsl:function name="cityEHRFunction:tokenizeExpressionEntries">
        <xsl:param name="content"/>
        <xsl:variable name="variablePrefix" select="'cityEHR:Variable:'"/>
        <xsl:variable name="pathSeparator" select="'/'"/>
        <xsl:variable name="regex" select="concat($variablePrefix,'([-a-zA-Z0-9_]+)',$pathSeparator)"/>
        
        <xsl:analyze-string select="$content" regex="{$regex}">
            <xsl:matching-substring>
                <xsl:variable name="entryId" as="xs:string" select="regex-group(1)"/>
                <xsl:if test="$entryId != 'math'">
                    <xsl:value-of select="concat('#ISO-13606:Entry:',$entryId)"/>
                </xsl:if>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    -->

</xsl:stylesheet>
