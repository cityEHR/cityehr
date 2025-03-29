<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    CDA2XForm-Module.xsl
    Utilities for transformation of CDA document to XForm, included in CDA2XForm and CDA2XFormFile
    
    Root of the CDA document is cda:ClinicalDocument, passed to renderCDADocument template
    Generates an XForm to be displayed in CityEHR
    
    Variables in this stylesheet are for XSLT or for XForms. All Xforms variables start with 'xforms'
       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet version="2.0" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events"
    xmlns:xxf="http://orbeon.org/oxf/xml/xforms" xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:cda="urn:hl7-org:v3"
    xmlns:iso-13606="http://www.iso.org/iso-13606" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" xmlns:saxon="http://saxon.sf.net/" xmlns:svg="http://www.w3.org/2000/svg">

    <!-- === Render CDA Document as XForm ==========================================================================
         Iterate through sections of the form, generating the xthml/xform output.
         This template has matched cda:ClinicalDocument, so iteration on $composition is relative to that. 
         alwaysHidden sections do not need to be rendered.       
        ====================================================================================================== -->


    <xsl:template name="renderCDADocument">
        <xsl:param name="composition"/>
        <xsl:param name="compositionTypeIRI"/>
                
        <!-- Show ISO-13606 Ids in dubugging mode -->
        <xxf:variable name="xformsShowIdClass"
            select="
            if (xxf:instance('viewControls-input-instance')/input[@id = 'showIds'] = 'true') then
            'ISO13606-Id'
            else
            'hidden'"/>
        
        <!-- Show ISO-13606 structure in debugging mode -->
        <xxf:variable name="xformsShowStructureClass"
            select="
            if (xxf:instance('viewControls-input-instance')/input[@id = 'showISO13606'] = 'true') then
            'ISO13606-Structure'
            else
            ''"/>

       <!-- This div contains the whole CDA document -->
        <xhtml:div
            class="ISO13606-Composition {{$xformsShowStructureClass}}"
            cache="{$view-parameters/formCache}">
            
            <!-- Show compositionID is selected for debugging -->
            <xsl:variable name="compositionId" select="$composition/cda:id/@extension"/>
            <xhtml:span class="{{$xformsShowIdClass}}">
                <xsl:value-of select="$compositionId"/>
            </xhtml:span>
            
            <!-- Render header sections (should be maximum of one, but you never know) ***jc deprecated 2023-12 -->
            <xsl:for-each
                select="$composition/cda:component/cda:structuredBody/cda:component/cda:section[not(@cityEHR:visibility = 'alwaysHidden')][@cityEHR:Rendition = 'Header']">
                <xsl:variable name="header" select="."/>

                <xsl:call-template name="renderFormHeader">
                    <xsl:with-param name="section" select="$header"/>
                </xsl:call-template>
            </xsl:for-each>

            <!-- Render top level sections -->

            <xsl:for-each
                select="$composition/cda:component/cda:structuredBody/cda:component/cda:section[not(@cityEHR:visibility = 'alwaysHidden')][not(@cityEHR:Rendition = 'Header')]">
                <xsl:variable name="section" select="."/>
                <xsl:variable name="sectionLayout"
                    select="
                        if (contains($section/@cityEHR:Sequence, 'Unranked')) then
                            'Unranked'
                        else
                            'Ranked'"/>
                <xsl:variable name="crossRefId" select="concat('Composition-1-Section-', string(position()))"/>

                <xsl:call-template name="renderFormSection">
                    <xsl:with-param name="compositionTypeIRI" select="$compositionTypeIRI"/>
                    <xsl:with-param name="section" select="$section"/>
                    <xsl:with-param name="sectionLayout" select="$sectionLayout"/>
                    <xsl:with-param name="crossRefId" select="$crossRefId"/>
                </xsl:call-template>

            </xsl:for-each>
        </xhtml:div>

    </xsl:template>


    <!-- === Render header on a form ==========================================================================
        
         The header is a section that contains (up to) five sub-sections, each of which has a defined place in the header:
         
         1) HeaderTop
         2) HeaderLeft
         3) HeaderRight
         4) HeaderTarget
         5) HeaderSubject
         
         These are laid out in a table grid:
         
         =====================
         |       Top         |
         =====================
         |Left    |     Right|
         =====================
         |Target  | Supplment|
         =====================
         |       Subject     |
         =====================
         
        ===================================================================================================== -->

    <xsl:template name="renderFormHeader">
        <xsl:param name="section"/>

        <xsl:variable name="sectionLabelWidth" select="$section/@cityEHR:labelWidth"/>
        <xsl:variable name="sectionTitle" select="$section/cda:title"/>
        <xsl:variable name="sectionId" select="$section/cda:id/@extension"/>
        <xsl:variable name="sectionLayout" select="'Unranked'"/>

        <xsl:variable name="sectionPath" select="cityEHRFunction:getXPath(saxon:path())"/>

        <!-- Get the sections for the header -->
        <xsl:variable name="headerTop" select="$section/cda:component[1]/cda:section[1]"/>
        <xsl:variable name="headerLeft" select="$section/cda:component[2]/cda:section[1]"/>
        <xsl:variable name="headerRight" select="$section/cda:component[3]/cda:section[1]"/>
        <xsl:variable name="headerTarget" select="$section/cda:component[4]/cda:section[1]"/>
        <xsl:variable name="headerSupplement" select="$section/cda:component[5]/cda:section[1]"/>
        <xsl:variable name="headerSubject" select="$section/cda:component[6]/cda:section[1]"/>

        <xhtml:table width="100%" class="formHeader">
            <xhtml:tbody>
                <xhtml:tr>
                    <xhtml:td align="center" colspan="2">
                        <xsl:if test="exists($headerTop)">
                            <xsl:variable name="headerTopLayout"
                                select="
                                    if ($headerTop/@cityEHR:Sequence = '#CityEHR:Property:Sequence:Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderFormSection">
                                <xsl:with-param name="section" select="$headerTop"/>
                                <xsl:with-param name="sectionLayout" select="$headerTopLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xhtml:td>
                </xhtml:tr>
                <xhtml:tr>
                    <xhtml:td align="left">
                        <xsl:if test="exists($headerLeft)">
                            <xsl:variable name="headerLeftLayout"
                                select="
                                    if ($headerLeft/@cityEHR:Sequence = '#CityEHR:Property:Sequence:Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderFormSection">
                                <xsl:with-param name="section" select="$headerLeft"/>
                                <xsl:with-param name="sectionLayout" select="$headerLeftLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xhtml:td>
                    <xhtml:td align="left">
                        <xsl:if test="exists($headerRight)">
                            <xsl:variable name="headerRightLayout"
                                select="
                                    if ($headerRight/@cityEHR:Sequence = '#CityEHR:Property:Sequence:Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderFormSection">
                                <xsl:with-param name="section" select="$headerRight"/>
                                <xsl:with-param name="sectionLayout" select="$headerRightLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xhtml:td>
                </xhtml:tr>
                <xhtml:tr>
                    <xhtml:td align="left">
                        <xsl:if test="exists($headerTarget)">
                            <xsl:variable name="headerTargetLayout"
                                select="
                                    if ($headerTarget/@cityEHR:Sequence = '#CityEHR:Property:Sequence:Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderFormSection">
                                <xsl:with-param name="section" select="$headerTarget"/>
                                <xsl:with-param name="sectionLayout" select="$headerTargetLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xhtml:td>
                    <xhtml:td align="left">
                        <xsl:if test="exists($headerSupplement)">
                            <xsl:variable name="headerSupplementLayout"
                                select="
                                    if ($headerTarget/@cityEHR:Sequence = '#CityEHR:Property:Sequence:Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderFormSection">
                                <xsl:with-param name="section" select="$headerSupplement"/>
                                <xsl:with-param name="sectionLayout" select="$headerSupplementLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xhtml:td>
                </xhtml:tr>
                <xhtml:tr>
                    <xhtml:td align="center" colspan="2">
                        <xsl:if test="exists($headerSubject)">
                            <xsl:variable name="headerSubjectLayout"
                                select="
                                    if ($headerSubject/@cityEHR:Sequence = '#CityEHR:Property:Sequence:Unranked') then
                                        'Unranked'
                                    else
                                        'Ranked'"/>
                            <xsl:call-template name="renderFormSection">
                                <xsl:with-param name="section" select="$headerSubject"/>
                                <xsl:with-param name="sectionLayout" select="$headerSubjectLayout"/>
                                <xsl:with-param name="crossRefId" select="''"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xhtml:td>
                </xhtml:tr>
            </xhtml:tbody>
        </xhtml:table>

    </xsl:template>


    <!-- === Render section on a form ==========================================================================
         Iterates through the section contents and calls templates to render sections (recursive) or entries.
        ===================================================================================================== -->

    <xsl:template name="renderFormSection">
        <xsl:param name="compositionTypeIRI"/>
        <xsl:param name="section"/>
        <xsl:param name="sectionLayout"/>
        <xsl:param name="crossRefId"/>

        <xsl:variable name="sectionLabelWidth" select="$section/@cityEHR:labelWidth"/>
        <xsl:variable name="sectionTitle" select="$section/cda:title"/>
        <xsl:variable name="sectionId" select="$section/cda:id/@extension"/>

        <xsl:variable name="sectionPath" select="cityEHRFunction:getXPath(saxon:path())"/>

        <!-- Only display section if visibility is 'true' (need logic for this inside the class attribute, since sections may be siblings in the xhtml).
             Also, the rendition of the section may be hidden (in which case, don't display it).
             The compositionDisplay is used when displaying pathways
             Can't have id on the xhtml:ul, since it gets duplicated by Orbeon.
             So have an empty xhtml:span to hold the id -->

        <xhtml:ul
            class="ISO13606-Section {{$xformsShowStructureClass}} {{if (xxf:instance('view-parameters-instance')/compositionDisplay='current' and ({$sectionPath}/@cityEHR:visibility='false' or {$sectionPath}/@cityEHR:rendition=('#CityEHR:EntryProperty:Hidden','#CityEHR:Property:Rendition:Hidden'))) then 'hidden' else ''}}">
            <xhtml:span id="{$crossRefId}"/>
            <xhtml:span class="{{$xformsShowIdClass}}">
                <xsl:value-of select="$sectionId"/>
            </xhtml:span>
            <!-- Only output the section header if it has a display name, or this section is a task in a pathway -->
            <xsl:if test="$sectionTitle[data(.) != ''] or $compositionTypeIRI = '#CityEHR:Pathway'">
                <xhtml:li class="ISO13606-Section-DisplayName">
                    <xsl:value-of select="$sectionTitle"/>
                    <!-- User interaction if this section is a pathway task -->
                    <xsl:if test="$compositionTypeIRI = '#CityEHR:Pathway'">
                        <xxf:variable name="xformsSection" select="{$sectionPath}"/>
                        <!-- Enter or show the status (use sessionStatus for this).
                        If the status is completed and the outcome is completed, then status cannot be changed.
                        If the status is charted or inProgess, then the status can be changed to completed (this skips or aborts the action, to be confirmed)
                        If the status is completed and the outcome is skipped-tbc or aborted-tbc, then the status can be changed back to charted or inProgress
                        -->
                        <xxf:variable name="xformsCurrentStatus" select="$xformsSection/@cityEHR:status"/>
                        <xxf:variable name="xformsCurrentSessionStatus" select="$xformsSection/@cityEHR:sessionStatus"/>
                        <xxf:variable name="xformsCurrentOutcome" select="$xformsSection/@cityEHR:outcome"/>

                        <xxf:variable name="xformsStatusDisplayClass"
                            select="
                                if ($xformsCurrentStatus = 'completed') then
                                    'ISO13606-Data'
                                else
                                    'hidden'"/>
                        <xxf:variable name="xformsStatusSelectClass"
                            select="
                                if ($xformsStatusDisplayClass = 'hidden') then
                                    'ISO13606-Data'
                                else
                                    'hidden'"/>

                        <!-- Display conditions that have been satisfied to trigger this task -->
                        <!-- Debugging
                            <xf:output ref="$xformsSection/@cityEHR:conditions"/>
                            -->
                        <xxf:variable name="xformsParameterList"
                            select="tokenize(substring-after($xformsSection/@cityEHR:conditions, 'if ('), ' castable as ')"/>
                        <xxf:variable name="xformsSatisfiedClass"
                            select="
                                if ($xformsSection/@cityEHR:visibility = 'true') then
                                    'satisfied'
                                else
                                    'notSatisfied'"/>
                        <xhtml:ul class="ISO13606-Conditions {{$xformsSatisfiedClass}}">
                            <xf:repeat nodeset="$xformsParameterList">
                                <xhtml:li>
                                    <xxf:variable name="xformsParameterString" select="."/>
                                    <xxf:variable name="xformsParameter"
                                        select="
                                            if (starts-with($xformsParameterString, 'xxf:instance')) then
                                                substring-before($xformsParameterString, '@value')
                                            else
                                                ''"/>
                                    <xxf:variable name="xformsParameterValue"
                                        select="
                                            if ($xformsParameter != '') then
                                                concat($xformsParameter, '@value')
                                            else
                                                ''"/>
                                    <xxf:variable name="xformsParameterDisplayName"
                                        select="
                                            if ($xformsParameter != '') then
                                                concat($xformsParameter, '@cityEHR:elementDisplayName')
                                            else
                                                ''"/>
                                    <xf:output
                                        ref="if ($xformsParameterDisplayName!='' and $xformsParameterValue!='') then concat(xxf:evaluate($xformsParameterDisplayName),' is ',xxf:evaluate($xformsParameterValue)) else ''"
                                    />
                                </xhtml:li>
                            </xf:repeat>
                        </xhtml:ul>

                        <xhtml:span class="ISO13606-Element">
                            <xhtml:span class="ISO13606-Element-DisplayName">
                                <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Pathways/parameters/status/@displayName"/>
                            </xhtml:span>
                            <!-- Show the status (if necessary) -->
                            <xhtml:span class="{{$xformsStatusDisplayClass}}">
                                <xf:output
                                    ref="xxf:instance('view-parameters-instance')/staticParameters/cityEHRFolder-Pathways/parameters/status/option[@value=$xformsSection/@cityEHR:sessionStatus]/@displayName"
                                />
                            </xhtml:span>
                            <!-- Select the status (if allowed) - can select the status or 'completed' -->
                            <xxf:variable name="xformsCurrentSessionStatus" select="$xformsSection/@cityEHR:sessionStatus"/>
                            <xxf:variable name="xformsStatusSelectionList"
                                select="xxf:instance('view-parameters-instance')/staticParameters/cityEHRFolder-Pathways/parameters/status/option[@value = ($xformsCurrentStatus, 'completed')]"/>

                            <xf:select1 class="{{$xformsStatusSelectClass}}" ref="$xformsSection/@cityEHR:sessionStatus">
                                <xf:itemset nodeset="$xformsStatusSelectionList">
                                    <xf:label ref="./@displayName"/>
                                    <xf:value ref="./@value"/>
                                </xf:itemset>
                                <!-- Ripple the changed status through the tasks/actions inside this section -->
                                <xf:action ev:event="xforms-value-changed" if="xxf:instance('cdaControl-instance')/formStatus='ready'">
                                    <!-- Progress the pathway -->
                                    <xf:dispatch name="progress-pathway" target="pathway-model"/>
                                </xf:action>

                            </xf:select1>
                        </xhtml:span>

                        <!-- Show the outcome, but only if it is set -->
                        <xxf:variable name="xformsOutcomeDisplayClass"
                            select="
                                if ($xformsSection/@cityEHR:outcome = 'toBeConfirmed') then
                                    'hidden'
                                else
                                    'ISO13606-Element'"/>
                        <xhtml:span class="{{$xformsOutcomeDisplayClass}}">
                            <xhtml:span class="ISO13606-Element-DisplayName">
                                <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Pathways/parameters/outcome/@displayName"/>
                            </xhtml:span>
                            <xhtml:span class="ISO13606-Data">
                                <xf:output class="ISO13606-Data"
                                    ref="xxf:instance('view-parameters-instance')/staticParameters/cityEHRFolder-Pathways/parameters/outcome/option[@value=$xformsSection/@cityEHR:outcome]/@displayName"
                                />
                            </xhtml:span>
                        </xhtml:span>
                    </xsl:if>
                </xhtml:li>
            </xsl:if>

            <!-- Display alert for the section, if one exists -->
            <xsl:if test="$section/@cityEHR:Alert != ''">
                <xhtml:li class="ISO13606-Section-Alert">
                    <xsl:value-of select="$section/@cityEHR:Alert"/>
                </xhtml:li>
            </xsl:if>

            <!-- Iterate through each entry and sub-section in the section -->
            <xsl:for-each select="$section/*">
                <xsl:variable name="component" select="."/>
                <!-- Entry - call template to render the entry -->
                <xsl:if test="$component/name() = 'entry'">
                    <xhtml:li class="{$sectionLayout}">
                        <xsl:call-template name="renderFormEntry">
                            <xsl:with-param name="entry" select="$component"/>
                            <xsl:with-param name="sectionLayout" select="$sectionLayout"/>
                            <xsl:with-param name="labelWidth" select="$sectionLabelWidth"/>
                        </xsl:call-template>
                    </xhtml:li>
                </xsl:if>

                <!-- Section - recursively call template to render sub-section 
                     Really want to do xsl-if and set the focus to the cda:section -->
                <xsl:for-each select="$component[name() = 'component']/cda:section">
                    <xsl:variable name="subSectionLayout"
                        select="
                            if (contains($component/cda:section/@cityEHR:Sequence, 'Unranked')) then
                                'Unranked'
                            else
                                'Ranked'"/>
                    <xhtml:li class="{$sectionLayout}">
                        <xsl:call-template name="renderFormSection">
                            <xsl:with-param name="compositionTypeIRI" select="$compositionTypeIRI"/>
                            <xsl:with-param name="section" select="$component/cda:section"/>
                            <xsl:with-param name="sectionLayout" select="$subSectionLayout"/>
                            <xsl:with-param name="crossRefId" select="''"/>
                        </xsl:call-template>
                    </xhtml:li>
                </xsl:for-each>

            </xsl:for-each>


            <xsl:if test="$sectionLayout = 'Unranked'">
                <xhtml:li class="LayoutFooter">&#160;</xhtml:li>
            </xsl:if>
        </xhtml:ul>


    </xsl:template>


    <!-- === Render entry on a form ==========================================================================
        Entry is rendered as <xhtml:ul> with each component (displayName, elements, etc) as <xhtml:li>
         The layout of the entry is:
            Ranked
            Unranked
            or Ascending/Descending for multipleEntry which are sorted
                                    or for multipleEntry where new entry is added as first entry (descending) or last (ascending)
            
            From 2019-02-13 
                @entryLayout is of the form #cityEHR:Property:Sequence:Unranked, so use contains to check for Unranked
                use sortOrder for Ascending/Descending
         ===================================================================================================== -->

    <xsl:template name="renderFormEntry">
        <xsl:param name="entry"/>
        <xsl:param name="sectionLayout"/>
        <xsl:param name="labelWidth"/>

        <xsl:variable name="entryPath" select="cityEHRFunction:getXPath(saxon:path())"/>


        <!-- These variables for entry properties are setting defaults, which shouldn't really happen.
             Needs to be refactored 2024-04-01 -->
        <xsl:variable name="entryLayout"
            select="
                if (exists($entry/@cityEHR:Sequence) and contains($entry/@cityEHR:Sequence, 'Unranked')) then
                    'Unranked'
                else
                    'Ranked'"/>
        <xsl:variable name="entrySortOrder"
            select="
                if (exists($entry/@cityEHR:SortOrder) and contains($entry/@cityEHR:SortOrder, 'Ascending')) then
                    'Ascending'
                else
                    'Descending'"/>
        <xsl:variable name="entryLabelWidth"
            select="
                if (exists($entry/@cityEHR:labelWidth)) then
                    $entry/@cityEHR:labelWidth
                else
                    ''"/>
        <xsl:variable name="entryCRUD"
            select="
                if (exists($entry/@cityEHR:CRUD)) then
                    $entry/@cityEHR:CRUD
                else
                    '#CityEHR:Property:CRUD:CRUD'"/>
        <xsl:variable name="entryRendition"
            select="
                if (exists($entry/@cityEHR:rendition)) then
                    $entry/@cityEHR:rendition
                else
                    ''"/>
        <xsl:variable name="entryScope"
            select="
                if (exists($entry/@cityEHR:Scope)) then
                    $entry/@cityEHR:Scope
                else
                    'Defined'"/>

        <!-- Since we are setting width in em, use half the character length of the width - this usually works fine.
             Only set the width in Ranked sections -->
        <xsl:variable name="width" select="round($labelWidth div 1.8)"/>
        <xsl:variable name="widthStyle"
            select="
                if ($sectionLayout = 'Ranked') then
                    concat('width:', $width, 'em;')
                else
                    ''"/>

        <!-- Debug conditional display 
        <xsl:value-of select="$entryPath"/> : 
        <xsl:value-of select="$entry/@cityEHR:conditions"/> : 
        <xf:output ref="{$entryPath}/@cityEHR:conditions"/> - 
        <xf:output ref="{$entryPath}/@cityEHR:visibility"/>
        -->

        <!-- Only display entry if doesn't have visibility of 'false' or scope of hidden
             From 09/10/17 also support rendition of hidden (scope of hidden is deprecated, but still supported)
             2019-02-13 New format of property does not need to support scope of hidden
             The compositionDisplay is used when displaying pathways
             The child of entry could be cda:observation. cda:act, etc-->

        <xhtml:ul
            class=" {{$xformsShowStructureClass}}  {{if (xxf:instance('view-parameters-instance')/compositionDisplay='current' and ({$entryPath}/@cityEHR:visibility='false' or {$entryPath}/@cityEHR:rendition=('#CityEHR:EntryProperty:Hidden','#CityEHR:Property:Rendition:Hidden') or {$entryPath}/@cityEHR:Scope='#CityEHR:EntryProperty:Hidden')) then 'hidden' else 'ISO13606-Entry'}}"
            style="{{if (xxf:instance('highlightEntryList-instance')/cda:id/@extension ='{$entry/descendant::cda:id/@extension}') then xxf:instance('control-instance')/highlightStyle else ''}}">
            <!-- Only output displayName for Single entries - MultipleEntry displayName is output in renderFormEntryContent -->
            <!-- Observation -->
            <xsl:if test="exists($entry/cda:observation/cda:code[@codeSystem = 'cityEHR']/@displayName)">
                <xhtml:li class="ISO13606-Entry-DisplayName {$entryLayout}" style="{$widthStyle}">
                    <xsl:value-of select="$entry/*/cda:code[@codeSystem = 'cityEHR']/@displayName"/>
                </xhtml:li>
            </xsl:if>
            <!-- Debugging and showing ISO-13606 ids
                 Use the extension entry as the identity for the entry
                 This is because we want to show the ids used in calculations -->
            <xhtml:li class="{{$xformsShowIdClass}}">
                <xsl:variable name="entryIRI" select="$entry/descendant::cda:id[1]/@extension"/>
                <xsl:value-of select="$entryIRI"/>
            </xhtml:li>

            <!-- Act.
                 If the status of the act is inProgress then it can be selected as the currentAct and launched from the viewControlActions
                 If the status of the act is completed and outcome is completed then it can be selected to view the subject document.
                 Note that these use the status, not the sessionStatus -->
            <xsl:if test="exists($entry/cda:act/cda:code[@codeSystem = 'cityEHR']/@displayName)">
                <xhtml:li class="ISO13606-Entry-DisplayName {$entryLayout}" style="{$widthStyle}">
                    <xxf:variable name="xformsAct" select="{$entryPath}/cda:act"/>
                    <xxf:variable name="xformsSelectActionClass"
                        select="
                            if ($xformsAct/@cityEHR:status = 'inProgress') then
                                ''
                            else
                                'hidden'"/>
                    <xxf:variable name="xformsSelectSubjectClass"
                        select="
                            if ($xformsAct/@cityEHR:status = 'completed' and $xformsAct/@cityEHR:outcome = 'completed') then
                                ''
                            else
                                'hidden'"/>
                    <xxf:variable name="xformsDisplayActionClass"
                        select="
                            if ($xformsSelectActionClass = 'hidden' and $xformsSelectSubjectClass = 'hidden') then
                                ''
                            else
                                'hidden'"/>

                    <!-- Select the act to select current action-->
                    <xf:trigger class="{{$xformsSelectActionClass}}" appearance="minimal">
                        <xf:label>
                            <xsl:value-of select="$entry/cda:act/cda:code[@codeSystem = 'cityEHR']/@displayName"/>
                        </xf:label>
                        <!-- Set currentAction when trigger is selected -->
                        <xf:action ev:event="DOMActivate">
                            <xf:setvalue ref="xxf:instance('notificationsControl-instance')/currentAction/subjectCompositionTypeIRI"
                                value="{$entryPath}/cda:act/cda:subject/cda:typeId/@root"/>
                            <xf:setvalue ref="xxf:instance('notificationsControl-instance')/currentAction/subjectHandleId"
                                value="{$entryPath}/cda:act/cda:subject/cda:id/@extension"/>
                            <xf:setvalue ref="xxf:instance('notificationsControl-instance')/currentAction/displayName"
                                value="{$entryPath}/cda:act/cda:code[@codeSystem='cityEHR']/@displayName"/>
                            <xf:recalculate model="viewControlsActions-model"/>
                        </xf:action>
                    </xf:trigger>
                    <!-- Select the act to show subject document for completed actions -->
                    <xf:trigger class="{{$xformsSelectSubjectClass}}" appearance="minimal">
                        <xf:label>
                            <xsl:value-of select="$entry/cda:act/cda:code[@codeSystem = 'cityEHR']/@displayName"/>
                        </xf:label>
                        <!-- Show the subject document in a dialog  -->
                        <xf:action ev:event="DOMActivate">
                            <xxf:show ev:event="DOMActivate" dialog="viewCDAHTML"/>
                        </xf:action>
                    </xf:trigger>
                    <!-- Display the act -->
                    <xhtml:span class="{{$xformsDisplayActionClass}}">
                        <xsl:value-of select="$entry/cda:act/cda:code[@codeSystem = 'cityEHR']/@displayName"/>
                    </xhtml:span>
                </xhtml:li>
            </xsl:if>

            <!-- Display alert for the entry, if one exists -->
            <xsl:if test="$entry/@cityEHR:Alert != ''">
                <xhtml:li class="ISO13606-Entry-Alert">
                    <xsl:value-of select="$entry/@cityEHR:Alert"/>
                </xhtml:li>
            </xsl:if>

            <!-- Render the entry content (clusters and elements) -->
            <xsl:call-template name="renderFormEntryContent">
                <xsl:with-param name="entry" select="$entry"/>
                <xsl:with-param name="entryLayout" select="$entryLayout"/>
                <xsl:with-param name="entrySortOrder" select="$entrySortOrder"/>
                <xsl:with-param name="entryCRUD" select="$entryCRUD"/>
                <xsl:with-param name="entryRendition" select="$entryRendition"/>
                <xsl:with-param name="entryScope" select="$entryScope"/>
                <xsl:with-param name="labelWidth" select="$entryLabelWidth"/>
                <xsl:with-param name="entryPath" select="$entryPath"/>
            </xsl:call-template>

            <xsl:if test="$entryLayout = 'Unranked'">
                <xhtml:li class="LayoutFooter">&#160;</xhtml:li>
            </xsl:if>
        </xhtml:ul>

    </xsl:template>


    <!-- === Render entry content ==========================================================================

        There is one type of cda:act entry to consider

        There are six types of cda:observation entry to consider:
            (1) Single entry uses cda:observation
            (1a) Single entry, rendered as directory or web service lookup
            (2) Single entry, rendered as image map
            (2a) Single entry, rendered as image(s)
            (3) multiple occurrences of the same entry use cda:organizer with classCode attribute of MultipleEntry
            (4) multipleEntry, rendered as image map
        ===================================================================================================== -->

    <xsl:template name="renderFormEntryContent">
        <xsl:param name="entry"/>
        <xsl:param name="entryLayout"/>
        <xsl:param name="entrySortOrder"/>
        <xsl:param name="entryCRUD"/>
        <xsl:param name="entryRendition"/>
        <xsl:param name="entryScope"/>
        <xsl:param name="labelWidth"/>
        <xsl:param name="entryPath"/>

        <!-- Use the root as the identity for the entry -->
        <xsl:variable name="entryIRI" select="$entry/descendant::cda:id[1]/@root"/>
        <xsl:variable name="entryId" select="substring-after($entryIRI, 'Entry:')"/>

        <!-- Get the key element for look-up.
             Only needed if entryCRUD is #CityEHR:EntryProperty:L or #CityEHR:EntryProperty:UL -->
        <xsl:variable name="directoryLookUp"
            select="
                if ($entryCRUD = ('#CityEHR:EntryProperty:L', '#CityEHR:EntryProperty:UL', '#CityEHR:Property:CRUD:L', '#CityEHR:Property:CRUD:UL')) then
                    true()
                else
                    false()"/>
        <xsl:variable name="sortCriteria" select="$entry/@cityEHR:sortCriteria"/>
        <xsl:variable name="keyIRI"
            select="
                if ($directoryLookUp and $sortCriteria != '') then
                    $sortCriteria
                else
                    if ($directoryLookUp) then
                        $entry/descendant::cda:value[@value][1]/@root
                    else
                        ''"/>

        <!-- === Act ======
             Allow user to select the act and set parameters -->
        <xsl:if test="$entry/cda:act">
            <!-- xformsEntry is set to help with some of the processing below -->
            <xxf:variable name="xformsEntry" select="{$entryPath}/cda:act"/>

            <xxf:variable name="xformsCurrentStatus" select="$xformsEntry/@cityEHR:status"/>
            <xxf:variable name="xformsCurrentSessionStatus" select="$xformsEntry/@cityEHR:sessionStatus"/>
            <xxf:variable name="xformsCurrentOutcome" select="$xformsEntry/@cityEHR:outcome"/>

            <!-- Display conditions that have been satisfied to trigger this task -->
            <!-- Debugging
                <xf:output ref="$xformsEntry/@cityEHR:conditions"/>
            -->
            <xhtml:li class="{$entryLayout}">
                <xxf:variable name="xformsParameterList" select="tokenize(substring-after($xformsEntry/@cityEHR:conditions, 'if ('), ' castable as ')"/>
                <xhtml:ul class="ISO13606-Conditions">
                    <xf:repeat nodeset="$xformsParameterList">
                        <xhtml:li>
                            <xxf:variable name="xformsParameterString" select="."/>
                            <xxf:variable name="xformsParameter"
                                select="
                                    if (starts-with($xformsParameterString, 'xxf:instance')) then
                                        substring-before($xformsParameterString, '@value')
                                    else
                                        ''"/>
                            <xxf:variable name="xformsParameterValue"
                                select="
                                    if ($xformsParameter != '') then
                                        concat($xformsParameter, '@value')
                                    else
                                        ''"/>
                            <xxf:variable name="xformsParameterDisplayName"
                                select="
                                    if ($xformsParameter != '') then
                                        concat($xformsParameter, '@cityEHR:elementDisplayName')
                                    else
                                        ''"/>
                            <xf:output
                                ref="if ($xformsParameterDisplayName!='' and $xformsParameterValue!='') then concat(xxf:evaluate($xformsParameterDisplayName),' is ',xxf:evaluate($xformsParameterValue)) else ''"
                            />
                        </xhtml:li>
                    </xf:repeat>
                </xhtml:ul>
            </xhtml:li>

            <xhtml:li class="{$entryLayout}">
                <!-- Select or display role of user for the action -->
                <xhtml:span class="ISO13606-Element">
                    <xhtml:span class="ISO13606-Element-DisplayName">
                        <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Pathways/parameters/role/@displayName"/>
                    </xhtml:span>
                    <!-- Parameters are either selected or displayed, depending on the current outcome of the action -->
                    <xxf:variable name="xformsParameterDisplayClass"
                        select="
                            if ($xformsCurrentStatus = 'completed') then
                                'ISO13606-Data'
                            else
                                'hidden'"/>
                    <xxf:variable name="xformsParameterSelectClass"
                        select="
                            if ($xformsParameterDisplayClass = 'hidden') then
                                'ISO13606-Data'
                            else
                                'hidden'"/>
                    <!-- Select the role -->
                    <xf:select1 class="{{$xformsParameterSelectClass}}" ref="$xformsEntry/@cityEHR:role">
                        <xf:itemset nodeset="xxf:instance('application-parameters-instance')/rbac/role">
                            <xf:label ref="./@displayName"/>
                            <xf:value ref="./@value"/>
                        </xf:itemset>
                    </xf:select1>
                    <!-- Display the role -->
                    <xhtml:span class="{{$xformsParameterDisplayClass}}">
                        <xf:output class="{{$xformsParameterDisplayClass}}"
                            ref="xxf:instance('application-parameters-instance')/rbac/role[@value=$xformsEntry/@cityEHR:role]/@displayName"/>
                    </xhtml:span>
                </xhtml:span>

                <!-- Enter or show the delay -->
                <xhtml:span class="ISO13606-Element">
                    <xhtml:span class="ISO13606-Element-DisplayName">
                        <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Pathways/parameters/delay/@displayName"/>
                    </xhtml:span>
                    <xf:input class="{{$xformsParameterSelectClass}}" ref="$xformsEntry/@cityEHR:delay" xxf:size="3"/>
                    <xhtml:span class="{{$xformsParameterDisplayClass}}">
                        <xf:output
                            ref="if ($xformsEntry/@cityEHR:delay='') then '{$view-parameters/staticParameters/cityEHRFolder-Pathways/parameters/delay/@noDelayLabel}' else $xformsEntry/@cityEHR:delay"
                        />
                    </xhtml:span>
                </xhtml:span>

                <!-- Enter or show the status.
                     If the status is completed and the outcome is completed, then status cannot be changed.
                     If the sessionStatus is charted, triggered or inProgess, then it can be changed to complete (this skips or aborts the action, to be confirmed)
                     If the sessionStatus is completed, then it can be changed back to the original status
                -->
                <xxf:variable name="xformsStatusDisplayClass"
                    select="
                        if ($xformsCurrentStatus = 'completed') then
                            'ISO13606-Data'
                        else
                            'hidden'"/>
                <xxf:variable name="xformsStatusSelectClass"
                    select="
                        if ($xformsStatusDisplayClass = 'hidden') then
                            'ISO13606-Data'
                        else
                            'hidden'"/>

                <xhtml:span class="ISO13606-Element">
                    <xhtml:span class="ISO13606-Element-DisplayName">
                        <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Pathways/parameters/status/@displayName"/>
                    </xhtml:span>
                    <xhtml:span class="{{$xformsStatusDisplayClass}}">
                        <xf:output class="{{$xformsStatusDisplayClass}}"
                            ref="xxf:instance('view-parameters-instance')/staticParameters/cityEHRFolder-Pathways/parameters/status/option[@value=$xformsEntry/@cityEHR:status]/@displayName"
                        />
                    </xhtml:span>
                    <!-- Select the status (if allowed) -->
                    <xxf:variable name="xformsStatusSelection"
                        select="xxf:instance('view-parameters-instance')/staticParameters/cityEHRFolder-Pathways/parameters/status/option[@value = ('completed', $xformsCurrentStatus)]"/>
                    <xf:select1 class="{{$xformsStatusSelectClass}}" ref="$xformsEntry/@cityEHR:sessionStatus">
                        <xf:itemset nodeset="$xformsStatusSelection">
                            <xf:label ref="./@displayName"/>
                            <xf:value ref="./@value"/>
                        </xf:itemset>
                        <!-- When action status is changed. -->
                        <xf:action ev:event="xforms-value-changed" if="xxf:instance('cdaControl-instance')/formStatus='ready'">
                            <!-- Progress the pathway -->
                            <xf:dispatch name="progress-pathway" target="pathway-model"/>
                        </xf:action>
                    </xf:select1>
                </xhtml:span>

                <!-- Show the outcome, but only if it is set -->
                <xxf:variable name="xformsOutComeDisplayClass"
                    select="
                        if ($xformsEntry/@cityEHR:outcome = 'toBeConfirmed') then
                            'hidden'
                        else
                            'ISO13606-Element'"/>
                <xhtml:span class="{{$xformsOutComeDisplayClass}}">
                    <xhtml:span class="ISO13606-Element-DisplayName">
                        <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Pathways/parameters/outcome/@displayName"/>
                    </xhtml:span>
                    <xhtml:span class="ISO13606-Data">
                        <xf:output
                            ref="xxf:instance('view-parameters-instance')/staticParameters/cityEHRFolder-Pathways/parameters/outcome/option[@value=$xformsEntry/@cityEHR:outcome]/@displayName"
                        />
                    </xhtml:span>
                </xhtml:span>
            </xhtml:li>
        </xsl:if>


        <!-- === (1) Single entry - form rendition ======
             Iterate through the elements for the entry -->

        <xsl:if test="exists($entry/cda:observation) and $entryRendition = ('#CityEHR:EntryProperty:Form', '#CityEHR:Property:Rendition:Form')">

            <!-- xformsObservation must be set before renderFormElement is called -->
            <xxf:variable name="xformsObservation" select="{$entryPath}/cda:observation"/>

            <xsl:variable name="elementSet" select="$entry//cda:value"/>

            <!-- render the elements for this entry -->
            <xsl:for-each select="$entry/cda:observation/cda:value">
                <xsl:variable name="element" select="."/>
                <xhtml:li class="{$entryLayout}">
                    <xsl:call-template name="renderFormElement">
                        <xsl:with-param name="entryId" select="$entryId"/>
                        <xsl:with-param name="entryOccurrence" select="'Single'"/>
                        <xsl:with-param name="entryCRUD" select="$entryCRUD"/>
                        <xsl:with-param name="keyIRI" select="$keyIRI"/>
                        <xsl:with-param name="entryLayout" select="$entryLayout"/>
                        <xsl:with-param name="entryRendition" select="$entryRendition"/>
                        <xsl:with-param name="entryScope" select="$entryScope"/>
                        <xsl:with-param name="labelWidth" select="$labelWidth"/>
                        <xsl:with-param name="element" select="$element"/>
                        <xsl:with-param name="elementSet" select="$elementSet"/>
                        <xsl:with-param name="setCount" select="1"/>
                        <xsl:with-param name="repeatCount" select="'single'"/>
                        <xsl:with-param name="categorizationElementExtension" select="''"/>
                        <xsl:with-param name="categoryClass" select="''"/>
                        <xsl:with-param name="categoryValue" select="''"/>
                        <xsl:with-param name="mappedElementIRI" select="''"/>
                    </xsl:call-template>
                </xhtml:li>
            </xsl:for-each>
        </xsl:if>
        <!-- end of Single entry -->


        <!-- === (2) Single entry - imageMap rendition ======
            Get id from <id xmlns="" root="cityEHR" extension="#ISO-13606:Entry:DAS68"/>
            Include the image map
            Iterate through the elements for the entry.
            Layout is not used. -->

        <xsl:if test="$entry[@cityEHR:rendition = ('#CityEHR:EntryProperty:ImageMap', '#CityEHR:Property:Rendition:ImageMap')]/cda:observation">

            <xhtml:li class="Ranked">
                <!-- Image map. -->
                <!-- Render image map - either the original way, or the new way with SVG -->
                <xsl:call-template name="renderImageMap">
                    <xsl:with-param name="entryId" select="$entryId"/>
                </xsl:call-template>

                <!-- Render the elements for this entry as hidden inputs.
                     Only for legacy HTML image maps
                     These inputs need ids so that they can be set using the setXformsControl javascript function onclick in the image map.
                     Toggle display:none / display:inline for debugging-->

                <xsl:variable name="inputStyle" select="'display:none;'"/>
                <xsl:for-each select="$entry/cda:observation/cda:value">
                    <xsl:variable name="element" select="."/>
                    <xsl:variable name="elementId" select="substring-after($element/@root, 'Element:')"/>
                    <xsl:variable name="inputId" select="concat($entryId, '-', $elementId)"/>
                    <xhtml:p class="ISO13606-Element-DisplayName" style="{$inputStyle}">
                        <xsl:value-of select="$inputId"/>
                        <xf:input id="{$inputId}" ref="{$entryPath}/cda:observation/cda:value[@extension='{$element/@extension}']/@value"/>
                    </xhtml:p>
                </xsl:for-each>
            </xhtml:li>

            <!-- Test image map hilighting by including the test image and map -->
            <!--
            <xsl:variable name="imageMapDemo" select="document('../examples/imagemaps/maphilight-demo.html')/html/body"/>
            <xsl:copy-of select="$imageMapDemo/*"/>
            -->

        </xsl:if>
        <!-- end of Single entry - imageMap rendition -->


        <!-- === (2a) Single entry - image rendition ======
            Iterate through the elements for the entry, display image found in displayName
            Set the displayName to the image, when the value changes (xforms-value-changed)
            Layout is not used. -->

        <xsl:if test="$entry[@cityEHR:rendition = ('#CityEHR:EntryProperty:Image', '#CityEHR:Property:Rendition:Image')]/cda:observation">

            <xsl:for-each select="$entry/cda:observation/cda:value">
                <xsl:variable name="element" select="."/>

                <xhtml:li class="ISO13606-Data">
                    <xxf:variable name="xformsElement" select="{$entryPath}/cda:observation/cda:value[@extension='{$element/@extension}']"/>

                    <xxf:variable name="xformsMediaClass"
                        select="
                            if ($xformsElement/@displayName = xs:base64Binary('')) then
                                'hidden'
                            else
                                ''"/>
                    <xhtml:span class="{{$xformsMediaClass}}">
                        <xf:output ref="$xformsElement/@displayName" mediatype="image/*"/>
                    </xhtml:span>

                    <!-- This crashes when the image is changed 
                    <xhtml:img class="{{$xformsMediaClass}}" src="data:image/*;base64, {{xs:base64Binary($xformsElement/@displayName)}}"/>
-->

                    <!-- Hidden input to deal with change in the value -->
                    <xf:input class="hidden" ref="$xformsElement/@value">
                        <xf:action ev:event="xforms-value-changed">
                            <!-- Reload the image -->
                            <xf:dispatch name="load-mediaElement" target="dictionary-model">
                                <xxf:context name="mediaElement" select="$xformsElement"/>
                                <xxf:context name="applicationIRI" select="''"/>
                            </xf:dispatch>
                        </xf:action>
                    </xf:input>
                </xhtml:li>
            </xsl:for-each>

        </xsl:if>


        <!-- === (3) Multiple occurrences of the same entry ==
            Entry contains an organizer for MultipleEntry.            
            The first component in the MultipleEntry is the template for the entries added to the second component.             
            Layout Ascending/Descending sets sorting, otherwise entries are unsorted.
        -->

        <xsl:if
            test="$entry[@cityEHR:rendition = ('#CityEHR:EntryProperty:Form', '#CityEHR:Property:Rendition:Form')]/cda:organizer[@classCode = 'MultipleEntry']">

            <xhtml:li class="Ranked">
                <!-- xformsObservationTemplate is a cda:component to be inserted into the xformsObservationSetContainer which is a cda:organizer containing cda:components -->
                <xxf:variable name="xformsObservationTemplate" select="{$entryPath}/cda:organizer/cda:component[1]"/>
                <xxf:variable name="xformsObservationSetContainer" select="{$entryPath}/cda:organizer/cda:component[2]/cda:organizer"/>

                <xsl:call-template name="renderMultipleEntry">
                    <xsl:with-param name="entry" select="$entry"/>
                    <xsl:with-param name="entryLayout" select="$entryLayout"/>
                    <xsl:with-param name="entrySortOrder" select="$entrySortOrder"/>
                    <xsl:with-param name="entryPath" select="$entryPath"/>
                    <xsl:with-param name="entryId" select="$entryId"/>
                    <xsl:with-param name="entryCRUD" select="$entryCRUD"/>
                    <xsl:with-param name="entryScope" select="$entryScope"/>
                    <xsl:with-param name="mappedElementIRI" select="''"/>
                </xsl:call-template>
            </xhtml:li>

        </xsl:if>
        <!-- end of MultipleEntry -->


        <!-- === (4) Multiple occurrences of the same entry, rendered as an ImageMap ==
            Entry contains an organizer for MultipleEntry.
            
            The first component in the MultipleEntry is the template for the entries added to the second component
            The template is a component that contains an observation (can't have any more complication than that).
            
            The first enumeratedValue element found in the entry is rendered as an image map.
            Each enumerated value is made as a hidden input which toggles when the corresponding area is clicked on the map.
            When a hidden entry toggles it adds a new entry to the multiple entry, with the enumeratedValue element set to the selected value.
            Entries are removed from the multipleEntry in the normal way (i.e. the image map just adds new entries)
            
            Layout Ascending/Descending sets sorting, otherwise entries are unsorted.
        -->

        <xsl:if
            test="$entry[@cityEHR:rendition = ('#CityEHR:EntryProperty:ImageMap', '#CityEHR:Property:Rendition:ImageMap')]/cda:organizer[@classCode = 'MultipleEntry']">


            <!-- The observationTemplate contains the template for the observation (found directly in the entryTemplate).
                 Set the observationTemplate to the containing cda:component, then $observationTemplate behaves the same way as $entry in a Single entry -->
            <xsl:variable name="observationTemplate" select="$entry/cda:organizer/cda:component[1]/cda:observation"/>
            <xsl:variable name="repeatCount" select="'multiple'"/>

            <!-- Get the first enumeratedValue element to use as the mappedElement.
                 The image map will select the value of this element in the template so that it is set to the selection when a new entry is added -->
            <xsl:variable name="mappedElement"
                select="$observationTemplate/cda:value[@cityEHR:elementType = ('#CityEHR:ElementProperty:enumeratedValue', '#CityEHR:Property:ElementType:enumeratedValue')][1]"/>
            <xsl:variable name="mappedElementIRI" select="$mappedElement/@extension"/>
            <xsl:variable name="mappedElementId" select="substring-after($mappedElementIRI, 'Element:')"/>

            <!-- Layout with the multipleEntry alongside the image -->
            <xhtml:li class="Ranked">
                <!-- xformsObservationTemplate is a cda:component to be inserted into the xformsObservationSetContainer which is a cda:organizer containing cda:components -->
                <xxf:variable name="xformsEntry" select="{$entryPath}"/>

                <xxf:variable name="xformsObservationTemplate" select="$xformsEntry/cda:organizer/cda:component[1]"/>
                <xxf:variable name="xformsObservationSetContainer" select="$xformsEntry/cda:organizer/cda:component[2]/cda:organizer"/>
                <xxf:variable name="xformsMappedElementTemplate"
                    select="$xformsEntry/cda:organizer/cda:component[1]//cda:observation/cda:value[@extension = '{$mappedElementIRI}']"/>

                <xhtml:ul>
                    <!-- Render image map - either the original way, or the new way with SVG -->
                    <xsl:call-template name="renderImageMap">
                        <xsl:with-param name="entryId" select="$entryId"/>
                    </xsl:call-template>

                    <!-- Multiple entry stuff - Needs to be the same as non-image map ME -->
                    <xhtml:li class="Unranked">
                        <xsl:call-template name="renderMultipleEntry">
                            <xsl:with-param name="entry" select="$entry"/>
                            <xsl:with-param name="entryLayout" select="$entryLayout"/>
                            <xsl:with-param name="entrySortOrder" select="$entrySortOrder"/>
                            <xsl:with-param name="entryPath" select="$entryPath"/>
                            <xsl:with-param name="entryId" select="$entryId"/>
                            <xsl:with-param name="entryCRUD" select="$entryCRUD"/>
                            <xsl:with-param name="entryScope" select="$entryScope"/>
                            <xsl:with-param name="mappedElementIRI" select="$mappedElementIRI"/>
                        </xsl:call-template>
                    </xhtml:li>
                    <!--
                    <xhtml:li class="LayoutFooter">&#160;</xhtml:li>
                    -->
                </xhtml:ul>


                <!-- Render the hidden input to hold the selection from the image map.
                     The value of this control is  set using the setXformsControl javascript function onclick in the image map.
                     The id is set in the image map as <entryId>-<mappedElementId> and the value is one of the enumerated values from that element
                     Toggle display:none / display:block for debugging -->
                <xsl:variable name="inputStyle" select="'display:none;'"/>
                <xsl:variable name="inputId" select="concat($entryId, '-', $mappedElementId)"/>

                <xhtml:p class="ISO13606-Element-DisplayName" style="{$inputStyle}">
                    <xsl:value-of select="$mappedElementId"/> - <xf:output ref="'{$inputId}'"/>
                    <xf:input id="{$inputId}" ref="xxf:instance('control-instance')/imageMapSelection">
                        <xf:action ev:event="xforms-value-changed" if="xxf:instance('cdaControl-instance')/formStatus='ready'">
                            <xxf:variable name="xformsImageMapSelection" select="."/>
                            <xf:dispatch name="add-multipleEntry" target="imageMap-model">
                                <xxf:context name="imageMapSelection" select="$xformsImageMapSelection"/>
                                <xxf:context name="mappedElementIRI" select="'{$mappedElementIRI}'"/>
                                <xxf:context name="entry" select="$xformsEntry"/>
                            </xf:dispatch>
                        </xf:action>
                    </xf:input>
                </xhtml:p>

            </xhtml:li>
        </xsl:if>
        <!-- end of MultipleEntry, image map rendition -->

    </xsl:template>


    <!-- === Render Multiple Entry. ==================================================================
         This renders the MultipleEntry as a table with each row representing an entry.
         Each entry in a cda:component.
    
         The following xforms variables must already be set:
        
         xformsObservationTemplate
         xformsObservationSetContainer
         Plus for image maps xformsMappedElementTemplate
         
         For entries that have categorizationCriteria set then a set of tables is created, one for each category.
         The entries have already been categorized using assign-sort-categories
         
         2019-02-13 Expended ME has scope of Full - previous property format supported Full/Expanded for legacy
         
         Invokes renderCDAEntryList is three places:   
            For an entry with categorizationCriteria
                For each category
                For resisual uncategorized entries
            For an entry without categorizationCriteria    
        ========== -->

    <xsl:template name="renderMultipleEntry">
        <xsl:param name="entry"/>
        <xsl:param name="entryLayout"/>
        <xsl:param name="entrySortOrder"/>
        <xsl:param name="entryPath"/>
        <xsl:param name="entryId"/>
        <xsl:param name="entryCRUD"/>
        <xsl:param name="entryScope"/>
        <xsl:param name="mappedElementIRI"/>


        <xsl:variable name="isExpandedEntry"
            select="
                if ($entryScope = ('#CityEHR:EntryProperty:Expanded', '#CityEHR:EntryProperty:Full', '#CityEHR:Property:Scope:Full')) then
                    true()
                else
                    false()"/>

        <xsl:variable name="observationTemplate" select="$entry/cda:organizer/cda:component[1]/cda:observation"/>
        <xsl:variable name="repeatCount" select="'multiple'"/>

        <!-- If an expanded multiple entry,
             Set hidden output to monitor the set of expanded element values -->
        <xsl:if test="$isExpandedEntry">
            <xxf:variable name="xformsExpandedElementTemplate"
                select="($xformsObservationTemplate/descendant::cda:value[@cityEHR:Scope = ('#CityEHR:ElementProperty:Expanded', '#CityEHR:ElementProperty:Full')])[1]"/>
            <xxf:variable name="xformsCalculatedValue" select="$xformsExpandedElementTemplate/@cityEHR:calculatedValue"/>
            <xxf:variable name="xformsCalculatedValueSet" context="$xformsExpandedElementTemplate"
                select="
                    if (exists($xformsCalculatedValue) and $xformsCalculatedValue != '') then
                        xxf:evaluate($xformsCalculatedValue)
                    else
                        ()"/>
            <!-- The hidden output is for all non-blank values, so changes when any value changes -->
            <xf:output class="hidden" ref="string-join($xformsCalculatedValueSet[.!=''],xxf:instance('view-parameters-instance')/resultSeparator)">
                <xf:action ev:event="xforms-value-changed">
                    <xf:dispatch name="expand-entry" target="cda-model">
                        <xxf:context name="expandedEntryOrganizer" select="$xformsObservationTemplate/ancestor::cda:organizer"/>
                    </xf:dispatch>
                </xf:action>
            </xf:output>
        </xsl:if>


        <!-- Entry is sorted by the first element that matches the designated sort element
             From 2017-05-16 If no sort criteria then entry is unsorted (was previously sorted by the first element if no sort element was specified)
             The change is made so that new entries can be added as first element (descending - i.e. last entered is listed first) 
             or last element (ascending i.e. first entered is listed first) -->
        <xsl:variable name="sortCriteria"
            select="
                if (exists($entry/@cityEHR:sortCriteria) and exists($observationTemplate/descendant::cda:value[not(child::*)][@root = $entry/@cityEHR:sortCriteria])) then
                    $entry/@cityEHR:sortCriteria
                else
                    ()"/>

        <!-- Set sort order for XForms if criteria is specified.
             From 2019-02-13 use sortOrder -->
        <xsl:if test="exists($sortCriteria)">
            <xxf:variable name="xformsObservationSortOrder"
                select="
                    if ('{$entrySortOrder}' = 'Ascending') then
                        'ascending'
                    else
                        if ('{$entrySortOrder}' = 'Descending') then
                            'descending'
                        else
                            'unsorted'"
            />
        </xsl:if>
        <!-- No sort criteria specified - entries are unsorted -->
        <xsl:if test="not(exists($sortCriteria))">
            <xxf:variable name="xformsObservationSortOrder" select="'unsorted'"/>
        </xsl:if>

        <xxf:variable name="xformsObservationCount" select="count($xformsObservationSetContainer/cda:component)"/>
        <!-- The sorted entry set applies the sort order to the full set -->
        <xxf:variable name="xformsSortedObservationSet"
            select="
                if ($xformsObservationSortOrder != 'unsorted' and $xformsObservationCount gt 0) then
                    xxf:sort($xformsObservationSetContainer/cda:component, descendant::cda:value[not(child::*)][@root = '{$sortCriteria}']/@value, 'text', $xformsObservationSortOrder)
                else
                    $xformsObservationSetContainer/cda:component"/>

        <xsl:variable name="categorizationCriteria"
            select="
                if (exists($entry/@cityEHR:categorizationCriteria)) then
                    $entry/@cityEHR:categorizationCriteria
                else
                    ''"/>

        <!-- Entry displayName - if the entry is categorized then the entry displayName is replaced by each category value displayName (below).
             For expanded multiple entry, don't show entry displayName if there are no expanded entries. -->
        <xsl:if test="$categorizationCriteria = ''">
            <xsl:if test="$isExpandedEntry">
                <xxf:variable name="xformsDisplayNameClass"
                    select="
                        if ($xformsObservationCount eq 0) then
                            'hidden'
                        else
                            'ISO13606-Entry-DisplayName'"
                />
            </xsl:if>
            <xsl:if test="not($isExpandedEntry)">
                <xxf:variable name="xformsDisplayNameClass" select="'ISO13606-Entry-DisplayName'"/>
            </xsl:if>
            <xhtml:span class="{{$xformsDisplayNameClass}}">
                <xsl:value-of select="$observationTemplate/cda:code[@codeSystem = 'cityEHR']/@displayName"/>
            </xhtml:span>
        </xsl:if>

        <!-- Get set of category values if this entry has categorization criteria specified.
             The categorization criteria element is found using the root element that matches the categorization criteria -->
        <xsl:variable name="dictionaryElement"
            select="
                if ($categorizationCriteria != '') then
                    $dictionary/iso-13606:EHR_Extract/iso-13606:elementCollection/iso-13606:element[@root = $categorizationCriteria]
                else
                    ()"/>

        <xsl:if test="exists($dictionaryElement)">
            <xsl:variable name="categorySet" select="$dictionaryElement/iso-13606:data"/>
            <xsl:variable name="categorizationElementRoot" select="$dictionaryElement/@root"/>
            <xsl:variable name="categorizationElementExtension" select="$dictionaryElement/@extension"/>

            <!-- Display the multiple entries. -->
            <!-- For entries to be categorized by the categorization criteria
                 There is one table of entries for each value of the categorization criteria -->

            <!-- Display sets of entries in each category -->
            <xsl:for-each select="$categorySet">
                <!-- Get details of the category -->
                <xsl:variable name="category" select="."/>
                <xsl:variable name="categoryClass" select="$category/@code"/>
                <xsl:variable name="categoryValue" select="$category/@value"/>
                <xsl:variable name="setCount" select="position()"/>

                <xhtml:span class="ISO13606-Entry-DisplayName">
                    <xsl:value-of select="$category/@displayName"/>
                </xhtml:span>

                <!-- Create the entry set for this category.
                     $xformsSortedObservationSet is a set of cda:component
                     Note that the sorting into the category has already been made using the assign-sort-categories action in the main-model 
                     The value of the  category is set in the cityEHR:origin attribute of the cda:id of the observation.
                     -->
                <xhtml:span>
                    <xxf:variable name="xformsObservationSet"
                        select="$xformsSortedObservationSet[cda:observation/cda:id/@cityEHR:origin = '{$categoryValue}']"/>
                    <xxf:variable name="xformsObservationSetCount" select="count($xformsObservationSet)"/>
                    <xsl:call-template name="renderCDAEntryList">
                        <xsl:with-param name="observationTemplate" select="$observationTemplate"/>
                        <xsl:with-param name="entryId" select="$entryId"/>
                        <xsl:with-param name="entryCRUD" select="$entryCRUD"/>
                        <xsl:with-param name="entryLayout" select="$entryLayout"/>
                        <xsl:with-param name="entrySortOrder" select="$entrySortOrder"/>
                        <xsl:with-param name="entryScope" select="$entryScope"/>
                        <xsl:with-param name="entryPath" select="$entryPath"/>
                        <xsl:with-param name="repeatCount" select="$repeatCount"/>
                        <xsl:with-param name="categorizationElementRoot" select="$categorizationElementRoot"/>
                        <xsl:with-param name="categorizationElementExtension" select="$categorizationElementExtension"/>
                        <xsl:with-param name="categoryClass" select="$categoryClass"/>
                        <xsl:with-param name="categoryValue" select="$categoryValue"/>
                        <xsl:with-param name="setCount" select="$setCount"/>
                        <xsl:with-param name="mappedElementIRI" select="$mappedElementIRI"/>
                    </xsl:call-template>
                </xhtml:span>
            </xsl:for-each>

            <!-- Check whether there are any residual uncategorized entries and display them here.
                 $xformsSortedObservationSet is a set of cda:component
                 Can't add new uncategorized entries, but can edit or delete them.
                 So only do this part if there are uncategorized entries -->
            <xhtml:span>
                <xxf:variable name="xformsObservationSet" select="$xformsSortedObservationSet[cda:observation/cda:id/@cityEHR:origin = '']"/>
                <xxf:variable name="xformsObservationSetCount" select="count($xformsObservationSet)"/>
                <xxf:variable name="xformsCategoryLabelClass"
                    select="
                        if ($xformsObservationSetCount gt 0) then
                            'ISO13606-Entry-DisplayName'
                        else
                            'hidden'"/>
                <xhtml:span class="{{$xformsCategoryLabelClass}}">
                    <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Forms/uncategorizedEntry/@displayName"/>
                </xhtml:span>
                <xsl:call-template name="renderCDAEntryList">
                    <xsl:with-param name="observationTemplate" select="$observationTemplate"/>
                    <xsl:with-param name="entryId" select="$entryId"/>
                    <xsl:with-param name="entryCRUD" select="$entryCRUD"/>
                    <xsl:with-param name="entryLayout" select="$entryLayout"/>
                    <xsl:with-param name="entrySortOrder" select="$entrySortOrder"/>
                    <xsl:with-param name="entryScope" select="$entryScope"/>
                    <xsl:with-param name="entryPath" select="$entryPath"/>
                    <xsl:with-param name="repeatCount" select="$repeatCount"/>
                    <xsl:with-param name="categorizationElementRoot" select="''"/>
                    <xsl:with-param name="categorizationElementExtension" select="''"/>
                    <xsl:with-param name="categoryClass" select="''"/>
                    <xsl:with-param name="categoryValue" select="$view-parameters/staticParameters/cityEHRFolder-Forms/uncategorizedEntry/@value"/>
                    <xsl:with-param name="setCount" select="count($categorySet) + 1"/>
                    <xsl:with-param name="mappedElementIRI" select="$mappedElementIRI"/>
                </xsl:call-template>
            </xhtml:span>
        </xsl:if>

        <!-- For entries with no categorization criteria
             There is just one table of entries -->
        <xsl:if test="$categorizationCriteria = ''">
            <xxf:variable name="xformsObservationSet" select="$xformsSortedObservationSet"/>
            <xxf:variable name="xformsObservationSetCount" select="count($xformsObservationSet)"/>
            <xsl:call-template name="renderCDAEntryList">
                <xsl:with-param name="observationTemplate" select="$observationTemplate"/>
                <xsl:with-param name="entryId" select="$entryId"/>
                <xsl:with-param name="entryCRUD" select="$entryCRUD"/>
                <xsl:with-param name="entryLayout" select="$entryLayout"/>
                <xsl:with-param name="entrySortOrder" select="$entrySortOrder"/>
                <xsl:with-param name="entryScope" select="$entryScope"/>
                <xsl:with-param name="entryPath" select="$entryPath"/>
                <xsl:with-param name="repeatCount" select="$repeatCount"/>
                <xsl:with-param name="categorizationElementRoot" select="''"/>
                <xsl:with-param name="categorizationElementExtension" select="''"/>
                <xsl:with-param name="categoryClass" select="''"/>
                <xsl:with-param name="categoryValue" select="''"/>
                <xsl:with-param name="setCount" select="1"/>
                <xsl:with-param name="mappedElementIRI" select="$mappedElementIRI"/>
            </xsl:call-template>
        </xsl:if>


    </xsl:template>



    <!-- === Render CDA Entry List. ==================================================================
         This is the contents of a MultipleEntry, held on $xformsObservationSet
         Each entry in the list is in a cda:component element.
         
         The following xforms variables must already be set:
         
             xformsObservationTemplate
             xformsMappedElementTemplate
             xformsObservationSetContainer   
             xformsObservationCount
             xformsObservationSet
             xformsObservationSetCount
             ========== -->

    <xsl:template name="renderCDAEntryList">
        <xsl:param name="observationTemplate"/>
        <xsl:param name="entryId"/>
        <xsl:param name="entryCRUD"/>
        <xsl:param name="entryLayout"/>
        <xsl:param name="entrySortOrder"/>
        <xsl:param name="entryScope"/>
        <xsl:param name="entryPath"/>
        <xsl:param name="repeatCount"/>
        <xsl:param name="categorizationElementRoot"/>
        <xsl:param name="categorizationElementExtension"/>
        <xsl:param name="categoryValue"/>
        <xsl:param name="categoryClass"/>
        <xsl:param name="setCount"/>
        <xsl:param name="mappedElementIRI"/>

        <!-- The value of the CRUD  property -->
        <xsl:variable name="crudValue" select="tokenize($entryCRUD, ':')[position() = last()]"/>

        <xsl:variable name="isExpandedEntry"
            select="
                if ($entryScope = ('#CityEHR:EntryProperty:Expanded', '#CityEHR:EntryProperty:Full', '#CityEHR:Property:Scope:Full')) then
                    true()
                else
                    false()"/>

        <!-- A read only entry cannot be updated or deleted -->
        <xsl:variable name="isReadOnlyEntry"
            select="
                if (contains($crudValue, 'U') or contains($crudValue, 'D')) then
                    false()
                else
                    true()"/>

        <xsl:variable name="hasRequiredValue"
            select="
                if (exists($observationTemplate//cda:value[@cityEHR:RequiredValue = 'Required'])) then
                    true()
                else
                    false()"/>

        <!-- Add button is not needed for any expanded multiple entry or any read-only entry 
             Also, not shown in categorized entry for the uncategorized entries
             And only if CRUD property includes 'C'
        -->
        <!--
        <xsl:if
            test="not($isExpandedEntry) and not($isReadOnlyEntry) and not($categoryValue = $view-parameters/staticParameters/cityEHRFolder-Forms/uncategorizedEntry/@value)">
 -->
        <xsl:if
            test="not($isExpandedEntry) and contains($crudValue, 'C') and not($categoryValue = $view-parameters/staticParameters/cityEHRFolder-Forms/uncategorizedEntry/@value)">

            <xhtml:span class="ISO13606-Entry-DisplayName">

                <xf:trigger appearance="minimal" class="formControl">
                    <xf:label>
                        <xhtml:img src="{{xxf:instance('view-parameters-instance')/staticFileRoot}}/icons/add.png" class="formControl"/>
                    </xf:label>
                    <!-- Causes a css problem 
                    <xf:hint class="hint">
                    <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Forms/formActions/action[@type='add']/@label"/>
                    </xf:hint>
                -->
                    <xf:action ev:event="DOMActivate">
                        <!-- Reset Mapped element in template if this is an image map rendition -->
                        <xsl:if test="$mappedElementIRI != ''">
                            <xf:setvalue ref="$xformsMappedElementTemplate/@value" value="''"/>
                            <xf:setvalue ref="$xformsMappedElementTemplate/@code" value="''"/>
                            <xf:setvalue ref="$xformsMappedElementTemplate/@displayName" value="''"/>
                        </xsl:if>

                        <!-- From 2019-02-13 use sortOrder -->
                        <xxf:variable name="addMultipleEntryPosition"
                            select="
                                if ('{$entrySortOrder}' = 'Ascending') then
                                    'last'
                                else
                                    if ('{$entrySortOrder}' = 'Descending') then
                                        'first'
                                    else
                                        if (xxf:instance('view-parameters-instance')/staticParameters/cityEHRFolder/addMultipleEntryPosition = 'last') then
                                            'last'
                                        else
                                            'first'"/>

                        <!-- Adding new entry as last in set -->
                        <xf:action if="$addMultipleEntryPosition = 'last'">
                            <xf:insert context="$xformsObservationSetContainer" nodeset="cda:component" origin="$xformsObservationTemplate"
                                at="last()" position="after"/>
                        </xf:action>
                        <!-- Or as first - this is the default if the option is not specified in view-parameters -->
                        <xf:action if="$addMultipleEntryPosition = 'first'">
                            <xf:insert context="$xformsObservationSetContainer" nodeset="cda:component" origin="$xformsObservationTemplate" at="1"
                                position="before"/>
                        </xf:action>

                        <!-- Get a handle on the new observation -->
                        <xxf:variable name="xformsNewObservation"
                            select="
                                if ($addMultipleEntryPosition = 'last') then
                                    $xformsObservationSetContainer/cda:component[last()]
                                else
                                    $xformsObservationSetContainer/cda:component[1]"/>

                        <!-- Set default values -->
                        <xf:dispatch name="set-entry-default-values" target="cda-model">
                            <xxf:context name="entry" select="$xformsNewObservation"/>
                        </xf:dispatch>

                        <!-- Set the category values in the newly added entry.
                            The descendant axis is needed to handle both Single and enumeratedClass entries.
                            This is needed so that when assign-sort-categories is called the new entry gets assigned to the category in which it was added.
                            Not needed for enumeratedClass elements (where the value will be set as a node in the class hierarchy) -->
                        <xf:setvalue
                            ref="$xformsNewObservation/descendant::cda:value[@extension='{$categorizationElementExtension}'][not(@cityEHR:elementType=('#CityEHR:ElementProperty:enumeratedClass','#CityEHR:Property:ElementType:enumeratedClass'))][1]/@value"
                            value="'{$categoryValue}'"/>
                        <xf:setvalue ref="$xformsNewObservation/descendant::cda:id[1]/@cityEHR:origin" value="'{$categoryValue}'"/>

                        <!-- If a required value then refresh the main model (for requiredElementStatus) -->
                        <xsl:if test="$hasRequiredValue">
                            <xf:action ev:event="xforms-value-changed">
                                <xf:recalculate model="main-model"/>
                            </xf:action>
                        </xsl:if>

                    </xf:action>
                </xf:trigger>

                <!-- Debugging -->
                <!--
            <xhtml:span class="ISO13606-Element-DisplayName">
                <xsl:value-of select="$category"/> / <xsl:value-of select="$categoryValue"/> / 
                <xf:output ref="$xformsObservationTemplate//cda:value[@extension='{$category}'][1]/@value"/>
            </xhtml:span>
            -->

            </xhtml:span>
        </xsl:if>

        <!-- Table to layout the multiple entries.
             If the entry is read only and there are no entries to display then don't show the table 
             (which would be empty and not show anyway, but takes some vertical space on the form) -->
        <xxf:variable name="xformsMEDisplayClass"
            select="
                if ('{$entryCRUD}' = ('#CityEHR:EntryProperty:R', '#CityEHR:Property:CRUD:R') and $xformsObservationSetCount eq 0) then
                    'hidden'
                else
                    'tableContainer'"/>

        <xhtml:div class="{{$xformsMEDisplayClass}}">
            <!-- Some attributes of the display -->
            <xsl:variable name="displayElementLabels"
                select="exists($observationTemplate/cda:value[@extension != $categorizationElementRoot][@cityEHR:elementDisplayName != ''])"/>

            <!-- Set of elements for the entry.
                 this is the full set of all descendant elements in the template -->
            <xsl:variable name="elementSet" select="$observationTemplate/descendant::cda:value"/>

            <!-- Unranked
                Table for the multiple entries - one row for each entry -->
            <xsl:if test="$entryLayout = 'Unranked'">
                <xsl:variable name="crudValue" select="tokenize($entryCRUD, ':')[position() = last()]"/>

                <xhtml:table class="CDAEntryList">
                    <!-- Header 
                     Don't show the header at all if there are no header displayNames.
                     This check can be done in XSLT since it won't change dynamically -->
                    <xsl:if test="$displayElementLabels">
                        <!-- Only show the header for the multiple entry if there is at least one entry in the set -->
                        <xhtml:thead class="{{if ($xformsObservationSetCount gt 0) then '' else 'hidden'}}">
                            <!-- Header rows with display names of elements or clusters
                             Previous version had multiple lines for clusters, but we now support nested clusters
                        -->
                            <xhtml:tr>
                                <!-- Need extra cell in header because first cell in each body row is the delete button
                                     Unless this is an expanded ME, or is read-only, which do not have delete buttons -->
                                <xsl:if test="not($isExpandedEntry) and not($isReadOnlyEntry)">
                                    <xhtml:th/>
                                </xsl:if>

                                <!-- If the entry has categorization criteria then don't show the sort element (it is used to create multiple entry sets instead).
                             But note that if the categorizationElementRoot is an alias for another element then that element will be shown. 
                             Also, don't show column header if all elements of that IRI are hidden (cityEHR:visibility='false') 
                             To test this, find all displayed elements of that IRI - either they don't have a cityEHR:visibility attribute or that attibute isn't false -->
                                <xsl:for-each select="$observationTemplate/cda:value[@extension != $categorizationElementRoot]">
                                    <xsl:variable name="elementIRI" select="./@extension"/>
                                    <xhtml:th
                                        class="{{if (exists($xformsObservationSet//cda:value[@extension='{$elementIRI}'][empty(@cityEHR:visibility) or @cityEHR:visibility!='false'])) then 'MultipleEntryHeader' else 'hidden' }}"
                                        align="right">
                                        <!-- Element displayName -->
                                        <xhtml:span class="ISO13606-Element-DisplayName">
                                            <xsl:value-of select="./@cityEHR:elementDisplayName"/>
                                        </xhtml:span>
                                        <!-- Units, if there are any -->
                                        <xsl:if test="./@units != ''">
                                            <xhtml:span class="ISO13606-Element-Units"> (<xsl:value-of select="./@units"/>) </xhtml:span>
                                        </xsl:if>
                                    </xhtml:th>
                                </xsl:for-each>
                            </xhtml:tr>
                        </xhtml:thead>

                    </xsl:if>

                    <!-- One row for each repeated entry. 
                    This repeat can be made in XForms using xf:repeat since the number of entries is dynamic.

                    The entries are sorted by element value and by category, if specified.
                    The sort/categorization has alreaady been made when $xformsObservationSet was created
                    
                    The xformsObservationSetContainer is an organizer containing cda:component elements                 
                -->

                    <!-- Body - contains one row for each entry -->
                    <xhtml:tbody>
                        <xf:repeat nodeset="$xformsObservationSet">
                            <xxf:variable name="xformsObservationComponent" select="."/>
                            <xhtml:tr>
                                <!-- Button to remove entry, but not for expanded or read only entries -->
                                <xsl:if test="not($isExpandedEntry) and not($entryCRUD = ('#CityEHR:EntryProperty:R', '#CityEHR:Property:CRUD:R'))">
                                    <xhtml:td>
                                        <!-- Don't display the button for prefilled entries that can't be updated.
                                             The CRUD for prefilled entries is held in the parent cda:component -->
                                        <xxf:variable name="xformsDeleteClass"
                                            select="
                                                if (exists($xformsObservationComponent[@cityEHR:CRUD = ('#CityEHR:EntryProperty:CR', '#CityEHR:Property:CRUD:CR')])) then
                                                    'hidden'
                                                else
                                                    'formControl'"/>
                                        <xf:trigger class="{{$xformsDeleteClass}}" appearance="minimal">
                                            <xf:label>
                                                <xhtml:img src="{{xxf:instance('view-parameters-instance')/staticFileRoot}}/icons/remove.png"
                                                    class="formControl"/>
                                            </xf:label>
                                            <!-- Causes a css problem 
                                        <xf:hint class="hint">
                                            <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Forms/formActions/action[@type='remove']/@label"/>
                                        </xf:hint>
                                        -->
                                            <xf:action ev:event="DOMActivate">
                                                <!-- Delete the entry -->
                                                <xf:delete nodeset="$xformsObservationComponent"/>

                                                <!-- If an imageMap then refresh the SVG image classes -->
                                                <xsl:if test="$mappedElementIRI != ''">
                                                    <xf:dispatch name="refresh-imageMapClasses" target="imageMap-model">
                                                        <xxf:context name="mappedElementIRI" select="'{$mappedElementIRI}'"/>
                                                        <xxf:context name="entry" select="$xformsEntry"/>
                                                    </xf:dispatch>
                                                </xsl:if>

                                                <!-- If a required value then refresh the main model (for requiredElementStatus) -->
                                                <xsl:if test="$hasRequiredValue">
                                                    <xf:action ev:event="xforms-value-changed">
                                                        <xf:recalculate model="main-model"/>
                                                    </xf:action>
                                                </xsl:if>
                                            </xf:action>
                                        </xf:trigger>
                                    </xhtml:td>
                                </xsl:if>

                                <!-- xformsObservation must be set before renderFormElement is called -->
                                <xxf:variable name="xformsObservation" select="$xformsObservationComponent/cda:observation"/>

                                <!-- RenderFormElement in XSLT, using the template entry.
                                     The pattern for the elements rendered will be the same for each row in the multipleEntry. 
                                     The elements are the value elements which have no children (i.e. clusters ignored, but their content elements are included).
                                     $entryPath in XSLT locates the multiple entry -->

                                <!-- Don't output element that is the sort criteria (but use the root, so that an aliased element is output) -->
                                <xsl:for-each select="$observationTemplate/cda:value[@extension != $categorizationElementRoot]">
                                    <xsl:variable name="element" select="."/>
                                    <xsl:variable name="elementIRI" select="./@extension"/>

                                    <xhtml:td
                                        class="{{if (exists($xformsObservationSet/descendant::cda:value[@extension='{$elementIRI}'][empty(@cityEHR:visibility) or @cityEHR:visibility!='false'])) then '' else 'hidden'  }}">

                                        <xsl:call-template name="renderFormElement">
                                            <xsl:with-param name="entryId" select="$entryId"/>
                                            <xsl:with-param name="entryOccurrence" select="'MultipleEntry'"/>
                                            <xsl:with-param name="entryCRUD" select="$entryCRUD"/>
                                            <xsl:with-param name="keyIRI" select="''"/>
                                            <xsl:with-param name="entryLayout" select="'Ranked'"/>
                                            <xsl:with-param name="entryRendition" select="''"/>
                                            <xsl:with-param name="entryScope" select="$entryScope"/>
                                            <xsl:with-param name="labelWidth" select="''"/>
                                            <xsl:with-param name="element" select="$element"/>
                                            <xsl:with-param name="elementSet" select="$elementSet"/>
                                            <xsl:with-param name="setCount" select="$setCount"/>
                                            <xsl:with-param name="repeatCount" select="'multiple'"/>
                                            <xsl:with-param name="categorizationElementExtension" select="$categorizationElementExtension"/>
                                            <xsl:with-param name="categoryClass" select="''"/>
                                            <xsl:with-param name="categoryValue" select="''"/>
                                            <xsl:with-param name="mappedElementIRI" select="$mappedElementIRI"/>
                                        </xsl:call-template>
                                    </xhtml:td>
                                </xsl:for-each>
                            </xhtml:tr>

                        </xf:repeat>
                    </xhtml:tbody>


                </xhtml:table>
            </xsl:if>

            <!-- Ranked
                 Table for the multiple entries - one column for each entry -->
            <xsl:if test="$entryLayout = 'Ranked'">
                <xsl:variable name="crudValue" select="tokenize($entryCRUD, ':')[position() = last()]"/>
                <xhtml:table class="CDAEntryList">
                    <!-- Header contains the remove button for each entry
                         Only show the header for the multiple entry if there is at least one entry in the set.
                         The number of columns depends on the (dynamic) number of entries in the multiple entry.
                         So the remove buttons must be placed using xf:repeat
                    -->
                    <xhtml:thead class="{{if ($xformsObservationSetCount gt 0) then '' else 'hidden'}}">
                        <xhtml:tr>
                            <!-- First column is for the element displayName
                                 So empty for the header row -->
                            <xhtml:th/>
                            <xf:repeat nodeset="$xformsObservationSet">
                                <xxf:variable name="xformsObservationComponent" select="."/>

                                <!-- Button to remove entry, but not for expanded or read only entries -->
                                <xsl:if test="not($isExpandedEntry) and not($entryCRUD = ('#CityEHR:EntryProperty:R', '#CityEHR:Property:CRUD:R'))">
                                    <xhtml:th>
                                        <!-- Don't display the button for prefilled entries that can't be updated.
                                             The CRUD for prefilled entries is held in the parent cda:component -->
                                        <xxf:variable name="xformsDeleteClass"
                                            select="
                                                if (exists($xformsObservationComponent[@cityEHR:CRUD = ('#CityEHR:EntryProperty:CR', '#CityEHR:Property:CRUD:CR')])) then
                                                    'hidden'
                                                else
                                                    'formControl'"/>
                                        <xf:trigger class="{{$xformsDeleteClass}}" appearance="minimal">
                                            <xf:label>
                                                <xhtml:img src="{{xxf:instance('view-parameters-instance')/staticFileRoot}}/icons/remove.png"
                                                    class="formControl"/>
                                            </xf:label>
                                            <!-- Causes a css problem 
                                        <xf:hint class="hint">
                                            <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Forms/formActions/action[@type='remove']/@label"/>
                                        </xf:hint>
                                        -->
                                            <xf:action ev:event="DOMActivate">
                                                <!-- Delete the entry -->
                                                <xf:delete nodeset="$xformsObservationComponent"/>
                                                <!-- If an imageMap then refresh the SVG image classes -->
                                                <xsl:if test="$mappedElementIRI != ''">
                                                    <xf:dispatch name="refresh-imageMapClasses" target="imageMap-model">
                                                        <xxf:context name="mappedElementIRI" select="'{$mappedElementIRI}'"/>
                                                    </xf:dispatch>
                                                </xsl:if>

                                                <!-- If a required value then refresh the main model (for requiredElementStatus) -->
                                                <xsl:if test="$hasRequiredValue">
                                                    <xf:action ev:event="xforms-value-changed">
                                                        <xf:recalculate model="main-model"/>
                                                    </xf:action>
                                                </xsl:if>
                                            </xf:action>
                                        </xf:trigger>
                                    </xhtml:th>
                                </xsl:if>
                            </xf:repeat>
                        </xhtml:tr>
                    </xhtml:thead>


                    <!-- One row for each repeated element. 
                    This repeat can be made in XSLT since the number of elements is static.

                    The observtions are sorted by element value and by category, if specified.
                    The sort/categorization has alreaady been made when $xformsObservationSet was created
                    
                    The xformsObservationSetContainer is an organizer containing cda:component elements wrapiing cda:observation                   
                -->

                    <!-- Body - contains one row for each element -->
                    <xhtml:tbody>
                        <xsl:for-each select="$observationTemplate/cda:value[@extension != $categorizationElementRoot]">
                            <xsl:variable name="element" select="."/>
                            <xsl:variable name="elementIRI" select="./@extension"/>

                            <xhtml:tr>
                                <!-- The first cell contains the label for the element.
                                     But only show if there are entries with visible elements for this row -->
                                <xhtml:td
                                    class="{{if (exists($xformsObservationSet//cda:value[@extension='{$elementIRI}'][empty(@cityEHR:visibility) or @cityEHR:visibility!='false'])) then 'MultipleEntryHeader' else 'hidden' }}"
                                    align="left">
                                    <!-- Element displayName -->
                                    <xhtml:span class="ISO13606-Element-DisplayName">
                                        <xsl:value-of select="./@cityEHR:elementDisplayName"/>
                                    </xhtml:span>
                                    <!-- Units, if there are any -->
                                    <xsl:if test="./@units != ''">
                                        <xhtml:span class="ISO13606-Element-Units"> (<xsl:value-of select="./@units"/>) </xhtml:span>
                                    </xsl:if>
                                </xhtml:td>

                                <!-- The remaining cells contain this element for each multiple entry.
                                     Iterate through the entries and input the element -->
                                <xf:repeat nodeset="$xformsObservationSet">
                                    <xhtml:td
                                        class="{{if (exists($xformsObservationSet/descendant::cda:value[@extension='{$elementIRI}'][empty(@cityEHR:visibility) or @cityEHR:visibility!='false'])) then '' else 'hidden'  }}">

                                        <xxf:variable name="xformsObservationComponent" select="."/>

                                        <!-- xformsObservation must be set before renderFormElement is called -->
                                        <xxf:variable name="xformsObservation" select="$xformsObservationComponent/cda:observation"/>

                                        <!-- RenderFormElement in XSLT, using the template entry.
                                         The pattern for the element rendered will be the same for each entry in the multipleEntry. 
                                         The elements are the value elements which have no children (i.e. clusters ignored, but their content elements are included).
                                         $entryPath in XSLT locates the multiple entry -->

                                        <xsl:call-template name="renderFormElement">
                                            <xsl:with-param name="entryId" select="$entryId"/>
                                            <xsl:with-param name="entryOccurrence" select="'MultipleEntry'"/>
                                            <xsl:with-param name="entryCRUD" select="$entryCRUD"/>
                                            <xsl:with-param name="keyIRI" select="''"/>
                                            <xsl:with-param name="entryLayout" select="'Ranked'"/>
                                            <xsl:with-param name="entryRendition" select="''"/>
                                            <xsl:with-param name="entryScope" select="$entryScope"/>
                                            <xsl:with-param name="labelWidth" select="''"/>
                                            <xsl:with-param name="element" select="$element"/>
                                            <xsl:with-param name="elementSet" select="$elementSet"/>
                                            <xsl:with-param name="setCount" select="$setCount"/>
                                            <xsl:with-param name="repeatCount" select="'multiple'"/>
                                            <xsl:with-param name="categorizationElementExtension" select="$categorizationElementExtension"/>
                                            <xsl:with-param name="categoryClass" select="''"/>
                                            <xsl:with-param name="categoryValue" select="''"/>
                                            <xsl:with-param name="mappedElementIRI" select="$mappedElementIRI"/>
                                        </xsl:call-template>

                                    </xhtml:td>

                                </xf:repeat>

                            </xhtml:tr>
                        </xsl:for-each>
                    </xhtml:tbody>


                </xhtml:table>
            </xsl:if>

        </xhtml:div>
    </xsl:template>



    <!-- === Render element on a form. ==================================================================
        
        $xformsObservation has already been set (this is actually the cda:observation that contains the cda:values)
        $xformsObservationComponent must also be set for multiple entries
        
        Element is rendered as <xhtml:ul> with each component (displayName, value, units, etc) an <xhtml:li>
        
        The parameters specify the entryOccurrence (Single or MultipleEntry), the element and the repeatCount (which is only supplied with multiple entries).
        
        $entryId is passed so that a unique Id can be generated for the autocomplete control
        
        <entry cityEHR:Sequence="Unranked" cityEHR:rendition="Form">
            <observation>
            <typeId root="cityEHR" extension="Type:Observation"/>
            <id root="cityEHR" extension="#ISO-13606:Entry:Gender"/>
            <code code="" codeSystem="cityEHR" displayName="Gender"/>
            <value xsi:type="xs:enumeratedValue" value="" units="" code="" codeSystem="" displayName="" extension="#ISO-13606:Element:Gender" root="cityEHR"/>
            </observation>
        </entry>
        
        The element is represented in CDA as the value element and is set up here in the $xformsElement xforms variable  
        
        If the element is actually a cluster, then need to iterate through its child elements
        Cluster changes the orientation of its contents (i.e. ranked/unranked changes to unranked/ranked for each nest of cluster
        Unless the cluster has a cityEHR:Sequence attribute, which forces the layout (from 2017-10-10)
        
        If the element is in a directory lookup entry, $entryCRUD is #CityEHR:EntryProperty:L or #CityEHR:EntryProperty:LU
        The keyIRI is set to the IRI if the element used as the lookup key
        For #CityEHR:EntryProperty:L, the key element is fully rendered and all other elements are read-only
        For #CityEHR:EntryProperty:UL, all elements are fully rendered
        
        There are ten types of element to consider:
            (0) staticValue
            (1) enumeratedValue, enumeratedDirectory or enumeratedCalculatedValue
            (2) enumerated class
            (3) memo type
            (4) range type
            (5) media
            (6) patient media
            (7) recognised XML type
            (8) calculatedValue or age
            (9) url
        ================================================================================================== -->

    <xsl:template name="renderFormElement">
        <xsl:param name="entryId"/>
        <xsl:param name="entryOccurrence"/>
        <xsl:param name="entryCRUD"/>
        <xsl:param name="keyIRI"/>
        <xsl:param name="entryLayout"/>
        <xsl:param name="entryRendition"/>
        <xsl:param name="entryScope"/>
        <xsl:param name="labelWidth"/>
        <xsl:param name="element"/>
        <xsl:param name="elementSet"/>
        <xsl:param name="setCount"/>
        <xsl:param name="repeatCount"/>
        <xsl:param name="categorizationElementExtension"/>
        <xsl:param name="categoryClass"/>
        <xsl:param name="categoryValue"/>
        <xsl:param name="mappedElementIRI"/>

        <xsl:variable name="position" select="cityEHRFunction:getNodePosition($elementSet, $element)"/>

        <xsl:variable name="root" select="$element/@root"/>
        <xsl:variable name="extension" select="$element/@extension"/>

        <!-- elementId is used for ids on autocomplete selections and imageMaps -->
        <xsl:variable name="elementId" select="substring-after($root, 'Element:')"/>
        <!-- v1 @cityEHR:fieldLength, v2 @cityEHR:Precision -->
        <xsl:variable name="fieldLength"
            select="
                if (exists($element/@cityEHR:fieldLength)) then
                    $element/@cityEHR:fieldLength
                else
                    if (exists($element/@cityEHR:Precision)) then
                        $element/@cityEHR:Precision
                    else
                        $view-parameters/staticParameters/cityEHRFolder/fieldLength"/>

        <!-- Check to see if this is a cluster or an element -->
        <xsl:variable name="iso-13606Type"
            select="
                if (exists($element/@value)) then
                    'ISO13606-Element'
                else
                    'ISO13606-Cluster'"/>

        <!-- Check whether the first element in an unranked cluster -->
        <xsl:variable name="firstClusterElement"
            select="
                if (exists($element/parent::cda:value) and not(exists($element/preceding-sibling::cda:value)) and $entryLayout = 'Unranked') then
                    true()
                else
                    false()"/>

        <!-- Check whether element is a required value -->
        <xsl:variable name="isRequiredValue"
            select="
                if (exists($element[@cityEHR:RequiredValue = 'Required'])) then
                    true()
                else
                    false()"/>
        
        <xsl:variable name="elementScope"
            select="
            if (exists($element/@cityEHR:Scope)) then
            $element/@cityEHR:Scope
            else
            ''"/>
        
        <!-- Check whether element is used as the axis for expanding a multiple entry -->
        <xsl:variable name="isExpansionAxis"
            select="
            if ($entryOccurrence='MultipleEntry' and contains($entryScope,'Full') and contains($elementScope,'Full')) then
            true()
            else
            false()"/>       
        

        <!-- Check whether top element or cluster (needed for MultipleEntry) -->
        <xsl:variable name="topLevelElement"
            select="
                if (exists($element/parent::cda:observation)) then
                    true()
                else
                    false()"/>

        <!-- Set the class of the element. Consists of a static base plus variable classes for:
                    required (requiredSet / requiredNotSet)
                    visibility (hidden / '')
                    
             These need to be set as AVTs inside the start tag (not created as variables first) because there is no container to limit the scope of the variable
        -->

        <!-- Set elementCRUD from entryCRUD so that it is easier to test the CRUDL setting -->
        <xsl:variable name="elementCRUD" select="tokenize($entryCRUD, ':')[position() = last()]"/>

        <!-- Set the xformsElement before processing.
             The xformsElement is found at the same position in the xformsObservation as the XSLT element is in elementSet -->
        <xxf:variable name="xformsElement"
            select="if (exists(($xformsObservation/descendant::cda:value)[{$position}])) then ($xformsObservation/descendant::cda:value)[{$position}] else ()"/>

        <!-- The element is hidden if it has @cityEHR:visibility='false' or a scope (v1) or rendition (v2) of hidden (i.e. @cityEHR:Scope='#CityEHR:ElementProperty:Hidden').
             The compositionDisplay is used when displaying pathways
             Note that such an element may still be involved in calculations 
             If @cityEHR:visibility='false' then it is removed when committed; if @cityEHR:Scope='#CityEHR:ElementProperty:Hidden' then it is stored -->
        <xhtml:ul
            class="{if ($firstClusterElement) then 'ISO13606-ClusterElement' else $iso-13606Type}  {{$xformsShowStructureClass}}  {{if (xxf:instance('view-parameters-instance')/compositionDisplay='current' and (exists($xformsElement[@cityEHR:visibility='false']) or exists($xformsElement[@cityEHR:Scope ='#CityEHR:ElementProperty:Hidden']) or exists($xformsElement[@cityEHR:elementRendition ='#CityEHR:ElementProperty:Hidden']))) then 'hidden' else ''}} {{if ($xformsElement/@cityEHR:RequiredValue='Required') then (if ($xformsElement/@value='') then 'requiredNotSet' else 'requiredSet') else ''}}">

            <!-- Since we are setting width in em, use half the character length of the width - this usually works fine.
                 Only set the width in Ranked sections -->
            <xsl:variable name="width"
                select="
                    if ($labelWidth castable as xs:integer) then
                        round($labelWidth div 1.7)
                    else
                        ''"/>
            <xsl:variable name="widthStyle"
                select="
                    if ($entryLayout = 'Ranked' and $width castable as xs:integer) then
                        concat('width:', $width, 'em;')
                    else
                        ''"/>

            <!-- Debugging and showing ISO-13606 ids
                 Use the extension entry as the identity for the entry -->
            <xhtml:li class="{{$xformsShowIdClass}}">
                <xsl:value-of select="$extension"/>
            </xhtml:li>

            <!-- Output the element displayName, except for the first element of an unranked cluster 
                 for Single entries
                 and for MultipleEntry where this is not a top-level element in the observation
                 For clusters, the displayName is output as normal for ranked clusters.
                 For unranked clusters the displayName of the cluster is combined with the displayName of the first element -->
            <xsl:if test="$iso-13606Type = 'ISO13606-Element' and not($firstClusterElement)">
                <xsl:if test="$entryOccurrence = 'Single' or ($entryOccurrence = 'MultipleEntry' and not($topLevelElement))">
                    <xhtml:li class="ISO13606-Element-DisplayName" style="{$widthStyle}">
                        <xf:output ref="$xformsElement/@cityEHR:elementDisplayName"/>
                    </xhtml:li>
                </xsl:if>
            </xsl:if>


            <!-- === Recursively call this template if processing a cluster.
                     The layout is toggled at each nest of cluster, unless explicitly set.
                     displayNames are aligned for elements within ranked clusters
                     
                     Displaynemas are not output for the first e;ement/cluster in the observation (already displated in the column/row header)
                      -->
            <xsl:if test="$iso-13606Type = 'ISO13606-Cluster'">
                <xsl:variable name="clusterLayout"
                    select="
                        if (exists($element/@cityEHR:Sequence) and $element/@cityEHR:Sequence != '') then
                            $element/@cityEHR:Sequence
                        else
                            if ($entryLayout = 'Ranked') then
                                'Unranked'
                            else
                                'Ranked'"/>
                <xsl:variable name="clusterLabelWidth"
                    select="
                        if ($clusterLayout = 'Ranked') then
                            max($element/cda:value/@cityEHR:elementDisplayName/string-length(.))
                        else
                            $labelWidth"/>

                <!-- Output displayName of the cluster
                     for Single entries
                     and for MultipleEntry where this is not a top-level element in the observation
                     If cluster is unranked, then combine cluster displayName with displayName of first element -->
                <xsl:variable name="displayName"
                    select="
                        if ($clusterLayout = 'Unranked') then
                            normalize-space(concat($element/@cityEHR:elementDisplayName, ' ', $element/cda:value[1]/@cityEHR:elementDisplayName))
                        else
                            $element/@cityEHR:elementDisplayName"/>
                <xsl:if test="$entryOccurrence = 'Single' or ($entryOccurrence = 'MultipleEntry' and not($topLevelElement))">
                    <xhtml:li class="ISO13606-Element-DisplayName {$clusterLayout}" style="{$widthStyle}">
                        <xf:output ref="'{$displayName}'"/>
                    </xhtml:li>
                </xsl:if>

                <!-- Process cluster contents -->
                <xsl:for-each select="$element/cda:value">
                    <xsl:variable name="clusterElement" select="."/>
                    <xhtml:li class="{$clusterLayout}">
                        <xsl:call-template name="renderFormElement">
                            <xsl:with-param name="entryId" select="$entryId"/>
                            <xsl:with-param name="entryOccurrence" select="$entryOccurrence"/>
                            <xsl:with-param name="entryCRUD" select="$entryCRUD"/>
                            <xsl:with-param name="keyIRI" select="$keyIRI"/>
                            <xsl:with-param name="entryLayout" select="$clusterLayout"/>
                            <xsl:with-param name="entryRendition" select="$entryRendition"/>
                            <xsl:with-param name="entryScope" select="$entryScope"/>
                            <xsl:with-param name="labelWidth" select="$clusterLabelWidth"/>
                            <xsl:with-param name="element" select="$clusterElement"/>
                            <xsl:with-param name="elementSet" select="$elementSet"/>
                            <xsl:with-param name="setCount" select="$setCount"/>
                            <xsl:with-param name="repeatCount" select="$repeatCount"/>
                            <xsl:with-param name="categorizationElementExtension" select="$categorizationElementExtension"/>
                            <xsl:with-param name="categoryClass" select="$categoryClass"/>
                            <xsl:with-param name="categoryValue" select="$categoryValue"/>
                            <xsl:with-param name="mappedElementIRI" select="$mappedElementIRI"/>
                        </xsl:call-template>
                    </xhtml:li>
                </xsl:for-each>
                <xhtml:li class="LayoutFooter">&#160;</xhtml:li>
            </xsl:if>


            <!-- === Display element value for read-only entry or element
                         Read-only if
                            single entry (multiple entry is made read only through bind on the form) and
                            CRUD is L and the element is not the key
                            or CRUD is not L and does not contain U 
                            
                            OR elementType is staticValue
            
                            OR this is Full scope element in a Full Scope (expanded) multiple entry (isExpansionAxis is true) -->
            <xsl:if
                test="
                    ($repeatCount = 'single' and (($elementCRUD = 'L' and $keyIRI != $root) or ($elementCRUD != 'L' and not(contains($elementCRUD, 'U')))) or
                    $element/@cityEHR:elementType = ('#CityEHR:ElementProperty:staticValue', '#CityEHR:Property:ElementType:staticValue') or
                    $isExpansionAxis)">
                <xxf:variable name="xformsValue"
                    select="
                        if ($xformsElement/@displayName != '') then
                            $xformsElement/@displayName
                        else
                            $xformsElement/@value"/>
                <xhtml:li class="ISO13606-Data {{$xformsShowStructureClass}} ">
                    <xf:output
                        ref="if ($xformsValue castable as xs:dateTime) then format-dateTime(xs:dateTime($xformsValue),'{$view-parameters/dateTimeDisplayFormat}','{$view-parameters/languageCode}',(),()) else 
                            if ($xformsValue castable as xs:date) then format-date(xs:date($xformsValue),'{$view-parameters/dateDisplayFormat}', '{$view-parameters/languageCode}',(),()) else 
                            if ($xformsValue castable as xs:time) then format-time(xs:time($xformsValue),'{$view-parameters/timeDisplayFormat}', '{$view-parameters/languageCode}',(),()) else 
                        $xformsValue"
                    />
                </xhtml:li>
            </xsl:if>

            <!-- === Process element for data input.
                     If this is an element and the entry is not read-only.
                     Entries in multipleEntry have CRUD on the cda:component
                     This is initially empty and is set when the form is committed.
                     So need to allow edit when CRUD is empty (which is the case for newly added multiple entries) -->

            <xsl:if
                test="not($isExpansionAxis) and ($iso-13606Type = 'ISO13606-Element' and (contains($elementCRUD, 'U') or ($elementCRUD = 'L' and $keyIRI = $root) or $repeatCount = 'multiple'))">

                <!-- === (1) Element is enumeratedValue, enumeratedDirectory or enumeratedCalculatedValue
                Get list of values from the data dictionary or directory:
                <element root="#ISO-13606:Element:Gender" extension="#ISO-13606:Element:Gender" cityEHR:elementDisplayName="">
                    <data code="#ISO-13606:Data:Male" codeSystem="cityEHR" value="M" displayName="Male"/>
                    <data code="#ISO-13606:Data:Female" codeSystem="cityEHR" value="Female" displayName="Female"/>
                    <data code="#ISO-13606:Data:Unspecified" codeSystem="cityEHR" value="U" displayName="Unspecified"/>
                </element>
                
                The values for selection come from the element specified in the root attribute (not the extension)
                
                If there is a calculatedValue then this is used to constrain the selection.
                For enumeratedCalculatedValue, if there are no dictionary elements, then the calculated values are used as the selection.
            -->
                <xsl:if
                    test="$element[@cityEHR:elementType = ('#CityEHR:ElementProperty:enumeratedValue', '#CityEHR:ElementProperty:enumeratedDirectory', '#CityEHR:ElementProperty:enumeratedCalculatedValue', '#CityEHR:Property:ElementType:enumeratedValue', '#CityEHR:Property:ElementType:enumeratedDirectory', '#CityEHR:Property:ElementType:enumeratedCalculatedValue')]">
                    <!-- renoved for xf: prefix change 2022-08-14
                    <xf:group ref="$xformsElement/@value">          
                    -->
                    <xsl:variable name="elementType" select="$element/@cityEHR:elementType"/>
                    <xsl:variable name="calculatedValue"
                        select="
                            if (exists($element/@cityEHR:calculatedValue)) then
                                $element/@cityEHR:calculatedValue
                            else
                                ''"/>

                    <xsl:variable name="appearance"
                        select="
                            if ($elementScope = '#CityEHR:ElementProperty:Full') then
                                'full'
                            else
                                'minimal'"/>

                    <!-- If there is a calculated value to constrain the selection -->
                    <xsl:if
                        test="$elementType = ('#CityEHR:ElementProperty:enumeratedCalculatedValue', '#CityEHR:Property:ElementType:enumeratedCalculatedValue') or $calculatedValue != ''">
                        <xxf:variable name="xformsCalculatedValueSet" context="$xformsElement/@value"
                            select="
                                if ($xformsElement/@cityEHR:calculatedValue != '') then
                                    xxf:evaluate($xformsElement/@cityEHR:calculatedValue)
                                else
                                    ()"
                        />
                    </xsl:if>

                    <!-- Enumerated values for the element come from its root element in the dictionary.
                             This is just used here to decide how to set the xformsValueSet -->
                    <xsl:variable name="dictionaryValues"
                        select="$dictionary/iso-13606:EHR_Extract/iso-13606:elementCollection/iso-13606:element[@root = $root]/iso-13606:data"/>
                    <xsl:variable name="hasDictionaryValues"
                        select="
                            if (empty($dictionaryValues)) then
                                false()
                            else
                                true()"/>

                    <!-- xformsValueSet - enumeratedValue -->
                    <xsl:if
                        test="$elementType = ('#CityEHR:ElementProperty:enumeratedValue', '#CityEHR:Property:ElementType:enumeratedValue') and $calculatedValue = ''">
                        <xxf:variable name="xformsValueSet"
                            select="xxf:instance('dictionary-instance')/iso-13606:elementCollection/iso-13606:element[@root = '{$root}']/iso-13606:data"
                        />
                    </xsl:if>
                    <xsl:if
                        test="$elementType = ('#CityEHR:ElementProperty:enumeratedValue', '#CityEHR:Property:ElementType:enumeratedValue') and $calculatedValue != ''">
                        <xxf:variable name="xformsValueSet"
                            select="xxf:instance('dictionary-instance')/iso-13606:elementCollection/iso-13606:element[@root = '{$root}']/iso-13606:data[@value = $xformsCalculatedValueSet]"
                        />
                    </xsl:if>

                    <!-- xformsValueSet - enumeratedDirectory -->
                    <xsl:if
                        test="$elementType = ('#CityEHR:ElementProperty:enumeratedDirectory', '#CityEHR:Property:ElementType:enumeratedDirectory') and $calculatedValue = ''">
                        <xxf:variable name="xformsValueSet"
                            select="xxf:instance('directoryElements-instance')//iso-13606:element[@root = '{$root}']/iso-13606:data"/>
                    </xsl:if>
                    <xsl:if
                        test="$elementType = ('#CityEHR:ElementProperty:enumeratedDirectory', '#CityEHR:Property:ElementType:enumeratedDirectory') and $calculatedValue != ''">
                        <xxf:variable name="xformsValueSet"
                            select="xxf:instance('directoryElements-instance')/iso-13606:elementCollection/iso-13606:element[@root = '{$root}']/iso-13606:data[@value = $xformsCalculatedValueSet]"
                        />
                    </xsl:if>

                    <!-- xformsValueSet - enumeratedCalculatedValue
                             If there are dictionaryValues then its the same as enumeratedValue, with values constrained by the calculated set.
                             If there are no dictionaryValues then use the $xformsCalculatedValueSet -->
                    <xsl:if
                        test="$elementType = ('#CityEHR:ElementProperty:enumeratedCalculatedValue', '#CityEHR:Property:ElementType:enumeratedCalculatedValue') and not(empty($dictionaryValues))">
                        <xxf:variable name="xformsValueSet"
                            select="xxf:instance('dictionary-instance')/iso-13606:elementCollection/iso-13606:element[@root = '{$root}']/iso-13606:data[@value = $xformsCalculatedValueSet]"
                        />
                    </xsl:if>
                    <xsl:if
                        test="$elementType = ('#CityEHR:ElementProperty:enumeratedCalculatedValue', '#CityEHR:Property:ElementType:enumeratedCalculatedValue') and empty($dictionaryValues)">
                        <xxf:variable name="xformsValueSet" select="$xformsCalculatedValueSet"/>
                    </xsl:if>

                    <!-- xformsValueSet will either be a set of nodes or a set of atomic values -->
                    <xxf:variable name="xformsValueSetType"
                        select="
                            if ($xformsValueSet[1] instance of element()) then
                                'node'
                            else
                                'atomic'"/>

                    <!-- Unspecified value is always a node -->
                    <xxf:variable name="xformsUnspecifiedValue"
                        select="
                            if ('{$appearance}' = 'full') then
                                xxf:instance('application-parameters-instance')/displayFormat/unspecifiedFullScopeElementValue/value
                            else
                                xxf:instance('application-parameters-instance')/displayFormat/unspecifiedElementValue/value"/>

                    <xhtml:li class="ISO13606-Data {{$xformsShowStructureClass}} ">
                        <!-- Debugging
                        <xf:output ref="sum((1,2,'hrh'[. castable as xs:integer],4[. castable as xs:integer][. gt 3]))"/>
                        <xf:output ref="count((xs:integer('1')[. gt 0],xs:integer(2)[. gt 3],3,4))"/>
                        -->

                        <!-- Expanded scope - just output the displayName -->
                        <xsl:if test="$elementScope = '#CityEHR:ElementProperty:Expanded'">
                            <xf:output ref="$xformsElement/@displayName"/>
                        </xsl:if>

                        <!-- Only select element values for defined scope -->
                        <xsl:if test="not($elementScope = ('#CityEHR:ElementProperty:Expanded', '#CityEHR:ElementProperty:Expanded'))">
                            <xf:select1 ref="$xformsElement/@value" appearance="{$appearance}" xxf:refresh-items="true">
                                <!-- Item set is dynamic for all elementType (from 2018-09-18) 
                                         For enumeratedCalculatedValue the item set may contain atomic values - if valueSetType is 'atomic' -->
                                <xf:itemset nodeset="$xformsUnspecifiedValue , $xformsValueSet">
                                    <xf:label ref="if (. instance of element()) then ./@displayName else ."/>
                                    <xf:value ref="if (. instance of element()) then ./@value  else ."/>
                                </xf:itemset>

                                <!-- User made a selection -->
                                <xf:action ev:event="xforms-value-changed" if="xxf:instance('cdaControl-instance')/formStatus='ready'">
                                    <!-- First get the node that was selected. 
                                            XForms code depends on whether $xformsValueSet is nodes or atomic values -->

                                    <!-- $xformsValueSet is set of nodes
                                            Note that the element name of the node can vary. 
                                            Is iso-13606:data for enumeratedValue or enumeratedDirectory, but can be anything for enumeratedCalculatedValue -->
                                    <xf:action if="$xformsValueSetType != 'atomic'">
                                        <xxf:variable name="xformsSelectedValue" select="$xformsValueSet[@value = $xformsElement/@value][1]"/>
                                        <xf:setvalue ref="$xformsElement/@code"
                                            value="if (exists($xformsSelectedValue/@code)) then $xformsSelectedValue/@code else $xformsUnspecifiedValue/@code"/>
                                        <xf:setvalue ref="$xformsElement/@codeSystem"
                                            value="if (exists($xformsSelectedValue/@codeSystem)) then $xformsSelectedValue/@codeSystem else 'cityEHR'"/>
                                        <xf:setvalue ref="$xformsElement/@displayName"
                                            value="if (exists($xformsSelectedValue/@displayName)) then $xformsSelectedValue/@displayName else ''"/>
                                        <xf:setvalue ref="$xformsElement/@units"
                                            value="if (exists($xformsSelectedValue/@units)) then $xformsSelectedValue/@units else ''"/>
                                    </xf:action>

                                    <!-- $xformsValueSet is set of atomic values -->
                                    <xf:action if="$xformsValueSetType = 'atomic'">
                                        <xf:setvalue ref="$xformsElement/@code" value="''"/>
                                        <xf:setvalue ref="$xformsElement/@codeSystem" value="'cityEHR'"/>
                                        <xf:setvalue ref="$xformsElement/@displayName" value="$xformsElement/@value"/>
                                        <xf:setvalue ref="$xformsElement/@units" value="''"/>
                                    </xf:action>

                                    <!-- If this element is used as the sort criteria in a multiple entry, then resort when it changes -->
                                    <xsl:if test="$categorizationElementExtension = $extension">
                                        <xf:action>
                                            <xf:dispatch name="assign-sort-categories" target="main-model">
                                                <xxf:context name="entry" select="$xformsObservation/ancestor::cda:entry"/>
                                            </xf:dispatch>
                                        </xf:action>
                                    </xsl:if>

                                    <!-- If this element is used as the key in a directory look-up, then do the look-up when it changes.
                                        Need to always do this, so that initial pre-filled setting also triggers the lookup.
                                    -->
                                    <xsl:if test="contains($elementCRUD, 'L') and $keyIRI = $root">
                                        <xf:action>
                                            <xf:dispatch name="lookup-directory-entry" target="directory-model">
                                                <xxf:context name="entry" select="$xformsObservation"/>
                                                <xxf:context name="keyElement" select="$xformsElement"/>
                                            </xf:dispatch>
                                        </xf:action>
                                    </xsl:if>
                                </xf:action>

                                <!-- If an imageMap then refresh the SVG image classes -->
                                <xsl:if test="$mappedElementIRI != ''">
                                    <xf:action ev:event="xforms-value-changed">
                                        <xf:dispatch name="refresh-imageMapClasses" target="imageMap-model">
                                            <xxf:context name="mappedElementIRI" select="'{$mappedElementIRI}'"/>
                                            <xxf:context name="entry" select="$xformsEntry"/>
                                        </xf:dispatch>
                                    </xf:action>
                                </xsl:if>

                                <!-- If a required value then refresh the main model (for requiredElementStatus) -->
                                <xsl:if test="$isRequiredValue">
                                    <xf:action ev:event="xforms-value-changed">
                                        <xf:recalculate model="main-model"/>
                                    </xf:action>
                                </xsl:if>
                            </xf:select1>
                        </xsl:if>
                    </xhtml:li>
                    <!-- Display units for element, if they exist -->
                    <xsl:call-template name="renderUnits">
                        <xsl:with-param name="entryOccurrence" select="$entryOccurrence"/>
                        <xsl:with-param name="element" select="$element"/>
                    </xsl:call-template>

                </xsl:if>
                <!-- End of emunerated value -->


                <!-- === (2) Element is enumerated class 
                Get the class and entry point node (if any) from the data dictionary:
                <element root="cityEHR" extension="#ISO-13606:Element:BacterialDiagnosis" cityEHR:elementDisplayName="Bacterial">
                    <data code="#CityEHR:Class:Diagnosis:BacterialInfection" codeSystem="CityEHR" value="#CityEHR:Class:Diagnosis:BacterialInfection"/>
                </element>
                
                Then get the list of values for the class from the data dictionary:
                <element root="cityEHR" extension="#CityEHR:Class:Diagnosis" cityEHR:elementDisplayName="">
                    <data code="#CityEHR:Class:Diagnosis:BacterialInfection" codeSystem="cityEHR" value="Bacterial Infection">
                        <data code="#CityEHR:Class:Diagnosis:Osteomyelitis" codeSystem="cityEHR" value="Osteomyelitis"/>
                        <data code="#CityEHR:Class:Diagnosis:LymeDisease" codeSystem="cityEHR" value="Lyme disease"/>
                    </data>
                </element>    
                
                The control used is fr:autocomplete which needs to have an id so that it can be set by calling the fr-set-label event.
                The id used needs to be based on the entry:element so that it can be worked out from the composition model.
                This can only be done if the composition does not contain duplicate entry:element combinations.
                The id in a multiple entry appends the position of the entry within the organizer.
            -->
                <xsl:if test="$element[@cityEHR:elementType = '#CityEHR:ElementProperty:enumeratedClass']">


                    <!-- Need to generate a unique id for the auotcomplete control.
                         This uses the xslt function generate-id to create a unique id 
                         (from 2017-09-15, so that can now have multiple instances of an enumerated class element in the same composition )
                         setCount is needed because there may be multiple inputs for the same CDA element for categorised entries -->
                    <!--
                    <xsl:variable name="inputId" select="concat($entryId,'-',$elementId,'-',$setCount)"/>
                    -->
                    <xsl:variable name="inputId" select="concat(generate-id(), '-', $setCount)"/>

                    <xhtml:li class="ISO13606-Data {{$xformsShowStructureClass}} ">

                        <!-- Get the class and entry node from the data dictionary.
                                 These can be done in XSLT since they don't change -->
                        <xsl:variable name="classElement"
                            select="$dictionary/iso-13606:EHR_Extract/iso-13606:elementCollection/iso-13606:element[@root = $root]/iso-13606:data[1]"/>
                        <xsl:variable name="classCode" select="$classElement/@code"/>

                        <!-- Also need to check if element is being used to categorize the entry. **jc**
                             If so, then can only select from the class hierarchy in the current category.
                             That category should be a node at or below the entryNode in the same class. 
                             If not then the moodel is badly specified (and maybe nothing can be selected).
                        -->
                        <xsl:variable name="categoryEntryNode"
                            select="
                                if ($classCode = $categoryClass) then
                                    $categoryValue
                                else
                                    $classCode"/>

                        <!-- The entryNode is the same as the classCode if no specific entryNode is set.
                             This doesn't change so can be done in XSLT -->
                        <xsl:variable name="entryNode"
                            select="
                                if ($categoryEntryNode != $classCode) then
                                    $categoryEntryNode
                                else
                                    $classElement/@value"/>

                        <!-- Two versions of the autocomplete - one for selection from static list (defined scope) the other for dynamic lookup (full scope).
                             Plus need to handle the third case where the scope is 'expanded' 
                             2024-04-05 - no longer using expanded scope -->

                        <!-- Full scope = use lookup service - new version 2014-02
                             Also use this for Defined scope after 2014-05-28 -->
                        <xsl:if test="true()">

                            <xxf:variable name="xformsUnspecifiedElementValue"
                                select="xxf:instance('application-parameters-instance')/displayFormat/unspecifiedElementValue/value"/>
                            <xxf:variable name="xformsUnspecifiedElementValueWidth"
                                select="$xformsUnspecifiedElementValue/string-length(@displayName)"/>

                            <!-- xformsRecordedNode is the node in the class dictionary which matches the current value for this element in the CDA
                                     This is used so that the user can change the displayName of xformsElement in the input control 
                                     but we still have a handle on the original displayName until the value of xformsElement is changed
                                     Not needed after 2014-06-13 since we use $xformsElement directly to achieve this -->

                            <!-- Input control is used to type the displayName used for lookup
                                     From 2014-06-13 use $xformsElement directly as the input value, then set @value and @displayName when user selects a value. 
                                     Requires $xformsElement to be set with pre-fills and removed on publish 
                                     Then don't need to use $xformsRecordedNode -->
                            <xxf:variable name="xformsControlWidth"
                                select="max((xxf:instance('view-parameters-instance')/staticParameters/cityEHRFolder/fieldLength, min((xxf:instance('view-parameters-instance')/staticParameters/cityEHRFolder/maxFieldLength, $xformsElement/string-length(@displayName)))))"/>
                            <!-- Debugging 
                                    <xf:output ref="$xformsElement/@value"/>
                                    <xf:output ref="$xformsRecordedNode/@displayName"/>
                                    <xf:output ref="$xformsElement/@cityEHR:suppDataSet"/>
                                -->
                            <!--
                                <xf:output ref="xxf:instance('control-instance')/enumeratedClass/debug"/>
                                -->
                            <!--
                                <xf:output ref="$xformsRecordedNode/@displayName"/> / <xf:output ref="$xformsElement/@displayName"/> / <xf:output ref="xxf:instance('control-instance')/enumeratedClass/recordedDisplayName"/> /
                                -->

                            <xf:input id="{$inputId}" incremental="true" ref="$xformsElement" xxf:size="{{$xformsControlWidth}}">
                                <!-- Search for values when the user changes the input.
                                     Note that this will also fire when set from the hierarchy browser.
                                     But that should set the $xformsSearchValue to be the same as $xformsRecordedNode/@displayName so no search occurs -->
                                <xf:action ev:event="xforms-value-changed" if="xxf:instance('cdaControl-instance')/formStatus='ready'">
                                    <xxf:variable name="xformsSearchValue" select="normalize-space($xformsElement)"/>

                                    <xf:action if="normalize-space($xformsElement/@displayName)!=$xformsSearchValue">
                                        <!-- Debugging -->
                                        <!--
                                                    <xxf:script> alert('value changed'); </xxf:script>
                                                -->

                                        <!-- Debugging
                                                <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/debug" value="current-dateTime()"/>
                                                -->

                                        <!-- Debugging
                                                    <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/debug" value="xxf:instance('getEnumeratedClassValuesXQuery-instance')"/>
                                                -->

                                        <!-- Get the enumerationClass here by query to class dictionary.
                                                 Result is put into enumeratedClass-instance -->
                                        <xf:dispatch name="get-enumeratedClassElements" target="classDictionary-model">
                                            <xxf:context name="searchValue" select="$xformsSearchValue"/>
                                            <xxf:context name="classCode" select="'{$classCode}'"/>
                                            <xxf:context name="entryNode" select="'{$entryNode}'"/>
                                            <xxf:context name="elementScope" select="'{$elementScope}'"/>
                                        </xf:dispatch>

                                        <!-- Display to user depends on the number of hits -->
                                        <xxf:variable name="xformsHitCount" select="count(xxf:instance('enumeratedClass-instance')/iso-13606:data)"/>
                                        <!-- Hits - show the dialog to select.
                                             Set the focus for the element so that it can ve accessed from the dialog -->
                                        <xf:action if="$xformsHitCount gt 1">
                                            <xxf:variable name="timeStamp" select="replace(replace(string(current-dateTime()), ':', '-'), '\+', '*')"/>
                                            <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/focus" value="$timeStamp"/>
                                            <xf:setvalue ref="$xformsElement/@cityEHR:focus" value="$timeStamp"/>

                                            <xxf:show dialog="ClassDropdown-dialog" neighbor="{$inputId}"/>
                                            <xf:setfocus control="ClassDropdown-dialog"/>
                                        </xf:action>
                                        <!-- No hits - hide the dialog -->
                                        <xf:action if="$xformsHitCount eq 0">
                                            <xxf:hide dialog="ClassDropdown-dialog"/>
                                        </xf:action>
                                        <!-- Only one hit - so set it and don't display dialog. -->
                                        <xf:action if="$xformsHitCount eq 1">
                                            <xxf:variable name="xformsSelectedNode"
                                                select="xxf:instance('enumeratedClass-instance')/iso-13606:data[1]"/>

                                            <xf:dispatch name="set-elementData" target="main-model">
                                                <xxf:context name="element" select="$xformsElement"/>
                                                <xxf:context name="selectedData" select="$xformsSelectedNode"/>
                                            </xf:dispatch>

                                            <!-- Reset the recorded value (used to refresh the input control text) -->
                                            <xf:setvalue ref="$xformsElement" value="$xformsSelectedNode/@displayName"/>
                                            <xxf:hide dialog="ClassDropdown-dialog"/>
                                        </xf:action>

                                    </xf:action>


                                    <!-- Hide the dropdown dialog if the input displayName matches a node exactly -->
                                    <xf:action if="normalize-space($xformsElement/@displayName)=$xformsSearchValue">
                                        <xxf:hide dialog="ClassDropdown-dialog"/>
                                    </xf:action>
                                </xf:action>

                                <!-- Hide the dropdown when user clicks out of the input control.
                                         No new value has been set so the displayName will revert to the recorded one.
                                         This copes with the scenario where a rapid input resets the $xformsElement but no search is triggered -->
                                <xf:action ev:event="DOMFocusOut">
                                    <!-- Debugging 
                                        <xxf:script> alert('focus out'); </xxf:script>
                                        -->
                                    <!--
                                        <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/recordedDisplayName" value="if (exists($xformsRecordedNode)) then $xformsRecordedNode/@displayName else ."/>
                                        <xf:dispatch target="{$inputId}" name="refresh"/>
                                        -->
                                    <xf:setvalue ref="$xformsElement" value="$xformsElement/@displayName"/>
                                    <xxf:hide dialog="ClassDropdown-dialog"/>
                                </xf:action>

                                <!-- Set the initial displayName when user clicks in to the control -->
                                <xf:action ev:event="DOMFocusIn">
                                    <!-- Debugging 
                                           <xxf:script> alert('focus in'); </xxf:script>
                                        -->
                                    <xf:setvalue ref="$xformsElement" value="$xformsElement/@displayName"/>
                                    <xxf:hide dialog="ClassDropdown-dialog"/>
                                </xf:action>

                                <!-- If an imageMap then refresh the SVG image classes -->
                                <xsl:if test="$mappedElementIRI != ''">
                                    <xf:action ev:event="xforms-value-changed">
                                        <xf:dispatch name="refresh-imageMapClasses" target="imageMap-model">
                                            <xxf:context name="mappedElementIRI" select="'{$mappedElementIRI}'"/>
                                            <xxf:context name="entry" select="$xformsEntry"/>
                                        </xf:dispatch>
                                    </xf:action>
                                </xsl:if>

                                <!-- If a required value then refresh the main model (for requiredElementStatus) -->
                                <xsl:if test="$isRequiredValue">
                                    <xf:action ev:event="xforms-value-changed">
                                        <xf:recalculate model="main-model"/>
                                    </xf:action>
                                </xsl:if>
                            </xf:input>

                            <!-- Button to select value by browsing class hierarchy.
                                 Dialog is launched to select from the class hierarchy.
                                 Only when classSelectButton is set to true in the view-parameters 
                                 Need to set the elemen focus, classCode and entryNode so that the dialog can display the correct hierarchy 
                                 and set the values when a node is selected -->
                            <xsl:if test="$view-parameters/staticParameters/cityEHRFolder-Forms/classSelectButton/@show = 'true'">
                                <xf:trigger class="ClassHierarchySelectTrigger" appearance="minimal">
                                    <xf:label>
                                        <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Forms/classSelectButton/@label"/>
                                    </xf:label>
                                    <xf:action ev:event="DOMActivate">
                                        <!-- Set enumeratedClass parameters for use in the dialog -->
                                        <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/elementDisplayName"
                                            value="'{$element/@cityEHR:elementDisplayName}'"/>
                                        <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/classNode" value="'{$classCode}'"/>
                                        <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/entryNode" value="'{$entryNode}'"/>

                                        <!-- Get the enumerationClass here by query to class dictionary ***jc
                                             Sets enumeratedClassHierarchy-instance -->
                                        <xf:dispatch name="update-enumeratedClassHierarchy" target="classDictionary-model">
                                            <xxf:context name="classCode" select="'{$classCode}'"/>
                                            <xxf:context name="entryNode" select="'{$entryNode}'"/>
                                            <xxf:context name="elementScope" select="'{$elementScope}'"/>
                                        </xf:dispatch>

                                        <!-- Set the selected node before showing selection dialog.
                                             Note that if no node is recorded (i.e. is empty or not in data dictionary) then this does not get set -->
                                        <xf:action>
                                            <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/elementScope"
                                                value="$xformsElement/@cityEHR:Scope"/>
                                            <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/selectedValue"
                                                value="$xformsElement/@value"/>
                                            <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/selectedNode/@value"
                                                value="$xformsElement/@value"/>
                                            <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/selectedNode/@displayName"
                                                value="$xformsElement/@displayName"/>
                                            <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/selectedNode/@units"
                                                value="$xformsElement/@units"/>
                                            <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/selectedNode/@code"
                                                value="$xformsElement/@code"/>
                                            <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/selectedNode/@codeSystem"
                                                value="$xformsElement/@codeSystem"/>
                                            <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/selectedNode/@cityEHR:suppDataSet"
                                                value="$xformsElement/@cityEHR:suppDataSet"/>
                                        </xf:action>

                                        <!-- Show the enumerated class dialog, positioned next to the element ($inputId).
                                             Set focus so that the element can be referenced in the dialog -->
                                        <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/inputId" value="'{$inputId}'"/>
                                        <xxf:variable name="timeStamp" select="replace(replace(string(current-dateTime()), ':', '-'), '\+', '*')"/>
                                        <xf:setvalue ref="xxf:instance('control-instance')/enumeratedClass/focus" value="$timeStamp"/>
                                        <xf:setvalue ref="$xformsElement/@cityEHR:focus" value="$timeStamp"/>

                                        <xxf:show ev:event="DOMActivate" dialog="ClassSelect-dialog" neighbor="{$inputId}"/>
                                    </xf:action>
                                </xf:trigger>
                            </xsl:if>

                        </xsl:if>

                        <!-- Display units for element, if they exist. -->
                        <!--
                        <xsl:call-template name="renderUnits">
                            <xsl:with-param name="entryOccurrence" select="$entryOccurrence"/>
                            <xsl:with-param name="element" select="$element"/>
                        </xsl:call-template>
                        -->

                        <!-- This is for debugging 
                    <xhtml:span class="SupplementaryEntryTrigger">
                        <xf:output ref="xxf:instance('control-instance')/suppDataSet/selectionCount"/>
                        <xsl:value-of select="$inputId"/>
                    </xhtml:span>
                    -->

                        <!-- Display additional information on supplementary entry, if SDS exists.
                             This is the trigger to enter the SDS
                             And display of any values that have been set.
                        
                             Don't show the button for multiple entries that are CRD (i.e. cannot be updated) -->
                        <xsl:if test="true()">
                            <xxf:variable name="xformsSupplementaryEntry"
                                select="$xformsObservation/cda:entryRelationship[@cityEHR:origin = '{$root}']"/>

                            <xxf:variable name="xformsSupplementaryEntryTriggerClass"
                                select="
                                    if (exists($xformsSupplementaryEntry)) then
                                        'SupplementaryEntryTrigger'
                                    else
                                        'hidden'"/>

                            <!-- Display trigger to enter the SDS in a dialogue -->
                            <xf:trigger class="{{$xformsSupplementaryEntryTriggerClass}}" appearance="minimal">
                                <xf:label>
                                    <xsl:value-of select="$view-parameters/staticParameters/cityEHRFolder-Forms/sdsButton/@label"/>
                                </xf:label>
                                <xf:action ev:event="DOMActivate">

                                    <!-- Set up the supplementary data set for the current element in the control-instance -->
                                    <xxf:variable name="timeStamp" select="replace(replace(string(current-dateTime()), ':', '-'), '\+', '*')"/>
                                    <xf:setvalue ref="xxf:instance('control-instance')/suppDataSet/focus" value="$timeStamp"/>
                                    <xf:setvalue ref="$xformsSupplementaryEntry/@cityEHR:focus" value="$timeStamp"/>

                                    <!-- Get the enumerationClass here by query to class dictionary -->
                                    <xf:dispatch name="get-dictionaryElements" target="classDictionary-model">
                                        <xxf:context name="classCode" select="'{$classCode}'"/>
                                        <xxf:context name="supplementaryEntry" select="$xformsSupplementaryEntry"/>
                                    </xf:dispatch>

                                    <xxf:show ev:event="DOMActivate" dialog="SDS-dialog" constrain="true"/>
                                </xf:action>
                            </xf:trigger>

                            <!-- Display the details of values in the SDS that have been set.
                                     This includes elements that are within clusters (i.e. cda:value/cda:value-->

                            <xxf:variable name="xformsHasSetValues"
                                select="exists($xformsSupplementaryEntry/cda:observation/descendant::cda:value[@value != ''])"/>
                            <xxf:variable name="xformsSetValues"
                                select="
                                    if ($xformsHasSetValues) then
                                        $xformsSupplementaryEntry/cda:observation/cda:value[@value != '' or cda:value/@value != '']
                                    else
                                        ()"/>
                            <xxf:variable name="xformsLabelWidth"
                                select="max($xformsSupplementaryEntry/cda:observation/cda:value[@value != '']/@cityEHR:elementDisplayName/string-length())"/>

                            <xhtml:ul class="SupplementaryEntry {{if ($xformsHasSetValues) then '' else 'hidden'}}">
                                <xf:repeat nodeset="$xformsSetValues">
                                    <xhtml:li class="Ranked">
                                        <xhtml:ul>
                                            <!-- Value may have child elements if it is a cluster.
                                         Only want to display the elements that have set values in the cluster. -->
                                            <xf:repeat nodeset="if (exists(./cda:value)) then ./cda:value[@value!=''] else .">
                                                <xxf:variable name="xformsSupplementaryEntryValue" select="."/>
                                                <!-- The layout depends on whether this element is in a cluster, or not -->
                                                <xxf:variable name="layoutClass"
                                                    select="
                                                        if ($xformsSupplementaryEntryValue/parent::*/name() = 'value') then
                                                            'Unranked'
                                                        else
                                                            'Ranked'"/>
                                                <xhtml:li class="{{$layoutClass}}">
                                                    <xhtml:ul class="ISO13606-Element {{$xformsShowStructureClass}} ">
                                                        <xhtml:li class="ISO13606-Element-DisplayName">
                                                            <xf:output ref="$xformsSupplementaryEntryValue/@cityEHR:elementDisplayName"/>
                                                        </xhtml:li>
                                                        <xxf:variable name="xformsValue" select="$xformsSupplementaryEntryValue/@value"/>
                                                        <xhtml:li class="ISO13606-Data {{$xformsShowStructureClass}} ">
                                                            <xf:output
                                                                ref="if ($xformsValue castable as xs:dateTime) then format-dateTime(xs:dateTime($xformsValue),'{$view-parameters/dateTimeDisplayFormat}', '{$view-parameters/languageCode}',(),()) else 
                                                      if ($xformsValue castable as xs:date) then format-date(xs:date($xformsValue),'{$view-parameters/dateDisplayFormat}', '{$view-parameters/languageCode}',(),()) else 
                                                      if ($xformsValue castable as xs:time) then format-time(xs:time($xformsValue),'{$view-parameters/timeDisplayFormat}', '{$view-parameters/languageCode}',(),()) else 
                                                                $xformsValue"
                                                            />
                                                        </xhtml:li>
                                                    </xhtml:ul>
                                                </xhtml:li>
                                            </xf:repeat>
                                            <xhtml:li class="LayoutFooter">&#160;</xhtml:li>
                                        </xhtml:ul>
                                    </xhtml:li>
                                </xf:repeat>
                                <xhtml:li class="LayoutFooter">&#160;</xhtml:li>
                            </xhtml:ul>

                            <!-- Set up an observer to check when the value of this element changes.
                                 This is made as a hidden input.
                                
                                 On change insert the new supplementary data set, if the selected node has one.

                                The supplementary data set is identified in the organizer by:
                                <id root="cityEHR" extension="#ISO-13606:Entry:Infection" cityEHR:origin="#ISO-13606:Element:Diagnosis"/>
                                
                                The selected SDS is identified by $extension and $xformsSelectedSDS
                                
                                For debugging can set class to message
                            -->
                            <xf:input class="hidden" ref="$xformsElement/@value">
                                <xf:action ev:event="xforms-value-changed" if="xxf:instance('cdaControl-instance')/formStatus='ready'">
                                    <xxf:variable name="xformsSDSiri" select="$xformsElement/@cityEHR:suppDataSet"/>

                                    <!-- Remove exisitng SDS -->
                                    <xf:delete nodeset="$xformsObservation/cda:entryRelationship[@cityEHR:origin='{$root}']"/>

                                    <!-- Get the dictionary entry for the SDS from the specialty dictionary -->
                                    <xxf:variable name="xformsSuppDataSetEntry"
                                        select="xxf:instance('dictionary-instance')/iso-13606:entryCollection/iso-13606:entry/cda:component/cda:observation[cda:id/@root = $xformsSDSiri]"/>

                                    <!-- The SDS observation is held in an entryRelationship element within the entry -->
                                    <xf:action if="exists($xformsSuppDataSetEntry)">
                                        <!-- Insert the template entryRelationship -->
                                        <xf:insert context="$xformsObservation" nodeset="*"
                                            origin="xxf:instance('control-instance')/suppDataSet/cda:entryRelationship" at="last()" position="after"/>
                                        <!-- Set the origin of the new entryRelationship -->
                                        <xxf:variable name="xformsSuppDataSet" select="$xformsObservation/cda:entryRelationship[@cityEHR:origin = '']"/>
                                        <xf:setvalue ref="$xformsSuppDataSet/@cityEHR:origin" value="'{$root}'"/>
                                        <!-- Insert the new SDS entry (cda:observation) -->
                                        <xf:insert context="$xformsSuppDataSet" origin="$xformsSuppDataSetEntry"/>
                                    </xf:action>

                                    <!-- If this element is used as the sort criteria in a multiple entry, then resort when it changes -->
                                    <xsl:if test="$categorizationElementExtension = $extension">
                                        <xf:action>
                                            <xf:dispatch name="assign-sort-categories" target="main-model">
                                                <xxf:context name="entry" select="$xformsObservation/ancestor::cda:entry"/>
                                            </xf:dispatch>
                                        </xf:action>
                                    </xsl:if>
                                </xf:action>
                            </xf:input>
                        </xsl:if>
                    </xhtml:li>
                </xsl:if>
                <!-- End of enumerated class -->

                <!-- === (3) Element is memo type 2015-05-30 added incremental="true" -->
                <xsl:if test="$element[@cityEHR:elementType = ('#CityEHR:ElementProperty:memo', '#CityEHR:Property:ElementType:memo')]">
                    <xhtml:li class="ISO13606-Data {{$xformsShowStructureClass}} ">
                        <xf:textarea ref="$xformsElement/@value" appearance="xxf:autosize" style="min-width: 30em;" incremental="true">
                            <xf:label/>
                            <!-- When value changes. -->
                            <xf:action ev:event="xforms-value-changed" if="xxf:instance('cdaControl-instance')/formStatus='ready'">
                                <!-- displayName of memo is always blank -->
                                <xf:setvalue ref="$xformsElement/@displayName" value="''"/>
                            </xf:action>
                        </xf:textarea>
                    </xhtml:li>
                    <!-- Display units for element, if they exist -->
                    <xsl:call-template name="renderUnits">
                        <xsl:with-param name="entryOccurrence" select="$entryOccurrence"/>
                        <xsl:with-param name="element" select="$element"/>
                    </xsl:call-template>
                </xsl:if>

                <!-- === (4) Element is range type -->
                <xsl:if test="$element[@cityEHR:elementType = ('#CityEHR:ElementProperty:rangeXXX', '#CityEHR:Property:ElementType:rangeXXX')]">

                    <!-- Range must be set using XSLT because start and end attributes on xf:tange cannot be AVTs -->
                    <xsl:variable name="dictionaryElement"
                        select="$dictionary/iso-13606:EHR_Extract/iso-13606:elementCollection/iso-13606:element[@extension = $root]/iso-13606:data"/>
                    <xsl:variable name="start"
                        select="
                            if ($dictionaryElement/iso-13606:data[1]/@value castable as xs:double) then
                                $dictionaryElement/iso-13606:data[1]/@value
                            else
                                '1'"/>
                    <xsl:variable name="end"
                        select="
                            if ($dictionaryElement/iso-13606:data[2]/@value castable as xs:double) then
                                $dictionaryElement/iso-13606:data[2]/@value
                            else
                                '100'"/>

                    <xhtml:li class="ISO13606-Data {{$xformsShowStructureClass}} ">
                        <xf:range ref="$xformsElement/@value" incremental="true" start="1" end="100">
                            <xf:label/>
                            <xf:action ev:event="xforms-value-changed" if="xxf:instance('cdaControl-instance')/formStatus='ready'">
                                <!-- If this element is used as the sort criteria in a multiple entry, then resort when it changes -->
                                <xsl:if test="$categorizationElementExtension = $extension">
                                    <xf:action>
                                        <xf:dispatch name="assign-sort-categories" target="main-model">
                                            <xxf:context name="entry" select="$xformsObservation/ancestor::cda:entry"/>
                                        </xf:dispatch>
                                    </xf:action>
                                </xsl:if>
                            </xf:action>
                        </xf:range>
                        <xf:output ref="$xformsElement/@value"/>
                    </xhtml:li>

                    <!-- Display units for element, if they exist -->
                    <xsl:call-template name="renderUnits">
                        <xsl:with-param name="entryOccurrence" select="$entryOccurrence"/>
                        <xsl:with-param name="element" select="$element"/>
                    </xsl:call-template>
                </xsl:if>

                <!-- === (5) Element is media type. 
                         Changed 2014-12-10.
                         Previously media filename was the elementId.
                         Changed to use the element value, which means different media can be set as default values.
                         Also means that this is determined in the $xformsElement.
                
                         From 2021-10-07 media is loaded to the form-instance and is held as the element content -->
                <!-- Until 2022-11-10 - now use rendtion on entry -->
                <!--
                <xsl:if test="$element[@cityEHR:elementType = ('#CityEHR:ElementProperty:media', '#CityEHR:Property:ElementType:media')]">
                    <xhtml:li class="ISO13606-Data">
                       <xxf:variable name="xformsDisplayImageClass"
                            select="
                                if ($xformsElement/@value != '') then
                                    'media'
                                else
                                    'hidden'"/>
                        <xhtml:img src="data:image/*;base64, {{xs:base64Binary($xformsElement/@value)}}" class="{{$xformsDisplayImageClass}}"/>
                    </xhtml:li>
                </xsl:if>
                -->

                <!-- === (6) Element is patient media type.
                             Control is upload to get the media to be stored in the record.
                             sourceType is set by the control when the image is uploaded -->

                <!-- The new (Single way) from 2021-19-15 
                     Requires the value to be bound to xs:base64Binary (done in cdaModel) -->
                <xsl:if
                    test="$element[@xsi:type = 'xs:base64Binary' and @cityEHR:elementType = ('#CityEHR:ElementProperty:patientMedia', '#CityEHR:Property:ElementType:patientMedia')]">
                    <xhtml:li class="ISO13606-Data {{$xformsShowStructureClass}} ">
                        <xf:upload ref="$xformsElement/@value" incremental="true">
                            <xf:action ev:event="xxforms-upload-done">
                                <!-- Not doing anything here -->
                            </xf:action>
                        </xf:upload>

                        <!-- Display the image, if it is set -->
                        <xf:group ref="$xformsElement/@value[.!='']" class="{{if ($xformsElement/@value = '') then 'hidden' else ''}}">
                            <xhtml:img src="data:image/*;base64,{{xs:base64Binary($xformsElement/@value)}}"/>
                        </xf:group>
                    </xhtml:li>
                </xsl:if>

                <!-- === (7) Element is recognised XML type.
                     Or range until we can get that working.
                     incremental="true" added 2015-05-29 but only for certain data types  -->
                <xsl:if
                    test="$element[@cityEHR:elementType = ('#CityEHR:ElementProperty:simpleType', '#CityEHR:ElementProperty:range', '#CityEHR:Property:ElementType:simpleType', '#CityEHR:Property:ElementType:range')]">
                    <xsl:variable name="incremental"
                        select="
                            if ($element/@xsi:type = 'xs:date') then
                                'false'
                            else
                                'true'"/>
                    <xhtml:li class="ISO13606-Data {{$xformsShowStructureClass}} ">
                        <xf:input ref="$xformsElement/@value" xxf:size="{$fieldLength}" incremental="{$incremental}">
                            <!-- When value changes, but only when control loses focus (so not when the value is changed by an agent that is not the user) -->
                            <xf:action ev:event="xforms-value-changed" if="xxf:instance('cdaControl-instance')/formStatus='ready'">
                                <!-- Check date input - only include for xs:date type elements -->
                                <xsl:if test="$element/@xsi:type = 'xs:date'">
                                    <xxf:variable name="xformsInputAsString" select="normalize-space(xs:string($xformsElement/@value))"/>
                                    <!-- Current date accelerator -->
                                    <xf:action
                                        if="$xformsInputAsString=xxf:instance('view-parameters-instance')/staticParameters/cityEHRFolder/currentDateAccelerator">
                                        <xf:setvalue ref="$xformsElement/@value" value="current-date()"/>
                                    </xf:action>
                                    <!-- Enter just a year (in an acceptable range) - set to default date.
                                        Uses the configuration parameter     
                                        <yearInputAsDate low="1900" high="2100" suffix="-01-01"/> -->
                                    <xf:action if="$xformsInputAsString castable as xs:integer">
                                        <xxf:variable name="xformsInputAsInteger" select="xs:integer($xformsInputAsString)"/>
                                        <xxf:variable name="xformsYearInputAsDate"
                                            select="xxf:instance('view-parameters-instance')/staticParameters/cityEHRFolder/yearInputAsDate"/>
                                        <xf:setvalue ref="$xformsElement/@value"
                                            value="if (($xformsInputAsInteger ge xs:integer($xformsYearInputAsDate/@low)) and ($xformsInputAsInteger le xs:integer($xformsYearInputAsDate/@high))) then concat($xformsInputAsString,$xformsYearInputAsDate/@suffix) else ."
                                        />
                                    </xf:action>

                                    <!-- Always reset the date so that it displays in the format specified in the view-parameters -->
                                    <!-- you wish
                                    <xf:setvalue ref="$xformsElement/@value" value="."/>
                                    -->
                                </xsl:if>

                                <!-- Clear the input if it is not of the correct data type (needs to be done after date accelerator stuff) -->
                                <xf:action if="not($xformsElement/@value castable as {$element/@xsi:type})">
                                    <xf:setvalue ref="$xformsElement/@value" value="''"/>
                                </xf:action>

                                <!-- Since this is a Single type, it just needs a value, not a displayName.
                                     But displayName may have been set to previous value (e.g. for imported data, or if the model has changed.
                                     So reset to blank, to make sure -->
                                <xf:setvalue ref="$xformsElement/@displayName" value="''"/>

                                <!-- If this element is used as the sort criteria in a multiple entry, then resort when it changes -->
                                <xsl:if test="$categorizationElementExtension = $extension">
                                    <xf:action>
                                        <xf:dispatch name="assign-sort-categories" target="main-model">
                                            <xxf:context name="entry" select="$xformsObservation/ancestor::cda:entry"/>
                                        </xf:dispatch>
                                    </xf:action>
                                </xsl:if>

                            </xf:action>

                            <!-- If this element is used as the key in a directory look-up, then do the look-up when it changes.
                                     Need to always do this, so that initial pre-filled setting also triggers the lookup.
                                     -->
                            <xsl:if test="contains($elementCRUD, 'L') and $keyIRI = $root">
                                <xf:action ev:event="xforms-value-changed">
                                    <xf:dispatch name="lookup-directory-entry" target="directory-model">
                                        <xxf:context name="entry" select="$xformsObservation"/>
                                        <xxf:context name="keyElement" select="$xformsElement"/>
                                    </xf:dispatch>
                                </xf:action>
                            </xsl:if>

                            <!-- If an imageMap then refresh the SVG image classes -->
                            <xsl:if test="$mappedElementIRI != ''">
                                <xf:action ev:event="xforms-value-changed">
                                    <xf:dispatch name="refresh-imageMapClasses" target="imageMap-model">
                                        <xxf:context name="mappedElementIRI" select="'{$mappedElementIRI}'"/>
                                        <xxf:context name="entry" select="$xformsEntry"/>
                                    </xf:dispatch>
                                </xf:action>
                            </xsl:if>

                            <!-- If a required value then refresh the main model (for requiredElementStatus) -->
                            <xsl:if test="$isRequiredValue">
                                <xf:action ev:event="xforms-value-changed">
                                    <xf:recalculate model="main-model"/>
                                </xf:action>
                            </xsl:if>

                        </xf:input>
                    </xhtml:li>
                    <!-- Display units for element, if they exist -->
                    <xsl:call-template name="renderUnits">
                        <xsl:with-param name="entryOccurrence" select="$entryOccurrence"/>
                        <xsl:with-param name="element" select="$element"/>
                    </xsl:call-template>
                </xsl:if>

                <!-- === (8) Element is calculated value or age -->
                <xsl:if
                    test="$element[@cityEHR:elementType = ('#CityEHR:ElementProperty:calculatedValue', '#CityEHR:ElementProperty:age', '#CityEHR:Property:ElementType:calculatedValue', '#CityEHR:Property:ElementType:age')]">
                    <xxf:variable name="xformsValue" select="$xformsElement/@value"/>
                    <xxf:variable name="xformsDisplayName" select="$xformsElement/@displayName"/>
                    <xhtml:li class="ISO13606-Data {{$xformsShowStructureClass}} ">
                        <!-- xf:group is needed to ensure that the xforms-value-changed event is triggered -->
                        <xf:group ref="$xformsValue">
                            <xf:output
                                ref="if ($xformsDisplayName !='') then $xformsDisplayName else if ($xformsValue castable as xs:dateTime) then format-dateTime(xs:dateTime($xformsValue),'{$view-parameters/dateTimeDisplayFormat}', '{$view-parameters/languageCode}',(),()) else 
                                if ($xformsValue castable as xs:date) then format-date(xs:date($xformsValue),'{$view-parameters/dateDisplayFormat}', '{$view-parameters/languageCode}',(),()) else 
                                if ($xformsValue castable as xs:time) then format-time(xs:time($xformsValue),'{$view-parameters/timeDisplayFormat}', '{$view-parameters/languageCode}',(),()) else 
                            $xformsValue"/>
                            <!-- If this element is used as the sort criteria in a multiple entry, then resort when it changes -->
                            <xsl:if test="$categorizationElementExtension = $extension">
                                <xf:action ev:event="xforms-value-changed" if="xxf:instance('cdaControl-instance')/formStatus='ready'">
                                    <xf:dispatch name="assign-sort-categories" target="main-model">
                                        <xxf:context name="entry" select="$xformsObservation/ancestor::cda:entry"/>
                                    </xf:dispatch>
                                </xf:action>
                            </xsl:if>
                            <!-- If this element is used the key in a directory look-up, then do the look-up when it changes.
                                     Need to always do this, so that initial pre-filled setting also triggers the lookup.
                                     Only perform look up if entry and element are both visible - this can be achieved by making sure in the model 
                                     that the calculation doesn't change the value when the element is hidden
                                -->
                            <xsl:if test="contains($elementCRUD, 'L') and $keyIRI = $root">
                                <xf:action ev:event="xforms-value-changed">
                                    <xf:dispatch name="lookup-directory-entry" target="directory-model">
                                        <xxf:context name="entry" select="$xformsObservation"/>
                                        <xxf:context name="keyElement" select="$xformsElement"/>
                                    </xf:dispatch>
                                </xf:action>
                            </xsl:if>

                            <!-- For calculatedValue, it just needs a value, not a displayName.
                                 But displayName may have been set to previous value (e.g. for imported data, or if the model has changed.
                                 So reset to blank, to make sure -->
                            <xsl:if
                                test="$element[@cityEHR:elementType = ('#CityEHR:ElementProperty:calculatedValue', '#CityEHR:Property:ElementType:calculatedValue')]">
                                <xf:action ev:event="xforms-value-changed">
                                    <xf:setvalue ref="$xformsElement/@displayName" value="''"/>
                                </xf:action>
                            </xsl:if>

                            <!-- For calculatedValue, set displayName using current parameters.
                                 Uses patient age stored in xxf:instance('patient-instance')/cdaheader/birthTime -->
                            <xsl:if test="$element[@cityEHR:elementType = ('#CityEHR:ElementProperty:age', '#CityEHR:Property:ElementType:age')]">
                                <xf:action ev:event="xforms-value-changed">
                                    <xf:dispatch name="set-patient-ageDisplayName" target="patientDemographics-model">
                                        <xxf:context name="value" select="$xformsElement/@value"/>
                                        <xxf:context name="displayName" select="$xformsElement/@displayName"/>
                                    </xf:dispatch>
                                </xf:action>
                            </xsl:if>
                        </xf:group>
                    </xhtml:li>
                    <!-- Display units for element, if they exist -->
                    <xsl:call-template name="renderUnits">
                        <xsl:with-param name="entryOccurrence" select="$entryOccurrence"/>
                        <xsl:with-param name="element" select="$element"/>
                    </xsl:call-template>
                </xsl:if>

                <!-- === (9) Element is URL -->
                <xsl:if test="$element[@cityEHR:elementType = ('#CityEHR:ElementProperty:url', '#CityEHR:Property:ElementType:url')]">
                    <xhtml:li class="ISO13606-Data {{$xformsShowStructureClass}} ">
                        <xhtml:a href="{$element/@value}" target="_blank">
                            <xsl:value-of select="$element/@displayName"/>
                        </xhtml:a>
                    </xhtml:li>
                </xsl:if>

            </xsl:if>

            <xhtml:li class="LayoutFooter">&#160;</xhtml:li>
            <!-- End of processing element -->

        </xhtml:ul>

        <!-- Handle result of directory look up for the key element.
             This is outside the element display, since it is always visible, even for hidden elements -->
        <xsl:if test="contains($elementCRUD, 'L') and $keyIRI = $root">
            <xhtml:li class="Unranked">
                <xxf:variable name="directoryEntrySet"
                    select="xxf:instance('directoryEntry-instance')[@entryId = '{$entryId}'][@elementId = '{$elementId}']"/>
                <!-- Message has been set in the lookup-directory-entry action -->
                <xf:output class="message"
                    ref="xxf:instance('directoryEntry-instance')[@entryId='{$entryId}'][@elementId='{$elementId}']/@displayName"/>
                <!-- User selection if there are multiple entries returned from the directory lookup -->
                <xf:select1 ref="if (exists($directoryEntrySet/cda:observation[2])) then $directoryEntrySet/@selection else ()">
                    <xf:itemset nodeset="$directoryEntrySet/cda:observation">
                        <xf:label
                            ref="if (descendant::cda:value[@extension='{$keyIRI}']/@displayName != '') then descendant::cda:value[@extension='{$keyIRI}']/@displayName else descendant::cda:value[@extension='{$keyIRI}']/@value"/>
                        <xf:value ref="descendant::cda:value[@extension='{$keyIRI}']/@value"/>
                    </xf:itemset>
                    <!-- User selected an entry -->
                    <xf:action ev:event="xforms-value-changed">
                        <!-- Get the selected directory entry -->
                        <xxf:variable name="directoryEntry"
                            select="$directoryEntrySet/cda:observation[descendant::cda:value[@extension = '{$keyIRI}']/@value = $directoryEntrySet/@selection]"/>
                        <!-- Set the entry on the form -->
                        <xf:dispatch name="set-entry-from-directory" target="directory-model">
                            <xxf:context name="entry" select="$xformsObservation"/>
                            <xxf:context name="elementIRI" select="'{$keyIRI}'"/>
                            <xxf:context name="directoryEntry" select="$directoryEntry"/>
                        </xf:dispatch>
                    </xf:action>
                </xf:select1>

            </xhtml:li>
        </xsl:if>


    </xsl:template>


    <!-- ====================================================================
         Render an image map for the specified entry.
         Either use the SVG image map, if it exists
         Or the HTML image map
         
         The set of SVG image maps for this composition is passed as svgImageMaps
         ==================================================================== -->

    <xsl:template name="renderImageMap">
        <xsl:param name="entryId"/>
        <!-- Degugging
        <xhtml:p class="error"><xsl:value-of select="$entryId"/></xhtml:p>
-->
        
        <!-- The imageMap should always exist (but don't assume so) and may be empty if no SVG has been loaded -->
        <xsl:variable name="imageMap" select="$svgImageMaps//svg:svg[@id = $entryId]"/>
        <xsl:variable name="imageMapContents"
            select="
                if (exists($imageMap)) then
                    $imageMap/*[1]
                else
                    ()"/>

        <xhtml:li class="Unranked imageContainer">
            <!-- SVG image map -->
            <xsl:if test="exists($imageMapContents)">
                <xsl:call-template name="renderSVGImageMap">
                    <xsl:with-param name="imageMap" select="$imageMap"/>
                </xsl:call-template>
            </xsl:if>

            <!-- HTML image map -->
            <!--
            <xsl:if test="not(exists($imageMapContents))">
                <xsl:call-template name="renderHTMLImageMap">
                    <xsl:with-param name="entryId" select="$entryId"/>
                </xsl:call-template>
            </xsl:if>
            -->
        </xhtml:li>

    </xsl:template>


    <!-- Render an HTML image map for the specified entry.
         Get details for the image map from the .html file in the resources for this application.
         That file contains additional code so that it will run standalone.
         Just need to get the width/height for the image and the map element itself.
         -->
    <xsl:template name="renderHTMLImageMap">
        <xsl:param name="entryId"/>

        <xsl:variable name="imagePath" select="concat('../resources/applications/', $applicationId, '/imageMaps/', $entryId)"/>
        <xsl:variable name="imageMapPath" select="concat('../resources/applications/', $applicationId, '/imageMaps/', $entryId)"/>

        <xsl:variable name="image" select="concat($imagePath, '.png')"/>
        <xsl:variable name="imageMap" select="concat($imageMapPath, '.html')"/>
        <xsl:variable name="imageMapRoot"
            select="
                if (exists(document($imageMap)/html)) then
                    document($imageMap)/html
                else
                    ()"/>

        <!-- Display image map, but only if it exists.
             imageContainer is needed so that we can apply css to make the image scroll properly in IE. 
             In Orbeon the image gets replaced by a background image that then needs the css backgroundAttachment: scroll -->
        <xsl:if test="exists($imageMapRoot)">
            <!-- Img needs to use correct path to the image, so write it here.
                Note that the 'map' class is used by maphilight and by javascript in cityEHR.js -->
            <img class="map imageContainer" src="{$image}" useMap="#{$entryId}" width="{$imageMapRoot/body/img/@width}"
                height="{$imageMapRoot/body/img/@height}" alt=""/>
            <!-- The image map can be copied from the image map html file. -->
            <xsl:copy-of select="$imageMapRoot/body/map"/>

        </xsl:if>

    </xsl:template>


    <!-- Render an SVG image map for the specified entry.
         Just copy its SVG to the XForm.
         -->
    <xsl:template name="renderSVGImageMap">
        <xsl:param name="imageMap"/>

        <xsl:copy-of select="$imageMap"/>

    </xsl:template>


    <!-- ====================================================================
        Render units for an element.
        Displays the units as set, or gets the calculated units
        ==================================================================== -->

    <xsl:template name="renderUnits">
        <xsl:param name="entryOccurrence"/>
        <xsl:param name="element"/>

        <xsl:if test="$entryOccurrence = 'Single' or exists($element/@cityEHR:calculatedUnit)">
            <xhtml:li class="ISO13606-Element-Units">
                <xxf:variable name="xformsElementUnitDisplayClass"
                    select="
                        if ($xformsElement/@units != '') then
                            ''
                        else
                            'hidden'"/>
                <xhtml:span class="{{$xformsElementUnitDisplayClass}}">(<xf:output ref="$xformsElement/@units"/>) </xhtml:span>
            </xhtml:li>
        </xsl:if>

    </xsl:template>



    <!-- ====================================================================
        Get the Xpath of the current context node.
        The full path must be found first by calling saxon:path() at the context where the function is called
        Path is from cda:ClinicalDocument as root and includes the cda namespace     
        The path used in the form is from form-instance, so is relative to the containing ClinicalDocument
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getXPath">
        <xsl:param name="fullXPath"/>

        <xsl:variable name="root" select="'/cda:ClinicalDocument'"/>
        <xsl:variable name="xPath" select="concat('xxf:instance(''form-instance'')', substring-after(replace($fullXPath, '/', '/cda:'), $root))"/>

        <!-- Output the XPath -->
        <xsl:value-of select="$xPath"/>

    </xsl:function>

    <!-- ====================================================================
         Pad a displayName label with the labelPadder to the specified length.
         Note that this is only useful if using fixed width fonts.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:padLabel">
        <xsl:param name="label"/>
        <xsl:param name="labelWidth"/>

        <xsl:variable name="textWidth" select="string-length($label)"/>
        <xsl:variable name="labelPadder"
            select="
                if (exists($view-parameters/labelPadder)) then
                    $view-parameters/labelPadder
                else
                    'x'"/>

        <xsl:variable name="fullLabel" select="cityEHRFunction:padText($label, $textWidth, $labelWidth, $labelPadder)"/>

        <!-- Output the padded label -->
        <xsl:value-of select="$fullLabel"/>

    </xsl:function>


    <!-- ====================================================================
        Pad label with the specified labelPadder to the specified length     
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:padText">
        <xsl:param name="label"/>
        <xsl:param name="textWidth"/>
        <xsl:param name="labelWidth"/>
        <xsl:param name="labelPadder"/>

        <!-- Recursive call to pad out until labelWidth is reached -->
        <xsl:variable name="paddedLabel"
            select="
                if ($textWidth &lt;= $labelWidth) then
                    cityEHRFunction:padText(concat($label, $labelPadder), $textWidth + 1, $labelWidth, $labelPadder)
                else
                    $label"/>

        <!-- Output the padded text -->
        <xsl:value-of select="$paddedLabel"/>

    </xsl:function>


    <!-- ====================================================================
        Get the position of a node within a node set     
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getNodePosition">
        <xsl:param name="nodeSet"/>
        <xsl:param name="node"/>

        <xsl:variable name="nodeId" select="generate-id($node)"/>
        <xsl:value-of select="cityEHRFunction:getNodeIdPosition(1, $nodeId, $nodeSet)"/>

    </xsl:function>

    <xsl:function name="cityEHRFunction:getNodeIdPosition">
        <xsl:param name="position" as="xs:integer"/>
        <xsl:param name="nodeId"/>
        <xsl:param name="nodeSet"/>

        <xsl:value-of
            select="
                if (generate-id($nodeSet[$position]) = $nodeId) then
                    $position
                else
                    cityEHRFunction:getNodeIdPosition($position + 1, $nodeId, $nodeSet)"/>

    </xsl:function>

</xsl:stylesheet>
