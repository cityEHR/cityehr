<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    CDA2SVGChart.xsl
    Input is a CDA document representing a generated view
    PLUS a control file which contains the variables that are to be charted
    
    Generates an SVG file that can be consumed by the SVG 2 PNG converter or rendered directly by modern browsers.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs" version="2.0" xmlns:cda="urn:hl7-org:v3"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions"
    xmlns:exist="http://exist.sourceforge.net/NS/exist">


    <xsl:output method="xml" indent="no" name="xml"/>

    <!-- Root document nodes -->
    <xsl:variable name="rootNode" select="/"/>
    <xsl:variable name="controlRootNode" select="document('input:control')/control"/>
    <xsl:variable name="validInputs"
        select="if (exists($rootNode) and exists($controlRootNode)) then true() else false()"/>

    <!-- Set the variables for the charts to be generated.
         The parameters have been set in control/current-chart as follows (not the complete set):
        <current-chart>
            <startTime/>
            <endTime/>
            <step/>
            <idRoot/>
            <plotGraphs/>
            <plotColours/>
            <variables>
                <variable action="false" checkboxStatus="" plotType="" plotColour="" minValue="" maxValue="" minTime="" maxTime="" scale="" entryId="#ISO-13606:Entry:OsteoporosisBoneChemistry" dateElementExtension="#ISO-13606:Element:SampleDate" variableElementExtension="#ISO-13606:Element:BoneChemistryTest" variableElementValue="#CityEHR:Class:Labs:P1NP" variableElementDisplayName="P1NP" valueElementExtension="#ISO-13606:Element:Double"/>
                <variable action="false" checkboxStatus="" plotType="" plotColour="" minValue="" maxValue="" minTime="" maxTime="" scale="" entryId="#ISO-13606:Entry:OsteoporosisBoneChemistry" dateElementExtension="#ISO-13606:Element:SampleDate" variableElementExtension="#ISO-13606:Element:BoneChemistryTest" variableElementValue="#CityEHR:Class:Labs:CTX" variableElementDisplayName="CTX" valueElementExtension="#ISO-13606:Element:Double"/>
            </variables>
            <plotConfiguration/>
        </current-chart>     
    -->

    <!-- Set the overall chart parameters  -->
    <xsl:variable name="timeExtension" select="'T00:00:00'"/>
    <xsl:variable name="startTime"
        select="xs:dateTime(concat(substring(document('input:control')/control/current-chart/startTime,1,10),$timeExtension))"/>
    <xsl:variable name="endTime"
        select="xs:dateTime(concat(substring(document('input:control')/control/current-chart/endTime,1,10),$timeExtension))"/>
    <xsl:variable name="intervalInDays"
        select="document('input:control')/control/current-chart/intervalInDays"/>
    <xsl:variable name="intervalInSeconds"
        select="cityEHRFunction:getDurationInSeconds($intervalInDays)"/>
    <xsl:variable name="step" select="document('input:control')/control/current-chart/step"/>
    <xsl:variable name="idRoot" select="document('input:control')/control/current-chart/idRoot"/>
    <xsl:variable name="plotGraphs"
        select="document('input:control')/control/current-chart/plotGraphs"/>
    <xsl:variable name="yAxisLegend"
        select="document('input:control')/control/current-chart/yAxisLegend"/>
    <xsl:variable name="plotLayout"
        select="document('input:control')/control/current-chart/plotLayout"/>

    <!-- Variables to be plotted -->
    <xsl:variable name="chartVariables"
        select="document('input:control')/control/current-chart/variables"/>
    <xsl:variable name="chartVariableCount" select="count($chartVariables/variable)"/>

    <!-- Timeseries and interval plot variables -->
    <xsl:variable name="timeseriesVariables"
        select="$chartVariables/variable[@plotType='timeseries']"/>
    <xsl:variable name="intervalVariables" select="$chartVariables/variable[@plotType='interval']"/>

    <!-- Get the number of timeseries and interval plots to be made -->
    <xsl:variable name="timeseriesPlotCount" select="count($timeseriesVariables)"/>
    <xsl:variable name="intervalPlotCount" select="count($intervalVariables)"/>

    <!-- Timeseries plot scales -->
    <xsl:variable name="timeseriesPlotScales" select="distinct-values($timeseriesVariables/@scale)"/>
    <xsl:variable name="timeseriesPlotScaleCount" select="count($timeseriesPlotScales)"/>

    <!-- Maximum timeseries per scale -->
    <xsl:variable name="timeseriesMaxScaleCount"
        select="max(cityEHRFunction:getScalePlotCounts($plotGraphs,$timeseriesVariables,$timeseriesPlotScales))"/>


    <!-- Configuration set from view-parameters -->
    <xsl:variable name="noDataMessage"
        select="document('input:control')/control/current-chart/plotConfiguration/noDataMessage"/>
    <xsl:variable name="plotSizeX"
        select="document('input:control')/control/current-chart/plotConfiguration/plotSizeX"/>
    <xsl:variable name="plotSizeY"
        select="document('input:control')/control/current-chart/plotConfiguration/plotSizeY"/>
    <xsl:variable name="legendOrientationX"
        select="document('input:control')/control/current-chart/plotConfiguration/legendOrientationX"/>
    <xsl:variable name="legendUnitSizeX"
        select="document('input:control')/control/current-chart/plotConfiguration/legendUnitSizeX"/>
    <xsl:variable name="legendUnitSizeY"
        select="document('input:control')/control/current-chart/plotConfiguration/legendUnitSizeY"/>
    <xsl:variable name="legendFontSize"
        select="document('input:control')/control/current-chart/plotConfiguration/legendFontSize"/>
    <xsl:variable name="plotSpacingX"
        select="document('input:control')/control/current-chart/plotConfiguration/plotSpacingX"/>
    <xsl:variable name="plotSpacingY"
        select="document('input:control')/control/current-chart/plotConfiguration/plotSpacingY"/>
    <xsl:variable name="plotDivisionsX"
        select="document('input:control')/control/current-chart/plotConfiguration/plotDivisionsX"/>
    <xsl:variable name="plotDivisionsYOffset"
        select="document('input:control')/control/current-chart/plotConfiguration/plotDivisionsYOffset"/>
    <xsl:variable name="divWidth"
        select="document('input:control')/control/current-chart/plotConfiguration/divWidth"/>
    <xsl:variable name="borderWidth"
        select="document('input:control')/control/current-chart/plotConfiguration/borderWidth"/>

    <xsl:variable name="intervalPlotSpacing"
        select="document('input:control')/control/current-chart/intervalPlotConfiguration/intervalPlotSpacing"/>

    <!-- Colours set from view-parameters -->
    <xsl:variable name="backgroundColour"
        select="document('input:control')/control/current-chart/plotColours/backgroundColour"/>
    <xsl:variable name="legendBackgroundColour"
        select="document('input:control')/control/current-chart/plotColours/legendBackgroundColour"/>
    <xsl:variable name="borderColour"
        select="document('input:control')/control/current-chart/plotColours/borderColour"/>
    <xsl:variable name="divColour"
        select="document('input:control')/control/current-chart/plotColours/divColour"/>


    <!-- === Keys to get values from the CDA.
             Note that these keys may include some combinations that are not in the variable list.
             But this is OK since they will include all the values we want to look up === -->

    <!-- The set of all variable values (these are cda:value elements) -->
    <!-- Can't use a variable in the xsl:key match attribute 
    <xsl:variable name="variableValueSet" select="$rootNode//cda:observation [cda:id/@extension=$chartVariables/variable/@entryId] [cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]] [cda:value[@extension=$chartVariables/variable/@dateElementExtension]] /cda:value[@extension=$chartVariables/variable/@valueElementExtension][@value castable as xs:double]"/>
    -->

    <!-- variableValues concatenates the entryId, variableElementExtension, variableElementValue and valueElementExtension -->
    <!--
    <xsl:key name="variableValues"
        match="//cda:observation [cda:id/@extension=$chartVariables/variable/@entryId] [cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]] [cda:value[@extension=$chartVariables/variable/@dateElementExtension]] /cda:value[@extension=$chartVariables/variable/@valueElementExtension][@value castable as xs:double]/@value"
        use="concat(../../cda:id/@extension,../../cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]/@extension,../../cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]/@value,../../cda:value[@extension=$chartVariables/variable/@valueElementExtension]/@extension)"/>
    -->

    <!-- variableValuesForDate concatenates the entryId, variableElementExtension, variableElementValue, dateElementExtension, dateElementValue and valueElementExtension -->
    <!--
    <xsl:key name="variableValuesForDate"
        match="//cda:observation [cda:id/@extension=$chartVariables/variable/@entryId] [cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]] [cda:value[@extension=$chartVariables/variable/@dateElementExtension]] /cda:value[@extension=$chartVariables/variable/@valueElementExtension][@value castable as xs:double]/@value"
        use="concat(../../cda:id/@extension,../../cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]/@extension,../../cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]/@value,../../cda:value[@extension=$chartVariables/variable/@dateElementExtension]/@extension,../../cda:value[@extension=$chartVariables/variable/@dateElementExtension]/@value,../../cda:value[@extension=$chartVariables/variable/@valueElementExtension]/@extension)"/>
    -->

    <!-- === Sets of dates for the x-axis === -->
    <!-- This is the full set of dates across the range selected -->
    <xsl:variable name="fullDateSetString">
        <xsl:call-template name="generateFullDateSet">
            <xsl:with-param name="startTime" select="$startTime"/>
            <xsl:with-param name="endTime" select="$endTime"/>
            <xsl:with-param name="step" select="$step"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="fullDateSet" select="tokenize($fullDateSetString,'@@@')"/>
    <xsl:variable name="divisionStep" select="ceiling(count($fullDateSet) div ($plotDivisionsX+1))"/>
    <xsl:variable name="divisionStepSize" select="$plotSizeX div ($plotDivisionsX+1)"/>
    <xsl:variable name="divisionLinePositions"
        select="if ($plotDivisionsX castable as xs:integer and xs:integer($plotDivisionsX) gt 0) then 1 to xs:integer($plotDivisionsX) else ()"/>

    <!-- Calculate sizes of the legends for x and y axes.
         These depend on the number of variables displayed in the legend.
         
         yAxisLegend is 0, 1 or 2 depending on whether the legend is shown on left, left and right or not at all.
         The legendUnitSizeY is the basic width unit for the legend - one unit is needed for the scale numbering plus one more unit for every variable shown on the chart.
         The legendSizeY is made to be the same size for all charts so that they stack up in line with each other.
         So the legendSizeY is made to accommodate the maximum number of vraiables on any of the charts.
    -->
    <xsl:variable name="legendSizeX"
        select="if ($legendOrientationX='vertical') then 3*$legendUnitSizeX else $legendUnitSizeX"/>
    <xsl:variable name="legendSizeY"
        select="if ($plotGraphs='individual') then 2*$legendUnitSizeY else $legendUnitSizeY*(1+$timeseriesMaxScaleCount)"/>

    <!-- Calculate sizes of the charts to be made.
         The size of the x-axis legend is its height, so contributes to the overall plotHeight.
         The size of the y-axis legend contributes to the width -->
    <xsl:variable name="intervalPlotHeight" select="$intervalPlotSpacing * $intervalPlotCount"/>
    <xsl:variable name="plotHeight" select="$plotSizeY + $legendSizeX + $intervalPlotHeight"/>


    <!-- Match the root.
         Draw set of charts for the cases of 'combined' plots and 'individual' plots
         Generate categories (x-axis)
         and datasets (y-axis) -->

    <xsl:template match="/">
        <!-- Error in input documents -->
        <xsl:if test="not($validInputs)">
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="300" version="1.1">
                <rect x="0" y="0" width="100" height="100" fill="#E8E8E8"/>
                <text x="50" y="50" font-size="12" text-anchor="middle">
                    <xsl:value-of select="'Error in chart pipeline inputs.'"/>
                </text>
            </svg>
        </xsl:if>


        <!-- If there is nothing to plot, then show that in the SVG -->
        <xsl:if test="$validInputs and $chartVariableCount = 0">
            <svg xmlns="http://www.w3.org/2000/svg" width="{$plotSizeX}" height="{$plotSizeY}"
                version="1.1">
                <rect x="0" y="0" width="{$plotSizeX}" height="{$plotSizeY}"
                    fill="{$backgroundColour}"/>
                <text x="{$plotSizeX div 2}" y="{$plotSizeY div 2}" font-size="12"
                    text-anchor="middle">
                    <xsl:value-of select="$noDataMessage"/>
                </text>
            </svg>
        </xsl:if>

        <!-- Group variables for combined plot.
             In combined plots, timeseries variables of the same scale are plotted on the same chart with the interval plots repeated below each one.
             If there are no timeseries variables then just the interval plots are output -->
        <xsl:if test="$validInputs and $timeseriesPlotCount gt 0 and $plotGraphs='combined'">

            <!-- Calculate the overall size of the svg image based on the number of charts to be made. 
                 The width is calculated based on the plotSize and the maximum number of legends to be drawn.
                 There can be 0, 1 or 2 instances of the y-axis legend (show none, left, or left and right) -->
            <xsl:variable name="svgHeight"
                select="$plotSpacingY + ($plotHeight + $plotSpacingY)*$timeseriesPlotScaleCount"/>
            <xsl:variable name="svgWidth"
                select="$plotSizeX + ($legendSizeY * $yAxisLegend) + 2*$plotSpacingX"/>

            <svg xmlns="http://www.w3.org/2000/svg" width="{$svgWidth}" height="{$svgHeight}"
                version="1.1">

                <!-- timeseries -->
                <!-- Combined plots means that the variables are grouped by scale - 1, 10, 100, 1000.
                     Scale 1 means y-axis values are 0 to 1; 10 means 0 to 10, etc -->
                <xsl:for-each select="$timeseriesPlotScales">
                    <xsl:variable name="plotCount" select="position()"/>
                    <xsl:variable name="scale" as="xs:integer" select="xs:integer(.)"/>

                    <xsl:variable name="plottedVariables"
                        select="$chartVariables/variable[@plotType='timeseries'][@scale=$scale]"/>

                    <!-- Get the origin of the Xaxis legend -->
                    <xsl:variable name="xOriginLegendX"
                        select="if ($yAxisLegend != 0) then $plotSpacingX + $legendSizeY else $plotSpacingX"/>
                    <xsl:variable name="yOriginLegendX"
                        select="($plotSpacingY + $plotHeight)*($plotCount -1) + $plotSpacingY + $plotSizeY"/>

                    <!-- Put x-axis legend in its own svg element so that all legends are drawn to the same co-ordinates -->
                    <svg x="{$xOriginLegendX}" y="{$yOriginLegendX}">
                        <!-- Create the x-axis legend background -->
                        <rect x="0" y="0" width="{$plotSizeX}" height="{$legendSizeX}"
                            fill="{$legendBackgroundColour}" stroke-width="{$borderWidth}"
                            stroke="{$borderColour}"/>

                        <!-- Output the X-Axis categories  -->
                        <xsl:call-template name="outputX-Axis">
                            <xsl:with-param name="fullDateSet" select="$fullDateSet"/>
                            <xsl:with-param name="legendSizeX" select="$legendSizeX"/>
                            <xsl:with-param name="divisionStep" select="$divisionStep"/>
                            <xsl:with-param name="divisionStepSize" select="$divisionStepSize"/>
                        </xsl:call-template>
                    </svg>

                    <!-- Variables to set the y-axis and horizontal division lines
                         Get the maximum value in the plotted variables.
                         Make sure the values are numbers before getting max/min.
                         The max value is across all variables to be plotted (on the same chart).
                         Scale 1 = 0-10, 10 = 10-100, 100 = 100-1000, etc
                         $maxValue div $scale returns a number between 1 and 10
                         yaxisDivisions is between 2 and 11 - its is the number of division lines to be shown, found by taking the ceiling() 
                         yaxisMax is the round up to the nearest y-axis division step plus a tenth (so that a division line and y-axis value can be drawn just below the top of the chart)
                         yaxisUnitSize is the number of pixels for each unit on the y-axis. -->
                    <xsl:variable name="maxValue"
                        select="max($chartVariables/variable[@scale=$scale]/@maxValue)"/>
                    <xsl:variable name="yaxisDivisions" select="ceiling($maxValue div $scale)"/>
                    <xsl:variable name="yaxisMax"
                        select="($yaxisDivisions + $plotDivisionsYOffset) * $scale"/>
                    <xsl:variable name="yaxisUnitSize" select="$plotSizeY div $yaxisMax"/>
                    <xsl:variable name="yaxisDivPositions"
                        select="if ($yaxisDivisions castable as xs:integer and xs:integer($yaxisDivisions) gt 0) then 1 to xs:integer($yaxisDivisions) else ()"/>

                    <!-- Get the origin of the Yaxis legend -->
                    <xsl:variable name="xOriginLeftLegendY" select="$plotSpacingX"/>
                    <xsl:variable name="xOriginRightLegendY"
                        select="$xOriginLeftLegendY + +$legendSizeY + $plotSizeX"/>
                    <xsl:variable name="yOriginLegendY"
                        select="$plotSpacingY + ($plotSpacingY + $plotHeight)*($plotCount - 1)"/>

                    <!-- Output y-axis legend to left and right, as determined by yAxisLegend -->
                    <xsl:if test="$yAxisLegend = (1,2)">
                        <xsl:call-template name="outputY-AxisLegend">
                            <xsl:with-param name="xOriginLegendY" select="$xOriginLeftLegendY"/>
                            <xsl:with-param name="yOriginLegendY" select="$yOriginLegendY"/>
                            <xsl:with-param name="position" select="'left'"/>
                            <xsl:with-param name="yaxisUnitSize" select="$yaxisUnitSize"/>
                            <xsl:with-param name="yaxisDivisions" select="$yaxisDivisions"/>
                            <xsl:with-param name="yaxisDivPositions" select="$yaxisDivPositions"/>
                            <xsl:with-param name="scale" select="$scale"/>
                            <xsl:with-param name="plottedVariables" select="$plottedVariables"/>
                        </xsl:call-template>
                    </xsl:if>
                    <xsl:if test="$yAxisLegend = 2">
                        <xsl:call-template name="outputY-AxisLegend">
                            <xsl:with-param name="xOriginLegendY" select="$xOriginRightLegendY"/>
                            <xsl:with-param name="yOriginLegendY" select="$yOriginLegendY"/>
                            <xsl:with-param name="position" select="'right'"/>
                            <xsl:with-param name="yaxisUnitSize" select="$yaxisUnitSize"/>
                            <xsl:with-param name="yaxisDivisions" select="$yaxisDivisions"/>
                            <xsl:with-param name="yaxisDivPositions" select="$yaxisDivPositions"/>
                            <xsl:with-param name="scale" select="$scale"/>
                            <xsl:with-param name="plottedVariables" select="$plottedVariables"/>
                        </xsl:call-template>
                    </xsl:if>

                    <!-- Get the origin of the plot -->
                    <xsl:variable name="xOriginPlot"
                        select="if ($yAxisLegend != 0) then $plotSpacingX + $legendSizeY else $plotSpacingX"/>
                    <xsl:variable name="yOriginPlot"
                        select="$plotSpacingY +($plotSpacingY + $plotHeight)*($plotCount - 1)"/>

                    <!-- Put the whole chart in its own svg element so that all co-ordinates are relative to its origin.
                         That way the generation of each chart uses the same co-ordinates, regardless of where the chart is placed on the page -->
                    <svg x="{$xOriginPlot}" y="{$yOriginPlot}">

                        <!-- Create the chart background -->
                        <rect x="0" y="0" width="{$plotSizeX}" height="{$plotSizeY}"
                            fill="{$backgroundColour}" stroke-width="{$borderWidth}"
                            stroke="{$borderColour}"/>

                        <!-- Debugging
                        <text x="{$plotSizeX div 2}" y="{$plotSizeY div 2}" font-size="12" text-anchor="middle">
                            <xsl:value-of select="$intervalInDays"/> / <xsl:value-of select="$intervalInSeconds"/>
                        </text>
                        -->
                        <!-- Draw the vertical division lines on the timeseries plot -->
                        <xsl:for-each select="$divisionLinePositions">
                            <xsl:variable name="divisionPosition" select="."/>
                            <xsl:variable name="divLineX"
                                select="$divisionStepSize * $divisionPosition"/>
                            <line x1="{$divLineX}" y1="0" x2="{$divLineX}" y2="{$plotSizeY}"
                                stroke-width="{$divWidth}" stroke="{$divColour}"/>
                        </xsl:for-each>

                        <!-- Draw the horizontal division lines on the timeseries plot -->
                        <xsl:for-each select="$yaxisDivPositions">
                            <xsl:variable name="divisionPosition" select="."/>
                            <xsl:variable name="divLineY"
                                select="($plotDivisionsYOffset + $divisionPosition -1)*$scale * $yaxisUnitSize"/>
                            <line x1="0" y1="{$divLineY}" x2="{$plotSizeX}" y2="{$divLineY}"
                                stroke-width="{$divWidth}" stroke="{$divColour}"/>
                        </xsl:for-each>

                        <!-- Create plot for each variable. 
                             Iteration through the variables is sorted by the plotType and scale.
                             Draw the anchor for each value and lines connecting each pair of values -->

                        <xsl:for-each select="$plottedVariables">
                            <xsl:variable name="variable" select="."/>
                            <xsl:call-template name="generateTimeseriesPlot">
                                <xsl:with-param name="rootNode" select="$rootNode"/>
                                <xsl:with-param name="variable" select="$variable"/>
                                <xsl:with-param name="startTime" select="$startTime"/>
                                <xsl:with-param name="endTime" select="$endTime"/>
                                <xsl:with-param name="yAxisMax" select="$yaxisMax"/>
                            </xsl:call-template>
                        </xsl:for-each>

                    </svg>

                    <!-- interval -->
                    <!-- The interval plots are placed below each timeseries plot
                     -->
                    <xsl:if test="$intervalPlotCount gt 0">
                        <!-- Get the origin of the interval plots -->
                        <xsl:variable name="xOriginIntervalPlot" select="$xOriginPlot"/>
                        <xsl:variable name="yOriginIntervalPlot"
                            select="$yOriginLegendX + $legendSizeX"/>

                        <!-- Generate the plot -->
                        <xsl:call-template name="generateIntervalPlot">
                            <xsl:with-param name="xOriginIntervalPlot" select="$xOriginIntervalPlot"/>
                            <xsl:with-param name="yOriginIntervalPlot" select="$yOriginIntervalPlot"/>

                            <xsl:with-param name="plotSizeX" select="$plotSizeX"/>
                            <xsl:with-param name="intervalPlotHeight" select="$intervalPlotHeight"/>
                            <xsl:with-param name="backgroundColour" select="$backgroundColour"/>
                            <xsl:with-param name="borderWidth" select="$borderWidth"/>
                            <xsl:with-param name="borderColour" select="$borderColour"/>

                            <xsl:with-param name="divisionLinePositions"
                                select="$divisionLinePositions"/>
                            <xsl:with-param name="divisionStepSize" select="$divisionStepSize"/>
                            <xsl:with-param name="divWidth" select="$divWidth"/>
                            <xsl:with-param name="divColour" select="$divColour"/>

                            <xsl:with-param name="intervalVariables" select="$intervalVariables"/>
                            <xsl:with-param name="intervalPlotSpacing" select="$intervalPlotSpacing"
                            />
                        </xsl:call-template>

                    </xsl:if>

                </xsl:for-each>

            </svg>

        </xsl:if>

        <!-- Individual Plots -->
        <xsl:if test="$validInputs and $timeseriesPlotCount gt 0 and $plotGraphs='individual'">

            <!-- Calculate the overall size of the svg image based on the number of charts to be made. 
                The width is calculated based on the plotSize and the maximum number of legends to be drawn.
                There can be 0, 1 or 2 instances of the y-axis legend (show none, left, or left and right) -->
            <xsl:variable name="svgHeight"
                select="$plotSpacingY + ($plotHeight + $plotSpacingY)*$timeseriesPlotCount"/>
            <xsl:variable name="svgWidth"
                select="$plotSizeX + ($legendSizeY * $yAxisLegend) + 2*$plotSpacingX"/>

            <svg xmlns="http://www.w3.org/2000/svg" width="{$svgWidth}" height="{$svgHeight}"
                version="1.1">

                <!-- timeseries -->
                <!-- Combined plots means that the variables are grouped by scale - 1, 10, 100, 1000.
                    Scale 1 means y-axis values are 0 to 1; 10 means 0 to 10, etc -->
                <xsl:for-each select="$timeseriesVariables">
                    <xsl:variable name="variable" select="."/>
                    <xsl:variable name="plotCount" select="position()"/>

                    <!-- Get the origin of the Xaxis legend -->
                    <xsl:variable name="xOriginLegendX"
                        select="if ($yAxisLegend != 0) then $plotSpacingX + $legendSizeY else $plotSpacingX"/>
                    <xsl:variable name="yOriginLegendX"
                        select="($plotSpacingY + $plotHeight)*($plotCount -1) + $plotSpacingY + $plotSizeY"/>

                    <!-- Put x-axis legend in its own svg element so that all legends are drawn to the same co-ordinates -->
                    <svg x="{$xOriginLegendX}" y="{$yOriginLegendX}">
                        <!-- Create the x-axis legend background -->
                        <rect x="0" y="0" width="{$plotSizeX}" height="{$legendSizeX}"
                            fill="{$legendBackgroundColour}" stroke-width="{$borderWidth}"
                            stroke="{$borderColour}"/>

                        <!-- Output the X-Axis categories  -->
                        <xsl:call-template name="outputX-Axis">
                            <xsl:with-param name="fullDateSet" select="$fullDateSet"/>
                            <xsl:with-param name="legendSizeX" select="$legendSizeX"/>
                            <xsl:with-param name="divisionStep" select="$divisionStep"/>
                            <xsl:with-param name="divisionStepSize" select="$divisionStepSize"/>
                        </xsl:call-template>
                    </svg>

                    <!-- Variables to set the y-axis and horizontal division lines
                        Get the maximum value in the plotted variables.
                        Make sure the values are numbers before getting max/min.
                        The max value is across all variables to be plotted (on the same chart).
                        Scale 1 = 0-10, 10 = 10-100, 100 = 100-1000, etc
                        $maxValue div $scale returns a number between 1 and 10
                        yaxisDivisions is between 2 and 11 - its is the number of division lines to be shown, found by taking the ceiling() 
                        yaxisMax is the round up to the nearest y-axis division step plus a tenth (so that a division line and y-axis value can be drawn just below the top of the chart)
                        yaxisUnitSize is the number of pixels for each unit on the y-axis. -->
                    <xsl:variable name="maxValue" select="$variable/@maxValue"/>
                    <xsl:variable name="scale" as="xs:integer" select="xs:integer($variable/@scale)"/>
                    <xsl:variable name="yaxisDivisions" select="ceiling($maxValue div $scale)"/>
                    <xsl:variable name="yaxisMax"
                        select="($yaxisDivisions + $plotDivisionsYOffset) * $scale"/>
                    <xsl:variable name="yaxisUnitSize" select="$plotSizeY div $yaxisMax"/>
                    <xsl:variable name="yaxisDivPositions"
                        select="if ($yaxisDivisions castable as xs:integer and xs:integer($yaxisDivisions) gt 0) then 1 to xs:integer($yaxisDivisions) else ()"/>

                    <!-- Get the origin of the Yaxis legend -->
                    <xsl:variable name="xOriginLeftLegendY" select="$plotSpacingX"/>
                    <xsl:variable name="xOriginRightLegendY"
                        select="$xOriginLeftLegendY + +$legendSizeY + $plotSizeX"/>
                    <xsl:variable name="yOriginLegendY"
                        select="$plotSpacingY + ($plotSpacingY + $plotHeight)*($plotCount - 1)"/>

                    <!-- Output y-axis legend to left and right, as determined by yAxisLegend -->
                    <xsl:if test="$yAxisLegend = (1,2)">
                        <xsl:call-template name="outputY-AxisLegend">
                            <xsl:with-param name="xOriginLegendY" select="$xOriginLeftLegendY"/>
                            <xsl:with-param name="yOriginLegendY" select="$yOriginLegendY"/>
                            <xsl:with-param name="position" select="'left'"/>
                            <xsl:with-param name="yaxisUnitSize" select="$yaxisUnitSize"/>
                            <xsl:with-param name="yaxisDivisions" select="$yaxisDivisions"/>
                            <xsl:with-param name="yaxisDivPositions" select="$yaxisDivPositions"/>
                            <xsl:with-param name="scale" select="$scale"/>
                            <xsl:with-param name="plottedVariables" select="$variable"/>
                        </xsl:call-template>
                    </xsl:if>
                    <xsl:if test="$yAxisLegend = 2">
                        <xsl:call-template name="outputY-AxisLegend">
                            <xsl:with-param name="xOriginLegendY" select="$xOriginRightLegendY"/>
                            <xsl:with-param name="yOriginLegendY" select="$yOriginLegendY"/>
                            <xsl:with-param name="position" select="'right'"/>
                            <xsl:with-param name="yaxisUnitSize" select="$yaxisUnitSize"/>
                            <xsl:with-param name="yaxisDivisions" select="$yaxisDivisions"/>
                            <xsl:with-param name="yaxisDivPositions" select="$yaxisDivPositions"/>
                            <xsl:with-param name="scale" select="$scale"/>
                            <xsl:with-param name="plottedVariables" select="$variable"/>
                        </xsl:call-template>
                    </xsl:if>

                    <!-- Get the origin of the plot -->
                    <xsl:variable name="xOriginPlot"
                        select="if ($yAxisLegend != 0) then $plotSpacingX + $legendSizeY else $plotSpacingX"/>
                    <xsl:variable name="yOriginPlot"
                        select="$plotSpacingY +($plotSpacingY + $plotHeight)*($plotCount - 1)"/>

                    <!-- Put the whole chart in its own svg element so that all co-ordinates are relative to its origin.
                        That way the generation of each chart uses the same co-ordinates, regardless of where the chart is placed on the page -->
                    <svg x="{$xOriginPlot}" y="{$yOriginPlot}">

                        <!-- Create the chart background -->
                        <rect x="0" y="0" width="{$plotSizeX}" height="{$plotSizeY}"
                            fill="{$backgroundColour}" stroke-width="{$borderWidth}"
                            stroke="{$borderColour}"/>

                        <!-- Debugging
                            <text x="{$plotSizeX div 2}" y="{$plotSizeY div 2}" font-size="12" text-anchor="middle">
                            <xsl:value-of select="$intervalInDays"/> / <xsl:value-of select="$intervalInSeconds"/>
                            </text>
                        -->
                        <!-- Draw the vertical division lines on the timeseries plot -->
                        <xsl:for-each select="$divisionLinePositions">
                            <xsl:variable name="divisionPosition" select="."/>
                            <xsl:variable name="divLineX"
                                select="$divisionStepSize * $divisionPosition"/>
                            <line x1="{$divLineX}" y1="0" x2="{$divLineX}" y2="{$plotSizeY}"
                                stroke-width="{$divWidth}" stroke="{$divColour}"/>
                        </xsl:for-each>

                        <!-- Draw the horizontal division lines on the timeseries plot -->
                        <xsl:for-each select="$yaxisDivPositions">
                            <xsl:variable name="divisionPosition" select="."/>
                            <xsl:variable name="divLineY"
                                select="($plotDivisionsYOffset + $divisionPosition -1)*$scale * $yaxisUnitSize"/>
                            <line x1="0" y1="{$divLineY}" x2="{$plotSizeX}" y2="{$divLineY}"
                                stroke-width="{$divWidth}" stroke="{$divColour}"/>
                        </xsl:for-each>

                        <!-- Create plot for the variable. -->

                        <xsl:call-template name="generateTimeseriesPlot">
                            <xsl:with-param name="rootNode" select="$rootNode"/>
                            <xsl:with-param name="variable" select="$variable"/>
                            <xsl:with-param name="startTime" select="$startTime"/>
                            <xsl:with-param name="endTime" select="$endTime"/>
                            <xsl:with-param name="yAxisMax" select="$yaxisMax"/>
                        </xsl:call-template>

                    </svg>

                    <!-- interval -->
                    <!-- The interval plots are placed below each timeseries plot
                    -->
                    <xsl:if test="$intervalPlotCount gt 0">
                        <!-- Get the origin of the interval plots -->
                        <xsl:variable name="xOriginIntervalPlot" select="$xOriginPlot"/>
                        <xsl:variable name="yOriginIntervalPlot"
                            select="$yOriginLegendX + $legendSizeX"/>

                        <!-- Generate the plot -->
                        <xsl:call-template name="generateIntervalPlot">
                            <xsl:with-param name="xOriginIntervalPlot" select="$xOriginIntervalPlot"/>
                            <xsl:with-param name="yOriginIntervalPlot" select="$yOriginIntervalPlot"/>

                            <xsl:with-param name="plotSizeX" select="$plotSizeX"/>
                            <xsl:with-param name="intervalPlotHeight" select="$intervalPlotHeight"/>
                            <xsl:with-param name="backgroundColour" select="$backgroundColour"/>
                            <xsl:with-param name="borderWidth" select="$borderWidth"/>
                            <xsl:with-param name="borderColour" select="$borderColour"/>

                            <xsl:with-param name="divisionLinePositions"
                                select="$divisionLinePositions"/>
                            <xsl:with-param name="divisionStepSize" select="$divisionStepSize"/>
                            <xsl:with-param name="divWidth" select="$divWidth"/>
                            <xsl:with-param name="divColour" select="$divColour"/>

                            <xsl:with-param name="intervalVariables" select="$intervalVariables"/>
                            <xsl:with-param name="intervalPlotSpacing" select="$intervalPlotSpacing"
                            />
                        </xsl:call-template>

                    </xsl:if>

                </xsl:for-each>

            </svg>

        </xsl:if>

        <!-- No timeseries - just one or more interval plots.
             Draw x-axis, y-axis then draw the interval plots -->
        <xsl:if test="$validInputs and $timeseriesPlotCount = 0 and $intervalPlotCount gt 0">

            <!-- Calculate the overall size of the svg image based on the number of charts to be made. -->
            <xsl:variable name="svgHeight"
                select="2*$plotSpacingY + $legendSizeX + $intervalPlotHeight"/>
            <xsl:variable name="svgWidth" select="$plotSizeX + $legendSizeY + 2*$plotSpacingX"/>

            <svg xmlns="http://www.w3.org/2000/svg" width="{$svgWidth}" height="{$svgHeight}"
                version="1.1">

                <!-- Get the origin of the Xaxis legend -->
                <xsl:variable name="xOriginLegendX" select="$plotSpacingX + $legendSizeY"/>
                <xsl:variable name="yOriginLegendX" select="$plotSpacingY + $intervalPlotHeight"/>

                <!-- Put x-axis legend in its own svg element so that all legends are drawn to the same co-ordinates -->
                <svg x="{$xOriginLegendX}" y="{$yOriginLegendX}">
                    <!-- Create the x-axis legend background -->
                    <rect x="0" y="0" width="{$plotSizeX}" height="{$legendSizeX}"
                        fill="{$legendBackgroundColour}" stroke-width="{$borderWidth}"
                        stroke="{$borderColour}"/>

                    <!-- Output the X-Axis categories  -->
                    <xsl:call-template name="outputX-Axis">
                        <xsl:with-param name="fullDateSet" select="$fullDateSet"/>
                        <xsl:with-param name="legendSizeX" select="$legendSizeX"/>
                        <xsl:with-param name="divisionStep" select="$divisionStep"/>
                        <xsl:with-param name="divisionStepSize" select="$divisionStepSize"/>
                    </xsl:call-template>
                </svg>

                <!-- Get the origin of the Yaxis legend -->
                <xsl:variable name="xOriginLegendY" select="$plotSpacingX"/>
                <xsl:variable name="yOriginLegendY" select="$plotSpacingY"/>

                <!-- Put y-axis legend in its own svg element so that all legends are drawn to the same co-ordinates -->
                <svg x="{$xOriginLegendY}" y="{$yOriginLegendY}">
                    <!-- Create the y-axis legend background -->
                    <rect x="0" y="0" width="{$legendSizeY}"
                        height="{$intervalPlotHeight + $legendSizeX}"
                        fill="{$legendBackgroundColour}" stroke-width="{$borderWidth}"
                        stroke="{$borderColour}"/>
                </svg>

                <!-- The interval plots are the only ones on ths chart -->
                <!-- Get the origin of the interval plots -->
                <xsl:variable name="xOriginIntervalPlot" select="$plotSpacingX + $legendSizeY"/>
                <xsl:variable name="yOriginIntervalPlot" select="$plotSpacingY"/>

                <!-- Generate the plot -->
                <xsl:call-template name="generateIntervalPlot">
                    <xsl:with-param name="xOriginIntervalPlot" select="$xOriginIntervalPlot"/>
                    <xsl:with-param name="yOriginIntervalPlot" select="$yOriginIntervalPlot"/>

                    <xsl:with-param name="plotSizeX" select="$plotSizeX"/>
                    <xsl:with-param name="intervalPlotHeight" select="$intervalPlotHeight"/>
                    <xsl:with-param name="backgroundColour" select="$backgroundColour"/>
                    <xsl:with-param name="borderWidth" select="$borderWidth"/>
                    <xsl:with-param name="borderColour" select="$borderColour"/>

                    <xsl:with-param name="divisionLinePositions" select="$divisionLinePositions"/>
                    <xsl:with-param name="divisionStepSize" select="$divisionStepSize"/>
                    <xsl:with-param name="divWidth" select="$divWidth"/>
                    <xsl:with-param name="divColour" select="$divColour"/>

                    <xsl:with-param name="intervalVariables" select="$intervalVariables"/>
                    <xsl:with-param name="intervalPlotSpacing" select="$intervalPlotSpacing"/>
                </xsl:call-template>

            </svg>

        </xsl:if>

    </xsl:template>


    <!-- ===
         Output a timeseries plot.
         Get the set of dates where there is a value to be plotted.
         Iterate through the dates to draw anchors and line plots
         
         startTime and endTime are of type xs:dataTime but the dates recorded in the CDA may be xs:date or xs:dateTime (or maybe not castablt to either)
         === -->
    <xsl:template name="generateTimeseriesPlot">
        <xsl:param name="rootNode"/>
        <xsl:param name="variable"/>
        <xsl:param name="startTime"/>
        <xsl:param name="endTime"/>
        <xsl:param name="yAxisMax"/>

        <xsl:variable name="id" select="$variable/@id"/>
        <xsl:variable name="entryId" select="$variable/@entryId"/>
        <xsl:variable name="colour" select="$variable/@plotColour"/>
        <xsl:variable name="markerShape" select="$variable/@markerShape"/>
        <xsl:variable name="plotLineWidth" select="$variable/@plotLineWidth"/>

        <!-- Generate the marker for plotted points -->
        <xsl:call-template name="generateMarker">
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="markerShape" select="$markerShape"/>
            <xsl:with-param name="colour" select="$colour"/>
        </xsl:call-template>

        <!-- Get the set of dates where this variable has a value to be plotted -->
        <xsl:variable name="plottedDateSet"
            select="cityEHRFunction:generateDateSet($variable,xs:string($startTime),xs:string($endTime))"/>

        <!-- Plot value for each date -->
        <xsl:for-each select="$plottedDateSet">
            <xsl:variable name="position" select="position()"/>

            <xsl:variable name="dateString" select="."/>
            <xsl:variable name="date"
                select="if ($dateString castable as xs:dateTime) then xs:dateTime($dateString) else if ($dateString castable as xs:date) then xs:date($dateString) else ()"/>
            <xsl:variable name="nextDateString" select="$plottedDateSet[$position + 1]"/>
            <xsl:variable name="nextDate"
                select="if ($nextDateString castable as xs:dateTime) then xs:dateTime($nextDateString) else if ($nextDateString castable as xs:date) then xs:date($nextDateString) else ()"/>

            <xsl:variable name="value"
                select="cityEHRFunction:getVariableValueForDate($variable,$dateString)"/>
            <xsl:variable name="nextValue"
                select="cityEHRFunction:getVariableValueForDate($variable,$nextDateString)"/>

            <!-- Get X and Y coordinates of the two values - these return null if the date/value does not exist -->
            <xsl:variable name="plotX1" select="cityEHRFunction:getDateCoordinate($date)"/>
            <xsl:variable name="plotY1"
                select="cityEHRFunction:getValueCoordinate($value,$yAxisMax)"/>
            <xsl:variable name="plotX2" select="cityEHRFunction:getDateCoordinate($nextDate)"/>
            <xsl:variable name="plotY2"
                select="cityEHRFunction:getValueCoordinate($nextValue,$yAxisMax)"/>

            <!-- Output line if all coordinates exist -->
            <xsl:if
                test="exists($plotX1) and exists($plotY1) and exists($plotX2) and exists($plotY2)">
                <line x1="{$plotX1}" y1="{$plotY1}" x2="{$plotX2}" y2="{$plotY2}"
                    stroke-width="{$plotLineWidth}" stroke="{$colour}"
                    style="marker-start: url(#{$id}); marker-end: url(#{$id});"/>
            </xsl:if>

        </xsl:for-each>
    </xsl:template>


    <!-- ===
        Output an interval plot
            startDates for the interval are in dateElement
            endDates are in valueElement
        === -->

    <xsl:template name="generateIntervalPlot">
        <xsl:param name="xOriginIntervalPlot"/>
        <xsl:param name="yOriginIntervalPlot"/>

        <xsl:param name="plotSizeX"/>
        <xsl:param name="intervalPlotHeight"/>
        <xsl:param name="backgroundColour"/>
        <xsl:param name="borderWidth"/>
        <xsl:param name="borderColour"/>

        <xsl:param name="divisionLinePositions"/>
        <xsl:param name="divisionStepSize"/>
        <xsl:param name="divWidth"/>
        <xsl:param name="divColour"/>

        <xsl:param name="intervalVariables"/>
        <xsl:param name="intervalPlotSpacing"/>

        <!-- Put interval plot in its own svg element so that all plots are drawn to the same co-ordinates -->
        <svg x="{$xOriginIntervalPlot}" y="{$yOriginIntervalPlot}">
            <!-- Create the interval plot background -->
            <rect x="0" y="0" width="{$plotSizeX}" height="{$intervalPlotHeight}"
                fill="{$backgroundColour}" stroke-width="{$borderWidth}" stroke="{$borderColour}"/>

            <!-- Draw the vertical division lines on the interval plot -->
            <xsl:for-each select="$divisionLinePositions">
                <xsl:variable name="divisionPosition" select="."/>
                <xsl:variable name="divLineX" select="$divisionStepSize * $divisionPosition"/>
                <line x1="{$divLineX}" y1="0" x2="{$divLineX}" y2="{$intervalPlotHeight}"
                    stroke-width="{$divWidth}" stroke="{$divColour}"/>
            </xsl:for-each>

            <!-- Iterate through the interval plots to draw the chart -->
            <xsl:for-each select="$intervalVariables">
                <xsl:variable name="intervalPlotVariable" select="."/>
                <xsl:variable name="intervalPlotCount" select="position()"/>
                <xsl:variable name="intervalPlotY"
                    select="($intervalPlotSpacing * $intervalPlotCount) - ($intervalPlotSpacing div 2)"/>

                <xsl:variable name="plotLineWidth" select="$intervalPlotVariable/@plotLineWidth"/>

                <!-- Generate the marker for plotted points -->
                <xsl:variable name="id" select="$intervalPlotVariable/@id"/>
                <xsl:variable name="colour" select="$intervalPlotVariable/@plotColour"/>
                <xsl:variable name="markerShape" select="$intervalPlotVariable/@markerShape"/>
                <xsl:call-template name="generateMarker">
                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="markerShape" select="$markerShape"/>
                    <xsl:with-param name="colour" select="$colour"/>
                </xsl:call-template>

                <xsl:variable name="entryId" select="$intervalPlotVariable/@entryId"/>
                <xsl:variable name="variableElementExtension"
                    select="$intervalPlotVariable/@variableElementExtension"/>
                <xsl:variable name="variableElementValue"
                    select="$intervalPlotVariable/@variableElementValue"/>
                <xsl:variable name="variableElementDisplayName"
                    select="$intervalPlotVariable/@variableElementDisplayName"/>
                <xsl:variable name="dateElementExtension"
                    select="$intervalPlotVariable/@dateElementExtension"/>
                <xsl:variable name="valueElementExtension"
                    select="$intervalPlotVariable/@valueElementExtension"/>

                <!--
                <xsl:variable name="startDateList" select="$rootNode//cda:observation[cda:id/@extension=$entryId][cda:value[@extension=$variableElementExtension][@value=$variableElementValue]]/cda:value[@extension=$dateElementExtension]/@value"/>
                <xsl:variable name="endDateList" select="$rootNode//cda:observation[cda:id/@extension=$entryId][cda:value[@extension=$variableElementExtension][@value=$variableElementValue]]/cda:value[@extension=$valueElementExtension]/@value"/>
                -->
                <!-- The interval is formed from the @values of the $dateElementExtension element (start) and $valueElementExtension (end) 
                     These are concatenated to form the range.
                     There may be repeats, so these are eliminated with distinct-values -->
                <xsl:variable name="separator" select="'@@@'"/>
                <xsl:variable name="intervalList"
                    select="distinct-values($rootNode//cda:observation[cda:id/@extension=$entryId][cda:value[@extension=$variableElementExtension][@value=$variableElementValue]]/concat(cda:value[@extension=$dateElementExtension]/@value,$separator,cda:value[@extension=$valueElementExtension]/@value))"/>

                <!-- Debugging 
                <text font-size="12" x="30" y="{$intervalPlotY}">
                    <xsl:value-of select="count($startDateList)"/> // <xsl:value-of select="$startDateList" separator=" / "/>
                </text>
                <text font-size="12" x="30" y="{$intervalPlotY+10}">
                    <xsl:value-of select="count($endDateList)"/> // <xsl:value-of select="$endDateList" separator=" / "/>
                </text>
                <text font-size="12" x="30" y="{$intervalPlotY}">
                <xsl:value-of select="count($intervalList)"/> // <xsl:value-of select="$intervalList" separator=" / "/>
                </text>
                -->
                <xsl:for-each select="$intervalList">
                    <xsl:variable name="interval" select="."/>

                    <!-- Get start and end date for the interval -->
                    <xsl:variable name="startDateString"
                        select="substring-before($interval,$separator)"/>
                    <xsl:variable name="startDate"
                        select="if ($startDateString castable as xs:dateTime) then xs:dateTime($startDateString) else if ($startDateString castable as xs:date) then xs:date($startDateString) else $startTime"/>
                    <xsl:variable name="endDateString"
                        select="substring-after($interval,$separator)"/>
                    <xsl:variable name="endDate"
                        select="if ($endDateString castable as xs:dateTime) then xs:dateTime($endDateString) else if ($endDateString castable as xs:date) then xs:date($endDateString) else $endTime"/>

                    <!-- Get X and Y coordinates of the two values - these return null if the date/value does noe exist -->
                    <xsl:variable name="plotX1"
                        select="cityEHRFunction:getDateCoordinate($startDate)"/>
                    <xsl:variable name="plotX2" select="cityEHRFunction:getDateCoordinate($endDate)"/>

                    <!-- Output line if all coordinates exist -->
                    <xsl:if test="exists($plotX1) and exists($plotX2)">
                        <line x1="{$plotX1}" y1="{$intervalPlotY}" x2="{$plotX2}"
                            y2="{$intervalPlotY}" stroke-width="{$plotLineWidth}"
                            stroke="{$intervalPlotVariable/@plotColour}"
                            style="marker-start: url(#{$id}); marker-end: url(#{$id});"/>
                    </xsl:if>

                </xsl:for-each>

                <!--
                <line x1="0" y1="{$intervalPlotY}" x2="{$plotSizeX}" y2="{$intervalPlotY}" stroke-width="{$intervalPlotLineWidth}" stroke="{$intervalPlotVariable/@plotColour}" style="marker-start: url(#{$id}); marker-end: url(#{$id});"/>
                -->

            </xsl:for-each>
        </svg>
    </xsl:template>



    <!-- === Output a marker with specified id, shape, colour
             Shape can be circle | bar | diamond | square | triangle
             Default is to output a circle -->
    <xsl:template name="generateMarker">
        <xsl:param name="id"/>
        <xsl:param name="markerShape"/>
        <xsl:param name="colour"/>

        <defs>
            <!-- Default (will be used if circle or not one of the other shapes) -->
            <xsl:if test="not($markerShape = ('bar','diamond','square','triangle'))">
                <marker id="{$id}" markerHeight="8" markerWidth="8" refX="4" refY="4">
                    <circle cx="4" cy="4" r="3" style="stroke: none; fill:{$colour};"/>
                </marker>
            </xsl:if>
            <xsl:if test="$markerShape='bar'">
                <marker id="{$id}" markerHeight="2" markerWidth="1" refX="0.5" refY="1">
                    <rect x="0" y="0" height="2" width="1" style="stroke: none; fill:{$colour};"/>
                </marker>
            </xsl:if>
            <xsl:if test="$markerShape='diamond'">
                <marker id="{$id}" markerHeight="8" markerWidth="8" refX="4" refY="4">
                    <path d="M2,4 L4,2 L6,4 L4,6" style="stroke: none; fill:{$colour};"/>
                </marker>
            </xsl:if>
            <xsl:if test="$markerShape='square'">
                <marker id="{$id}" markerHeight="1" markerWidth="1" refX="0.5" refY="0.5">
                    <rect x="0" y="0" height="1" width="1" style="stroke: none; fill:{$colour};"/>
                </marker>
            </xsl:if>
            <xsl:if test="$markerShape='triangle'">
                <marker id="{$id}" markerHeight="8" markerWidth="8" refX="4" refY="4">
                    <path d="M2,6 L4,2 L6,6" style="stroke: none; fill:{$colour};"/>
                </marker>
            </xsl:if>
        </defs>
    </xsl:template>



    <!-- ===
         Get set of time intervals for x-axis for a particular variable
         Need to look for descendant values of the observation (TBD)
         <variable entryId="#ISO-13606:Entry:OsteoporosisBoneChemistry" dateElementExtension="#ISO-13606:Element:SampleDate" variableElementExtension="#ISO-13606:Element:BoneChemistryTest" variableElementValue="CTX" valueElementExtension="#ISO-13606:Element:Double"/>
         
         There are six cases:
            1) Observation with date, variable and value elements
            2) Observation with date and value elements (no variable)
            3) Observation with variable and value element (no date), simple entry
            4) Observation with value element (no date or variable), simple entry
            5) Observation with variable and value element (no date), multiple entry
            6) Observation with value element (no date or variable), multiple entry
            
            For (3,4) the effective time is used as the date and is on cda:observation 
            For (5,6) the effectiveTime is on the parent cda:component
         -->
    <xsl:function name="cityEHRFunction:generateDateSet">
        <xsl:param name="variable"/>
        <xsl:param name="startTime" as="xs:string"/>
        <xsl:param name="endTime" as="xs:string"/>

        <xsl:variable name="entryId" select="$variable/@entryId"/>
        <xsl:variable name="dateElementExtension" select="$variable/@dateElementExtension"/>
        <xsl:variable name="variableElementExtension" select="$variable/@variableElementExtension"/>
        <xsl:variable name="variableElementValue" select="$variable/@variableElementValue"/>
        <xsl:variable name="valueElementExtension" select="$variable/@valueElementExtension"/>
        
        <xsl:variable name="observationSet"
            select="$rootNode/descendant::cda:observation[cda:id/@extension=$entryId]"/>

        <!-- Date element is defined for (1) and (2) -->
        <xsl:if test="$dateElementExtension != ''">
            <!-- (1) variable different from value -->
            <xsl:if test="$variableElementExtension != $valueElementExtension">
                <xsl:sequence
                    select="cityEHRFunction:sort($observationSet [cda:value[@extension=$variableElementExtension][@value=$variableElementValue]] /cda:value[@extension=$dateElementExtension][@value ge $startTime][@value le $endTime]/@value)"
                />
            </xsl:if>
            <!-- (2) variable same as value -->
            <xsl:if test="$variableElementExtension = $valueElementExtension">
                <xsl:sequence
                    select="cityEHRFunction:sort($observationSet [cda:value[@extension=$valueElementExtension]] /cda:value[@extension=$dateElementExtension][@value ge $startTime][@value le $endTime]/@value)"
                />
            </xsl:if>
        </xsl:if>
        <!-- No date defined - using effectiveTime attribute -->
        <xsl:if test="$dateElementExtension = ''">
            <!-- Simple entry, date is on cda:observation -->
            <xsl:if
                test="$rootNode/descendant::cda:observation[cda:id/@extension=$entryId][@effectiveTime]">
                <!-- (3) variable different from value -->
                <xsl:if test="$variableElementExtension != $valueElementExtension">
                    <xsl:sequence
                        select="cityEHRFunction:sort($rootNode/descendant::cda:observation [cda:id/@extension=$entryId] [cda:value[@extension=$variableElementExtension][@value=$variableElementValue]] [@effectiveTime ge $startTime][@effectiveTime le $endTime]/@effectiveTime)"
                    />
                </xsl:if>
                <!-- (4) variable same as value -->
                <xsl:if test="$variableElementExtension = $valueElementExtension">
                    <xsl:sequence
                        select="cityEHRFunction:sort($rootNode/descendant::cda:observation [cda:id/@extension=$entryId] [cda:value[@extension=$valueElementExtension]] [@effectiveTime ge $startTime][@effectiveTime le $endTime]/@effectiveTime)"
                    />
                </xsl:if>
            </xsl:if>
            <!-- Multiple entry, date is on parent cda:component -->
            <xsl:if
                test="$rootNode/descendant::cda:observation[cda:id/@extension=$entryId][ancestor::cda:component/@effectiveTime]">
                <!-- (5) variable different from value -->
                <xsl:if test="$variableElementExtension != $valueElementExtension">
                    <xsl:sequence
                        select="cityEHRFunction:sort($observationSet [cda:value[@extension=$variableElementExtension][@value=$variableElementValue]] /ancestor::cda:component[@effectiveTime ge $startTime][@effectiveTime le $endTime]/@effectiveTime)"
                    />
                </xsl:if>
                <!-- (6) variable same as value -->
                <xsl:if test="$variableElementExtension = $valueElementExtension">
                    <xsl:sequence
                        select="cityEHRFunction:sort($observationSet [cda:value[@extension=$valueElementExtension]] /ancestor::cda:component[@effectiveTime ge $startTime][@effectiveTime le $endTime]/@effectiveTime)"
                    />
                </xsl:if>
            </xsl:if>
        </xsl:if>
    </xsl:function>


    <!-- ===
        Get set of time intervals for x-axis.
        Recursive call until the endTime is reached
    -->
    <xsl:template name="generateFullDateSet">
        <xsl:param name="startTime" as="xs:dateTime"/>
        <xsl:param name="endTime" as="xs:dateTime"/>
        <xsl:param name="step"/>

        <xsl:variable name="nextTime" as="xs:dateTime"
            select="if ($step castable as xs:yearMonthDuration) then $startTime + xs:yearMonthDuration($step) else $startTime + xs:dayTimeDuration($step)"/>

        <xsl:value-of select="$startTime"/>

        <xsl:if test="$startTime le $endTime">
            <xsl:value-of select="'@@@'"/>
            <xsl:call-template name="generateFullDateSet">
                <xsl:with-param name="startTime" select="$nextTime"/>
                <xsl:with-param name="endTime" select="$endTime"/>
                <xsl:with-param name="step" select="$step"/>
            </xsl:call-template>
        </xsl:if>

    </xsl:template>


    <!-- === 
        Function gets sequence of number of timeseries plots in each scale
    -->
    <xsl:function name="cityEHRFunction:getScalePlotCounts">
        <xsl:param name="plotGraphs"/>
        <xsl:param name="timeseriesVariables"/>
        <xsl:param name="timeseriesPlotScales"/>

        <xsl:if test="$plotGraphs='individual'">
            <xsl:value-of select="1"/>
        </xsl:if>

        <xsl:for-each select="$timeseriesPlotScales">
            <xsl:variable name="scale" select="."/>
            <xsl:value-of select="count($timeseriesVariables[@scale=$scale])"/>
        </xsl:for-each>
    </xsl:function>

    <!-- ===
         Output the y-axis legend  
         Put y-axis legend in its own svg element so that all legends are drawn to the same co-ordinates.
         The legend may be positioned to the left or right of the chart -->
    <xsl:template name="outputY-AxisLegend">
        <xsl:param name="xOriginLegendY"/>
        <xsl:param name="yOriginLegendY"/>
        <xsl:param name="position"/>
        <xsl:param name="yaxisUnitSize"/>
        <xsl:param name="yaxisDivisions"/>
        <xsl:param name="yaxisDivPositions"/>
        <xsl:param name="scale"/>
        <xsl:param name="plottedVariables"/>

        <xsl:variable name="valueAnchor" select="if ($position='right') then 'start' else 'end'"/>

        <svg x="{$xOriginLegendY}" y="{$yOriginLegendY}">
            <!-- Create the y-axis legend background -->
            <rect x="0" y="0" width="{$legendSizeY}" height="{$plotHeight}"
                fill="{$legendBackgroundColour}" stroke-width="{$borderWidth}"
                stroke="{$borderColour}"/>

            <!-- Draw the y-axis legend values -->
            <xsl:for-each select="$yaxisDivPositions">
                <xsl:variable name="divisionPosition" select="."/>
                <xsl:variable name="legendValue"
                    select="($yaxisDivisions - $divisionPosition +1) * $scale"/>
                <xsl:variable name="divLineX"
                    select="if ($position='left') then $legendSizeY - ($legendFontSize div 2) else ($legendFontSize div 2)"/>
                <xsl:variable name="divLineY"
                    select="($plotDivisionsYOffset + $divisionPosition -1)*$scale * $yaxisUnitSize + ($legendFontSize div 2)"/>
                <text x="{$divLineX}" y="{$divLineY}" font-size="{$legendFontSize}"
                    text-anchor="{$valueAnchor}">
                    <xsl:value-of select="$legendValue"/>
                </text>
            </xsl:for-each>

            <!-- Draw the y-axis variable legends -->
            <xsl:for-each select="$plottedVariables">
                <xsl:variable name="variable" select="."/>
                <xsl:variable name="count" select="position()"/>
                <xsl:variable name="xPos"
                    select="if ($position='left') then ($count - 0.5)*$legendUnitSizeY else $legendSizeY - (($count - 0.5)*$legendUnitSizeY)"/>
                <xsl:variable name="yPos" select="$legendFontSize"/>
                <!-- Show variable colour -->
                <rect x="{$xPos - 0.25*$legendUnitSizeY}" y="{$yPos}" width="{$legendFontSize}"
                    height="{$legendFontSize}" fill="{$variable/@plotColour}"/>
                <!-- Show variable displayName -->
                <text x="{$xPos}" y="{$yPos*3}" font-size="{$legendFontSize}" anchor="start"
                    style="writing-mode: tb;">
                    <xsl:value-of select="$variable/@variableElementDisplayName"/>
                </text>
            </xsl:for-each>
        </svg>
    </xsl:template>


    <!-- ===
         Output the x-axis categories  -->
    <xsl:template name="outputX-Axis">
        <xsl:param name="fullDateSet"/>
        <xsl:param name="legendSizeX"/>
        <xsl:param name="divisionStep"/>
        <xsl:param name="divisionStepSize"/>


        <xsl:variable name="fullDateSetCount" select="count($fullDateSet)"/>

        <!-- Legend can be oriented vertical of horizontal -->
        <xsl:variable name="legendOrientation"
            select="if ($legendOrientationX='vertical') then 'writing-mode: tb;' else ''"/>

        <xsl:for-each select="$fullDateSet">
            <xsl:variable name="date" select="."/>
            <xsl:variable name="count" select="position()"/>

            <!-- Draw label at each division line, but not at the last position -->
            <xsl:variable name="divisionCount" select="round($count div $divisionStep)"/>
            <xsl:variable name="drawLabel"
                select="if (($divisionCount * $divisionStep eq $count) and ($count lt $fullDateSetCount)) then true() else false()"/>

            <!-- Legend can be oriented vertical of horizontal -->
            <xsl:if test="$drawLabel">
                <xsl:variable name="divLineX" select="$divisionStepSize * $divisionCount"/>
                <xsl:variable name="formattedDate" select="substring($date,1,10)"/>
                <text font-size="12" x="{$divLineX}" y="{$legendSizeX div 2}" text-anchor="middle"
                    style="{$legendOrientation}">
                    <xsl:value-of select="$formattedDate"/>
                </text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>


    <!-- === 
        Function returns a sorted sequence of strings
    -->
    <xsl:function name="cityEHRFunction:sort">
        <xsl:param name="sequence"/>

        <xsl:for-each select="$sequence">
            <xsl:sort select="."/>
            <xsl:value-of select="."/>
        </xsl:for-each>
    </xsl:function>

    <!-- === 
            Function returns the list of variableValues keys
            variableValues concatenates the entryId, variableElementExtension, variableElementValue and valueElementExtension -->

    <xsl:function name="cityEHRFunction:getAllVariableValuesKeys">
        <xsl:param name="chartVariables"/>

        <xsl:for-each select="$chartVariables/*">
            <xsl:variable name="variable" select="."/>
            <xsl:value-of select="cityEHRFunction:getVariableValuesKey($variable)"/>
        </xsl:for-each>
    </xsl:function>

    <!-- === 
        Function returns the variableValuesKey for a variable
        variableValues concatenates the entryId, variableElementExtension, variableElementValue and valueElementExtension -->
    <xsl:function name="cityEHRFunction:getVariableValuesKey">
        <xsl:param name="variable"/>

        <xsl:value-of
            select="concat($variable/@entryId, $variable/@variableElementExtension, $variable/@variableElementValue, $variable/@valueElementExtension)"/>

    </xsl:function>

    <!-- === 
        Function returns the value for a variable at a specified date
        
        There are six cases:
        1) Observation with date, variable and value elements
        2) Observation with date and value elements (no variable)
        3) Observation with variable and value element (no date), simple entry
        4) Observation with value element (no date or variable), simple entry
        5) Observation with variable and value element (no date), multiple entry
        6) Observation with value element (no date or variable), multiple entry
        
        For (3,4) the effective time is used as the date and is on cda:observation 
        For (5,6) the effectiveTime is on the parent cda:component -->

    <xsl:function name="cityEHRFunction:getVariableValueForDate">
        <xsl:param name="variable"/>
        <xsl:param name="date"/>

        <xsl:variable name="entryId" select="$variable/@entryId"/>
        <xsl:variable name="dateElementExtension" select="$variable/@dateElementExtension"/>
        <xsl:variable name="variableElementExtension" select="$variable/@variableElementExtension"/>
        <xsl:variable name="variableElementValue" select="$variable/@variableElementValue"/>
        <xsl:variable name="valueElementExtension" select="$variable/@valueElementExtension"/>

        <xsl:variable name="observationSet"
            select="$rootNode/descendant::cda:observation[cda:id/@extension=$entryId]"/>

        <!-- Date element is defined for (1) and (2) -->
        <xsl:if test="$dateElementExtension != ''">
            <!-- (1) variable different from value -->
            <xsl:if test="$variableElementExtension != $valueElementExtension">
                <xsl:value-of
                    select="$observationSet[cda:value[@extension=$dateElementExtension][@value=$date]] [cda:value[@extension=$variableElementExtension][@value=$variableElementValue]] [1]/cda:value[@extension=$valueElementExtension][@value castable as xs:double]/@value"
                />
            </xsl:if>
            <!-- (2) variable same as value -->
            <xsl:if test="$variableElementExtension = $valueElementExtension">
                <xsl:value-of
                    select="$observationSet[cda:value[@extension=$dateElementExtension][@value=$date]] [1] /cda:value[@extension=$valueElementExtension][@value castable as xs:double]/@value"
                />
            </xsl:if>
        </xsl:if>

        <!-- No date defined - using effectiveTime attribute -->
        <xsl:if test="$dateElementExtension = ''">
            <!-- Simple entry, date is on cda:observation -->
            <xsl:if test="$observationSet[@effectiveTime]">
                <!-- (3) variable different from value -->
                <xsl:if test="$variableElementExtension != $valueElementExtension">
                    <xsl:value-of
                        select="$observationSet[@effectiveTime=$date][cda:value[@extension=$variableElementExtension][@value=$variableElementValue]][1]/cda:value[@extension=$valueElementExtension][@value castable as xs:double]/@value"
                    />
                </xsl:if>
                <!-- (4) variable same as value -->
                <xsl:if test="$variableElementExtension = $valueElementExtension">
                    <xsl:value-of
                        select="$observationSet[@effectiveTime=$date][1]/cda:value[@extension=$valueElementExtension][@value castable as xs:double]/@value"
                    />
                </xsl:if>
            </xsl:if>

            <!-- Multiple entry, date is on parent cda:component -->
            <xsl:if test="$observationSet[ancestor::cda:component/@effectiveTime]">
                <!-- (5) variable different from value -->
                <xsl:if test="$variableElementExtension != $valueElementExtension">
                    <xsl:value-of
                        select="$observationSet[ancestor::cda:component/@effectiveTime=$date][cda:value[@extension=$variableElementExtension][@value=$variableElementValue]][1]/cda:value[@extension=$valueElementExtension][@value castable as xs:double]/@value"
                    />
                </xsl:if>
                <!-- (6) variable same as value -->
                <xsl:if test="$variableElementExtension = $valueElementExtension">
                    <xsl:value-of
                        select="$observationSet[ancestor::cda:component/@effectiveTime=$date][1]/cda:value[@extension=$valueElementExtension][@value castable as xs:double]/@value"
                    />
                </xsl:if>
            </xsl:if>

        </xsl:if>
    </xsl:function>

    <!-- === 
            Function gets the number of seconds in a dateTime duration
             -->
    <xsl:function name="cityEHRFunction:getDurationInSeconds">
        <xsl:param name="dayTimeDuration"/>

        <xsl:variable name="days" select="days-from-duration($dayTimeDuration)"/>
        <xsl:variable name="hours" select="hours-from-duration($dayTimeDuration)"/>
        <xsl:variable name="minutes" select="minutes-from-duration($dayTimeDuration)"/>
        <xsl:variable name="seconds" select="seconds-from-duration($dayTimeDuration)"/>

        <xsl:value-of select="$seconds+($minutes*60)+($hours*3600)+($days*24*3600)"/>
    </xsl:function>


    <!-- === 
        Function gets y-coordinate of a value
    -->
    <xsl:function name="cityEHRFunction:getValueCoordinate">
        <xsl:param name="value"/>
        <xsl:param name="yAxisMax"/>

        <xsl:if test="$value castable as xs:double">
            <xsl:variable name="yValue" select="$yAxisMax - $value"/>
            <xsl:value-of select="($yValue div $yAxisMax) * $plotSizeY"/>
        </xsl:if>
    </xsl:function>


    <!-- === 
        Function gets x-coordinate of a date(Time)
        $timeExtension is global variable for the string representng 0 time that must be added to a date to make it a dateTime
        $intervalInSeconds is global variable with the total x-axis interval
        $plotSizeX is a global variable with the total x-axis size
    -->
    <xsl:function name="cityEHRFunction:getDateCoordinate">
        <xsl:param name="date"/>

        <xsl:variable name="dateTimeString"
            select="if ($date castable as xs:date) then concat(substring(xs:string($date),1,10),$timeExtension) else xs:string($date)"/>

        <xsl:if test="$dateTimeString castable as xs:dateTime">
            <xsl:variable name="xIntervalDuration"
                select="xs:dateTime($dateTimeString) - $startTime"/>
            <xsl:variable name="xIntervalSeconds"
                select="cityEHRFunction:getDurationInSeconds($xIntervalDuration)"/>
            <xsl:value-of select="($xIntervalSeconds div $intervalInSeconds) * $plotSizeX"/>
        </xsl:if>
    </xsl:function>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>
</xsl:stylesheet>
