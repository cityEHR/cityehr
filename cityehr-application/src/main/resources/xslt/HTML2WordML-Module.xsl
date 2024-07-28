<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    HTML2WordML-Module.xsl
    Input is an HTML document
    Root of the HTML document is html
    Generates wordML that forms the document.xml component of the .docx zip
    
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

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" xmlns:ve="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml"
    xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
    xmlns:wx="http://schemas.microsoft.com/office/word/2003/auxHint">

    <!-- Letterhead prefix is used to mark content in the Word template -->
    <xsl:variable name="letterheadPrefix" select="'cityEHR:letter:'"/>

    <!-- Get templates for the letterhead and other page set up -->
    <xsl:variable name="letterheadTemplate" select="$wordTemplate//w:body/w:tbl[1]"/>
    <xsl:variable name="tableWidth" select="$letterheadTemplate/w:tblGrid[1]/sum(w:gridCol/@w:w)"/>
    <xsl:variable name="footerTemplate" select="$wordTemplate//w:body/w:sectPr[w:footerReference][1]"/>
    <xsl:variable name="sectionTemplate" select="$wordTemplate/descendant::w:p[descendant::w:t = 'cityEHR:letter:Section'][1]"/>
    <xsl:variable name="paragraphTemplate" select="$wordTemplate/descendant::w:p[descendant::w:t = 'cityEHR:letter:Paragraph'][1]"/>
    <xsl:variable name="imageTemplate" select="$wordTemplate//w:pict[1]"/>

    <!-- Get the sections for the header -->
    <xsl:variable name="root" select="/"/>
    <xsl:variable name="headerContent" select="//div[@class = 'ISO13606-Composition']/table[@class = 'Header']"/>

    <!-- HTML root node -->
    <xsl:template match="html">
        <w:document xmlns:ve="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
            xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml"
            xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word"
            xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
            xmlns:wx="http://schemas.microsoft.com/office/word/2003/auxHint">
            <w:body>
                <!-- Set up document letterhead as per the template -->
                <xsl:apply-templates select="$letterheadTemplate" mode="letterhead"/>

                <!-- Process the sections in the HTML content -->
                <xsl:apply-templates select="//div[@class = 'ISO13606-Composition']/ul"/>

                <!-- Set up footer as per the template -->
                <xsl:call-template name="outputFooter">
                    <xsl:with-param name="footerTemplate" select="$footerTemplate"/>
                </xsl:call-template>
            </w:body>
        </w:document>

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
    <xsl:template match="imgX">
        <xsl:variable name="imageId" select="@name"/>
        <xsl:variable name="imageFileName" select="concat($imageId, '.png')"/>
        <xsl:variable name="imageWidth" select="cityEHRFunction:getImageInfo($image-file-info, $imageFileName, 'width')"/>
        <xsl:variable name="imageHeight" select="cityEHRFunction:getImageInfo($image-file-info, $imageFileName, 'height')"/>

        <!-- Toggle this true() / false() for debugging -->
        <xsl:if test="true()">
            <w:pict>
                <!-- Set up image as per the template -->
                <xsl:if test="not(empty($imageTemplate))">
                    <xsl:apply-templates select="$imageTemplate/v:shapetype" mode="copy"/>
                </xsl:if>
                <!-- Or use predefined image set up -->
                <xsl:if test="empty($imageTemplate)">
                    <xsl:call-template name="outputImageSetUp"/>
                </xsl:if>
                <!-- Output the actual image -->
                <xsl:variable name="style" select="concat('width:', $imageWidth, 'pt;height:', $imageHeight, 'pt')"/>
                <v:shape id="_x0000_i1025" type="#_x0000_t75" style="{$style}">
                    <v:imagedata r:id="{$imageId}" o:title="{$imageId}"/>
                </v:shape>
            </w:pict>
        </xsl:if>

        <xsl:if test="false()">
            <w:r>
                <w:t> Filename: <xsl:value-of select="$imageFileName"/>
                </w:t>
            </w:r>
            <w:r>
                <w:t> Height: <xsl:value-of select="$imageHeight"/>
                </w:t>
                <w:t> Width: <xsl:value-of select="$imageWidth"/>
                </w:t>
            </w:r>
        </xsl:if>
    </xsl:template>


    <xsl:template match="img">
        <w:drawing>
            <wp:anchor distT="0" distB="0" distL="114300" distR="114300" simplePos="0" relativeHeight="251658240" behindDoc="0" locked="0"
                layoutInCell="1" allowOverlap="1">
                <wp:simplePos x="1847850" y="914400"/>
                <wp:positionH relativeFrom="margin">
                    <wp:align>right</wp:align>
                </wp:positionH>
                <wp:positionV relativeFrom="margin">
                    <wp:align>top</wp:align>
                </wp:positionV>
                <wp:extent cx="2438400" cy="1828800"/>
                <wp:effectExtent l="19050" t="0" r="0" b="0"/>
                <wp:wrapSquare wrapText="bothSides"/>
                <wp:docPr id="1" name="Picture 0" descr="Blue hills.jpg"/>
                <wp:cNvGraphicFramePr>
                    <a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/>
                </wp:cNvGraphicFramePr>
                <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
                    <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
                        <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">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"</pic:pic>
                    </a:graphicData>
                </a:graphic>
            </wp:anchor>
        </w:drawing>
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
