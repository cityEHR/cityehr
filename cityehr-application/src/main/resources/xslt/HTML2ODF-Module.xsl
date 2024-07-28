<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    HTML2ODF-Module.xsl
    Input is an HTML document
    Root of the HTML document is html
    Generates ODF that forms the content.xml component of the .odt zip
    
    Combined parameters have been set up as $view-parameters, $session-parameters and $system-parameters
       
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
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
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
    xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:rpt="http://openoffice.org/2005/report" xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:grddl="http://www.w3.org/2003/g/data-view#" xmlns:officeooo="http://openoffice.org/2009/office"
    xmlns:tableooo="http://openoffice.org/2009/table" xmlns:drawooo="http://openoffice.org/2010/draw"
    xmlns:calcext="urn:org:documentfoundation:names:experimental:calc:xmlns:calcext:1.0"
    xmlns:loext="urn:org:documentfoundation:names:experimental:office:xmlns:loext:1.0"
    xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0"
    xmlns:formx="urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:form:1.0" xmlns:css3t="http://www.w3.org/TR/css3-text/"
    
    xmlns:w="w"
    xmlns:v="v"
    xmlns:p="p"
    xmlns:o="o"
    >

    <!-- Letterhead prefix is used to mark content in the ODF template -->
    <xsl:variable name="letterheadPrefix" select="'cityEHR:letter:'"/>

    <!-- Get templates for the letterhead and other page set up -->
    <xsl:variable name="letterheadTemplate" select="$odfTemplate//office:text/table:table[1]"/>
    <xsl:variable name="tableWidth" select="$letterheadTemplate/w:tblGrid[1]/sum(w:gridCol/@w:w)"/>
    <xsl:variable name="image-file-info" select="()"/>
    <xsl:variable name="sectionTemplate" select="$odfTemplate/descendant::text:p[.//text() = 'cityEHR:letter:Section'][1]"/>
    <xsl:variable name="paragraphTemplate" select="$odfTemplate/descendant::text:p[.//text() = 'cityEHR:letter:Paragraph'][1]"/>

    <!-- Get the sections for the header -->
    <xsl:variable name="root" select="/"/>
    <xsl:variable name="headerContent" select="//div[@class = 'ISO13606-Composition']/table[@class = 'Header']"/>

    <!-- HTML root node -->
    <xsl:template match="html">
        <office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
            xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
            xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
            xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink"
            xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
            xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
            xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0"
            xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0"
            xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0" xmlns:ooo="http://openoffice.org/2004/office"
            xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events"
            xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rpt="http://openoffice.org/2005/report"
            xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" xmlns:xhtml="http://www.w3.org/1999/xhtml"
            xmlns:grddl="http://www.w3.org/2003/g/data-view#" xmlns:officeooo="http://openoffice.org/2009/office"
            xmlns:tableooo="http://openoffice.org/2009/table" xmlns:drawooo="http://openoffice.org/2010/draw"
            xmlns:calcext="urn:org:documentfoundation:names:experimental:calc:xmlns:calcext:1.0"
            xmlns:loext="urn:org:documentfoundation:names:experimental:office:xmlns:loext:1.0"
            xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0"
            xmlns:formx="urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:form:1.0" xmlns:css3t="http://www.w3.org/TR/css3-text/"
            office:version="1.2">

            <!-- Copy ODF elements before the body -->
            <xsl:copy-of select="$odfTemplate/office:body/preceding-sibling::*" copy-namespaces="no"/>

            <office:body>
                <office:text>
                    <!-- Copy ODF elements before the letterheadTemplate -->
                    <xsl:copy-of select="$letterheadTemplate/preceding-sibling::*" copy-namespaces="no"/>
                   
                    <!-- Set up document letterhead as per the template -->
                    <!--
                    <xsl:apply-templates select="$letterheadTemplate" mode="letterhead"/>
                    -->

                    <!-- Process the sections in the HTML content -->
                    <!--
                    <xsl:apply-templates select="//div[@class = 'ISO13606-Composition']/ul"/>
                    -->
                    
                    <xsl:apply-templates select="//img"/>

                </office:text>
            </office:body>
        </office:document-content>

    </xsl:template>

    <!-- Div - can be used as containers (e.g. tableContainer) so process children -->
    <xsl:template match="div">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- Paragraph - generally shouldn't contain anything useful, but just in case -->
    <xsl:template match="p">
        <xsl:apply-templates/>
    </xsl:template>


    <!-- === Lists with <ul>
        This HTML element is used to represent section, entry and element.
        The layout within the list is either Ranked or Unranked (for elements always Unranked) === -->

    <!-- Letterhead.
         This template matches letterhead content handed on from processing of the Word ML letter header
         The matches of ul in the letterhead will be the sections for HeaderTop, HeaderLeft, etc.
         Assuming that header sections do not have titles (may want to change that) then...
         Just need to process its children using the default templates -->
    <xsl:template match="ul" mode="letterhead">
        <!-- Output section header here is supported in the future -->
        <xsl:apply-templates mode="#default"/>
    </xsl:template>

    <!-- Ranked and Unranked Section.
         Section header is a w:p, then process contents,
         But only process when there is some content (these are designated by the class emptySection) -->
    <xsl:template match="ul[contains(@class, 'ISO13606-Section')]">
        <!-- Check for emptySection before processing -->
        <xsl:if test="not(contains(@class, 'emptySection'))">
            <xsl:variable name="rendition"
                select="
                    if (contains(@class, 'Standalone')) then
                        'Standalone'
                    else
                        ''"/>
            <xsl:variable name="hasDisplayName" select="exists(li[@class = 'ISO13606-Section-DisplayName'][descendant::text()])"/>
            <xsl:if test="$rendition = 'Standalone' or $hasDisplayName">
                <w:p>
                    <!-- Set up paragraph formatting for the section -->
                    <xsl:apply-templates select="$sectionTemplate/@*" mode="copy"/>
                    <xsl:apply-templates select="$sectionTemplate/w:pPr" mode="copy"/>
                    <!-- Insert page break -->
                    <xsl:if test="$rendition = 'Standalone'">
                        <w:r>
                            <w:br w:type="page"/>
                        </w:r>
                    </xsl:if>
                    <!-- Output section displayName, if there is one.
                 Copy format for text run from the template -->
                    <xsl:if test="$hasDisplayName">
                        <w:r>
                            <xsl:apply-templates select="$sectionTemplate/w:r/w:rPr" mode="copy"/>
                            <xsl:apply-templates select="li[@class = 'ISO13606-Section-DisplayName']"/>
                        </w:r>
                    </xsl:if>
                </w:p>
            </xsl:if>

            <!-- Process contents of Ranked amd Unranked section.
             This is handled differently for Ranked amd Unranked sections -->
            <!-- Ranked -->
            <xsl:apply-templates select="li[@class = 'Ranked']"/>

            <!-- Unranked -->
            <xsl:variable name="contentList" select="li[@class = 'Unranked']"/>
            <xsl:variable name="contentCount" select="count($contentList)"/>
            <xsl:call-template name="outputUnrankedSection">
                <xsl:with-param name="count" select="$contentCount"/>
                <xsl:with-param name="contentList" select="$contentList"/>
                <xsl:with-param name="widthRemaining" select="$tableWidth"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>


    <!-- Unranked Section 
         Output as a table -->
    <xsl:template name="outputUnrankedSection">
        <xsl:param name="count"/>
        <xsl:param name="contentList"/>
        <xsl:param name="widthRemaining"/>
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
                            <xsl:apply-templates select="."/>
                        </w:tc>
                    </xsl:for-each>
                </w:tr>
            </w:tbl>
        </xsl:if>
    </xsl:template>


    <!-- Entries are either ranked (series of paragraphs) or unranked (one paragraph with running text).
         Multiple entries have a maximum of two <li> elements - the first with the displayName (if present) the second with a table of entries.
         The table of multiple entries is in an <li> element with class MultipleEntry-->

    <xsl:template match="ul[@class = 'ISO13606-Entry'][descendant::text()]">
        <!-- Contents list contains displayName and elements for Ranked/Unranked entries -->
        <xsl:variable name="contentsList" select="li[not(@class = ('MultipleEntry', 'LayoutFooter'))]"/>
        <xsl:if test="not(empty($contentsList))">
            <w:p>
                <xsl:call-template name="outputParagraphStyle">
                    <xsl:with-param name="content" select="."/>
                </xsl:call-template>

                <!-- Process the displayName amd elements.
                 This handles all but the MultipleEntry table -->
                <xsl:apply-templates select="$contentsList"/>
            </w:p>
        </xsl:if>
        <!-- Now process MutlipleEntry -->
        <xsl:apply-templates select="li[@class = 'MultipleEntry']/*"/>
    </xsl:template>

    <!-- Displayname - Ranked, Unranked and MultipleEntry -->
    <xsl:template match="ul[@class = 'ISO13606-Entry']/li[contains(@class, 'ISO13606-Entry-DisplayName')][descendant::text()]">
        <w:r>
            <xsl:apply-templates/>
        </w:r>
    </xsl:template>

    <!-- Ranked entry - element/cluster contents - each element in the entry is on a new line -->
    <xsl:template
        match="ul[@class = 'ISO13606-Entry']/li[contains(@class, 'Ranked')][not(contains(@class, 'ISO13606-Entry-DisplayName'))][descendant::text()]">
        <!-- Output break before element -->
        <xsl:if test="preceding-sibling::li">
            <w:r>
                <w:br/>
            </w:r>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>


    <!-- Unranked entry - elements/clusters -->
    <xsl:template
        match="ul[@class = 'ISO13606-Entry']/li[contains(@class, 'Unranked')][not(contains(@class, 'ISO13606-Entry-DisplayName'))][descendant::text()]">
        <!-- Output space before element -->
        <xsl:if test="preceding-sibling::li">
            <w:r>
                <w:t xml:space="preserve"><xsl:text> </xsl:text></w:t>
            </w:r>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>


    <!-- Elements.
         Output displayName, value and units, but only if they have some text.
         Elements are within the w:p of their entry.
    -->
    <xsl:template match="ul[@class = 'ISO13606-Element']/li[@class != 'LayoutFooter'][descendant::text()]">
        <w:r>
            <!-- Output style for text runs -->
            <xsl:call-template name="outputTextRunStyle">
                <xsl:with-param name="content" select="."/>
            </xsl:call-template>
            <!-- Output the text nodes -->
            <xsl:apply-templates/>
            <!-- Output space after displayName -->
            <xsl:if test="@class = 'ISO13606-Element-DisplayName'">
                <w:t xml:space="preserve"><xsl:text> </xsl:text></w:t>
            </xsl:if>
        </w:r>
        <!-- Space after each component of the element -->
        <w:r>
            <w:t xml:space="preserve"><xsl:text> </xsl:text></w:t>
        </w:r>
    </xsl:template>

    <!-- Spacer for layout footer is ignored -->
    <xsl:template match="li[@class = 'LayoutFooter']"/>

    <!-- Empty entry header is ignored -->
    <xsl:template match="li[contains(@class, 'ISO13606-Entry-DisplayName')][empty(descendant::text())]"/>

    <!-- Multiple entry with single element, rendered as a list -->
    <xsl:template match="ul[@class = 'CDAEntryList']/li">
        <w:p>
            <xsl:call-template name="outputParagraphStyle">
                <xsl:with-param name="content" select="."/>
            </xsl:call-template>

            <xsl:apply-templates select="*"/>
        </w:p>
    </xsl:template>

    <!-- Tables -->
    <xsl:template match="table">
        <xsl:if test="true()">
            <w:tbl>
                <w:tblPr>
                    <w:tblW w:w="0" w:type="auto"/>
                </w:tblPr>
                <xsl:apply-templates/>
            </w:tbl>
        </xsl:if>
    </xsl:template>

    <xsl:template match="caption">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tbody">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tr">
        <w:tr>
            <xsl:apply-templates/>
        </w:tr>
    </xsl:template>

    <!-- Cells (th or td).
     Add span if there is a colspan -->
    <xsl:template match="th | td">
        <w:tc>
            <xsl:variable name="colspan" as="xs:integer"
                select="
                    if (exists(@colspan) and @colspan castable as xs:integer) then
                        xs:integer(@colspan)
                    else
                        0"/>
            <xsl:if test="$colspan gt 0">
                <w:tcPr>
                    <w:gridSpan w:val="{$colspan}"/>
                </w:tcPr>
            </xsl:if>
            <!-- Cell contains a paragraph and must have some content, even if the HTML cell is empty -->
            <w:p>
                <xsl:if test="not(exists(./*))">
                    <w:r>
                        <w:t/>
                    </w:r>
                </xsl:if>
                <xsl:apply-templates/>
            </w:p>
        </w:tc>
    </xsl:template>


    <!-- Images.
         The image meta data is stored in the global variable image-file-info
         This has height/width in pixels obtained from Orbeon directory scan of the files.
         
         cityEHRFunction:getImageInfo gets the height/width in pixels
         -->
    

    <xsl:template match="img"> 
    
        <text:p text:style-name="qr-wrapper">
            <draw:frame draw:name="img1" svg:width="{@width}pt" svg:height="{@height}pt">
                <draw:image xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad">
                    <office:binary-data>
                        <xsl:value-of select="substring-after(@src,'data:image/*;base64,')"/>
                    </office:binary-data>
                </draw:image>
            </draw:frame>
        </text:p>
        
    </xsl:template>



    <!-- Various HTML elements that need to have descendents proecssed -->
    <xsl:template match="tt">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="code">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="pre">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="b | strong">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="i | em">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="br">
        <xsl:text>&#xA;</xsl:text>
    </xsl:template>

    <!-- Span 
     Used for column headers in MultipleEntry with class="ISO13606-Element-DisplayName" 
     Needs a wrapper <w:r> in that case - may not need it in other cases if encountered later -->
    <xsl:template match="span">
        <w:r>
            <xsl:apply-templates/>
        </w:r>
    </xsl:template>


    <!-- Debug - Match all other nodes -->
    <!--
    <xsl:template match="node()">
        <w:t>
            <xsl:value-of select="name()"/>
        </w:t>
    </xsl:template>
    -->

    <!-- Match all text nodes -->
    <xsl:template match="text()">
        <xsl:if test="normalize-space() != ''">
            <w:t>
                <xsl:value-of select="normalize-space()"/>
            </w:t>
        </xsl:if>
    </xsl:template>


    <!-- === Templates for copying template letterhead without whitespace 
         These templates are used with the Word ML template letterhead as input
         The markers for HeaderTop, HeaderLeft, etc are replaced with content from the HTML
         All other Word ML is copied through to the output
    -->
    <!-- Ignore preferred width so that table will autosize -->
    <!--
    <xsl:template match="w:tcW" mode="letterhead" priority="1"/>
    -->

    <!-- Generate column widths, based on the left and right header.
         This will resize the columns to match the width of any image in these headers -->
    <xsl:template match="w:tblGrid" mode="letterhead" priority="1">
        <xsl:variable name="headerLeft" select="$headerContent/descendant::td[@class = 'HeaderLeft']/ul"/>
        <xsl:variable name="headerRight" select="$headerContent/descendant::td[@class = 'HeaderRight']/ul"/>

        <w:tblGrid>
            <xsl:call-template name="outputColumnSpecifications">
                <xsl:with-param name="count" select="2"/>
                <xsl:with-param name="contentList" select="($headerLeft, $headerRight)"/>
                <xsl:with-param name="widthRemaining" select="$tableWidth"/>
            </xsl:call-template>
        </w:tblGrid>
    </xsl:template>

    <!-- Header content (letterhead) 
         Get the type of the header section
         Get its content from the HTML
         Then output the WordML -->
    <xsl:template match="w:p[starts-with(w:r/w:t, 'cityEHR:letter:')]" mode="letterhead" priority="1">
        <!-- Get header section type -->
        <xsl:variable name="headerSection" select="substring-after(w:r/w:t, 'cityEHR:letter:')"/>
        <!-- Get header content from the HTML -->
        <xsl:variable name="content" select="$headerContent/descendant::td[@class = $headerSection]/ul"/>
        <!-- Output the content, including a test for empty content -->
        <xsl:call-template name="outputHeaderContent">
            <xsl:with-param name="content" select="$content"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Just copy other letterhead nodes -->
    <xsl:template match="text()" mode="letterhead" priority="1">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>

    <xsl:template match="node() | @*" mode="letterhead">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="letterhead"/>
        </xsl:copy>
    </xsl:template>



    <!-- Templates for copying any template content without whitespace -->
    <xsl:template match="text()" mode="copy" priority="1">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>

    <xsl:template match="node() | @*" mode="copy">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="copy"/>
        </xsl:copy>
    </xsl:template>


    <!-- == Function to return column width === -->
    <xsl:function name="cityEHRFunction:getColumnWidth">
        <xsl:param name="column"/>

        <xsl:variable name="imageWidth" select="$column//img/@width"/>
        <xsl:value-of
            select="
                if (exists($imageWidth[1])) then
                    $imageWidth[1]
                else
                    'proportional(1)'"
        />
    </xsl:function>

    <!-- == Function to return number of columns in a table === -->
    <xsl:function name="cityEHRFunction:getColumnCount">
        <xsl:param name="table"/>
        <xsl:value-of select="max($table/descendant::tr/count(td))"/>
    </xsl:function>

    <!-- Template to output column specifications.
         Called recursively to count the number of columns required.
         contentList is the set of content for each column (may be () if this is not available) -->
    <xsl:template name="outputColumnSpecifications">
        <xsl:param as="xs:integer" name="count"/>
        <xsl:param name="contentList"/>
        <xsl:param as="xs:double" name="widthRemaining"/>

        <xsl:variable name="contentImageWidths" select="cityEHRFunction:getImageWidth(contentList[1]/descendant::img)"/>

        <xsl:if test="$count gt 0">
            <xsl:variable name="columnWidth"
                select="
                    if (empty($contentImageWidths)) then
                        round($widthRemaining div $count)
                    else
                        round(max($contentImageWidths) * 20)"/>
            <w:gridCol w:w="{$columnWidth}"/>
            <xsl:variable name="nextCount" select="$count - 1"/>
            <xsl:variable name="nextWidthRemaining" select="$widthRemaining - $columnWidth"/>
            <xsl:call-template name="outputColumnSpecifications">
                <xsl:with-param name="count" select="$nextCount"/>
                <xsl:with-param name="contentList" select="$contentList[position() gt 1]"/>
                <xsl:with-param name="widthRemaining" select="$nextWidthRemaining"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- === Function to return image height/width 
        Explanation of the imaging sizing in MSWord is given at http://startbigthinksmall.wordpress.com/2010/01/04/points-inches-and-emus-measuring-units-in-office-open-xml/
        
        Word processes documents at a resolution of 72 dpi (i.e. 72 pixels per inch).
        The unit of measurement for images is the English Metric Unit (EMU).
        One inch equates to 914400 EMUs and a centimeter is 360000.
        So an image of size 100 x 50 pixels is (100/72)*914400 x (50/72)*914400 EMU. 
        Conveniently, 914400/72 = 12700.
        So to get the image size in EMU from pixels just multiply by 12700.
        i.e. 100 x 50 pixels is 1270000 x 635000 EMU
        
        At 72 dpi, 1px = 1pt
        On Windows resolution is 96dpi, so  
        
          === -->
    <xsl:function name="cityEHRFunction:getImageInfo">
        <xsl:param name="image-file-info"/>
        <xsl:param name="imageFileName"/>
        <xsl:param name="infoType"/>

        <xsl:variable name="emuMultiplier" as="xs:integer" select="12700"/>
        <xsl:variable name="imageDefaultSize" as="xs:integer" select="100"/>

        <xsl:variable name="imageMetaData" select="$image-file-info//file[@name = $imageFileName]/image-metadata/basic-info"/>
        <xsl:variable name="pixelSize"
            select="
                if (exists($imageMetaData)) then
                    $imageMetaData/*[name() = $infoType]
                else
                    $imageDefaultSize"/>
        <xsl:variable name="pointSize" select="$pixelSize * 72 div 96"/>
        <!--
       <xsl:value-of select="format-number($pixelSize * $emuMultiplier,'#')"/>
-->
        <xsl:value-of select="format-number($pointSize, '#####.####')"/>

    </xsl:function>


    <!-- === Function to return the list of image widths from a list of img elements
         === -->
    <xsl:function name="cityEHRFunction:getImageWidth">
        <xsl:param name="imgElementList"/>

        <xsl:for-each select="$imgElementList">
            <xsl:variable name="imageId" select="./@name"/>
            <xsl:variable name="imageFileName" select="concat($imageId, '.png')"/>
            <xsl:variable name="imageWidth" select="cityEHRFunction:getImageInfo($image-file-info, $imageFileName, 'width')"/>

            <xsl:value-of select="$imageWidth"/>
        </xsl:for-each>

    </xsl:function>

    <!-- === Template to output paragraph attributes and style.
         Find the context of the paragraph - either a header cell or the general document
         Set the template for the paragraph
         Output the template attributes
         Output the template w:pPr element
         
         Note that this template must be called immediately after output of a w:p 
         so that the template attributes are added to that element
        === -->

    <xsl:template name="outputParagraphStyle">
        <xsl:param name="content"/>

        <xsl:variable name="letterheadContext"
            select="('HeaderTop', 'HeaderLeft', 'HeaderRight', 'HeaderTarget', 'HeaderSupplement', 'HeaderSubject')"/>

        <xsl:variable name="headerContext" select="$content/ancestor::td[@class = $letterheadContext]/@class"/>

        <xsl:variable name="template"
            select="
                if ($headerContext) then
                    $letterheadTemplate/descendant::w:p[substring-after(w:r/w:t, $letterheadPrefix) = $headerContext]
                else
                    $paragraphTemplate"/>

        <xsl:apply-templates select="$template/@*" mode="copy"/>
        <xsl:apply-templates select="$template/w:pPr" mode="copy"/>

    </xsl:template>


    <!-- === Template to output text run attributes and style.
        Find the context of the text run - either a header cell or the general document
        Set the template for the text run
        Output the template attributes
        Output the template w:rPr element
        
        Note that this template must be called immediately after output of a w:r 
        so that the template attributes are added to that element
        === -->

    <xsl:template name="outputTextRunStyle">
        <xsl:param name="content"/>

        <xsl:variable name="letterheadContext"
            select="('HeaderTop', 'HeaderLeft', 'HeaderRight', 'HeaderTarget', 'HeaderSupplement', 'HeaderSubject')"/>

        <xsl:variable name="headerContext" select="$content/ancestor::td[@class = $letterheadContext]/@class"/>

        <xsl:variable name="template"
            select="
                if ($headerContext) then
                    $letterheadTemplate/descendant::w:r[substring-after(w:t, $letterheadPrefix) = $headerContext]
                else
                    $paragraphTemplate"/>

        <xsl:apply-templates select="$template/@*" mode="copy"/>
        <xsl:apply-templates select="$template/w:rPr" mode="copy"/>

    </xsl:template>


    <!-- === Template to output header content
         Used in table cells of the header, which must have content
         Tests whether content is empty and outputs empty paragraph if it is.
         Then outputs the content
         === -->

    <xsl:template name="outputHeaderContent">
        <xsl:param name="content"/>
        <xsl:if test="not(exists($content/*))">
            <w:p>
                <xsl:call-template name="outputParagraphStyle">
                    <xsl:with-param name="content" select="$content"/>
                </xsl:call-template>
                <w:r>
                    <w:t/>
                </w:r>
            </w:p>
        </xsl:if>
        <!-- This one does nothing if content is empty -->
        <xsl:apply-templates select="$content" mode="letterhead"/>
    </xsl:template>


    <!-- === Template to output the footer.
         The footer is a w:sectPr element which contains various page formatting.
        
         Just copy the footer - may do other stuff here in the future
        === -->
    <xsl:template name="outputFooter">
        <xsl:param name="footerTemplate"/>
        <xsl:apply-templates select="$footerTemplate" mode="copy"/>
    </xsl:template>


    <!-- === Template to output standard image set up
         === -->

    <xsl:template name="outputImageSetUp">
        <v:shapetype id="_x0000_t75" coordsize="21600,21600" o:spt="75" o:preferrelative="t" path="m@4@5l@4@11@9@11@9@5xe" filled="f" stroked="f">
            <v:stroke joinstyle="miter"/>
            <v:formulas>
                <v:f eqn="if lineDrawn pixelLineWidth 0"/>
                <v:f eqn="sum @0 1 0"/>
                <v:f eqn="sum 0 0 @1"/>
                <v:f eqn="prod @2 1 2"/>
                <v:f eqn="prod @3 21600 pixelWidth"/>
                <v:f eqn="prod @3 21600 pixelHeight"/>
                <v:f eqn="sum @0 0 1"/>
                <v:f eqn="prod @6 1 2"/>
                <v:f eqn="prod @7 21600 pixelWidth"/>
                <v:f eqn="sum @8 21600 0"/>
                <v:f eqn="prod @7 21600 pixelHeight"/>
                <v:f eqn="sum @10 21600 0"/>
            </v:formulas>
            <v:path o:extrusionok="f" gradientshapeok="t" o:connecttype="rect"/>
            <o:lock v:ext="edit" aspectratio="t"/>
        </v:shapetype>
    </xsl:template>

    <!-- === Template to output page break
    === -->

    <xsl:template name="outputPageBreak">
        <w:p>
            <w:r>
                <w:br w:type="page"/>
            </w:r>
        </w:p>
        <!--
        <w:p w:rsidR="00364CAC" w:rsidRDefault="00364CAC">
            <w:r>
                <w:lastRenderedPageBreak/>
                <w:t>cityEHR:letter:pagebreak</w:t>
            </w:r>
        </w:p>
        -->
    </xsl:template>

</xsl:stylesheet>
