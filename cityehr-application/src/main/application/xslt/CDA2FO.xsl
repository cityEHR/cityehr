<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    CDA2FO.xsl
    Input is a CDA document, or any other document (e.g. formDefinition) that contains a CDA Document
    Root of the CDA document is cda:ClinicalDocument
    Generates XSL-FO to be displayed in CityEHR as a PDF
      
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" xmlns:fo="http://www.w3.org/1999/XSL/Format">

    <!-- Set global variable to toggle display of the CDA Header -->
    <xsl:variable name="outputHeader" select="'yes'"/>

    <!-- Set global variable to differentiate output display of events and views 
         Views are either of type Folder or Composition. Otherwise outputType is Event -->
    <xsl:variable name="outputType" select="if (//cda:ClinicalDocument/cda:id/@extension='cityEHR:Folder') then 'Folder' else (if (//cda:ClinicalDocument/cda:id/@extension='cityEHR:Composition') then 'Composition' else'Event')"/>

    <!-- Set global variables for data extracted from the CDA Header -->
    <xsl:variable name="parameters" select="document('input:parameters')/parameters"/>

    <!-- If external demographics has been supplied then use those for the header,
    otherwise use the detail from the CDA header -->
    <xsl:variable name="patientId" select="$parameters/patientId"/>

    <xsl:variable name="patientFamily" select="$parameters/currentRecord/family"/>
    <xsl:variable name="patientGiven" select="$parameters/currentRecord/given"/>
    <xsl:variable name="patientPrefix" select="$parameters/currentRecord/prefix"/>
    <xsl:variable name="patientAdministrativeGenderCode" select="$parameters/currentRecord/administrativeGenderCode"/>
    <xsl:variable name="patientBirthTime" select="$parameters/currentRecord/birthTime"/>

    <!-- Match the root of the CDA document -->
    <xsl:template match="cda:ClinicalDocument">
        <fo:root>

            <fo:layout-master-set>
                <!-- fo:layout-master-set defines in its children the page layout:
                    the pagination and layout specifications
                    - page-masters: have the role of describing the intended subdivisions
                    of a page and the geometry of these subdivisions
                    In this case there is only a simple-page-master which defines the
                    layout for all pages of the text
                -->
                <!-- layout information -->
                <fo:simple-page-master master-name="simple" page-height="29.7cm" page-width="21cm" margin-top="1cm" margin-bottom="1cm" margin-left="2.5cm" margin-right="2.5cm">
                    <fo:region-body margin-top="1cm" margin-bottom="1cm"/>
                    <fo:region-before extent="1cm"/>
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

                <fo:static-content flow-name="xsl-region-before">
                    <fo:table>
                        <fo:table-body>
                            <fo:table-row>
                                <fo:table-cell>
                                    <fo:block text-align="left" font-size="10pt"> Patient Id:<xsl:text> </xsl:text>
                                        <xsl:value-of select="$patientId"/><xsl:text> </xsl:text>
                                    </fo:block>
                                </fo:table-cell>
                                <fo:table-cell>
                                    <fo:block text-align="right" font-size="10pt" white-space="normal">

                                        <xsl:value-of select="$patientFamily"/>
                                        <xsl:text>, </xsl:text>
                                        <xsl:value-of select="$patientGiven"/>

                                    </fo:block>
                                </fo:table-cell>
                            </fo:table-row>
                        </fo:table-body>
                    </fo:table> --> </fo:static-content>

                <fo:static-content flow-name="xsl-region-after">
                    <fo:table>
                        <fo:table-body>
                            <fo:table-row>
                                <fo:table-cell>
                                    <fo:block text-align="left" font-size="10pt">
                                        <xsl:value-of select="/*/cda:ClinicalDocument/cda:code[@codeSystem='cityEHR']/@displayName"/>
                                    </fo:block>
                                </fo:table-cell>
                                <fo:table-cell>
                                    <fo:block text-align="right" font-size="10pt"> Page [<fo:page-number/>] of [<fo:page-number-citation ref-id="last-page"/>] </fo:block>
                                </fo:table-cell>
                            </fo:table-row>
                        </fo:table-body>
                    </fo:table>
                </fo:static-content>

                <fo:flow flow-name="xsl-region-body">

                    <!-- this defines a title -->
                    

                    <xsl:for-each select="./cda:component/cda:structuredBody/cda:component/cda:section[not(@cityEHR:visibility='alwaysHidden')]">
                        <xsl:variable name="section" select="."/>
                        <xsl:variable name="sectionLayout" select="if ($section/@cityEHR:Sequence='Unranked') then 'Unranked' else 'Ranked'"/>

                        <!-- Only process sections that have some content -->
                        <xsl:if test="cityEHRFunction:entryRecorded($section)='true'">
                            <xsl:call-template name="renderCDASection">
                                <xsl:with-param name="section" select="$section"/>
                                <xsl:with-param name="sectionLayout" select="$sectionLayout"/>
                            </xsl:call-template>
                        </xsl:if>

                        <!-- For sections that have no content, but do have a title -->
                        <xsl:if test="cityEHRFunction:entryRecorded($section)='false'">
                            <xsl:variable name="sectionTitle" select="$section/cda:title"/>
                            <!-- Only output the section header if it has a display name -->
                            <xsl:if test="$sectionTitle[data(.)!='']">
                                <fo:block font-size="14pt" font-family="sans-serif" line-height="16pt" space-after.optimum="15pt" background-color="white" color="black" text-align="left" padding-top="3pt">
                                    <xsl:value-of select="$sectionTitle"/>
                                </fo:block>
                                
                                <fo:block>
                                    <xsl:value-of select="$parameters/staticParameters/cityEHRFolder-Views/emptySection"/>
                                </fo:block>
                            </xsl:if>
                        </xsl:if>
                    </xsl:for-each>



                    <fo:block id="last-page"> </fo:block>

                </fo:flow>
                <!-- closes the flow element-->


            </fo:page-sequence>
            <!-- closes the page-sequence -->

        </fo:root>
    </xsl:template>



    <!-- Mop up any other nodes -->
    <xsl:template match="*">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="text()"/>



    <!-- === Render section of a CDA Document ===============================================================
        Iterates through the section contents and calls templates to render sections (recursive) or entries.
        ===================================================================================================== -->

    <xsl:template name="renderCDASection">
        <xsl:param name="section"/>
        <xsl:param name="sectionLayout"/>

        <xsl:variable name="sectionLabelWidth" select="$section/@cityEHR:labelWidth"/>
        <xsl:variable name="sectionTitle" select="$section/cda:title"/>
        <xsl:variable name="sectionId" select="$section/cda:id/@extension"/>

      
        <fo:block>
            <!-- Only output the section header if it has a display name -->
            <xsl:if test="$sectionTitle[data(.)!='']">
                <fo:block font-size="14pt" font-family="sans-serif" line-height="16pt" space-after.optimum="15pt" background-color="white" color="black" text-align="left" padding-top="3pt">
                    <xsl:value-of select="$sectionTitle"/>
                </fo:block>
            </xsl:if>

            <!-- Iterate through each entry and sub-section in the section -->
            <xsl:for-each select="$section/*">
                <xsl:variable name="component" select="."/>

                <!-- Entry - call template to render the entry but only if it has some content -->
                <xsl:if test="$component/name()='entry' and cityEHRFunction:entryRecorded($component)='true'">
                    <fo:block>
                        <xsl:call-template name="renderCDAEntry">
                            <xsl:with-param name="entry" select="$component"/>
                            <xsl:with-param name="sectionLayout" select="$sectionLayout"/>
                            <xsl:with-param name="labelWidth" select="$sectionLabelWidth"/>
                        </xsl:call-template>
                    </fo:block>
                </xsl:if>

                <!-- Section - recursively call template to render sub-section 
                    Really want to do xsl-if and set the context to the cda:section -->
                <xsl:for-each select="$component[name()='component']/cda:section">
                    <xsl:variable name="subSection" select="$component/cda:section"/>
                    <xsl:variable name="subSectionLayout" select="if ($subSection/@cityEHR:Sequence='Unranked') then 'Unranked' else 'Ranked'"/>
                    <!-- Only process sections that have some content -->
                    <xsl:if test="cityEHRFunction:entryRecorded($subSection)='true'">
                        <fo:block>
                            <xsl:call-template name="renderCDASection">
                                <xsl:with-param name="section" select="$subSection"/>
                                <xsl:with-param name="sectionLayout" select="$subSectionLayout"/>
                            </xsl:call-template>
                        </fo:block>
                    </xsl:if>

                    <!-- For sections that have no content, but do have a title -->
                    <xsl:if test="cityEHRFunction:entryRecorded($subSection)='false'">
                        <xsl:variable name="sectionTitle" select="$subSection/cda:title"/>
                        <!-- Only output the section header if it has a display name -->
                        <xsl:if test="$sectionTitle[data(.)!='']">
                            <fo:block>
                                <fo:block>
                                    <xsl:value-of select="$sectionTitle"/>
                                </fo:block>
                                <fo:block>
                                    <xsl:value-of select="$parameters/staticParameters/cityEHRFolder-Views/emptySection"/>
                                </fo:block>
                            </fo:block>
                        </xsl:if>
                    </xsl:if>

                </xsl:for-each>

            </xsl:for-each>

        </fo:block>

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

        <xsl:variable name="entryLayout" select="$entry/@cityEHR:Sequence"/>
        <xsl:variable name="entryLabelWidth" select="$entry/@cityEHR:labelWidth"/>

        <!-- Since we are setting width in em, use half the character length of the width - this usually works fine.
            Only set the width in Ranked sections -->
        <xsl:variable name="width" select="round($labelWidth div 2)"/>
        <xsl:variable name="widthStyle" select="if ($sectionLayout='Ranked') then concat('width:',$width,'em;') else ''"/>


        <fo:block>
            <fo:block>
                <!-- Just display first label - caters for Composition views with more than one instance os the entry.
                    and also cases for multipleEntry and entries with enumeratedClass elements.
                    Only one of these options in the select will match. -->
                <xsl:value-of select="$entry/*[name()='observation' or name()='encounter'][1]/cda:code[@codeSystem='cityEHR']/@displayName"/>
            </fo:block>
            <xsl:call-template name="renderCDAEntryContent">
                <xsl:with-param name="entry" select="$entry"/>
                <xsl:with-param name="entryLayout" select="$entryLayout"/>
                <xsl:with-param name="labelLength" select="$entryLabelWidth"/>
            </xsl:call-template>
        </fo:block>

    </xsl:template>



    <!-- === Render entry content ==========================================================================
        There are eight types of entry to consider:
        (1) simple entry, form rendition uses cda:observation or cda:encounter (may handle other type of CDA events in the future)
        (2) simple entry, image map rendition displays the image map
        (3) simple entry with supplementary data use cda:organiser with classCode attribute of EnumeratedClassEntry
        (4) simple entry, image map rendition and supplementary data
        
        (5) multiple occurrences of the same entry use cda:organizer with classCode attribute of MultipleEntry
        (6) multiple occurrences of the same entry, image map rendition
        (7) multiple occurrences of the same entry, with supplementary data
        (8) multiple occurrences of the same entry, image map rendition and supplementary data
        ===================================================================================================== -->

    <xsl:template name="renderCDAEntryContent">
        <xsl:param name="entry"/>
        <xsl:param name="entryLayout"/>
        <xsl:param name="labelLength"/>

        <!-- === (1) Simple entry ======
            Form rendition just outputs the elements; ImageMap rendition shows the map as well
            Iterate through the elements for the entry -->

        <xsl:if test="$entry[not(cda:organizer)][@cityEHR:rendition='#CityEHR:EntryProperty:Form']">
            <!-- Simple observation or encounter. The selected nodeset is the union of the two matches,
                although only one will contribute results in any one instance -->

            <xsl:for-each select="$entry/cda:observation/cda:value | $entry/cda:encounter/cda:participant/cda:participantRole/cda:playingEntity">
                <fo:block>
                    <xsl:variable name="element" select="."/>
                    <xsl:call-template name="renderCDAElement">
                        <xsl:with-param name="element" select="$element"/>
                    </xsl:call-template>
                </fo:block>
            </xsl:for-each>

        </xsl:if>
        <!-- End of Simple entry - form rendition  -->


    </xsl:template>
    
    
    
    <!-- === Render element (i.e. cda:value, cda:playingEntity, etc) ============================
        The element is rendered based on its attributes, not the name of the cda element.
        Which means this works for CDA's representation of elements in any type of entry.
        
        Can be called without the supplementary-entry-organizer if necessary.
        ======================================================================================= -->
    
    <xsl:template name="renderCDAElement">
        <xsl:param name="element"/>
        <!--
            <xsl:param name="supplementary-entry-organizer"/>
        -->
        
        <xsl:variable name="extension" select="$element/@extension"/>
        <xsl:variable name="fieldLength" select="if (exists($element/@cityEHR:fieldLength)) then $element/@cityEHR:fieldLength else $parameters/staticParameters/cityEHRFolder/fieldLength"/>
        
        <fo:block>
            <fo:block>
                <xsl:value-of select="$element/@cityEHR:elementDisplayName"/>
            </fo:block>
            <fo:block>
                <xsl:variable name="value" select="if ($element/@displayName != '') then $element/@displayName else $element/@value"/>
                <xsl:variable name="type" select="if ($element/@xsi:type != '') then $element/@xsi:type else 'xs:string'"/>
                
                <xsl:value-of select="cityEHRFunction:outputValue($value,$type)"/>
                
                <!-- Display supplementary data (SDS) if available -->
                <!--
                    <xsl:variable name="hasSupplementaryEntry" select="if (exists($supplementary-entry-organizer)) then $supplementary-entry-organizer/cda:component/cda:observation/cda:id/@cityEHR:origin=$extension else false()"/>               
                    <xsl:if test="$hasSupplementaryEntry">
                    <xsl:variable name="supplementaryEntry" select="$supplementary-entry-organizer/cda:component[cda:observation/cda:id/@cityEHR:origin=$extension]"/>
                    <xsl:call-template name="renderSupplementaryEntry">
                    <xsl:with-param name="supplementaryEntry" select="$supplementaryEntry"/>
                    </xsl:call-template>
                    </xsl:if>               
                -->
                
            </fo:block>
            <!-- Display units for element, if they exist -->
            <xsl:if test="$element/@units!=''">
                <fo:block>
                    <xsl:value-of select="$element/@units"/>
                </fo:block>
            </xsl:if>
            
        </fo:block>
        
    </xsl:template>




    <!-- ====================================================================
        Check whether a section or entry (as observation, encounter, etc) has any values recorded
        Returns true when a value is detected, otherwise false    
        
        Finds:
        
        <value xsi:type="xs:date" value="" units="" code="" codeSystem="" displayName=""
        cityEHR:elementDisplayName="Sample Date"
        extension="#ISO-13606:Element:SampleDate"
        root="cityEHR"
        cityEHR:elementType="#CityEHR:ElementProperty:simpleType"
        cityEHR:valueRequired="#CityEHR:ElementProperty:Optional"/>
        
        
        <playingEntity xsi:type="xs:string" value="" units="" code="" codeSystem="" displayName=""
        cityEHR:elementDisplayName="Clinic Id"
        cityEHR:elementType="#CityEHR:ElementProperty:simpleType"
        cityEHR:valueRequired="#CityEHR:ElementProperty:Optional"/>
        
        etc.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:entryRecorded">
        <xsl:param name="parent"/>

        <xsl:value-of select="if (exists($parent/descendant::*[@xsi:type!='xs:boolean'][@value!=''])) then 'true' else if (exists($parent/descendant::*[@xsi:type='xs:boolean'][@value=$parameters/displayBoolean/value/@value])) then 'true' else 'false'"/>

    </xsl:function>


    <!-- ====================================================================
        Check whether an entry (as encounter) has any participants recorded
        Returns true when a value is detected, otherwise false       
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:encounterEntryRecorded">
        <xsl:param name="entry"/>

        <xsl:value-of select="if (exists($entry/descendant::playingEntity[@xsi:type!='xs:boolean']/@value!='')) then 'true' else if (exists($entry/descendant::value[@xsi:type='xs:boolean'][@value=$parameters/displayBoolean/value/@value])) then 'true' else 'false'"/>

    </xsl:function>


    <!-- ====================================================================
        Output a value, based on its type       
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:outputValue">
        <xsl:param name="value"/>
        <xsl:param name="type"/>
        
        <fo:block>
             <xsl:value-of select="concat($parameters/staticFileRoot,'/media/letterhead.png')"/>
            <fo:external-graphic src="url('{$parameters/staticFileRoot}/media/letterhead.png')"/></fo:block>

        <xsl:value-of select="if ($type='xs:dateTime' and $value castable as xs:dateTime) then format-dateTime(xs:dateTime($value),$parameters/dateTimeDisplayFormat, $parameters/languageCode,(),()) else 
            if ($type='xs:date' and $value castable as xs:date) then format-date(xs:date($value),$parameters/dateDisplayFormat, $parameters/languageCode,(),()) else 
            if ($type='xs:time' and $value castable as xs:time) then format-time(xs:time($value),$parameters/timeDisplayFormat, $parameters/languageCode,(),()) else 
            if ($type='xs:boolean' and exists($parameters/displayBoolean/value[@value=$value])) then $parameters/displayBoolean/value[@value=$value] else
            $value"/>

    </xsl:function>


</xsl:stylesheet>
