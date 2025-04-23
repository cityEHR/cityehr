<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    CDA2HTML-Module.xsl
    Input is a CDA document
    Root of the CDA document is cda:ClinicalDocument
    Generates HTML to be displayed in CityEHR
    
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
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <!-- === Global Variables ===============================================================================
         Set here for both CDA2HTML and CDA2HTMLFile
         ==================================================================================================== -->
    <!-- Set global variable to toggle display of the CDA Header -->
    <xsl:variable name="outputHeader" select="'no'"/>

    <!-- Set externalId -->
    <xsl:variable name="externalId" select="$session-parameters/externalId"/>

    <!-- Set global variable for viewHistory (current|historic) -->
    <xsl:variable name="viewHistory"
        select="
            if ($session-parameters/viewHistory = 'historic') then
                'historic'
            else
                'current'"/>

    <!-- A complete CDA document has a document element of cda:ClinicalDocument
         But this stylesheet may also be used to transform cda:entry embedded in a patient data set
         So we can't assume that the cda:ClinicalDocument exists -->
    <xsl:variable name="ClinicalDocument" select="//cda:ClinicalDocument"/>

    <!-- Set global variable to differentiate output display of events and views 
         Views are either of type Folder or Composition. Otherwise outputType is Event -->
    <xsl:variable name="outputType"
        select="
            if (//cda:ClinicalDocument/cda:id/@extension = 'cityEHR:Folder') then
                'Folder'
            else
                (if (//cda:ClinicalDocument/cda:id/@extension = 'cityEHR:Composition') then
                    'Composition'
                else
                    'Event')"/>

    <!-- Set the Application and Specialty for this CDA Document.
        These are found in the cda element:
        <templateId root="#ISO-13606:EHR_Extract:Elfin" extension="#ISO-13606:Folder:NOC"/> 
        Which is a child of the ClinicalDocument element -->
    <xsl:variable name="applicationIRI" select="//cda:ClinicalDocument/cda:templateId/@root"/>
    <xsl:variable name="specialtyIRI" select="//cda:ClinicalDocument/cda:templateId/@extension"/>

    <!-- Set locations to mirror the exist database collections -->
    <xsl:variable name="applicationLocation"
        select="replace(substring($applicationIRI, 2), ':', '-')"/>
    <xsl:variable name="specialtyLocation" select="replace(substring($specialtyIRI, 2), ':', '-')"/>

    <!-- Get the composition for this CDA document.
        This is found in the cda element:
        <typeId root="cityEHR" extension="#CityEHR:Letter:patientletter"/>
        Which is a child of the ClinicalDocument element
    -->
    <xsl:variable name="compositionIRI" select="//cda:ClinicalDocument[1]/cda:typeId/@extension"/>
    <xsl:variable name="compositionDisplayName"
        select="//cda:ClinicalDocument[1]/cda:code[@codeSystem = 'cityEHR']/@displayName"/>
    <xsl:variable name="compositionEffectiveTime"
        select="//cda:ClinicalDocument[1]/cda:effectiveTime/@value"/>

    <!-- Get patient demographics -->
    <xsl:variable name="patientId"
        select="//cda:ClinicalDocument[1]/cda:recordTarget/cda:patientRole/cda:id/@extension"/>
    <xsl:variable name="patientGiven"
        select="//cda:ClinicalDocument[1]/cda:recordTarget/cda:patientRole/cda:patient/cda:name/cda:given"/>
    <xsl:variable name="patientFamily"
        select="//cda:ClinicalDocument[1]/cda:recordTarget/cda:patientRole/cda:patient/cda:name/cda:family"/>
    <xsl:variable name="patientPrefix"
        select="//cda:ClinicalDocument[1]/cda:recordTarget/cda:patientRole/cda:patient/cda:name/cda:prefix"/>
    <xsl:variable name="patientAdministrativeGenderCode"
        select="//cda:ClinicalDocument[1]/cda:recordTarget/cda:patientRole/cda:patient/cda:administrativeGenderCode/@displayName"/>
    <xsl:variable name="patientBirthTime"
        select="//cda:ClinicalDocument[1]/cda:recordTarget/cda:patientRole/cda:patient/cda:birthTime/@value"/>


    <!-- === Render the HTML <head> element ==================================================
             Including meta elements to hold data on the application, specialty and cda header
         ===================================================================================== -->
    <xsl:template name="renderHTMLHead">
        <head>
            <link rel="stylesheet" type="text/css" href="../styles/cityEHR.css" media="screen"/>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            <meta name="externalId" content="{$externalId}"/>
            <meta name="applicationIRI" content="{$applicationIRI}"/>
            <meta name="specialtyIRI" content="{$specialtyIRI}"/>
            <meta name="compositionIRI" content="{$compositionIRI}"/>
            <meta name="compositionDisplayName" content="{$compositionDisplayName}"/>
            <meta name="compositionEffectiveTime" content="{$compositionEffectiveTime}"/>
            <meta name="patientId" content="{$patientId}"/>
            <meta name="patientGiven" content="{$patientGiven}"/>
            <meta name="patientFamily" content="{$patientFamily}"/>
            <meta name="patientPrefix" content="{$patientPrefix}"/>
            <meta name="patientAdministrativeGenderCode"
                content="{$patientAdministrativeGenderCode}"/>
            <meta name="patientBirthTime" content="{$patientBirthTime}"/>

            <meta name="headerText"
                content="{concat($compositionEffectiveTime,' - ', $compositionDisplayName)}"/>
            <meta name="footerText" content="{concat($patientId,' / ', $patientFamily)}"/>
        </head>
    </xsl:template>


    <!-- ===  Match cda:ClinicalDocument to output the CDA document =========================================
        Iterates through the sections of the document calling template to render each one.
        There may be multiple cda:ClinicalDocument for Folder views.
        ===================================================================================================== -->
    <xsl:template match="cda:ClinicalDocument">
        <xsl:variable name="compositionCount" as="xs:integer"
            select="count(preceding::cda:ClinicalDocument) + 1"/>
        <!-- Debugging -->
        <!--
        <p class="message"> Output type: <xsl:value-of select="$outputType"/><br/> View history:
                <xsl:value-of select="$viewHistory"/>
        </p>
-->

        <!-- Only output multiple compositions for Folder views, showing historic data.
             This means that for Folder views showing 'current' data only the first match on this template is used. -->
        <xsl:if
            test="$compositionCount = 1 or ($outputType = 'Folder' and $viewHistory = 'historic')">

            <div class="ISO-13606:Composition">
                <!-- Iterate through sections of the form.
             This template has matched cda:ClinicalDocument, so iteration is relative to that. 
             alwaysHidden sections do not need to be rendered. -->

                <!-- Output composition title if this is a folder view (i.e. can have multiple compositions) -->
                <xsl:if test="$outputType = 'Folder'">
                    <xsl:variable name="effectiveTime" select="cda:effectiveTime/@value"/>
                    <xsl:variable name="crossRefId"
                        select="concat('Composition-', $compositionCount)"/>

                    <ul class="ISO13606-Section" id="{$crossRefId}">
                        <li class="ISO13606-Section-DisplayName">
                            <!-- Output the effective time -->
                            <xsl:value-of select="cityEHRFunction:outputDateValue($effectiveTime)"/>
                            <xsl:value-of
                                select="concat(' - ', cda:code[@codeSystem = 'cityEHR']/@displayName)"
                            />
                        </li>
                    </ul>
                </xsl:if>

                <!-- Render header sections (should be maximum of one, but you never know) ***jc deprecated 2023-12 -->
                <xsl:for-each
                    select="./cda:component/cda:structuredBody/cda:component/cda:section[not(@cityEHR:visibility = 'alwaysHidden')][@cityEHR:Rendition = 'Header']">
                    <xsl:variable name="header" select="."/>

                    <xsl:call-template name="renderFormHeader">
                        <xsl:with-param name="section" select="$header"/>
                    </xsl:call-template>
                </xsl:for-each>

                <!-- Get all other sections to render (not the header and must be visible) -->
                <xsl:variable name="renderedSectionList"
                    select="./cda:component/cda:structuredBody/cda:component/cda:section[not(@cityEHR:visibility = ('alwaysHidden', 'false'))][not(@cityEHR:Rendition = 'Header')]"/>

                <!-- If there are no visible sections -->
                <xsl:if test="empty($renderedSectionList)">
                    <p class="ISO13606-Entry-DisplayName">
                        <xsl:value-of
                            select="$view-parameters/staticParameters/cityEHRFolder-Views/emptyComposition"
                        />
                    </p>
                </xsl:if>

                <!-- Render all visible sections. -->
                <xsl:for-each select="$renderedSectionList">
                    <xsl:variable name="section" select="."/>
                    <xsl:variable name="position" select="position()"/>

                    <xsl:variable name="sectionHasData"
                        select="cityEHRFunction:entryRecorded($section)"/>

                    <xsl:variable name="sectionLayout"
                        select="
                            if ($section/@cityEHR:Sequence = 'Unranked') then
                                'Unranked'
                            else
                                'Ranked'"/>
                    <xsl:variable name="crossRefId"
                        select="concat('Composition-', $compositionCount, '-Section-', xs:string($position))"/>

                    <!-- Only processing sections that are visible -->
                    <xsl:call-template name="renderCDASection">
                        <xsl:with-param name="section" select="$section"/>
                        <xsl:with-param name="sectionLayout" select="$sectionLayout"/>
                        <xsl:with-param name="crossRefId" select="$crossRefId"/>
                    </xsl:call-template>
                </xsl:for-each>
            </div>
        </xsl:if>

    </xsl:template>


    <!-- ===  Match patientSet to output cda:entry in a data set =========================================
        Iterates through the patientData of the document calling template render each cda:entry.
        There may be multiple patientData for a single or multiple patients.
        ===================================================================================================== -->

    <xsl:template match="patientSet">

        <xsl:variable name="patientDataSet" select="patientData"/>
        <xsl:variable name="patientSet" select="distinct-values(patientData/@patientId)"/>
        <xsl:variable name="dataSetTemplate" select="$patientDataSet[1]"/>

        <table class="displayList">
            <tbody>
                <!-- Report has one row for each element in the entry set, but not for hidden elements (scope v1 or rendition v2)
                     The entry set has already been filtered to only contain entries that are not hidden -->
                <xsl:for-each
                    select="$dataSetTemplate/cda:entry/descendant::cda:value[not(@cityEHR:Scope = '#CityEHR:ElementProperty:Hidden' or @cityEHR:elementRendition = '#CityEHR:ElementProperty:Hidden')]">
                    <xsl:variable name="entry" select="ancestor::cda:entry"/>
                    <xsl:variable name="entryDisplayName"
                        select="$entry/descendant::cda:code[@codeSystem = 'cityEHR'][1]/@displayName"/>
                    <xsl:variable name="entryIRI" select="$entry/descendant::cda:id[1]/@extension"/>

                    <xsl:variable name="elementIRI" select="@extension"/>
                    <xsl:variable name="elementCount"
                        select="
                            if ((position() mod 2) = 0) then
                                'even'
                            else
                                'odd'"/>

                    <tr class="{$elementCount}">
                        <td>
                            <xsl:value-of
                                select="concat($entryDisplayName, ' ', @cityEHR:elementDisplayName)"
                            />
                        </td>
                        <xsl:for-each
                            select="$patientDataSet/cda:entry[descendant::cda:id[1]/@extension = $entryIRI]/descendant::cda:value[@extension = $elementIRI]">
                            <td>
                                <xsl:value-of select="@value"/>
                            </td>
                        </xsl:for-each>
                    </tr>
                </xsl:for-each>
            </tbody>
        </table>

    </xsl:template>


    <!-- An exception was passed in, not a CDA document.
         Can just show the first exception to help with debugging. -->
    <xsl:template match="exceptions">
        <p class="errorMessage">
            <xsl:value-of select="*[1]"/>
        </p>
    </xsl:template>

    <!-- Mop up any other nodes -->
    <xsl:template match="*">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="text()"/>


    <!-- === Render header on a form ==========================================================================
        
        The header is a section that contains (up to) six sub-sections, each of which has a defined place in the header:
        
        1) HeaderTop
        2) HeaderLeft
        3) HeaderRight
        4) HeaderTarget
        5) Supplement
        6) HeaderSubject
        
        These are laid out in a table grid:
        
        =====================
        |       Top         |
        =====================
        |Left    |     Right|
        =====================
        |Target | Supplement|
        =====================
        |       Subject     |
        =====================
        
        Before 07/2015 there were only 5 subsections in the header.
        So need additional option to support that.
        
        ===================================================================================================== -->

    <xsl:template name="renderFormHeader">
        <xsl:param name="section"/>

        <xsl:variable name="sectionLabelWidth" select="$section/@cityEHR:labelWidth"/>
        <xsl:variable name="sectionTitle" select="$section/cda:title"/>
        <xsl:variable name="sectionIRI" select="$section/cda:id/@extension"/>
        <xsl:variable name="sectionLayout" select="'Unranked'"/>

        <!-- Context list depends on the number of sub-sections in the header -->
        <xsl:variable name="letterheadSectionCount" select="count($section/cda:component)"/>
        <xsl:variable name="letterheadContext"
            select="
                if ($letterheadSectionCount = 5) then
                    ('HeaderTop', 'HeaderLeft', 'HeaderRight', 'HeaderTarget', 'HeaderSubject')
                else
                    ('HeaderTop', 'HeaderLeft', 'HeaderRight', 'HeaderTarget', 'HeaderSupplement', 'HeaderSubject')"/>

        <!-- Get the sections for the header -->
        <xsl:variable name="headerTop" select="$section/cda:component[1]/cda:section[1]"/>
        <xsl:variable name="headerLeft" select="$section/cda:component[2]/cda:section[1]"/>
        <xsl:variable name="headerRight" select="$section/cda:component[3]/cda:section[1]"/>
        <xsl:variable name="headerTarget" select="$section/cda:component[4]/cda:section[1]"/>
        <xsl:variable name="headerSupplement"
            select="
                if ($letterheadSectionCount = 5) then
                    ()
                else
                    $section/cda:component[5]/cda:section[1]"/>
        <xsl:variable name="headerSubject"
            select="
                if ($letterheadSectionCount = 5) then
                    $section/cda:component[5]/cda:section[1]
                else
                    $section/cda:component[6]/cda:section[1]"/>

        <!-- Header is a table with two columns
             First and last sections span two cells
             Odd numbered positions start a new row -->
        <table width="100%" class="Header {$sectionIRI}">
            <tbody>
                <tr>
                    <td class="HeaderTop" align="center" colspan="2">
                        <xsl:if test="exists($headerTop)">
                            <xsl:variable name="headerTopLayout"
                                select="
                                    if ($headerTop/@cityEHR:Sequence = 'Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderCDASection">
                                <xsl:with-param name="section" select="$headerTop"/>
                                <xsl:with-param name="sectionLayout" select="$headerTopLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </td>
                </tr>
                <tr>
                    <td class="HeaderLeft" align="left">
                        <xsl:if test="exists($headerLeft)">
                            <xsl:variable name="headerLeftLayout"
                                select="
                                    if ($headerLeft/@cityEHR:Sequence = 'Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderCDASection">
                                <xsl:with-param name="section" select="$headerLeft"/>
                                <xsl:with-param name="sectionLayout" select="$headerLeftLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </td>
                    <td class="HeaderRight" align="left">
                        <xsl:if test="exists($headerRight)">
                            <xsl:variable name="headerRightLayout"
                                select="
                                    if ($headerRight/@cityEHR:Sequence = 'Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderCDASection">
                                <xsl:with-param name="section" select="$headerRight"/>
                                <xsl:with-param name="sectionLayout" select="$headerRightLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </td>
                </tr>
                <tr>
                    <td class="HeaderTarget" align="left" colspan="2">
                        <xsl:if test="exists($headerTarget)">
                            <xsl:variable name="headerTargetLayout"
                                select="
                                    if ($headerTarget/@cityEHR:Sequence = 'Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderCDASection">
                                <xsl:with-param name="section" select="$headerTarget"/>
                                <xsl:with-param name="sectionLayout" select="$headerTargetLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </td>
                    <td class="HeaderSupplement" align="right" colspan="2">
                        <xsl:if test="exists($headerSupplement)">
                            <xsl:variable name="headerSupplementLayout"
                                select="
                                    if ($headerSupplement/@cityEHR:Sequence = 'Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderCDASection">
                                <xsl:with-param name="section" select="$headerSupplement"/>
                                <xsl:with-param name="sectionLayout"
                                    select="$headerSupplementLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </td>
                </tr>
                <tr>
                    <td class="HeaderSubject" align="center" colspan="2">
                        <xsl:if test="exists($headerSubject)">
                            <xsl:variable name="headerSubjectLayout"
                                select="
                                    if ($headerSubject/@cityEHR:Sequence = 'Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderCDASection">
                                <xsl:with-param name="section" select="$headerSubject"/>
                                <xsl:with-param name="sectionLayout" select="$headerSubjectLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </td>
                </tr>
            </tbody>
        </table>

    </xsl:template>


    <!-- === Render section of a CDA Document ===============================================================
        Iterates through the section contents and calls templates to render sections (recursive) or entries.
        ===================================================================================================== -->

    <xsl:template name="renderCDASection">
        <xsl:param name="section"/>
        <xsl:param name="sectionLayout"/>
        <xsl:param name="crossRefId"/>

        <xsl:variable name="sectionLabelWidth" select="$section/@cityEHR:labelWidth"/>
        <xsl:variable name="sectionTitle" select="$section/cda:title"/>
        <xsl:variable name="sectionIRI" select="$section/cda:id/@extension"/>
        <xsl:variable name="sectionRenditon"
            select="
                if ($section/@cityEHR:rendition = '#CityEHR:EntryProperty:Standalone') then
                    'Standalone'
                else
                    ''"/>
        <xsl:variable name="sectionHasData" select="cityEHRFunction:entryRecorded($section)"/>

        <!-- Output section, but only if it has some data content -->
        <xsl:if test="$sectionHasData = 'true'">
            <ul class="ISO13606-Section {$sectionRenditon} {$sectionIRI}">
                <!-- Add id attribute if there is one -->
                <xsl:if test="string-length($crossRefId) gt 0">
                    <xsl:attribute name="id">
                        <xsl:value-of select="$crossRefId"/>
                    </xsl:attribute>
                </xsl:if>

                <!-- Only output the section header if it has a display name.
                 The section header is always displayed at the top as a block (i.e. not Ranked/Unranked) -->
                <xsl:if test="$sectionTitle[data(.) != '']">
                    <li class="ISO13606-Section-DisplayName">
                        <xsl:value-of select="$sectionTitle"/>
                    </li>
                </xsl:if>

                <!-- Iterate through each entry and sub-section in the section, provided it is visible -->
                <xsl:for-each select="$section/*[not(@cityEHR:visibility = 'false')]">
                    <xsl:variable name="component" select="."/>

                    <!-- Entry - call template to render the entry but only if it has some content -->
                    <xsl:if
                        test="$component/name() = 'entry' and cityEHRFunction:entryRecorded($component) = 'true'">

                        <li class="{$sectionLayout}">
                            <xsl:call-template name="renderCDAEntry">
                                <xsl:with-param name="entry" select="$component"/>
                                <xsl:with-param name="sectionLayout" select="$sectionLayout"/>
                                <xsl:with-param name="labelWidth" select="$sectionLabelWidth"/>
                            </xsl:call-template>
                        </li>
                    </xsl:if>

                    <!-- Section - recursively call template to render sub-section -->
                    <xsl:if test="exists($component/cda:section)">
                        <xsl:variable name="subSection" select="$component/cda:section"/>
                        <xsl:variable name="subSectionLayout"
                            select="
                                if ($subSection[@cityEHR:Sequence = 'Unranked']) then
                                    'Unranked'
                                else
                                    'Ranked'"/>

                        <li class="{$sectionLayout}">
                            <xsl:call-template name="renderCDASection">
                                <xsl:with-param name="section" select="$subSection"/>
                                <xsl:with-param name="sectionLayout" select="$subSectionLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </li>
                    </xsl:if>

                </xsl:for-each>
                <xsl:if test="$sectionLayout = 'Unranked'">
                    <li class="LayoutFooter">&#160;</li>
                </xsl:if>
            </ul>
        </xsl:if>

        <!-- For sections that have no content, but do have a title and are visible -->
        <xsl:if test="$sectionHasData = 'false'">
            <xsl:variable name="sectionTitle"
                select="
                    if (exists($section/cda:title)) then
                        $section/cda:title
                    else
                        ''"/>
            <!-- Only output the section header if it has a display name -->
            <xsl:if test="$sectionTitle != ''">
                <ul class="ISO13606-Section emptySection" id="{$crossRefId}">
                    <li class="ISO13606-Section-DisplayName">
                        <xsl:value-of select="$sectionTitle"/>
                    </li>
                    <li class="Ranked">
                        <ul class="ISO13606-Entry">
                            <li class="ISO13606-Entry-DisplayName">
                                <xsl:value-of
                                    select="$view-parameters/staticParameters/cityEHRFolder-Views/emptySection"
                                />
                            </li>
                        </ul>
                    </li>
                </ul>
            </xsl:if>
        </xsl:if>

    </xsl:template>


    <!-- === Render entry in CDA document ===================================================================
        There are two types of entry to consider:
        Ranked
        Unranked
        ===================================================================================================== -->

    <xsl:template name="renderCDAEntry">
        <xsl:param name="entry"/>
        <xsl:param name="sectionLayout"/>
        <xsl:param name="labelWidth"/>

        <!-- This needs to work for single and multiple entries, hence the //cda:id[1] -->
        <xsl:variable name="entryIRI" select="$entry//cda:id[1]/@extension"/>

        <xsl:variable name="entryLayout" select="$entry/@cityEHR:Sequence"/>
        <xsl:variable name="entryLabelWidth" select="$entry/@cityEHR:labelWidth"/>

        <!-- Since we are setting width in em, use half the character length of the width - this usually works fine.
             Only set the width in Ranked sections -->
        <xsl:variable name="width" select="round($labelWidth div 2)"/>
        <xsl:variable name="widthStyle"
            select="
                if ($sectionLayout = 'Ranked') then
                    concat('width:', $width, 'em;')
                else
                    ''"/>

        <!-- Debugging -->
        <!--
        <p class="message"> Rendering Entry </p>
        -->
        <ul class="ISO13606-Entry {$entryIRI}">
            <!-- Render the displayName
                 Just display first label - caters for Composition views with more than one instance os the entry.
                 and also cases for multipleEntry and entries with enumeratedClass elements.
                 Only one of these options in the select will match. -->
            <xsl:variable name="simpleDisplayName"
                select="$entry/*[name() = 'observation' or name() = 'encounter'][1]/cda:code[@codeSystem = 'cityEHR']/@displayName"/>
            <xsl:variable name="multipleEntryDisplayName"
                select="$entry/cda:organizer[1]/cda:component[1]//cda:code[@codeSystem = 'cityEHR']/@displayName"/>

            <xsl:if test="exists($simpleDisplayName) and $simpleDisplayName != ''">
                <li class="ISO13606-Entry-DisplayName {$entryLayout}" style="{$widthStyle}">
                    <xsl:value-of select="$simpleDisplayName"/>
                </li>
            </xsl:if>
            <xsl:if test="exists($multipleEntryDisplayName) and $multipleEntryDisplayName != ''">
                <li class="ISO13606-Entry-DisplayName" style="{$widthStyle}">
                    <xsl:value-of select="$multipleEntryDisplayName"/>
                </li>
            </xsl:if>

            <!-- Render the content -->
            <xsl:call-template name="renderCDAEntryContent">
                <xsl:with-param name="entry" select="$entry"/>
                <xsl:with-param name="entryLayout" select="$entryLayout"/>
                <xsl:with-param name="labelWidth" select="$entryLabelWidth"/>
            </xsl:call-template>
            <xsl:if test="$entryLayout = 'Unranked'">
                <li class="LayoutFooter">&#160;</li>
            </xsl:if>
        </ul>

    </xsl:template>


    <!-- === Render entry content ==========================================================================
        There are eight types of entry to consider:
        (1) simple entry, form rendition uses cda:observation or cda:encounter (may handle other type of CDA events in the future)
        (2) simple entry, image map rendition displays the image map
        (3) Simple entry - image rendition 
        (4) multiple occurrences of the same entry use cda:organizer with classCode attribute of MultipleEntry
        (5) multiple occurrences of the same entry, image map rendition
         
        A multiple entry contains a cda:organizer with two components, the first with the template
        and the second with another organizer with one component for each multiple entry
        
        Supplementatry data sets are contained in cda:entryRelationship within the cda:observation, cda:encounter, etc
        ===================================================================================================== -->

    <xsl:template name="renderCDAEntryContent">
        <xsl:param name="entry"/>
        <xsl:param name="entryLayout"/>
        <xsl:param name="labelWidth"/>

        <!-- Debugging -->
        <!--
        <p class="message"> Rendering Entry Content
        </p>
        -->

        <!-- === (1) Simple entry ======
             This one must match any entry that does not have cityEHR properties set -->

        <xsl:if
            test="$entry[not(cda:organizer)][not(@cityEHR:rendition = ('#CityEHR:EntryProperty:ImageMap', '#CityEHR:EntryProperty:Image'))]">
            <!-- Simple observation or encounter. The selected nodeset is the union of the two matches,
                 although only one will contribute results in any one instance -->

            <xsl:call-template name="renderSimpleEntry">
                <xsl:with-param name="entry" select="$entry"/>
                <xsl:with-param name="entryLayout" select="$entryLayout"/>
                <xsl:with-param name="labelWidth" select="$labelWidth"/>
            </xsl:call-template>

        </xsl:if>
        <!-- End of Simple entry - form rendition  -->


        <!-- === (2) Simple entry - imageMap rendition ======
             Get id from <id xmlns="" root="cityEHR" extension="#ISO-13606:Entry:DAS68"/>
             cityEHR:rendition="#CityEHR:EntryProperty:ImageMap"
             Include the image map if it exists in cda:text/svg:svg
             Iterate through the elements for the entry, displayed next to the image map -->

        <xsl:if
            test="$entry[not(cda:organizer)][@cityEHR:rendition = '#CityEHR:EntryProperty:ImageMap']/cda:observation">

            <xsl:call-template name="renderSimpleEntry">
                <xsl:with-param name="entry" select="$entry"/>
                <xsl:with-param name="entryLayout" select="$entryLayout"/>
                <xsl:with-param name="labelWidth" select="$labelWidth"/>
            </xsl:call-template>

            <!-- Original way - deprecated 2025-03-15 -->
            <xsl:if test="false()">
                <li class="{$entryLayout}">
                    <div class="tableContainer">
                        <table>
                            <tbody>
                                <tr>
                                    <!-- Output the image map with selections shown? -->
                                    <td>
                                        <!-- Image map here -->
                                        <!-- But not displaying the map - could make this an option whether to display, or not -->
                                    </td>

                                    <!-- Iterate through the list of elements, outputting the boolean 'true' values.
                             The element can be set as 'true' or '1' to be boolean true; 'false' or '0' to be boolean false.
                             Only displaying the values for the 'true' elements (i.e. elements that are highlighted on the map)
                             Need to add another parameter to renderCDAElement so that it has options for how to treat boolean values -->
                                    <td>
                                        <ul>
                                            <li class="{$entryLayout}">
                                                <xsl:for-each
                                                  select="$entry/cda:observation/cda:value[@value != '0']">
                                                  <xsl:variable name="element" select="."/>
                                                  <ul class="ISO13606-Element">
                                                  <li class="ISO13606-Element-DisplayName">
                                                  <xsl:value-of
                                                  select="$element/@cityEHR:elementDisplayName"/>
                                                  </li>
                                                  </ul>
                                                </xsl:for-each>
                                            </li>
                                        </ul>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </li>
            </xsl:if>
        </xsl:if>
        <!-- End of Simple entry - imageMap rendition -->


        <!-- === (3) Simple entry - image rendition ======
             Display media images, which are held in the displayName attrbutes of the cda:values -->

        <xsl:if
            test="$entry[not(cda:organizer)][@cityEHR:rendition = '#CityEHR:EntryProperty:Image']/cda:observation">
            <xsl:variable name="entryIRI" select="$entry/*[1]/cda:id/@extension"/>
            <ul>
                <li class="{$entryLayout}">
                    <xsl:for-each
                        select="$entry/cda:observation/cda:value[@displayName != '' and @displayName castable as xs:base64Binary]">
                        <xsl:variable name="element" select="."/>
                        <xsl:variable name="elementIRI" select="$element/@extension"/>

                        <ul class="ISO13606-Element {$entryIRI}/{$elementIRI}">
                            <li class="ISO13606-Element-DisplayName">
                                <img
                                    src="data:image/*;base64,{xs:base64Binary($element/@displayName)}"
                                    height="{$element/@cityEHR:height}"
                                    width="{$element/@cityEHR:width}"/>
                            </li>
                        </ul>
                    </xsl:for-each>
                </li>
            </ul>
        </xsl:if>
        <!-- end of Simple entry - image rendition -->



        <!-- === (4) Multiple occurrences of the same entry ==
            Entry contains an organizer for MultipleEntry.
            
            The first component in the MultipleEntry organizer is the template for the entries added to the second component
            The template is a component that contains an observation or another organizer for an EnumeratedClassEntry 
            Th second component contains an organizer, which contains another component for each entry
            Only generate output if the second component contains some content    
        -->
        <xsl:if test="$entry/cda:organizer[@classCode = 'MultipleEntry']">
            <xsl:variable name="organizer" select="$entry/cda:organizer"/>
            <!-- The entryIRI is either in the cda:observation or the cda:observation inside the enumeratedClass organizer.
                 Note that for read-only entries the entryIRI is set to '' on publish. -->
            <xsl:variable name="entryIRI"
                select="
                    if (exists($organizer/cda:component[1]/descendant::cda:id[1]/@extension)) then
                        $organizer/cda:component[1]/descendant::cda:id[1]/@extension
                    else
                        ''"/>
            <xsl:variable name="rootIRI"
                select="
                    if (exists($organizer/cda:component[1]/descendant::cda:id[1]/@root)) then
                        $organizer/cda:component[1]/descendant::cda:id[1]/@root
                    else
                        ''"/>

            <xsl:variable name="entryScope"
                select="
                    if (exists($entry/@cityEHR:Scope)) then
                        $entry/@cityEHR:Scope
                    else
                        ''"/>

            <!-- Debugging -->
            <!--
            <p class="message"> Multiple entry: <xsl:value-of select="$entryIRI"/>
            </p>
            -->

            <!-- Multiple entry can be Ranked or Unranked.
                 If the multiple entry is empty, then don't generate any output.
                 To check this, see if there are any elements in the organizer within the second component of the multiple entry organizer -->
            <xsl:if test="exists($organizer/cda:component[2]/cda:organizer/*)">
                <li class="MultipleEntry">
                    <!-- Output needs an entryIRI for use in checkbox ids -->
                    <xsl:call-template name="outputMultipleEntryOrganizer">
                        <xsl:with-param name="organizer" select="$organizer"/>
                        <xsl:with-param name="entryIRI"
                            select="
                                if ($entryIRI != '') then
                                    $entryIRI
                                else
                                    $rootIRI"/>
                        <xsl:with-param name="entryScope" select="$entryScope"/>
                    </xsl:call-template>
                </li>
            </xsl:if>

        </xsl:if>
        <!-- End of Multiple occurrences of the same entry -->


        <!-- === (5) Multiple occurrences of the same entry, image map rendition ==
             TBD
        -->

    </xsl:template>


    <!-- === Output a Supplementary Entry (supplementary data set) 
             The supplementaryEntry is an entryRelationship
         === -->

    <xsl:template name="renderSupplementaryEntry">
        <xsl:param name="supplementaryEntry"/>

        <xsl:variable name="supplementaryEntryIRI" select="$supplementaryEntry/cda:id/@extension"/>

        <p class="error">
            <xsl:value-of select="$supplementaryEntryIRI"/>
        </p>

        <!-- Only display SDS if some values were set -->
        <xsl:if test="exists($supplementaryEntry/cda:observation//cda:value[@value != ''])">
            <xsl:variable name="labelWidth" select="''"/>
            <ul class="SupplementaryEntry {$supplementaryEntryIRI}">
                <xsl:for-each select="$supplementaryEntry/cda:observation/cda:value">
                    <!-- Simple element -->
                    <xsl:variable name="element" select="."/>
                    <li>
                        <xsl:call-template name="renderCDAElement">
                            <xsl:with-param name="element" select="$element"/>
                            <xsl:with-param name="entryIRI" select="$supplementaryEntryIRI"/>
                            <xsl:with-param name="entryType" select="'Simple'"/>
                            <xsl:with-param name="entryLayout" select="'Ranked'"/>
                            <xsl:with-param name="labelWidth" select="$labelWidth"/>
                            <xsl:with-param name="supplementaryEntry" select="()"/>
                        </xsl:call-template>
                    </li>
                </xsl:for-each>
            </ul>
        </xsl:if>

    </xsl:template>


    <!-- === Output a simple Observation or Encounter 
             cda:observation | cda:encounter             
             For event, folder or current composition view just output the entry.             
             For historic composition view need to output all entries with their effectiveTime            
             === -->

    <xsl:template name="renderSimpleEntry">
        <xsl:param name="entry"/>
        <xsl:param name="entryLayout"/>
        <xsl:param name="labelWidth"/>

        <!-- Get entryIRI and rendition - works for observation, act, encounter, etc -->
        <xsl:variable name="entryIRI" select="$entry/*[1]/cda:id/@extension"/>

        <!-- Displaying Event or Folder view, or just showing the current value in a Composition view.
             There is only one observation, act, encounter, etc for the entry -->
        <xsl:if
            test="$outputType = 'Event' or $outputType = 'Folder' or ($outputType = 'Composition' and $viewHistory = 'current')">

            <!-- Iterate through each element, provided it is visible.
                 TBD add elements from cda:act, cda:supply, cda:substanceAdministration -->
            <xsl:for-each
                select="
                    $entry/cda:observation[1]/cda:value[not(@cityEHR:visibility = 'false')] |
                    $entry/cda:encounter[1]/cda:participant/cda:participantRole/cda:playingEntity[not(@cityEHR:visibility = 'false')]">

                <xsl:variable name="element" select="."/>

                <!-- Set up the supplementary entry for processing on selection of element
                         Since there is only one element, the supplementary entry should always match the origin of that element -->
                <xsl:variable name="supplementaryEntry"
                    select="$entry/cda:observation/cda:entryRelationship[@cityEHR:origin = $element/@extension]"/>

                <li class="{$entryLayout}">
                    <xsl:call-template name="renderCDAElement">
                        <xsl:with-param name="element" select="$element"/>
                        <xsl:with-param name="entryIRI" select="$entryIRI"/>
                        <xsl:with-param name="entryType" select="'Simple'"/>
                        <xsl:with-param name="entryLayout" select="$entryLayout"/>
                        <xsl:with-param name="labelWidth" select="$labelWidth"/>
                        <xsl:with-param name="supplementaryEntry" select="$supplementaryEntry"/>
                    </xsl:call-template>
                </li>
            </xsl:for-each>

        </xsl:if>

        <!-- Display composition view, historic - show all entries in the date range
             These are displayed in a table, with the date of the observation, unless there is a date element in the entry -->
        <xsl:if test="$outputType = 'Composition' and $viewHistory = 'historic'">

            <!-- Get the set of observation dates.
                 If there is a date element in the entry then this should be used. otherwise use effectiveTime
                 Note that the sortDescending sorts and returns distinct values only -->

            <xsl:variable name="effectiveTimeDateSet"
                select="cityEHRFunction:sortDescending($entry/cda:observation/@effectiveTime)"/>
            <xsl:variable name="recordedDateElement"
                select="($entry/cda:observation//cda:value[@xsi:type = ('xs:date', 'xs:dateTime', 'xs:time')])[1]/@extension"/>
            <xsl:variable name="recordedDateSet"
                select="cityEHRFunction:sortDescending($entry//cda:value[@extension = $recordedDateElement]/@value)"/>

            <xsl:variable name="dateSet"
                select="
                    if (empty($recordedDateSet)) then
                        $effectiveTimeDateSet
                    else
                        $recordedDateSet"/>

            <xsl:if test="exists($dateSet)">
                <li class="{$entry/@cityEHR:Sequence}">
                    <div class="tableContainer">
                        <table>
                            <thead>
                                <!-- Create a column in the table for each date in the set -->
                                <tr>
                                    <td/>
                                    <td/>
                                    <xsl:for-each select="$dateSet">
                                        <xsl:variable name="date" select="."/>
                                        <td>
                                            <span class="ISO13606-Element-DisplayName">
                                                <xsl:value-of
                                                  select="cityEHRFunction:outputDateValue($date)"/>
                                            </span>
                                        </td>
                                    </xsl:for-each>
                                </tr>
                            </thead>
                            <tbody>
                                <!-- One row for each element in the entry (need to cope with clusters).
                                     use the first observation to get the displayNames
                                     The $recordedDateElement has already been output in the header, so don't need it again -->
                                <xsl:for-each
                                    select="$entry/cda:observation[1]/cda:value[@extension != $recordedDateElement]">
                                    <xsl:variable name="element" select="."/>
                                    <xsl:variable name="elementIRI" select="$element/@extension"/>
                                    <tr>
                                        <!-- First cell selects element for graphing -->
                                        <xsl:variable name="plotType" select="'timeseries'"/>
                                        <xsl:variable name="dateElementExtension"
                                            select="$recordedDateElement"/>
                                        <xsl:variable name="variableElementExtension"
                                            select="$elementIRI"/>
                                        <xsl:variable name="variableElementValue"
                                            select="$element/@cityEHR:elementDisplayName"/>

                                        <xsl:variable name="variableEntryDisplayName"
                                            select="$entry/cda:observation[1]/cda:code[@codeSystem = 'cityEHR']/@displayName"/>
                                        <xsl:variable name="variableElementDisplayName"
                                            select="$element/@cityEHR:elementDisplayName"/>
                                        <xsl:variable name="displayNameConnector"
                                            select="
                                                if ('' = ($variableEntryDisplayName, $variableElementDisplayName)) then
                                                    ''
                                                else
                                                    ' / '"/>
                                        <xsl:variable name="variableDisplayName"
                                            select="concat($variableEntryDisplayName, $displayNameConnector, $variableElementDisplayName)"/>

                                        <xsl:variable name="valueElementExtension"
                                            select="$elementIRI"/>
                                        <xsl:variable name="checkboxId"
                                            select="concat($entryIRI, $valueElementExtension)"/>

                                        <td>
                                            <!-- Include checkbox for selecting the element for graphing, but only for numeric data types -->
                                            <xsl:if
                                                test="$element/@xsi:type = ('xs:double', 'xs:integer')">
                                                <span name="{$checkboxId}" class="unchecked"
                                                  onclick="var newState=setCheckboxes('{$checkboxId}',this.className); this.className=newState; setXformsControl('setVariable-entryId','{$entryIRI}'); setXformsControl('setVariable-plotType','{$plotType}'); setXformsControl('setVariable-dateElementExtension','{$dateElementExtension}'); setXformsControl('setVariable-variableElementExtension','{$variableElementExtension}'); setXformsControl('setVariable-variableElementValue','{$variableElementValue}'); setXformsControl('setVariable-variableElementDisplayName','{$variableDisplayName}'); setXformsControl('setVariable-valueElementExtension','{$valueElementExtension}');  setXformsControl('setVariable-action',newState); callXformsAction('main-model','set-chart-variable'); ">
                                                  <span class="unchecked">
                                                  <input type="checkbox" onclick="return false"
                                                  onkeydown="return false"/>
                                                  </span>
                                                  <span class="checked">
                                                  <input type="checkbox" onclick="return false"
                                                  onkeydown="return false" checked="yes"/>
                                                  </span>
                                                </span>
                                            </xsl:if>
                                        </td>
                                        <!-- Second cell shows element name -->
                                        <td>
                                            <span class="ISO13606-Element-DisplayName">
                                                <xsl:value-of
                                                  select="$element/@cityEHR:elementDisplayName"/>
                                            </span>
                                        </td>
                                        <!-- One cell for each value that matches the date in that column.
                                             The observation is matched using the effective time or the recorded time ***jc -->
                                        <xsl:for-each select="$dateSet">
                                            <xsl:variable name="date" select="."/>

                                            <xsl:variable name="observation"
                                                select="
                                                    if (empty($recordedDateSet)) then
                                                        $entry/cda:observation[@effectiveTime = $date][1]
                                                    else
                                                        $entry/cda:observation[descendant::cda:value[@extension = $recordedDateElement]/@value = $date][1]"/>
                                            <xsl:variable name="element"
                                                select="$observation/cda:value[@extension = $elementIRI]"/>
                                            <td>
                                                <xsl:variable name="value"
                                                  select="
                                                        if ($element/@displayName != '') then
                                                            $element/@displayName
                                                        else
                                                            $element/@value"/>
                                                <xsl:variable name="type"
                                                  select="
                                                        if ($element/@xsi:type != '') then
                                                            $element/@xsi:type
                                                        else
                                                            'xs:string'"/>
                                                <span class="ISO13606-Data">
                                                  <xsl:value-of
                                                  select="cityEHRFunction:outputValue($value, $type)"
                                                  />
                                                </span>
                                            </td>

                                        </xsl:for-each>
                                    </tr>
                                </xsl:for-each>
                            </tbody>
                        </table>
                    </div>
                </li>
            </xsl:if>
        </xsl:if>

    </xsl:template>


    <!-- === Output MultipleEntry organizer.
             First component of the organizer contains the template entry (used for labels, headings, etc)
             Second component contains the set of recorded entries.
             The second organizer contains a set of organizers, each with the effectiveTime that they were recorded.
             Each of these organizers contains a set of components for(observation, act, encounter, supply, substanceAdministration) 
             Supplementary Data Sets (SDS) are in the entryRelationship element  === -->

    <xsl:template name="outputMultipleEntryOrganizer">
        <xsl:param name="organizer"/>
        <xsl:param name="entryIRI"/>
        <xsl:param name="entryScope"/>

        <!-- Debugging -->
        <!--
        <p class="message">outputMultipleEntryOrganizer</p>
        -->
        <!-- Use descendant axis to get the observation template (so that entries with enumeratedClass elements are handled) -->
        <xsl:variable name="observationTemplate"
            select="$organizer/cda:component[1]/descendant::cda:observation[1]"/>

        <!-- Date variable is first xs:date or xs:dateTime type element -->
        <xsl:variable name="dateElementExtension"
            select="$observationTemplate/cda:value[@xsi:type = 'xs:date' or @xsi:type = 'xs:dateTime'][1]/@extension"/>
        <!-- Plotted variable is first enumeratedValue or enumeratedClass type element -->
        <xsl:variable name="variableElementExtension"
            select="$observationTemplate/cda:value[@cityEHR:elementType = ('#CityEHR:ElementProperty:enumeratedValue', '#CityEHR:ElementProperty:enumeratedClass')][1]/@extension"/>

        <!--
    plot type depends on different data patterns found.
    
    interval      
            Variable (first element that is enumeratedValue or enumeratedClass)
            startTime (first xs:date or xs:dateTime element)
            endTime (second xs:date or xs:dateTime element)
    
    timeseries    
            Time (xs:date or xs:dateTime element)
            Variable (first element that is enumeratedValue or enumeratedClass)
            Value (last element that is xs:double or xs:integer)
    
    plotted     Has a date/time element and one or more numeric elements but doesn't match either of the patterns above
    
    non-plotted   Doesn't match any of these patterns
    
    Look for the interval pattern first, then the time series, then plotted, then non-plotted
    
        -->
        <xsl:variable name="plotType" select="cityEHRFunction:getPlotType($observationTemplate)"/>
        <!-- Debugging -->
        <!--
        <span class="message">
            <xsl:value-of select="$plotType"/>
        </span>
-->

        <!-- selectionClass hides or displays selection boxes for plotted variables -->
        <xsl:variable name="selectionClass"
            select="
                if ($viewHistory = 'current' or ($viewHistory = 'historic' and $plotType = 'non-plotted')) then
                    'hidden'
                else
                    'checkbox'"/>


        <!-- Plotted value depends on the plot type:           
            For interval type plot is the second xs:date or xs:dateTime element
            For timeseries is last xs:integer or xs:double element in the entry -->
        <xsl:variable name="valueElementExtension"
            select="
                if ($plotType = 'interval') then
                    $observationTemplate/cda:value[@xsi:type = 'xs:date' or @xsi:type = 'xs:dateTime'][2]/@extension
                else
                    $observationTemplate/cda:value[@xsi:type = 'xs:double' or @xsi:type = 'xs:integer'][last()]/@extension"/>

        <!-- Event type view -->
        <xsl:if test="$outputType = 'Event'">
            <xsl:call-template name="outputBasicMultipleEntry">
                <xsl:with-param name="entryIRI" select="$entryIRI"/>
                <xsl:with-param name="observationTemplate" select="$observationTemplate"/>
                <xsl:with-param name="organizer" select="$organizer/cda:component[2]/cda:organizer"
                />
            </xsl:call-template>
        </xsl:if>

        <!-- For Folder views just need to allow selection of variables to graph.
             If the pattern is 'non-plotted' then don't allow selection.
             Note that this may be an enumeratedClass entry, so descendant observations need to be found. -->
        <xsl:if test="$outputType = 'Folder'">
            <div class="tableContainer">
                <table class="CDAEntryList">
                    <thead>
                        <tr>
                            <td class="{$selectionClass}"/>
                            <xsl:for-each select="$observationTemplate/cda:value">
                                <td>
                                    <span class="ISO13606-Element-DisplayName">
                                        <xsl:value-of select="./@cityEHR:elementDisplayName"/>
                                    </span>
                                </td>
                            </xsl:for-each>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Tester
                    <tr><td>unchecked <input type="checkbox"/></td> <td>checked <input type="checkbox" checked="yes"/></td></tr>
                    -->
                        <xsl:for-each
                            select="$organizer/cda:component[2]/cda:organizer/cda:component">
                            <!-- The entry is either simple or in an enuneratedClass organizer -->
                            <xsl:variable name="entry"
                                select="cda:observation | cda:organizer/cda:component[1]/cda:observation"/>
                            <tr>
                                <!-- Value of plotted variable (first non-xs:date type element) -->
                                <xsl:variable name="variableElement"
                                    select="$entry/cda:value[@xsi:type != 'xs:date'][1]"/>
                                <xsl:variable name="variableElementValue"
                                    select="$variableElement/@value"/>
                                <xsl:variable name="variableDisplayName"
                                    select="
                                        if ($variableElement/@displayName != '') then
                                            $variableElement/@displayName
                                        else
                                            $variableElementValue"/>

                                <!-- CheckboxId is unique - used to link identical variables and also to trigger setting the variable as a parameter in the model -->
                                <!-- **jc error here** -->
                                <xsl:variable name="checkboxId"
                                    select="concat($entryIRI, $variableElementExtension, $variableElementValue)"/>
                                <!-- Would use checkboxIdURI, but seems to get unescaped in name for some reason, so might as well use checkboxId -->
                                <xsl:variable name="checkboxIdURI"
                                    select="encode-for-uri($checkboxId)"/>

                                <!-- This one works with characters
                                <td>
                                    <span name="{$checkboxId}" class="unchecked" onClick="var newState=setCheckboxes('{$checkboxId}',this.className); this.className=newState; setXformsControl('setVariable-entryId','{$entryIRI}'); setXformsControl('setVariable-dateElementExtension','{$dateElementExtension}'); setXformsControl('setVariable-variableElementExtension','{$variableElementExtension}'); setXformsControl('setVariable-variableElementValue','{$variableElementValue}'); setXformsControl('setVariable-valueElementExtension','{$valueElementExtension}');  setXformsControl('setVariable-action',newState); callXformsAction('main-model','set-chart-variable'); ">
                                        <span class="unchecked">&#9723;
                                        </span>
                                        <span class="checked">&#9745;
                                        </span>
                                    </span>
                            </td>
                                -->
                                <!-- The check boxes are displayed checked and unchecked.
                                     The standard behaviour of the checkboxes is prevented by the onclick/onkeydown actions on the checkboxes
                                     The container span element sets the class as checked|unchecked and calls javascript to set charting parameters
                                     The css controls whether the checked or unchecked box is displayed.
                                     -->
                                <td class="{$selectionClass}">
                                    <span name="{$checkboxId}" class="unchecked"
                                        onclick="var newState=setCheckboxes('{$checkboxId}',this.className); this.className=newState; setXformsControl('setVariable-entryId','{$entryIRI}'); setXformsControl('setVariable-plotType','{$plotType}'); setXformsControl('setVariable-dateElementExtension','{$dateElementExtension}'); setXformsControl('setVariable-variableElementExtension','{$variableElementExtension}'); setXformsControl('setVariable-variableElementValue','{$variableElementValue}'); setXformsControl('setVariable-variableElementDisplayName','{$variableDisplayName}'); setXformsControl('setVariable-valueElementExtension','{$valueElementExtension}');  setXformsControl('setVariable-action',newState); callXformsAction('main-model','set-chart-variable'); ">
                                        <span class="unchecked">
                                            <input type="checkbox" onclick="return false"
                                                onkeydown="return false"/>
                                        </span>
                                        <span class="checked">
                                            <input type="checkbox" onclick="return false"
                                                onkeydown="return false" checked="yes"/>
                                        </span>
                                    </span>
                                </td>
                                <xsl:for-each select="$entry/cda:value">
                                    <xsl:variable name="element" select="."/>
                                    <td>
                                        <xsl:variable name="value"
                                            select="
                                                if ($element/@displayName != '') then
                                                    $element/@displayName
                                                else
                                                    $element/@value"/>
                                        <xsl:variable name="type"
                                            select="
                                                if ($element/@xsi:type != '') then
                                                    $element/@xsi:type
                                                else
                                                    'xs:string'"/>
                                        <span class="ISO13606-Data">
                                            <xsl:value-of
                                                select="cityEHRFunction:outputValue($value, $type)"
                                            />
                                        </span>
                                    </td>
                                </xsl:for-each>
                            </tr>
                        </xsl:for-each>
                    </tbody>
                </table>
            </div>
        </xsl:if>

        <!-- For Composition views need to sort entries by date and plotted variable.
             The table layout depends on the plotType.
             For 'current' viewHistory just show the first date, for 'historic' show all dates
          -->
        <xsl:if test="$outputType = 'Composition'">

            <!-- Observation list is the set of first descendant observations (caters for enumeratedClass entries)
                 Date variable is first xs:date type element.
                 Assuming here that the date is not in a cluster -->
            <xsl:variable name="observationList"
                select="$organizer/cda:component[2]//cda:observation[1]"/>

            <xsl:variable name="fullDateList"
                select="cityEHRFunction:sortDescending($observationList/cda:value[@xsi:type = 'xs:date'][1]/@value)"/>
            <xsl:variable name="dateList"
                select="
                    if ($viewHistory = 'historic') then
                        $fullDateList
                    else
                        $fullDateList[1]"/>

            <!-- Plotted variable is first enumeratedClass or enumeratedValue element.
                 Look for this in the observation template for the multiple entry.
                 This is used as the column header for the first column (which contains the variable name) -->
            <xsl:variable name="variableElementDisplayName"
                select="$organizer/cda:component[1]//cda:observation[1]/cda:value[@cityEHR:elementType = '#CityEHR:ElementProperty:enumeratedValue' or @cityEHR:elementType = '#CityEHR:ElementProperty:enumeratedClass'][1]/@cityEHR:elementDisplayName"/>

            <!-- Variable list could use code as unique value and then get displayName or value to display. 
                 Better to use value and assume this is unique and then get displayName to display, if there is one.
                 If the entry is expanded then need to restrict the variable list to the expanded variables only. -->
            <xsl:variable name="fullVariableList"
                select="distinct-values($organizer/cda:component[2]/cda:organizer/cda:component//cda:observation[1]/cda:value[@extension = $variableElementExtension][@value != ''][1]/@value)"/>
            <xsl:variable name="variableList"
                select="
                    if ($entryScope = '#CityEHR:EntryProperty:Expanded') then
                        cityEHRFunction:getExpandedEntryVariables($organizer)
                    else
                        $fullVariableList"/>

            <!-- Debugging 
            <span class="ISO13606-Element-DisplayName">
                <xsl:value-of select="$variableList" separator=" - "/>
            </span>
            -->

            <!-- Timeseries data pattern -->
            <xsl:if test="$plotType = 'timeseries'">
                <div class="tableContainer">
                    <table class="CDAEntryList">
                        <thead>
                            <tr>
                                <th class="{$selectionClass}"/>
                                <th>
                                    <xsl:value-of select="$variableElementDisplayName"/>
                                </th>
                                <xsl:for-each select="$dateList">
                                    <th>
                                        <xsl:value-of select="cityEHRFunction:outputDateValue(.)"/>
                                    </th>
                                </xsl:for-each>
                            </tr>
                        </thead>
                        <tbody>
                            <xsl:for-each select="$variableList">
                                <xsl:variable name="variable" select="."/>
                                <!-- If variable does not have a display name, then use the value instead -->
                                <xsl:variable name="displayName"
                                    select="
                                        if (exists($organizer/cda:component[2]/cda:organizer//cda:observation/cda:value[@extension = $variableElementExtension][1][@value = $variable]/@displayName)) then
                                            $organizer/cda:component[2]/cda:organizer//cda:observation/cda:value[@extension = $variableElementExtension][1][@value = $variable]/@displayName
                                        else
                                            ''"/>
                                <xsl:variable name="variableDisplayName"
                                    select="
                                        if ($displayName != '') then
                                            $displayName[1]
                                        else
                                            $variable"/>

                                <tr>
                                    <!-- Value of plotted variable (first non-xs:date type element) -->
                                    <xsl:variable name="variableElementValue" select="$variable"/>
                                    <!-- CheckboxId is unique - used to link identical variables and also to trigger setting the variable as a parameter in the model -->
                                    <xsl:variable name="checkboxId"
                                        select="concat($entryIRI, $variableElementExtension, $variableElementValue)"/>
                                    <!-- Would use checkboxIdURI, but seems to get unescaped in name for some reason, so might as well use checkboxId -->
                                    <xsl:variable name="checkboxIdURI"
                                        select="encode-for-uri($checkboxId)"/>

                                    <!-- This one works with characters
                            <td>
                                <a name="{$checkboxId}" class="unchecked" onClick="var newState=setCheckboxes('{$checkboxId}',this.className); this.className=newState; setXformsControl('setVariable-entryIRI','{$entryIRI}'); setXformsControl('setVariable-dateElementExtension','{$dateElementExtension}'); setXformsControl('setVariable-variableElementExtension','{$variableElementExtension}'); setXformsControl('setVariable-variableElementValue','{$variableElementValue}'); setXformsControl('setVariable-valueElementExtension','{$valueElementExtension}');  setXformsControl('setVariable-action',newState); callXformsAction('main-model','set-chart-variable'); ">
                                    <span class="unchecked">&#9723;</span>
                                    <span class="checked">&#9745;</span>
                                </a>
                            </td>
                            -->
                                    <!-- The check boxes are displayed checked and unchecked.
                                The standard behaviour of the checkboxes is prevented by the onclick/onkeydown actions on the checkboxes
                                The container span element sets the class as checked|unchecked and calls javascript to set charting parameters
                                The css controls whether the checked or unchecked box is displayed.
                            -->
                                    <td class="{$selectionClass}">
                                        <span name="{$checkboxId}" class="unchecked"
                                            onclick="var newState=setCheckboxes('{$checkboxId}',this.className); this.className=newState; setXformsControl('setVariable-entryId','{$entryIRI}');  setXformsControl('setVariable-plotType','{$plotType}'); setXformsControl('setVariable-dateElementExtension','{$dateElementExtension}'); setXformsControl('setVariable-variableElementExtension','{$variableElementExtension}'); setXformsControl('setVariable-variableElementValue','{$variableElementValue}'); setXformsControl('setVariable-variableElementDisplayName','{$variableDisplayName}'); setXformsControl('setVariable-valueElementExtension','{$valueElementExtension}');  setXformsControl('setVariable-action',newState); callXformsAction('main-model','set-chart-variable'); ">
                                            <span class="unchecked">
                                                <input type="checkbox" onclick="return false"
                                                  onkeydown="return false"/>
                                            </span>
                                            <span class="checked">
                                                <input type="checkbox" onclick="return false"
                                                  onkeydown="return false" checked="yes"/>
                                            </span>
                                        </span>
                                    </td>

                                    <td>
                                        <xsl:value-of select="$variableDisplayName"/>
                                    </td>
                                    <!-- Looking for the entry (cda:observation) in the organizer that has the specified date and variable.
                                         The entry is in the second component of the ME organizer.
                                         This contains a set of organizers with the effectiveTime attribute set to the time they were recorded.
                                         Within each of those organizers is a set of components (X) that contain an observation (simple entry) or an organizer (enumerated class entry)
                                         which contains two components, the first with the observation, the second with the set of supplementary data sets.
                                         So the recorded values are in the first cda:observation found with the components (X) -->
                                    <xsl:for-each select="$dateList">
                                        <xsl:variable name="date" select="."/>
                                        <xsl:variable name="entry"
                                            select="$organizer/cda:component[2]/cda:organizer/cda:component//cda:observation[1][cda:value[@extension = $dateElementExtension][@value = $date]][cda:value[@extension = $variableElementExtension][@value = $variable]]"/>

                                        <!-- It is possible to have more than one value at the specified date/time.
                                             Only show the unique values (i.e. if the same value is recorded more than once for the same date/time then only display it once)-->
                                        <xsl:variable name="values"
                                            select="distinct-values($entry/cda:value[@extension = $valueElementExtension]/@value)"/>
                                        <td>
                                            <xsl:for-each select="$values">
                                                <!-- Get the first instance of the value -->
                                                <xsl:variable name="distinctValue" select="."/>
                                                <xsl:variable name="element"
                                                  select="($entry/cda:value[@extension = $valueElementExtension][@value = $distinctValue])[1]"/>
                                                <xsl:variable name="value"
                                                  select="
                                                        if ($element/@displayName != '') then
                                                            $element/@displayName
                                                        else
                                                            $element/@value"/>
                                                <xsl:variable name="type"
                                                  select="
                                                        if ($element/@xsi:type != '') then
                                                            $element/@xsi:type
                                                        else
                                                            'xs:string'"/>
                                                <xsl:if test="position() gt 1">
                                                  <br/>
                                                </xsl:if>
                                                <span class="ISO13606-Data">
                                                  <xsl:value-of
                                                  select="cityEHRFunction:outputValue($value, $type)"
                                                  />
                                                </span>
                                            </xsl:for-each>
                                        </td>
                                    </xsl:for-each>
                                </tr>
                            </xsl:for-each>
                        </tbody>
                    </table>
                </div>
            </xsl:if>

            <!-- Interval data pattern -->
            <xsl:if test="$plotType = 'interval'">
                <div class="tableContainer">
                    <table class="CDAEntryList">
                        <tbody>
                            <!-- Debugging -->
                            <!--
                        <tr>
                            <td/>
                            <td><xsl:value-of select="$variableList"/></td>
                        </tr>
                        -->
                            <xsl:for-each select="$variableList">
                                <xsl:variable name="variable" select="."/>
                                <!-- If variable does not have a display name, then use the value instead -->
                                <xsl:variable name="displayName"
                                    select="
                                        if (exists($organizer/cda:component[2]/cda:organizer//cda:observation/cda:value[@extension = $variableElementExtension][@value = $variable]/@displayName)) then
                                            $organizer/cda:component[2]/cda:organizer//cda:observation/cda:value[@extension = $variableElementExtension][@value = $variable]/@displayName
                                        else
                                            ''"/>
                                <xsl:variable name="variableDisplayName"
                                    select="
                                        if ($displayName != '') then
                                            $displayName[1]
                                        else
                                            $variable"/>

                                <tr>
                                    <!-- Value of plotted variable (first non-xs:date type element) -->
                                    <xsl:variable name="variableElementValue" select="$variable"/>
                                    <!-- CheckboxId is unique - used to link identical variables and also to trigger setting the variable as a parameter in the model -->
                                    <xsl:variable name="checkboxId"
                                        select="concat($entryIRI, $variableElementExtension, $variableElementValue)"/>
                                    <!-- Would use checkboxIdURI, but seems to get unescaped in name for some reason, so might as well use checkboxId -->
                                    <xsl:variable name="checkboxIdURI"
                                        select="encode-for-uri($checkboxId)"/>

                                    <!-- This one works with characters
                                    <td>
                                    <a name="{$checkboxId}" class="unchecked" onClick="var newState=setCheckboxes('{$checkboxId}',this.className); this.className=newState; setXformsControl('setVariable-entryId','{$entryIRI}'); setXformsControl('setVariable-dateElementExtension','{$dateElementExtension}'); setXformsControl('setVariable-variableElementExtension','{$variableElementExtension}'); setXformsControl('setVariable-variableElementValue','{$variableElementValue}'); setXformsControl('setVariable-valueElementExtension','{$valueElementExtension}');  setXformsControl('setVariable-action',newState); callXformsAction('main-model','set-chart-variable'); ">
                                    <span class="unchecked">&#9723;</span>
                                    <span class="checked">&#9745;</span>
                                    </a>
                                    </td>
                                -->
                                    <!-- The check boxes are displayed checked and unchecked.
                                    The standard behaviour of the checkboxes is prevented by the onclick/onkeydown actions on the checkboxes
                                    The container span element sets the class as checked|unchecked and calls javascript to set charting parameters
                                    The css controls whether the checked or unchecked box is displayed.
                                -->
                                    <td class="{$selectionClass}">
                                        <span name="{$checkboxId}" class="unchecked"
                                            onclick="var newState=setCheckboxes('{$checkboxId}',this.className); this.className=newState; setXformsControl('setVariable-entryId','{$entryIRI}');  setXformsControl('setVariable-plotType','{$plotType}'); setXformsControl('setVariable-dateElementExtension','{$dateElementExtension}'); setXformsControl('setVariable-variableElementExtension','{$variableElementExtension}'); setXformsControl('setVariable-variableElementValue','{$variableElementValue}'); setXformsControl('setVariable-variableElementDisplayName','{$variableDisplayName}'); setXformsControl('setVariable-valueElementExtension','{$valueElementExtension}');  setXformsControl('setVariable-action',newState); callXformsAction('main-model','set-chart-variable'); ">
                                            <span class="unchecked">
                                                <input type="checkbox" onclick="return false"
                                                  onkeydown="return false"/>
                                            </span>
                                            <span class="checked">
                                                <input type="checkbox" onclick="return false"
                                                  onkeydown="return false" checked="yes"/>
                                            </span>
                                        </span>
                                    </td>

                                    <td>
                                        <xsl:value-of select="$variableDisplayName"/>
                                    </td>
                                    <!-- One cell for each recorded entry for this variable. 
                                     The date interval pair is made as xs:dateTime/xs:dateTime 
                                     Then just need the distinct values of these -->
                                    <xsl:for-each
                                        select="distinct-values($organizer/cda:component[2]/cda:organizer//cda:observation[cda:value[@extension = $variableElementExtension][@value = $variableElementValue]]/concat(cda:value[@extension = $dateElementExtension]/@value, '/', cda:value[@extension = $valueElementExtension]/@value))">
                                        <xsl:variable name="recordedRange" select="."/>
                                        <td>
                                            <xsl:value-of
                                                select="cityEHRFunction:outputRecordedRange($recordedRange)"
                                            />
                                        </td>
                                    </xsl:for-each>

                                </tr>
                            </xsl:for-each>
                        </tbody>
                    </table>
                </div>
            </xsl:if>
            <!-- End of interval plotType -->

            <!-- Plotted data pattern.
                 One row for each element in the entry.
                 First column shows the element displayName, other columns show value at each date -->
            <xsl:if test="$plotType = 'plotted'">
                <xsl:variable name="elementList"
                    select="$observationTemplate//cda:value[@extension != $dateElementExtension][exists(@value)]"/>
                <div class="tableContainer">
                    <table class="CDAEntryList">
                        <thead>
                            <tr>
                                <th class="{$selectionClass}"><!-- For checkbox --></th>
                                <th><!-- For element displayName --></th>
                                <xsl:for-each select="$dateList">
                                    <th>
                                        <xsl:value-of select="cityEHRFunction:outputDateValue(.)"/>
                                    </th>
                                </xsl:for-each>
                            </tr>
                        </thead>
                        <tbody>
                            <xsl:for-each select="$elementList">
                                <xsl:variable name="element" select="."/>
                                <!-- If variable does not have a display name, then use the value instead -->
                                <xsl:variable name="displayName"
                                    select="$element/@cityEHR:elementDisplayName"/>
                                <xsl:variable name="elementIRI" select="$element/@extension"/>

                                <tr>
                                    <!-- Checkbox -->
                                    <td class="{$selectionClass}">
                                        <!-- Goes here if can be plotted -->
                                    </td>

                                    <td>
                                        <xsl:value-of select="$displayName"/>
                                    </td>
                                    <!-- Looking for the entry (cda:observation) in the organizer that has the specified date and element.
                                        The entry is in the second component of the ME organizer.
                                        This contains a set of organizers with the effectiveTime attribute set to the time they were recorded.
                                        Within each of those organizers is a set of components (X) that contain an observation (simple entry) or an organizer (enumerated class entry)
                                        which contains two components, the first with the observation, the second with the set of supplementary data sets.
                                        So the recorded values are in the first cda:observation found with the components (X) -->
                                    <xsl:for-each select="$dateList">
                                        <xsl:variable name="date" select="."/>
                                        <xsl:variable name="entry"
                                            select="$organizer/cda:component[2]/cda:organizer/cda:component//cda:observation[1][cda:value[@extension = $dateElementExtension][@value = $date]]"/>

                                        <!-- It is possible to have more than one value at the specified date/time -->
                                        <xsl:variable name="values"
                                            select="$entry/cda:value[@extension = $elementIRI]"/>
                                        <td>
                                            <xsl:for-each select="$values">
                                                <xsl:variable name="element" select="."/>
                                                <xsl:variable name="value"
                                                  select="
                                                        if ($element/@displayName != '') then
                                                            $element/@displayName
                                                        else
                                                            $element/@value"/>
                                                <xsl:variable name="type"
                                                  select="
                                                        if ($element/@xsi:type != '') then
                                                            $element/@xsi:type
                                                        else
                                                            'xs:string'"/>
                                                <xsl:if test="position() gt 1">
                                                  <br/>
                                                </xsl:if>
                                                <span class="ISO13606-Data">
                                                  <xsl:value-of
                                                  select="cityEHRFunction:outputValue($value, $type)"
                                                  />
                                                </span>
                                            </xsl:for-each>
                                        </td>
                                    </xsl:for-each>
                                </tr>
                            </xsl:for-each>
                        </tbody>
                    </table>
                </div>
            </xsl:if>
            <!-- End of plotted data pattern -->

            <!-- Non-plotted data pattern -->
            <xsl:if test="$plotType = 'non-plotted'">
                <!-- Date variable is the effectiveTime in the organizer -->
                <xsl:variable name="organizerList"
                    select="$organizer/cda:component[2]/cda:organizer"/>
                <xsl:variable name="fullDateList"
                    select="cityEHRFunction:sortAscending($organizerList/@effectiveTime)"/>
                <xsl:variable name="dateList"
                    select="
                        if ($viewHistory = 'historic') then
                            $fullDateList
                        else
                            $fullDateList[last()]"/>

                <xsl:for-each select="$dateList">
                    <xsl:variable name="date" select="."/>
                    <xsl:variable name="datedOrganizer"
                        select="$organizerList[@effectiveTime = $date]"/>
                    <span class="ISO13606-Element-DisplayName">
                        <xsl:value-of
                            select="
                                if ($viewHistory = 'historic') then
                                    cityEHRFunction:outputValue($date, 'xs:dateTime')
                                else
                                    ''"
                        />
                    </span>
                    <xsl:call-template name="outputBasicMultipleEntry">
                        <xsl:with-param name="entryIRI" select="$entryIRI"/>
                        <xsl:with-param name="observationTemplate" select="$observationTemplate"/>
                        <xsl:with-param name="organizer" select="$datedOrganizer"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:if>

        </xsl:if>
        <!-- End of composition type view -->


    </xsl:template>


    <!-- === outputBasicMultipleEntry ============================
         Handles each entry in the multiple entry, when the data pattern is not one of the plotted types.
         The organizer is from the second component in the multiple entry and contains a set of components with
             cda:observation    (simple entry)
             containing cda:entryRelationship      (enuermated class entry)
             
         Multiple entries are laid out as a table, unless there is only one element in the entry
         In this case a (simpler) list is used.
         -->

    <xsl:template name="outputBasicMultipleEntry">
        <xsl:param name="entryIRI"/>
        <xsl:param name="observationTemplate"/>
        <xsl:param name="organizer"/>

        <!-- Get the count of elements in the template entry 
             - layout as list for single element, table for more than one -->
        <xsl:variable name="elementCount" as="xs:integer"
            select="count($observationTemplate/cda:value)"/>

        <!-- Only need to display entries that have some data recorded -->
        <xsl:variable name="entryList"
            select="$organizer/cda:component[descendant::cda:value[@value != '']]"/>

        <!-- Only one element - layout is a list
             2025-03-20 - Deprecated - simpler to process HTML if all cases are handled in the same way-->
        <xsl:if test="false() and $elementCount = 1">
            <ul class="CDAEntryList">
                <!-- Only include the header if the (one) element has a displayName  -->
                <xsl:if
                    test="exists($observationTemplate/cda:value[@cityEHR:elementDisplayName != ''])">
                    <li>
                        <span class="ISO13606-Element-DisplayName">
                            <xsl:value-of
                                select="$observationTemplate/cda:value/@cityEHR:elementDisplayName"
                            />
                        </span>
                    </li>
                </xsl:if>

                <!-- One list item for each entry.
                     Entry in the list is actually a cda:component that contains cda:observation, etc
                     There should only be one element, but don't assume that (in case the observation template doesn't match the observation -->
                <xsl:for-each select="$entryList">
                    <xsl:variable name="entry" select="."/>
                    <xsl:variable name="element" select="$entry/cda:observation/cda:value[1]"/>

                    <!-- Set up the supplementary entry for processing on selection of element
                         Since there is only one element, the supplementary entry should always match the origin of that element -->
                    <xsl:variable name="supplementaryEntry"
                        select="$entry/cda:observation/cda:entryRelationship[@cityEHR:origin = $element/@extension]"/>

                    <li>
                        <xsl:call-template name="renderCDAElement">
                            <xsl:with-param name="element" select="$element"/>
                            <xsl:with-param name="entryIRI" select="$entryIRI"/>
                            <xsl:with-param name="entryType" select="'MultipleEntry'"/>
                            <xsl:with-param name="entryLayout" select="'Ranked'"/>
                            <xsl:with-param name="labelWidth" select="''"/>
                            <xsl:with-param name="supplementaryEntry" select="$supplementaryEntry"/>
                        </xsl:call-template>
                    </li>

                </xsl:for-each>
            </ul>
        </xsl:if>

        <!-- More than one element - layout is a table -->
        <xsl:if test="$elementCount != 1">
            <!-- 2025-03-20 - Deprecated - just output the tableContainer div -->
        </xsl:if>
        
        <div class="tableContainer">
            <table class="CDAEntryList">
                <!-- Only include the header if there is at least one displayName as a column title -->
                <xsl:if
                    test="exists($observationTemplate/cda:value[@cityEHR:elementDisplayName != ''])">
                    <thead>
                        <!-- Header rows with display names of elements
                    First header row contains the element/cluster cityEHR:elementDisplayNames, if there are any. 
                -->
                        <tr>
                            <xsl:for-each select="$observationTemplate/cda:value">
                                <th>
                                    <span class="ISO13606-Element-DisplayName">
                                        <xsl:value-of select="./@cityEHR:elementDisplayName"/>
                                    </span>
                                </th>
                            </xsl:for-each>
                        </tr>
                    </thead>
                </xsl:if>

                <tbody>
                    <xsl:for-each select="$entryList">
                        <xsl:variable name="entry" select="."/>
                        <tr>
                            <!-- Multiple entry organizer contains simple entries (just allowing cda:observation here)
                                     ^^^ should also have act, encounter, supply, substanceAdministration -->
                            <xsl:for-each select="$entry/cda:observation/cda:value">
                                <xsl:variable name="element" select="."/>
                                <xsl:variable name="supplementaryEntry"
                                    select="$entry/cda:observation/cda:entryRelationship[@cityEHR:origin = $element/@extension]"/>
                                <td>
                                    <xsl:call-template name="renderCDAElement">
                                        <xsl:with-param name="element" select="$element"/>
                                        <xsl:with-param name="entryIRI" select="$entryIRI"/>
                                        <xsl:with-param name="entryType" select="'MultipleEntry'"/>
                                        <xsl:with-param name="entryLayout" select="'Ranked'"/>
                                        <xsl:with-param name="labelWidth" select="''"/>
                                        <xsl:with-param name="supplementaryEntry"
                                            select="$supplementaryEntry"/>
                                    </xsl:call-template>
                                </td>
                            </xsl:for-each>

                            <!--  2025-04-15 Deprecated - now using entryRelationship
                                      Multiple entry organizer contains entries with enumerated class values.
                                     The entry is represented as an organizer.
                                      First component in the organizer is the entry, second component is the set of supplementary data sets -->
                            <xsl:if
                                test="false() and $entry/cda:organizer[@classCode = 'EnumeratedClassEntry']">

                                <!-- Set up the main entry that has enumeratedClass element -->
                                <xsl:variable name="mainEntry"
                                    select="$entry/cda:organizer/cda:component[1]/cda:observation"/>

                                <!-- Set up the supplementary entry for processing on selection of element -->
                                <xsl:variable name="supplementary-entry-organizer"
                                    select="$entry/cda:organizer/cda:component[2]/cda:organizer"/>

                                <xsl:for-each select="$mainEntry/cda:value">
                                    <xsl:variable name="element" select="."/>
                                    <xsl:variable name="elementIRI" select="$element/@extension"/>
                                    <xsl:variable name="supplementaryEntry"
                                        select="$supplementary-entry-organizer/cda:component[cda:observation/cda:id/@cityEHR:origin = $elementIRI]"/>

                                    <td>
                                        <xsl:call-template name="renderCDAElement">
                                            <xsl:with-param name="element" select="$element"/>
                                            <xsl:with-param name="entryIRI" select="$entryIRI"/>
                                            <xsl:with-param name="entryType"
                                                select="'MultipleEntry'"/>
                                            <xsl:with-param name="entryLayout" select="'Ranked'"/>
                                            <xsl:with-param name="labelWidth" select="''"/>
                                            <xsl:with-param name="supplementaryEntry"
                                                select="$supplementaryEntry"/>
                                        </xsl:call-template>

                                    </td>
                                </xsl:for-each>
                            </xsl:if>

                        </tr>
                    </xsl:for-each>
                </tbody>
            </table>
        </div>

    </xsl:template>

    <!-- === Render element (i.e. cda:value, cda:playingEntity, etc) ============================
        The element is rendered based on its attributes, not the name of the cda element.
        Which means this works for CDA's representation of elements in any type of entry.
        
        Recursive call to handle clusters.
        
        Can be called without the supplementaryEntry if necessary.
        If set, supplementaryEntry is a cda:entryRelationship
        
        ======================================================================================= -->

    <xsl:template name="renderCDAElement">
        <xsl:param name="element"/>
        <xsl:param name="entryIRI"/>
        <xsl:param name="entryType"/>
        <xsl:param name="entryLayout"/>
        <xsl:param name="labelWidth"/>
        <xsl:param name="supplementaryEntry"/>

        <xsl:variable name="elementIRI" select="$element/@extension"/>
        <xsl:variable name="id" select="substring-after($elementIRI, 'Element:')"/>
        <xsl:variable name="fieldLength"
            select="
                if (exists($element/@cityEHR:fieldLength)) then
                    $element/@cityEHR:fieldLength
                else
                    ''"/>

        <!-- Check to see if this is a cluster or an element -->
        <xsl:variable name="iso-13606Type"
            select="
                if (exists($element/@value)) then
                    'ISO13606-Element'
                else
                    'ISO13606-Cluster'"/>

        <!-- Check to see if this is element/cluster has any value set -->
        <xsl:variable name="hasValueSet"
            select="
                if ($iso-13606Type = 'ISO13606-Element' and $element/@value != '') then
                    'true'
                else
                    if ($iso-13606Type = 'ISO13606-Cluster' and $element//cda:value/@value != '') then
                        'true'
                    else
                        'false'"/>

        <xsl:if test="$hasValueSet = 'true'">
            <ul class="{$iso-13606Type}">

                <!-- Output the element displayName for simple entries, not for multipleEntries -->
                <xsl:if test="$entryType = 'Simple'">
                    <!-- Since we are setting width in em, use half the character length of the width - this usually works fine.
                        Only set the width in Ranked sections -->
                    <xsl:variable name="width"
                        select="
                            if ($labelWidth castable as xs:integer) then
                                round(($labelWidth + 4) div 2)
                            else
                                ''"/>
                    <xsl:variable name="widthStyle"
                        select="
                            if ($entryLayout = 'Ranked' and $width castable as xs:integer) then
                                concat('width:', $width, 'em;')
                            else
                                ''"/>

                    <li class="ISO13606-Element-DisplayName" style="{$widthStyle}">
                        <xsl:value-of select="$element/@cityEHR:elementDisplayName"/>
                    </li>
                </xsl:if>

                <!-- === Recursively call this template if processing a cluster.
            The layout is toggled at each nest of cluster
        -->
                <xsl:if test="$iso-13606Type = 'ISO13606-Cluster'">
                    <xsl:for-each select="$element/cda:value">
                        <xsl:variable name="clusterElement" select="."/>
                        <xsl:variable name="entryLayoutToggle"
                            select="
                                if ($entryLayout = 'Ranked') then
                                    'Unranked'
                                else
                                    'Ranked'"/>
                        <xsl:variable name="clusterLabelWidth"
                            select="$clusterElement/@cityEHR:labelWidth"/>
                        <li class="{$entryLayout}">
                            <xsl:call-template name="renderCDAElement">
                                <xsl:with-param name="element" select="$clusterElement"/>
                                <xsl:with-param name="entryIRI" select="$entryIRI"/>
                                <xsl:with-param name="entryType" select="'Simple'"/>
                                <xsl:with-param name="entryLayout" select="$entryLayoutToggle"/>
                                <xsl:with-param name="labelWidth" select="$clusterLabelWidth"/>
                                <xsl:with-param name="supplementaryEntry" select="()"/>
                            </xsl:call-template>
                        </li>
                    </xsl:for-each>
                    <li class="LayoutFooter">&#160;</li>
                </xsl:if>

                <!-- Processing an element -->
                <xsl:if test="$iso-13606Type = 'ISO13606-Element'">

                    <!-- Changed 2021-10-15 to use base64Binary in the value attribute for media and patientMedia  -->
                    <xsl:if
                        test="$element/@cityEHR:elementType = ('#CityEHR:ElementProperty:media', '#CityEHR:Property:ElementType:media', '#CityEHR:ElementProperty:patientMedia', '#CityEHR:Property:ElementType:patientMedia')">
                        <xsl:variable name="displayImageClass"
                            select="
                                if ($element/@value != '') then
                                    'media'
                                else
                                    'hidden'"/>
                        <li class="ISO13606-Data  {$entryIRI}/{$elementIRI}">
                            <img src="data:image/*;base64, {xs:base64Binary($element/@value)}"
                                class="{$displayImageClass}"/>

                            <!-- Old way, before 2021-10-15 -->
                            <!--
                            <img name="{$element/@value}"
                                src="{$view-parameters/staticFileRoot}/applications/{$applicationLocation}/media/{$element/@value}.png">
                                -->
                            <!-- Add attribute if the element (image) has fieldlength set -->
                            <!-- Not doing this any more - 2014-11-14
                                <xsl:if test="string-length($fieldLength) &gt; 0">
                                    <xsl:attribute name="width">
                                        <xsl:value-of select="concat($fieldLength,'em')"/>
                                    </xsl:attribute>
                                </xsl:if>
                                -->
                            <!--
                            </img>
                            -->
                        </li>
                    </xsl:if>

                    <!-- If element is patientMedia type then image is embedded in the value -->
                    <!-- Old way, before 2021-10-15 -->
                    <!--
                    <xsl:if test="$element/@cityEHR:elementType = '#CityEHR:ElementProperty:patientMedia'">
                        <li class="ISO13606-Data">
                            <img src="{concat($element/@value,', ',$element)}" alt=""/>
                        </li>
                    </xsl:if>
                    -->

                    <!-- Anything else, show the displayName or value ***jc -->
                    <xsl:if
                        test="not($element/@cityEHR:elementType = ('#CityEHR:ElementProperty:media', '#CityEHR:Property:ElementType:media', '#CityEHR:ElementProperty:patientMedia', '#CityEHR:Property:ElementType:patientMedia'))">
                        <li class="ISO13606-Data  {$entryIRI}/{$elementIRI}">
                            <xsl:variable name="value"
                                select="
                                    if ($element/@displayName != '') then
                                        $element/@displayName
                                    else
                                        $element/@value"/>
                            <xsl:variable name="type"
                                select="
                                    if ($element/@xsi:type != '') then
                                        $element/@xsi:type
                                    else
                                        'xs:string'"/>

                            <xsl:value-of select="cityEHRFunction:outputValue($value, $type)"/>

                            <!-- Display supplementary data (SDS) if available -->
                            <xsl:if test="exists($supplementaryEntry)">
                                <xsl:call-template name="renderSupplementaryEntry">
                                    <xsl:with-param name="supplementaryEntry"
                                        select="$supplementaryEntry"/>
                                </xsl:call-template>
                            </xsl:if>
                        </li>

                        <!-- Display units for element, if they exist -->
                        <xsl:if test="$element/@units != '' and $entryType = 'Simple'">
                            <li class="ISO13606-Element-Units">
                                <xsl:value-of select="$element/@units"/>
                            </li>
                        </xsl:if>
                    </xsl:if>
                </xsl:if>

                <li class="LayoutFooter">&#160;</li>

            </ul>
        </xsl:if>

    </xsl:template>


    <!-- ====================================================================
        Check whether a section or entry (as observation, encounter, etc) has any values recorded
        Returns true when a value is detected, otherwise false   
        
        Note that this only works if all temaplate documents have values set to "", including for xs:booleam types in multipleEntry templates
        
        Updated 2015-07-28
        This needs to work on saved compositions as well as published compositions
        So data in multiple entry organisers or in hidden sctions/entries/elements needs to be ignored
        
        Finds:
        
        <value xsi:type="xs:date" value="" units="" code="" codeSystem="" displayName=""
        cityEHR:elementDisplayName="Sample Date"
        extension="#ISO-13606:Element:SampleDate"
        root="cityEHR"
        cityEHR:elementType="#CityEHR:ElementProperty:simpleType"
        cityEHR:RequiredValue="Optional"/>
        
        
        <playingEntity xsi:type="xs:string" value="" units="" code="" codeSystem="" displayName=""
        cityEHR:elementDisplayName="Clinic Id"
        cityEHR:elementType="#CityEHR:ElementProperty:simpleType"
        cityEHR:RequiredValue="Optional"/>
        
        etc.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:entryRecorded">
        <xsl:param name="component"/>

        <!-- Get all visible entries
             Split them into simple entry, multiple entry and enumerated class entry -->
        <xsl:variable name="visibleEntries"
            select="$component/descendant-or-self::cda:entry[not(ancestor-or-self::*/@cityEHR:visibility = 'false')]"/>
        <xsl:variable name="visibleSimpleEntries"
            select="$visibleEntries[not(descendant::cda:organizer/@classCode = ('MultipleEntry', 'EnumeratedClassEntry'))]"/>
        <xsl:variable name="visibleMultipleEntries"
            select="$visibleEntries[descendant::cda:organizer/@classCode = 'MultipleEntry']"/>
        <xsl:variable name="visibleEnumeratedClassEntries"
            select="$visibleEntries[descendant::cda:organizer/@classCode = 'EnumeratedClassEntry']"/>

        <!-- Test for data in any entry.
             Must have a value in an element that is visible -->
        <xsl:variable name="hasSimpleEntryData"
            select="
                if (exists($visibleEntries[descendant::cda:value[@value != ''][not(@cityEHR:visibility = 'false')]])) then
                    'true'
                else
                    'false'"/>
        <xsl:variable name="hasMEEntryData"
            select="
                if (exists($visibleMultipleEntries[descendant::cda:organizer[@classCode = 'MultipleEntry']/cda:component[2]/descendant::cda:value[@value != ''][not(@cityEHR:visibility = 'false')]])) then
                    'true'
                else
                    'false'"/>
        <xsl:variable name="hasECEntryData"
            select="
                if (exists($visibleEnumeratedClassEntries[descendant::cda:organizer[@classCode = 'EnumeratedClassEntry']/cda:component[1]/descendant::cda:value[@value != ''][not(@cityEHR:visibility = 'false')]])) then
                    'true'
                else
                    'false'"/>

        <xsl:value-of
            select="
                if (($hasSimpleEntryData, $hasMEEntryData, $hasECEntryData) = 'true') then
                    'true'
                else
                    'false'"/>

    </xsl:function>


    <!-- ====================================================================
        Check whether an entry (as encounter) has any participants recorded
        Returns true when a value is detected, otherwise false       
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:encounterEntryRecorded">
        <xsl:param name="entry"/>

        <xsl:value-of
            select="
                if (exists($entry/descendant::playingEntity[@xsi:type != 'xs:boolean']/@value != '')) then
                    'true'
                else
                    if (exists($entry/descendant::value[@xsi:type = 'xs:boolean'][@value = $view-parameters/displayBoolean/value/@value])) then
                        'true'
                    else
                        'false'"/>

    </xsl:function>


    <!-- ====================================================================
         Output a value, based on its type.
         Need to cater for xs:date recorded as dateTime, so take only the first 10 characters of this one
         ==================================================================== -->
    <xsl:function name="cityEHRFunction:outputValue">
        <xsl:param name="value"/>
        <xsl:param name="type"/>

        <xsl:value-of
            select="
                if ($type = 'xs:dateTime' and $value castable as xs:dateTime) then
                    format-dateTime(xs:dateTime($value), $session-parameters/dateTimeDisplayFormat, $session-parameters/languageCode, (), ())
                else
                    if ($type = 'xs:date' and substring($value, 1, 10) castable as xs:date) then
                        format-date(xs:date(substring($value, 1, 10)), $session-parameters/dateDisplayFormat, $session-parameters/languageCode, (), ())
                    else
                        if ($type = 'xs:time' and $value castable as xs:time) then
                            format-time(xs:time($value), $session-parameters/timeDisplayFormat, $session-parameters/languageCode, (), ())
                        else
                            if ($type = 'xs:boolean' and exists($session-parameters/displayBoolean/value[@value = $value])) then
                                $session-parameters/displayBoolean/value[@value = $value]
                            else
                                $value"
        />
    </xsl:function>


    <!-- ====================================================================
        Output a date or dateTime value, based on its type.
        Use this when the value should be either a date, dateTime or time
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:outputDateValue">
        <xsl:param name="value"/>

        <xsl:value-of
            select="
                if ($value castable as xs:dateTime) then
                    format-dateTime(xs:dateTime($value), $session-parameters/dateTimeDisplayFormat, $session-parameters/languageCode, (), ())
                else
                    if ($value castable as xs:date) then
                        format-date(xs:date($value), $session-parameters/dateDisplayFormat, $session-parameters/languageCode, (), ())
                    else
                        if ($value castable as xs:time) then
                            format-time(xs:time($value), $session-parameters/timeDisplayFormat, $session-parameters/languageCode, (), ())
                        else
                            $value"
        />
    </xsl:function>


    <!-- ====================================================================
         Sort a sequence based on values of its nodes.
         Returns the distinct values, sorted from lowest to highest
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:sortAscending">
        <xsl:param name="sequence"/>
        <xsl:for-each select="distinct-values($sequence)">
            <xsl:sort select="." order="ascending"/>
            <xsl:value-of select="."/>
        </xsl:for-each>
    </xsl:function>

    <!-- ====================================================================
        Sort a sequence based on values of its nodes.
        Returns the distinct values, sorted from highest to lowest
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:sortDescending">
        <xsl:param name="sequence"/>
        <xsl:for-each select="distinct-values($sequence)">
            <xsl:sort select="." order="descending"/>
            <xsl:value-of select="."/>
        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
         Get the type of plot for a multipleEntry
         Returns the following types:
                 
         interval      
                         Variable (first element that is enumeratedValue or enumeratedClass)
                         startTime (first xs:date or xs:dateTime element)
                         endTime (second xs:date or xs:dateTime element)
         
         timeseries      
                         Time (xs:date or xs:dateTime element)
                         Variable (first element that is enumeratedValue or enumeratedClass)
                         Value (last element that is xs:double or xs:integer)

         
         plotted         
                         Time (xs:date or xs:dateTime element) or use the effectiveTime
                         One or more value (last element that is xs:double or xs:integer)
         
         non-plotted   
                         Doesn't match any of these patterns
                         
         Note that interval and timeseries patterns must exist at the top level elements, not within clusters.
         Plotted pattern can exist with clusters.
        ==================================================================== -->

    <xsl:function name="cityEHRFunction:getPlotType">
        <xsl:param name="entryTemplate"/>

        <xsl:variable name="interval"
            select="
                if (exists($entryTemplate[cda:value[@xsi:type = 'xs:date' or @xsi:type = 'xs:dateTime'][2]][cda:value[@cityEHR:elementType = '#CityEHR:ElementProperty:enumeratedValue' or @cityEHR:elementType = '#CityEHR:ElementProperty:enumeratedClass']])) then
                    'true'
                else
                    'false'"/>

        <xsl:variable name="timeseries"
            select="
                if ($interval = 'false' and exists($entryTemplate[cda:value[@xsi:type = 'xs:date' or @xsi:type = 'xs:dateTime']][cda:value[@cityEHR:elementType = '#CityEHR:ElementProperty:enumeratedValue' or @cityEHR:elementType = '#CityEHR:ElementProperty:enumeratedClass']][cda:value[@xsi:type = 'xs:double' or @xsi:type = 'xs:integer']])) then
                    'true'
                else
                    'false'"/>

        <xsl:variable name="plotted"
            select="
                if ($interval = 'false' and $timeseries = 'false' and exists($entryTemplate[cda:value[@xsi:type = 'xs:double' or @xsi:type = 'xs:integer']])) then
                    'true'
                else
                    'false'"/>

        <xsl:value-of
            select="
                if ($interval = 'true') then
                    'interval'
                else
                    if ($timeseries = 'true') then
                        'timeseries'
                    else
                        if ($plotted = 'true') then
                            'plotted'
                        else
                            'non-plotted'"/>

    </xsl:function>


    <!-- ====================================================================
         Get expanded entry variable list.
         Returns the list of elementIRIs or an empty list.
         The organizer contains the template entry in its first component plus a set of cda:observations containing the expanded ME values
         The template entry will have an empty value for the expanded element
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getExpandedEntryVariables">
        <xsl:param name="organizer"/>

        <xsl:variable name="expandedVariableList"
            select="distinct-values($organizer/cda:component[1]//cda:value[@cityEHR:Scope = '#CityEHR:ElementProperty:Expanded'][@value != '']/@value)"/>

        <xsl:for-each select="$expandedVariableList">
            <xsl:sequence select="."/>
        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        Output a recorded range.
        The range is in the form xs:dataTime/xs:dateTime
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:outputRecordedRange">
        <xsl:param name="recordedRange"/>

        <xsl:variable name="rangeStart" select="substring-before($recordedRange, '/')"/>
        <xsl:variable name="rangeEnd" select="substring-after($recordedRange, '/')"/>

        <xsl:value-of
            select="
                if ($rangeEnd = '') then
                    cityEHRFunction:outputValue($rangeStart, ('xs:date', 'xs:dateTime', 'xs:time'))
                else
                    (cityEHRFunction:outputValue($rangeStart, ('xs:date', 'xs:dateTime', 'xs:time')), 'to', cityEHRFunction:outputValue($rangeEnd, ('xs:date', 'xs:dateTime', 'xs:time')))"/>

    </xsl:function>


</xsl:stylesheet>
