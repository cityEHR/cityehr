<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    Results2SVGDashboard.xsl
    Input is the aggregatedResults document, formed by running all queries specified in the dashboardQuerySet in the application-parameters
    PLUS the combined view-parameters, system-parameters and application=parameters passed in as the parameters input, of the form:
    
    <allParameters>
        <parameters type="system">
            ...system parameters are here...
        </parameters>
        <parameters type="view">
            ...view parameters are here...
        </parameters>
        <parameters type="application">
            ...application configuration parameters are here
        </parameters>    
    </allParameters>
    
    Generates the dashboard panes as xhtml with SVG charts, where configured for a query.
    
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
    version="2.0" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:svg="http://www.w3.org/2000/svg" xmlns:math="http://exslt.org/math">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Inputs 
         Main (data) input is the aggregatedResults document.
         Plus the combined parameters, which are separated out here -->
    <xsl:variable name="view-parameters" select="document('input:parameters')//parameters[@type='view']"/>
    <xsl:variable name="session-parameters" select="document('input:parameters')//parameters[@type='session']"/>
    <xsl:variable name="application-parameters" select="document('input:parameters')//parameters[@type='application']"/>


    <!-- Match the aggregatedResults -->
    <xsl:template match="aggregatedResults">
        <xhtml:div class="dashboard">
            <xsl:apply-templates/>
        </xhtml:div>
    </xsl:template>

    <!-- One pane for each result returned.
         If the query is properly formed then it should return:
         
         <queryResults>
            <total value="0"/>
            <category displayName="" value="0"/>
            ...
         </queryResults>
         
         But don't assume this (so match *)
         Depending on how the query was called, this may be wrapped in an exist:result element, so look for queryResults in the return from the service (serviceReturn)
         
         The results match with the dashboardQuery elements in dashboardQuerySet in the application-parameters -->
    <xsl:template match="aggregatedResults/*">
        <xsl:variable name="serviceReturn" select="."/>
        <xsl:variable name="queryResults" select="if ($serviceReturn/name() = 'queryResults') then $serviceReturn else $serviceReturn/queryResults"/>

        <!-- Get the corresponding dashboardQuery -->
        <xsl:variable name="dashboardQueryCount" select="position()"/>
        <xsl:variable name="dashboardQuery"
            select="$application-parameters/dashboardQuerySet/dashboardQuery[position() = $dashboardQueryCount]"/>

        <!-- Set some properties of the pane -->
        <xsl:variable name="displayName" select="$dashboardQuery/@displayName"/>
        <xsl:variable name="chart" select="$dashboardQuery/@chart"/>
        <xsl:variable name="dashBlockClass" select="if ($chart!='') then 'dash-block wide' else 'dash-block'"/>

        <!-- Get colours for the pane display -->
        <xsl:variable name="paneColourCount" select="max((1,count($view-parameters/staticParameters/cityEHRDashboard/paneColours/colour)))"/>
        <xsl:variable name="paneColourSelector"
            select="$dashboardQueryCount - ($paneColourCount * floor(($dashboardQueryCount - 1) div $paneColourCount))"/>

        <xsl:variable name="paneColour" select="$view-parameters/staticParameters/cityEHRDashboard/paneColours/colour[position()=$paneColourSelector]"/>
        <xsl:variable name="titleColourStyle" select="concat('background: ',$paneColour/@title,'!important;')"/>
        <xsl:variable name="contentColourStyle" select="concat('background: ',$paneColour/@content,'!important;')"/>
        <xsl:variable name="footerColourStyle" select="concat('background: ',$paneColour/@footer,'!important;')"/>

        <xhtml:div class="{$dashBlockClass}" style="{$contentColourStyle}">
            <!-- Header -->
            <xhtml:div class="searchTitle" style="{$titleColourStyle}">
                <xsl:value-of select="$displayName"/>
            </xhtml:div>
            <!-- Body - main query result and chart display-->
            <xhtml:div class="dashboardContent">
                <xsl:if test="exists($queryResults)">
                    <xhtml:ul>
                        <xsl:variable name="baseColour" select="$paneColour/@content"/>
                        <xsl:variable name="categorySet" select="$queryResults/category"/>
                        <xsl:variable name="categoryCount" select="count($categorySet)"/>
                        <xsl:variable name="chartColourKeys"
                            select="if ($chart!='') then cityEHRFunction:getChartColourKeys($baseColour,$categoryCount) else ()"/>

                        <xhtml:li class="fig  Unranked">
                            <xsl:value-of select="$queryResults/total/@value"/>
                        </xhtml:li>
                        <!-- The query breakdown.
                             This is displayed as a set of labelled numbers and (optionally) as a chart -->
                        <!-- Labelled numbers -->
                        <xhtml:li class="categories Unranked">
                            <xhtml:table>
                                <xhtml:tbody>
                                    <!-- Iterate through the categories in the queryResults -->
                                    <xsl:for-each select="$categorySet">
                                        <xsl:variable name="categoryNumber" select="position()"/>
                                        <xhtml:tr>
                                            <!-- Colour key (only if chart is configured).-->
                                            <xsl:if test="$chart!=''">
                                                <xsl:variable name="chartKeyStyle"
                                                    select="concat('background: ',$chartColourKeys[position()=$categoryNumber],'!important;')"/>
                                                <xhtml:td style="{$chartKeyStyle} width:20px;"/>
                                            </xsl:if>
                                            <!-- displayname -->
                                            <xhtml:td>
                                                <xsl:value-of select="@displayName"/>
                                            </xhtml:td>
                                            <!-- value -->
                                            <xhtml:td>
                                                <xsl:value-of select="@value"/>
                                            </xhtml:td>
                                        </xhtml:tr>
                                    </xsl:for-each>
                                </xhtml:tbody>
                            </xhtml:table>
                        </xhtml:li>
                        
                        <!-- Chart (SVG) -->
                        <xsl:if test="($chart!='')">
                            <xhtml:li class="chart Unranked">
                                <xsl:call-template name="generateChart">
                                    <xsl:with-param name="chartType" select="$chart"/>
                                    <xsl:with-param name="categorySet" select="$categorySet"/>
                                    <xsl:with-param name="chartColourKeys" select="$chartColourKeys"/>
                                </xsl:call-template>
                            </xhtml:li>
                        </xsl:if>
                        <xhtml:li class="LayoutFooter">&#160;</xhtml:li>
                    </xhtml:ul>
                </xsl:if>

                <!-- No results returned by service - show the static queryResults configured in the view-parameters -->
                <xsl:if test="not(exists($queryResults))">
                    <!-- Debugging - show the exception (messy) -->
                    <!--
                    <xhtml:p>
                        <xsl:value-of select="$serviceReturn"/>
                    </xhtml:p>
                    -->
                    <xhtml:ul>
                        <xhtml:li class="fig  Unranked">
                            <xsl:value-of select="$view-parameters/staticParameters/cityEHRDashboard/queryResults/total/@value"/>
                        </xhtml:li>
                        <xhtml:li class="categories Unranked">
                            <xsl:for-each select="$view-parameters/staticParameters/cityEHRDashboard/queryResults/category">
                                <xsl:variable name="category" select="."/>
                                <xsl:value-of select="$category/@displayName"/>
                                <xsl:value-of select="$category/@value"/>
                                <xhtml:br/>
                            </xsl:for-each>
                        </xhtml:li>
                        <xhtml:li class="LayoutFooter">&#160;</xhtml:li>
                    </xhtml:ul>

                </xsl:if>
            </xhtml:div>
            <!-- Footer -->
            <xhtml:div class="searchFooter" style="{$footerColourStyle}">
                <xsl:value-of select="$view-parameters/staticParameters/cityEHRDashboard/queryTimeLabel"/>

                <xsl:variable name="queryTime" select="if (exists($queryResults/queryTime)) then $queryResults/queryTime else current-dateTime()"/>
                <xsl:value-of
                    select="if ($queryTime castable as xs:dateTime) then format-dateTime(xs:dateTime($queryTime),$session-parameters/dateTimeDisplayFormat, $session-parameters/languageCode, (), ()) else 
                    if ($queryTime castable as xs:date) then format-date(xs:date($queryTime),$session-parameters/dateDisplayFormat, $session-parameters/languageCode, (), ()) else 
                    if ($queryTime castable as xs:time) then format-time(xs:time($queryTime),$session-parameters/timeDisplayFormat, $session-parameters/languageCode, (), ()) else 
                    $queryTime"/>

            </xhtml:div>
        </xhtml:div>
    </xsl:template>


    <!-- === 
        cityEHRFunction:getChartColourKeys
        Generate a sequence of RGB colours for a chart
            baseColour is of the form rgb(x,y,z)
            categoryCount is an integer number of categories
        === -->
    <xsl:function name="cityEHRFunction:getChartColourKeys">
        <xsl:param name="baseColour"/>
        <xsl:param name="categoryCount"/>

        <!-- Get separate RGB values -->
        <xsl:variable name="baseColourRGB"
            select="for $i in tokenize(substring-before(substring-after($baseColour,'rgb('),')'),',') return xs:integer($i)"/>
        <xsl:variable name="red" select="$baseColourRGB[1]"/>
        <xsl:variable name="green" select="$baseColourRGB[2]"/>
        <xsl:variable name="blue" select="$baseColourRGB[3]"/>

        <!-- Check that baseColourRGB is correctly formed
             Then iterate $categoryCount times -->
        <xsl:if test="count($baseColourRGB) eq 3">
            <xsl:for-each select="1 to $categoryCount">
                <xsl:variable name="categoryNumber" select="."/>

                <!-- Set the incremental RGB values -->
                <xsl:variable name="incrementalRed" select="xs:string($categoryNumber * floor($red div ($categoryCount + 1)))"/>
                <xsl:variable name="incrementalGreen" select="xs:string($categoryNumber * floor($green div ($categoryCount + 1)))"/>
                <xsl:variable name="incrementalBlue" select="xs:string($categoryNumber * floor($blue div ($categoryCount + 1)))"/>

                <!-- Return the rgb string of the form (rgb(x,y,z) -->
                <xsl:value-of select="concat('rgb(',$incrementalRed,',',$incrementalGreen,',',$incrementalBlue,')')"/>

            </xsl:for-each>
        </xsl:if>

    </xsl:function>


    <!-- ===
         Generate SVG chart from query results 
         === -->
    <xsl:template name="generateChart">
        <xsl:param name="chartType"/>
        <xsl:param name="categorySet"/>
        <xsl:param name="chartColourKeys"/>

        <xsl:variable name="chartProperties" select="$view-parameters/staticParameters/cityEHRDashboard/chartProperties"/>
        <xsl:variable name="chartWidth" as="xs:integer"
            select="if ($chartProperties/@width castable as xs:integer) then xs:integer($chartProperties/@width) else 200"/>
        <xsl:variable name="chartHeight" as="xs:integer"
            select="if ($chartProperties/@height castable as xs:integer) then xs:integer($chartProperties/@height) else 120"/>
        <xsl:variable name="chartPadding" as="xs:integer"
            select="if ($chartProperties/@padding castable as xs:integer) then xs:integer($chartProperties/@padding) else 10"/>
        <xsl:variable name="chartBarToSpaceRatio" as="xs:integer"
            select="if ($chartProperties/@barToSpaceRatio castable as xs:integer) then xs:integer($chartProperties/@barToSpaceRatio) else 2"/>
        <xsl:variable name="baselineWidth" as="xs:integer"
            select="if ($chartProperties/@baselineWidth castable as xs:integer) then xs:integer($chartProperties/@baselineWidth) else 1"/>
        <xsl:variable name="baselineColour" select="$chartProperties/@baselineColour"/>

        <!-- Every chart has a display for each category.
             Category values must be numbers -->
        <xsl:variable name="categoryCount" select="count($categorySet)"/>
        
        <xhtml:svg width="{$chartWidth}px" height="{$chartHeight}px">

            <!-- Draw different type of chart, depending on $chartType -->
            <xsl:choose>
                <!-- Pie chart -->
                <xsl:when test="$chartType='pie'">
                    <xsl:variable name="totalValue" select="sum($categorySet/@value[. castable as xs:double])"/>
                    
                    <!-- Using exslt math functions, which don't include pi, so need to use asin(1) = pi/2
                         Total 360 degree angle in radians is 2*pi -->
                    <xsl:variable name="pi" select="math:asin(1) * 2"/>
                    <xsl:variable name="arcIncrement" select="if ($totalValue gt 0) then $pi * 2 div $totalValue else $pi * 2"/>

                    <xsl:variable name="radius" select="floor(($chartHeight - $chartPadding) div 2)"/>
                    <xsl:variable name="centreX" select="$radius + $chartPadding"/>
                    <xsl:variable name="centreY" select="$radius + $chartPadding"/>

                    <!-- Draw pie segment for each category usning SVG path -->
                    <xsl:for-each select="$categorySet">
                        <xsl:variable name="categoryValue" select="@value"/>
                        <xsl:variable name="categoryNumber" select="position()"/>

                        <!-- Only draw a sgement if the value is greater than zero -->
                        <xsl:if test="$categoryValue castable as xs:double and xs:double($categoryValue) gt 0">
                            <xsl:variable name="priorValues" select="$categorySet[position() lt $categoryNumber]/@value[. castable as xs:double]"/>
                            <xsl:variable name="segmentStartAngle" select="if (empty($priorValues)) then 0 else sum($priorValues) * $arcIncrement"/>
                            <xsl:variable name="segmentEndAngle" select="$segmentStartAngle + ($categoryValue * $arcIncrement)"/>

                            <!-- startPos and endPos on the circumference are worked out using trig functions -->
                            <xsl:variable name="startPosX" select="$centreX + ($radius * math:cos($segmentStartAngle))"/>
                            <xsl:variable name="startPosY" select="$centreY + ($radius * math:sin($segmentStartAngle))"/>
                            <xsl:variable name="endPosX" select="$centreX + ($radius * math:cos($segmentEndAngle))"/>
                            <xsl:variable name="endPosY" select="$centreY + ($radius * math:sin($segmentEndAngle))"/>
                            
                            <!-- large-arc-flag determinrs whether the long or short arc path is followed.
                                 If the angle to be drawn is less than pi (180 degrees) then draw the short arc (1), otherwise the long arc (0)-->
                            <xsl:variable name="large-arc-flag" select="if ($segmentEndAngle - $segmentStartAngle le $pi) then 0 else 1"/>
                            
                            <!-- The pie chart segment for the category is defined by a path
                                Start at the centre of the pie (M)
                                Line to the startPos on the circumference (L)
                                Arc from the startPos to the endPos at specified radius (A) 
                                Then close the arc (z)
                            -->
                            <xsl:variable name="d"
                                select="concat('M ',$centreX,',',$centreY,' L ',$startPosX,',',$startPosY,' A ',$radius,',',$radius,' 0 ',$large-arc-flag,', 1 ',$endPosX,',',$endPosY,' z')"/>
                            <xhtml:path d="{$d}" fill="{$chartColourKeys[position() =$categoryNumber]}"/>

                        </xsl:if>
                    </xsl:for-each>

                </xsl:when>

                <!-- Horizontal Bar Chart 
                    Has $categoryNumber horizontal bars, separated by $categoryNumber -1 spaces
                    The ratio of bar width to space is configured as barToSpaceRatio
                    Bars are drawn for each category using
                    <rect x="50" y="20" width="150" height="150"/>                       
                    where
                    x is distance from left margin
                    y is distance from top margin
                    width is the length of the bar (proportional to the category value)
                    height is the width of the bar, fixed by the chart height, number of categories and spacing (barToSpaceRatio)
                -->
                <xsl:when test="$chartType='horizontal-bar'">
                    <xsl:variable name="maxValue" select="max($categorySet/@value)"/>
                    <xsl:variable name="barLengthIncrement" select="($chartWidth - (2 * $chartPadding)) div $maxValue"/>

                    <xsl:variable name="widthUnit"
                        select="($chartHeight - (2 * $chartPadding)) div (($categoryCount - 1) + ($categoryCount * $chartBarToSpaceRatio))"/>
                    <xsl:variable name="barWidth" select="$widthUnit * $chartBarToSpaceRatio"/>

                    <!-- Draw the baseline
                         This is a vertical line, $chartPadding from the left of the chart -->
                    <xhtml:line x1="{$chartPadding}" y1="{$chartPadding}" x2="{$chartPadding}" y2="{$chartHeight - $chartPadding}"
                        stroke="{$baselineColour}" stroke-width="{$baselineWidth}"/>

                    <!-- Draw bar for each category -->
                    <xsl:for-each select="$categorySet">
                        <xsl:variable name="categoryValue" select="@value"/>
                        <xsl:variable name="categoryNumber" select="position()"/>

                        <xsl:variable name="barLength" select="$barLengthIncrement * $categoryNumber"/>
                        <xsl:variable name="x" select="$chartPadding"/>
                        <xsl:variable name="y" select="$chartPadding + $widthUnit * (1 + $chartBarToSpaceRatio) * ($categoryNumber - 1)"/>

                        <xhtml:rect x="{$x}" y="{$y}" width="{$barLength}" height="{$barWidth}"
                            fill="{$chartColourKeys[position() = $categoryNumber]}"/>
                    </xsl:for-each>
                </xsl:when>


                <!-- Default is Vertical Bar Chart
                     Has $categoryNumber vertical bars, separated by $categoryNumber -1 spaces
                     The ratio of bar width to space is configured as barToSpaceRatio
                     Bars are drawn for each category using
                        <rect x="50" y="20" width="150" height="150"/>                       
                        where
                            x is distance from left margin
                            y is distance from top margin
                            width is the width of the bar, fixed by the chart width, number of categories and spacing (barToSpaceRatio)                           
                            height is the length of the bar (proportional to the category value)
                     -->
                <xsl:otherwise>
                    <xsl:variable name="maxValue" select="max($categorySet/@value)"/>
                    <xsl:variable name="barLengthIncrement" select="($chartHeight - (2 * $chartPadding)) div $maxValue"/>

                    <xsl:variable name="widthUnit"
                        select="($chartWidth - (2 * $chartPadding)) div (($categoryCount - 1) + ($categoryCount * $chartBarToSpaceRatio))"/>
                    <xsl:variable name="barWidth" select="$widthUnit * $chartBarToSpaceRatio"/>

                    <!-- Draw the baseline.
                         This is a horizontal line, $chartPadding from the bottom of the chart -->
                    <xhtml:line x1="{$chartPadding}" y1="{$chartHeight - $chartPadding}" x2="{$chartWidth - $chartPadding}"
                        y2="{$chartHeight - $chartPadding}" stroke="{$baselineColour}" stroke-width="{$baselineWidth}"/>

                    <!-- Draw bar for each category -->
                    <xsl:for-each select="$categorySet">
                        <xsl:variable name="categoryValue" select="@value"/>
                        <xsl:variable name="categoryNumber" select="position()"/>

                        <xsl:variable name="barLength" select="$barLengthIncrement * $categoryValue"/>
                        <xsl:variable name="x" select="$chartPadding + $widthUnit * (1 + $chartBarToSpaceRatio) * ($categoryNumber - 1)"/>
                        <xsl:variable name="y" select="$chartHeight - $chartPadding - $barLength"/>

                        <xhtml:rect x="{$x}" y="{$y}" width="{$barWidth}" height="{$barLength}"
                            fill="{$chartColourKeys[position() = $categoryNumber]}"/>
                    </xsl:for-each>
                </xsl:otherwise>

            </xsl:choose>

        </xhtml:svg>


    </xsl:template>




    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>
</xsl:stylesheet>
