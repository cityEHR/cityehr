<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================    
    HTML2FO-Module.xsl
    
    Input is an HTML document
    Root of the HTML document is html
    Generates XSL-FO to be transformed to PDF/RTF by FOP
      
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
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <!-- Document element -->
    <xsl:variable name="root" select="/*[1]"/>

    <!-- === Set variables found in meta elements in the HTML head === -->
    <!-- Patient demographics  -->
    <xsl:variable name="patientId"
        select="
            if (exists(//head/meta[@name = 'patientId'])) then
                //head/meta[@name = 'patientId']/@content
            else
                ''"/>
    <xsl:variable name="patientFamily"
        select="
            if (exists(//head/meta[@name = 'patientFamily'])) then
                //head/meta[@name = 'patientFamily']/@content
            else
                ''"/>
    <xsl:variable name="patientGiven"
        select="
            if (exists(//head/meta[@name = 'patientGiven'])) then
                //head/meta[@name = 'patientGiven']/@content
            else
                ''"/>
    <xsl:variable name="patientPrefix"
        select="
            if (exists(//head/meta[@name = 'patientPrefix'])) then
                //head/meta[@name = 'patientPrefix']/@content
            else
                ''"/>
    <xsl:variable name="patientAdministrativeGenderCode"
        select="
            if (exists(//head/meta[@name = 'patientAdministrativeGenderCode'])) then
                //head/meta[@name = 'patientAdministrativeGenderCode']/@content
            else
                ''"/>
    <xsl:variable name="patientBirthTime"
        select="
            if (exists(//head/meta[@name = 'patientBirthTime'])) then
                //head/meta[@name = 'patientBirthTime']/@content
            else
                ''"/>

    <!-- Application, Specialty and Composition for this HTML Document. -->
    <xsl:variable name="applicationIRI"
        select="
            if (exists(//head/meta[@name = 'applicationIRI'])) then
                //head/meta[@name = 'applicationIRI']/@content
            else
                ''"/>
    <xsl:variable name="specialtyIRI"
        select="
            if (exists(//head/meta[@name = 'specialtyIRI'])) then
                //head/meta[@name = 'specialtyIRI']/@content
            else
                ''"/>
    <xsl:variable name="compositionIRI"
        select="
            if (exists(//head/meta[@name = 'compositionIRI'])) then
                //head/meta[@name = 'compositionIRI']/@content
            else
                ''"/>

    <!-- Header and footer text -->
    <xsl:variable name="headerText"
        select="
            if (exists(//head/meta[@name = 'headerText'])) then
                //head/meta[@name = 'headerText']/@content
            else
                ''"/>
    <xsl:variable name="footerText"
        select="
            if (exists(//head/meta[@name = 'footerText'])) then
                //head/meta[@name = 'footerText']/@content
            else
                ''"/>
    <xsl:variable name="pagePrefix"
        select="
            if (exists(//head/meta[@name = 'pagePrefix'])) then
                //head/meta[@name = 'footerText']/@content
            else
                '[ '"/>
    <xsl:variable name="pageConjunction"
        select="
            if (exists(//head/meta[@name = 'pageConjunction'])) then
                //head/meta[@name = 'footerText']/@content
            else
                ' / '"/>
    <xsl:variable name="pageSuffix"
        select="
            if (exists(//head/meta[@name = 'pageSuffix'])) then
                //head/meta[@name = 'footerText']/@content
            else
                ' ]'"/>

    <!-- Variables for page size -->
    <xsl:variable name="pagewidth" select="21"/>
    <xsl:variable name="pageheight" select="29.7"/>
    <xsl:variable name="marginleft" select="2.5"/>
    <xsl:variable name="marginright" select="2.5"/>

    <!-- HTML root node -->
    <xsl:template name="generate-fo">

        <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
            <fo:layout-master-set>
                <!-- fo:layout-master-set defines in its children the page layout:
                    the pagination and layout specifications
                    - page-masters: have the role of describing the intended subdivisions
                    of a page and the geometry of these subdivisions
                    In this case there is only a simple-page-master which defines the
                    layout for all pages of the text
                -->
                <!-- layout information -->
                <fo:simple-page-master master-name="simple" page-height="{$pageheight}cm"
                    page-width="{$pagewidth}cm" margin-top="1.3" margin-bottom="1cm"
                    margin-left="{$marginleft}cm" margin-right="{$marginright}cm">
                    <fo:region-body margin-top="2cm" margin-bottom="1cm"/>
                    <fo:region-before extent="1.2cm"/>
                    <fo:region-after extent="1cm"/>
                </fo:simple-page-master>
            </fo:layout-master-set>
            <!-- end: defines page layout -->


            <!-- start page-sequence
                here comes the text (contained in flow objects)
                the page-sequence can contain different fo:flows
                the attribute value of master-name refers to the page layout
                which is to be used to layout the text contained in this
                page-sequence-->
            <fo:page-sequence master-reference="simple">

                <!-- start fo:flow
                    each flow is targeted
                    at one (and only one) of the following:
                    xsl-region-body (usually: normal text)
                    xsl-region-before (usually: header)
                    xsl-region-after (usually: footer)
                    xsl-region-start (usually: left margin)
                    xsl-region-end (usually: right margin)
                    ['usually' applies here to languages with left-right and top-down
                    writing direction like English]
                    in this case there is only one target: xsl-region-body
                -->
                <!--                
                    <fo:flow flow-name="xsl-region-before">
                    <fo:block font-weight="bold">
                    NHS Number: <xsl:value-of select="$demographicsDoc/demographics:NHSNumber"/>
                    </fo:block>                   
                    </fo:flow>
                -->
                <!--
                    <fo:flow flow-name="xsl-region-after">
                    <fo:block font-weight="bold">
                    Page x of X
                    </fo:block>                   
                    </fo:flow>
                -->

                <!-- Header
                 Show patient info if this is patient-specific data.
                 Plus header text -->
                <fo:static-content flow-name="xsl-region-before">
                    <!-- Patient specific info -->
                    <xsl:if test="$patientId != ''">
                        <fo:table>
                            <fo:table-body>
                                <fo:table-row>
                                    <fo:table-cell>
                                        <fo:block text-align="left" font-size="10pt">
                                            <xsl:value-of select="$patientId"/>
                                        </fo:block>
                                    </fo:table-cell>
                                    <fo:table-cell>
                                        <fo:block text-align="right" font-size="10pt">
                                            <xsl:if test="$patientFamily">
                                                <xsl:value-of select="$patientFamily"/>
                                            </xsl:if>
                                            <xsl:if test="$patientFamily and $patientGiven">
                                                <xsl:text> / </xsl:text>
                                                <xsl:value-of select="$patientGiven"/>
                                            </xsl:if>
                                        </fo:block>
                                    </fo:table-cell>
                                </fo:table-row>
                            </fo:table-body>
                        </fo:table>
                    </xsl:if>

                    <!-- Header text -->
                    <fo:block text-align="left" font-size="10pt" space-before="1em">
                        <xsl:value-of select="$headerText"/>
                    </fo:block>

                    <!-- Horizontal border on header -->
                    <fo:block>
                        <fo:leader leader-pattern="rule" leader-length.optimum="100%"
                            rule-style="double" rule-thickness="1pt"/>
                    </fo:block>
                </fo:static-content>

                <fo:static-content flow-name="xsl-region-after">

                    <!-- Horizontal border on footer -->
                    <fo:block>
                        <fo:leader leader-pattern="rule" leader-length.optimum="100%"
                            rule-style="double" rule-thickness="1pt"/>
                    </fo:block>

                    <fo:table>
                        <fo:table-body>

                            <fo:table-row>
                                <!-- Footer test -->
                                <fo:table-cell>
                                    <fo:block text-align="left" font-size="10pt">
                                        <xsl:value-of select="$footerText"/>
                                    </fo:block>
                                </fo:table-cell>

                                <!-- Page info -->
                                <fo:table-cell>
                                    <fo:block text-align="right" font-size="10pt">
                                        <xsl:value-of select="$pagePrefix" xml:space="preserve"/>
                                        <fo:page-number/>
                                        <xsl:value-of select="$pageConjunction" xml:space="preserve"/>
                                        <fo:page-number-citation ref-id="last-page"/>
                                        <xsl:value-of select="$pageSuffix" xml:space="preserve"/>
                                    </fo:block>
                                </fo:table-cell>
                            </fo:table-row>
                        </fo:table-body>
                    </fo:table>
                </fo:static-content>

                <!-- Now process the content of the HTML -->
                <fo:flow flow-name="xsl-region-body" font-family="serif" font-size="10pt">
                    <xsl:apply-templates select="$root"/>
                    <fo:block id="last-page"/>
                </fo:flow>

            </fo:page-sequence>

        </fo:root>
    </xsl:template>

    <!-- Content is exceptions, not HTML.
         This happens if there was an exception in the pipeline that calls the transformation -->
    <xsl:template match="exceptions">
        <fo:block font-size="12pt" font-weight="bold" space-before="1em">
            <fo:block font-size="12pt" font-weight="bold" space-before="1em">
                <xsl:value-of
                    select="normalize-space($parameters/printPipeline/printText/text[@type = 'errorMessage']/@displayName)"
                />
            </fo:block>
            <fo:block font-size="12pt" font-weight="bold" space-before="1em">
                <xsl:value-of select="$parameters/htmlCacheHandle"/>
            </fo:block>
        </fo:block>
    </xsl:template>


    <!-- Html just passes through - content is matched by templates below -->
    <xsl:template match="html">
        <xsl:apply-templates/>
    </xsl:template>


    <!-- Head/Title -->
    <!--
        <xsl:template match="head/title">
        <fo:static-content flow-name="xsl-region-before">
        <fo:block font-family="serif" font-size="10pt" text-align="center">
        <xsl:value-of select="."/>
        </fo:block>
        </fo:static-content>
        
        <fo:static-content flow-name="xsl-region-after">
        <fo:block font-family="serif" font-size="10pt" text-align="center"> Page <fo:page-number/>
        </fo:block>
        </fo:static-content>
        </xsl:template>
    -->


    <!-- Body just passes through - this means the HTML does not need to contain head/body elements -->
    <xsl:template match="body">
        <xsl:apply-templates/>
    </xsl:template>

    <!--
    <xsl:template match="blockquote">
        <fo:block space-before="6pt" space-after="6pt" margin-left="2em" margin-right="2em">
            <xsl:call-template name="set-pagebreak"/>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="h1">
        <fo:block font-size="18pt">
            <xsl:call-template name="set-alignment"/>
            <xsl:call-template name="set-pagebreak"/>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="h2">
        <fo:block font-size="14pt">
            <xsl:call-template name="set-alignment"/>
            <xsl:call-template name="set-pagebreak"/>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="h3">
        <fo:block font-size="12pt" font-weight="bold" space-before="6pt">
            <xsl:call-template name="set-alignment"/>
            <xsl:call-template name="set-pagebreak"/>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="h4">
        <fo:block font-weight="bold" space-before="1mm">
            <xsl:call-template name="set-alignment"/>
            <xsl:call-template name="set-pagebreak"/>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    
    -->

    <xsl:template name="set-alignment">
        <xsl:choose>
            <xsl:when test="@align = 'left' or contains(@class, 'left')">
                <xsl:attribute name="text-align">start</xsl:attribute>
            </xsl:when>
            <xsl:when test="@align = 'center' or contains(@class, 'center')">
                <xsl:attribute name="text-align">center</xsl:attribute>
            </xsl:when>
            <xsl:when test="@align = 'right' or contains(@class, 'right')">
                <xsl:attribute name="text-align">end</xsl:attribute>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="set-pagebreak">
        <xsl:if test="contains(@style, 'page-break-before')">
            <xsl:attribute name="break-before">page</xsl:attribute>
        </xsl:if>
        <xsl:if test="contains(@style, 'page-break-after')">
            <xsl:attribute name="break-after">page</xsl:attribute>
            <xsl:message>
                <xsl:value-of select="@style"/>
            </xsl:message>
        </xsl:if>
    </xsl:template>

    <!-- There is one div in the CDA HTML of class="ISO13606-Composition"
         Plus, can be used as containers (e.g. tableContainer) so process children -->
    <xsl:template match="div">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- Paragraphs just get passed through, unless they are for an error message -->
    <xsl:template match="p[@class = 'errorMessage']">
        <fo:block font-size="12pt" font-weight="bold" space-before="1em">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="p">
        <fo:block>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>


    <!-- === Lists with <ul>
        This HTML element is used to represent section, entry and element.
        The layout within the list is either Ranked or Unranked (for elements always Unranked) === -->

    <!-- Sections are ranked (block) or unranked (table) -->
    <!-- Ranked -->
    <xsl:template match="ul[contains(@class, 'ISO13606-Section')][li/@class = 'Ranked']">
        <xsl:variable name="rendition"
            select="
                if (contains(@class, 'Standalone')) then
                    'Standalone'
                else
                    ''"/>
        <fo:block>
            <xsl:if test="$rendition = 'Standalone'">
                <xsl:attribute name="page-break-before">
                    <xsl:value-of select="'always'"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="$rendition != 'Standalone'">
                <xsl:attribute name="space-before">
                    <xsl:value-of select="'1em'"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    <xsl:template match="ul[contains(@class, 'ISO13606-Section')]/li[@class = 'Ranked']">
        <fo:block>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    <xsl:template
        match="ul[contains(@class, 'ISO13606-Section')][li/@class = 'Ranked']/li[@class = 'ISO13606-Section-DisplayName']">
        <fo:block font-size="12pt" font-weight="bold" space-before="1em">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <!-- Unranked -->
    <xsl:template
        match="ul[contains(@class, 'ISO13606-Section')][li/@class = 'Unranked'][descendant::text()]">
        <xsl:variable name="rendition"
            select="
                if (contains(@class, 'Standalone')) then
                    'Standalone'
                else
                    ''"/>
        <fo:block>
            <xsl:if test="$rendition = 'Standalone'">
                <xsl:attribute name="page-break-before">
                    <xsl:value-of select="'always'"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="$rendition != 'Standalone'">
                <xsl:attribute name="space-before">
                    <xsl:value-of select="'1em'"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:for-each select="li[@class = 'ISO13606-Section-DisplayName']">
                <fo:block font-size="12pt" font-weight="bold" space-before="1em">
                    <xsl:value-of select="."/>
                </fo:block>
            </xsl:for-each>

            <fo:table>
                <xsl:for-each select="li[@class = 'Unranked']">
                    <xsl:variable name="column" select="."/>
                    <fo:table-column column-width="{cityEHRFunction:getColumnWidth($column)}"/>
                </xsl:for-each>
                <fo:table-body>
                    <fo:table-row>
                        <!-- Always need each cell, even if empty -->
                        <xsl:for-each select="li[contains(@class, 'Unranked')]">
                            <fo:table-cell>
                                <fo:block>
                                    <xsl:apply-templates/>
                                </fo:block>
                            </fo:table-cell>
                        </xsl:for-each>
                    </fo:table-row>
                </fo:table-body>
            </fo:table>
        </fo:block>
    </xsl:template>


    <!-- Entries are either ranked (blocks) or unranked (inline) -->
    <!-- Ranked entry -->
    <xsl:template match="ul[contains(@class,'ISO13606-Entry')][li/@class = 'Ranked'][descendant::text()]">
        <fo:block space-before="1em">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    <!-- This matches elements where there is an entry displayName but not the displayName itself -->
    <xsl:template match="ul[contains(@class,'ISO13606-Entry')]/li[@class = 'Ranked'][descendant::text()]">
        <fo:block space-before="0.2em">
            <!-- Indent elements if there is a displayName for the entry -->
            <xsl:if
                test="preceding-sibling::li[@class = 'ISO13606-Entry-DisplayName Ranked'][descendant::text()]">
                <xsl:attribute name="margin-left">
                    <xsl:value-of select="'1em'"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    <!-- Unranked -->
    <xsl:template match="ul[contains(@class,'ISO13606-Entry')][li/@class = 'Unranked'][descendant::text()]">
        <fo:block space-before="0.5em">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    <xsl:template
        match="ul[contains(@class,'ISO13606-Entry')]/li[contains(@class, 'Unranked')][descendant::text()]">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- Multiple entries are rendered as tables, except when there is only one element, in which case a ranked list is used -->
    <xsl:template match="ul[@class = 'CDAEntryList'][descendant::text()]">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="ul[@class = 'CDAEntryList']/li[descendant::text()]">
        <fo:block space-before="1em">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>



    <!-- Elements -->
    <xsl:template
        match="ul[@class = 'ISO13606-Element']/li[@class != 'LayoutFooter'][descendant::text()]">
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template
        match="ul[@class = 'ISO13606-Element']/li[@class='ISO13606-Element-DisplayName'][descendant::text()]">
        <fo:inline font-style="italic">
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>
    <xsl:template
        match="ul[@class = 'ISO13606-Element']/li[contains(@class,'ISO13606-Data')][descendant::text()]">
        <fo:inline font-weight="bold">
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>

    <!-- Spacer for layout footer is ignored -->
    <xsl:template match="li[@class = 'LayoutFooter']"/>

    <!-- Empty entry header is ignored -->
    <xsl:template
        match="li[contains(@class, 'ISO13606-Entry-DisplayName')][empty(descendant::text())]"/>

    <!-- Table.
         xsl-fo (or FOP) doesn't like empty table elements, 
         so make sure there is content in the HTML elements before processing them.
         An empty block is OK - so need to get down to that level before leaving empty content.
         Only process tables that have thead and/or tbody - otherwise ignore -->
    <xsl:template match="table[thead or tbody]">
        <fo:table>
            <!-- Output column specifications, but only if there are specifications in the HTML -->
            <xsl:if test="exists(col)">
                <xsl:call-template name="generate-column-specifications">
                    <xsl:with-param name="table" select="."/>
                </xsl:call-template>
            </xsl:if>
            <xsl:apply-templates/>
        </fo:table>
    </xsl:template>

    <xsl:template match="caption">
        <fo:caption>
            <fo:block>
                <xsl:apply-templates/>
            </fo:block>
        </fo:caption>
    </xsl:template>

    <!-- thead with some content -->
    <xsl:template match="thead[tr/th or tr/td]">
        <fo:table-header>
            <xsl:apply-templates/>
        </fo:table-header>
    </xsl:template>

    <!-- thead with no content -->
    <xsl:template match="thead[not(tr/th or tr/td)]">
        <fo:table-body>
            <fo:table-row>
                <fo:table-cell>
                    <fo:block/>
                </fo:table-cell>
            </fo:table-row>
        </fo:table-body>
    </xsl:template>

    <!-- tbody with some content -->
    <xsl:template match="tbody[tr/td]">
        <fo:table-body>
            <xsl:apply-templates/>
        </fo:table-body>
    </xsl:template>

    <!-- tbody with no content -->
    <xsl:template match="tbody[not(tr/td)]">
        <fo:table-body>
            <fo:table-row>
                <fo:table-cell>
                    <fo:block/>
                </fo:table-cell>
            </fo:table-row>
        </fo:table-body>
    </xsl:template>

    <!-- tr with some content -->
    <xsl:template match="tr[th | td]">
        <fo:table-row>
            <xsl:if test="@space-before != ''">
                <xsl:attribute name="space-before">
                    <xsl:value-of select="@space-before"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="../thead">
                <xsl:attribute name="background-color">#ddd</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </fo:table-row>
    </xsl:template>

    <!-- tr with no content -->
    <xsl:template match="tr[not(th | td)]">
        <fo:table-row>
            <fo:table-cell>
                <fo:block/>
            </fo:table-cell>
        </fo:table-row>
    </xsl:template>

    <xsl:template match="th">
        <fo:table-cell font-weight="bold" background-color="#ddd">
            <xsl:if test="ancestor::table/@border &gt; 0">
                <xsl:attribute name="border-style">solid</xsl:attribute>
                <xsl:attribute name="border-width">1pt</xsl:attribute>
            </xsl:if>
            <fo:block>
                <xsl:apply-templates/>
            </fo:block>
        </fo:table-cell>
    </xsl:template>

    <xsl:template match="td">
        <fo:table-cell>
            <xsl:if test="ancestor::table/@border &gt; 0">
                <xsl:attribute name="border-style">solid</xsl:attribute>
                <xsl:attribute name="border-width">1pt</xsl:attribute>
            </xsl:if>
            <fo:block>
                <xsl:apply-templates/>
            </fo:block>
        </fo:table-cell>
    </xsl:template>

    <!-- Other block elements -->
    <xsl:template match="tt">
        <fo:inline font-family="monospace">
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>

    <xsl:template match="code">
        <fo:inline font-family="monospace">
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>

    <xsl:template match="img">
        <xsl:variable name="src"
            select="
                if (starts-with(@src, 'url')) then
                    @src
                else
                    if (starts-with(@src, 'data:image/*')) then
                        concat('data:image/png', substring-after(@src, 'data:image/*'))
                    else
                        if (starts-with(@src, 'data:image')) then
                            @src
                        else
                            concat('url(''', @src, ''')')"/>
        <xsl:variable name="content-width"
            select="
                if (exists(@width)) then
                    @width
                else
                    'scale-to-fit'"/>
        <xsl:variable name="content-height"
            select="
                if (exists(@height)) then
                    @height
                else
                    '100%'"/>
        <!--
        <fo:external-graphic width="100%" src="{$src}" content-width="{$content-width}" scaling="uniform" content-height="{$content-height}"/>
-->
        <fo:external-graphic src="{$src}"/>
        <!-- Debugging -->
        <!--
        <xsl:value-of select="$src"/>
        <xsl:value-of select="$content-height"/>
        <xsl:value-of select="$content-width"/>
-->
    </xsl:template>

    <xsl:template match="pre">
        <fo:block white-space-collapse="false" font-family="monospace" font-size="10pt">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="b | strong">
        <fo:inline font-weight="bold">
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>

    <xsl:template match="i | em">
        <fo:inline font-style="italic">
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>

    <xsl:template match="hr">
        <fo:block>
            <fo:leader leader-pattern="rule" leader-length.optimum="100%" rule-style="double"
                rule-thickness="1pt"/>
        </fo:block>
    </xsl:template>

    <xsl:template match="br">
        <fo:block>
            <xsl:text>&#xA;</xsl:text>
        </fo:block>
    </xsl:template>

    <xsl:template match="span">
        <xsl:apply-templates/>
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


    <!-- == Find width - not used === -->
    <xsl:template name="find-width">
        <xsl:param name="node"/>
        <xsl:choose>
            <xsl:when test="@width">
                <xsl:value-of select="@width"/>
            </xsl:when>
            <xsl:when test="@style">
                <xsl:value-of
                    select="
                        substring-before(
                        substring-after(@style, ':'), ';')"
                />
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- == Generate column specifications
            Uses recursive template to generate the set of fo:table-column elements
            === -->
    <xsl:template name="generate-column-specifications">
        <xsl:param name="table"/>
        <!-- Number of columns -->
        <xsl:variable name="columnCount"
            select="max(($table/descendant::tr/count(td), $table/descendant::tr/count(th)))"/>
        <!-- Specified columns - note that this list may be empty -->
        <xsl:variable name="columnWidthList" select="$table/col/@width[. castable as xs:double]"/>
        <xsl:variable name="specifiedColumnCount" select="count($columnWidthList)"/>
        <xsl:variable name="totalColumnWidth" select="sum($columnWidthList)"/>
        <xsl:variable name="defaultColumnWidth"
            select="
                if (exists($columnWidthList)) then
                    min($columnWidthList)
                else
                    1"/>
        <xsl:variable name="columnWidthUnit"
            select="($pagewidth - $marginleft - $marginright) div ($totalColumnWidth + ($columnCount - $specifiedColumnCount) * $defaultColumnWidth)"/>

        <xsl:if test="$columnCount gt 0">
            <xsl:call-template name="output-table-column">
                <xsl:with-param name="columnWidthList" select="$columnWidthList"/>
                <xsl:with-param name="columnWidthUnit" select="$columnWidthUnit"/>
                <xsl:with-param name="defaultColumnWidth" select="$defaultColumnWidth"/>
                <xsl:with-param name="columnNumber" select="1"/>
                <xsl:with-param name="columnCount" select="$columnCount"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="output-table-column">
        <xsl:param name="columnWidthList"/>
        <xsl:param name="columnWidthUnit"/>
        <xsl:param name="defaultColumnWidth"/>
        <xsl:param name="columnNumber"/>
        <xsl:param name="columnCount"/>

        <xsl:variable name="nextColumnNumber" select="$columnNumber + 1"/>

        <xsl:variable name="specifiedColumnWidth"
            select="$columnWidthList[position() = $columnNumber]"/>
        <xsl:variable name="proportionalColumnWidth"
            select="
                if (exists($specifiedColumnWidth)) then
                    $specifiedColumnWidth
                else
                    $defaultColumnWidth"/>
        <xsl:variable name="columnWidth"
            select="number($columnWidthUnit) * number($proportionalColumnWidth)"/>

        <fo:table-column column-width="{$columnWidth}cm" column-number="{$columnNumber}"/>

        <xsl:if test="$nextColumnNumber le $columnCount">
            <xsl:call-template name="output-table-column">
                <xsl:with-param name="columnWidthList" select="$columnWidthList"/>
                <xsl:with-param name="columnWidthUnit" select="$columnWidthUnit"/>
                <xsl:with-param name="defaultColumnWidth" select="$defaultColumnWidth"/>
                <xsl:with-param name="columnNumber" select="$nextColumnNumber"/>
                <xsl:with-param name="columnCount" select="$columnCount"/>
            </xsl:call-template>
        </xsl:if>

    </xsl:template>

</xsl:stylesheet>
