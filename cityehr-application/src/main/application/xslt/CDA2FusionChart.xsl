<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    CDA2FusionChart.xsl
    Input is a CDA document representing a generated view
    PLUS a control file which contains the variables that are to be charted
    
    Generates an XML file that can be consumed by the Fusion Charts processor.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Root document node -->
    <xsl:variable name="rootNode" select="/"/>

    <!-- Set the variables for the chart to be generated.
        <current-chart>
        <startTime/>
        <endTime/>
        <interval/>
        <intervalInDays/>
        <intervalUnits/>
        <step/>
        <plotGraphs/>
        <plotColours/>
        <plotDivisions/>
            <variable action="false" checkboxStatus="" entryId="" dateElementExtension="" variableElementExtension="" variableElementValue="" valueElementExtension=""/>
            <variables>
                <variable entryId="#ISO-13606:Entry:OsteoporosisBoneChemistry" dateElementExtension="#ISO-13606:Element:SampleDate" variableElementExtension="#ISO-13606:Element:BoneChemistryTest" variableElementValue="P1NP" valueElementExtension="#ISO-13606:Element:Double"/>
                <variable entryId="#ISO-13606:Entry:OsteoporosisBoneChemistry" dateElementExtension="#ISO-13606:Element:SampleDate" variableElementExtension="#ISO-13606:Element:BoneChemistryTest" variableElementValue="CTX" valueElementExtension="#ISO-13606:Element:Double"/>
            </variables>
        </current-chart>     
    -->

    <!-- The information for each chart variable is as follows:
        
        entryId                     the id of the entry (cda:observation/cda:id/@extension)
        dateElementExtension        the id of the element (cda:value)  used for the date (x-axis) - if empty then use the effectiveTime on the observation
        variableElementExtension    the id of the element (cda:value) used as the variable to plot - can be empty
        variableElementValue        the value of the variable - used to select the entries to be plotted, but uses all entries if variableElementExtension is empty
        valueElementExtension       the id the element (cda:value) holding variable value to be plotted on y-axis
    -->
    <xsl:variable name="chartVariables" select="document('input:control')/control/current-chart/variables"/>
    <xsl:variable name="idRoot" select="document('input:control')/control/current-chart/idRoot"/>
    <xsl:variable name="plotGraphs" select="document('input:control')/control/current-chart/plotGraphs"/>
    <xsl:variable name="plotDivisions" select="document('input:control')/control/current-chart/plotDivisions"/>
    <xsl:variable name="startTime" select="document('input:control')/control/current-chart/startTime"/>
    <xsl:variable name="endTime" select="document('input:control')/control/current-chart/endTime"/>
    <xsl:variable name="step" select="document('input:control')/control/current-chart/step"/>

    <!-- === Keys to get values from the CDA.
             Note that these keys may include some combinations that are not in the variable list.
             But this is OK since they will include all the values we want to look up === -->

    <!-- The set of all variable values (these are cda:value elements) -->
    <!-- Can't use a variable in the xsl:key match attribute 
    <xsl:variable name="variableValueSet" select="$rootNode//cda:observation [cda:id/@extension=$chartVariables/variable/@entryId] [cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]] [cda:value[@extension=$chartVariables/variable/@dateElementExtension]] /cda:value[@extension=$chartVariables/variable/@valueElementExtension][@value castable as xs:double]"/>
    -->

    <!-- variableValues concatenates the entryId, variableElementExtension, variableElementValue and valueElementExtension -->
    <xsl:key name="variableValues" match="//cda:observation [cda:id/@extension=$chartVariables/variable/@entryId] [cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]] [cda:value[@extension=$chartVariables/variable/@dateElementExtension]] /cda:value[@extension=$chartVariables/variable/@valueElementExtension][@value castable as xs:double]/@value" use="concat(../../cda:id/@extension,../../cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]/@extension,../../cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]/@value,../../cda:value[@extension=$chartVariables/variable/@valueElementExtension]/@extension)"/>

    <!-- variableValuesForDate concatenates the entryId, variableElementExtension, variableElementValue, dateElementExtension, dateElementValue and valueElementExtension -->
    <xsl:key name="variableValuesForDate" match="//cda:observation [cda:id/@extension=$chartVariables/variable/@entryId] [cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]] [cda:value[@extension=$chartVariables/variable/@dateElementExtension]] /cda:value[@extension=$chartVariables/variable/@valueElementExtension][@value castable as xs:double]/@value"
        use="concat(../../cda:id/@extension,../../cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]/@extension,../../cda:value[@extension=$chartVariables/variable/@variableElementExtension][@value=$chartVariables/variable/@variableElementValue]/@value,../../cda:value[@extension=$chartVariables/variable/@dateElementExtension]/@extension,../../cda:value[@extension=$chartVariables/variable/@dateElementExtension]/@value,../../cda:value[@extension=$chartVariables/variable/@valueElementExtension]/@extension)"/>

    <!-- === Sets of dates for the x-axis === -->
    <!-- This is the full set of dates across the range selected -->
    <xsl:variable name="fullDateSet">
        <xsl:call-template name="generateFullDateSet">
            <xsl:with-param name="startTime" select="$startTime"/>
            <xsl:with-param name="endTime" select="$endTime"/>
            <xsl:with-param name="step" select="$step"/>
        </xsl:call-template>
    </xsl:variable>

    <!-- These are the actual dates in the CDA document which match elements in the variable set.
         Must have the same entry id and dateElementExtension
         -->
    <xsl:variable name="recordedDateSet">
        <xsl:for-each select="$chartVariables/variable">
            <xsl:call-template name="generateDateSet">
                <xsl:with-param name="rootNode" select="$rootNode"/>
                <xsl:with-param name="variable" select="."/>
                <xsl:with-param name="startTime" select="$startTime"/>
                <xsl:with-param name="endTime" select="$endTime"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:variable>
    <!-- There may be duplicates in the fullDateSet -->
    <!-- This is the full set of dates across the range selected -->
    <xsl:variable name="combinedDateSet" select="(tokenize($fullDateSet,'@@@'),tokenize($recordedDateSet,'@@@'))"/>
    <xsl:variable name="distinctDateSet" select="cityEHRFunction:sort(distinct-values($combinedDateSet))"/>
    <xsl:variable name="divisionStep" select="round(count($distinctDateSet) div ($plotDivisions+1))"/>

    <!-- Match the root.
    
         Generate categories (x-axis)
         and datasets (y-axis) -->

    <xsl:template match="/">
        <!-- Use the data attribute to send stuff back to xforms for debugging -->

        <chartSet data="">
            <!-- Debugging
            <fullDateSet><xsl:value-of select="$fullDateSet"></xsl:value-of></fullDateSet>                        
            <distinctDateSet><xsl:value-of select="$distinctDateSet[1]"></xsl:value-of></distinctDateSet>
            -->

            <!-- Group variables for combined plot -->
            <xsl:if test="$plotGraphs='combined'">
                <!-- Get the minimum and maximum values in the plotted variables.
                     Make sure the values are numbers before getting max/min.
                     The max/min are across all variables to be plotted (on the same chart) -->

                <xsl:variable name="timeseriesPlotScales" select="distinct-values($chartVariables/variable[@plotType='timeseries']/@scale)"/>

                <!-- timeseries -->
                <!-- Combined plots means that the variables are grouped by scale - 1, 10, 100, 1000 -->
                <xsl:for-each select="$timeseriesPlotScales">
                    <xsl:variable name="scale" as="xs:integer" select="xs:integer(.)"/>

                    <!-- Get the maximum values in the plotted variable, and the number of division lines -->
                    <xsl:variable name="maxValue" select="max($chartVariables/variable[@scale=$scale]/@maxValue)"/>
                    <xsl:variable name="scaleDivisions" select="round($maxValue div $scale)"/>
                    <xsl:variable name="yaxismaxvalue" select="($scaleDivisions + 1 ) * $scale"/>
                    <xsl:variable name="divLines" select="if ($scaleDivisions le 5) then ($scaleDivisions * 2) + 1 else $scaleDivisions"/>

                    <xsl:variable name="graphId" select="concat($idRoot,$scale)"/>

                    <graph graphId="{$graphId}" caption="" xAxisName="Date" yAxisName="" hovercapbg="FFECAA" hovercapborder="F47E00" formatNumberScale="0" decimalPrecision="2" showvalues="0" showLimits="0" showNames="1" animation="0" numdivlines="{$divLines}" numVdivlines="{$plotDivisions}" yaxisminvalue="0" yaxismaxvalue="{$yaxismaxvalue}" lineThickness="1" lineShadow="0" zeroPlaneThickness="3" rotateNames="1" showLegend="1">
                        <!-- Output the X-Axis categories -->
                        <xsl:call-template name="outputX-Axis">
                            <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                        </xsl:call-template>

                        <!-- Create dataset for each variable to be plotted.
                         This is different for timeseries and interval plots. 
                         Iteration through the variables is sorted by the plotType and scale. -->

                        <!-- timeseries -->
                        <xsl:for-each select="$chartVariables/variable[@plotType='timeseries'][@scale=$scale]">
                            <xsl:variable name="variable" select="."/>
                            <xsl:call-template name="generateTimeseriesPlot">
                                <xsl:with-param name="variable" select="$variable"/>
                                <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </graph>

                </xsl:for-each>

                <!-- interval -->
                <!-- The interval plots spaced out between the max and min values on the timeseries plots.
                    Not done now - just make the interval step 1, since intervals are plotted on their own graph -->
                <!--
                    <xsl:variable name="intervalPlotDivisions" select="count($chartVariables/variable[@plotType='interval'])+1"/>
                    <xsl:variable name="intervalStep" select="max( ( 1, (($yaxismaxvalue - $yaxisminvalue) div $intervalPlotDivisions) ) )"/>
                -->
                <xsl:variable name="intervalPlot" select="if (exists($chartVariables/variable[@plotType='interval'])) then 'true' else 'false'"/>
                <xsl:variable name="intervalStep" select="1"/>

                <!-- Interval position is -1 for below the zero plane, 1 for above it -->
                <xsl:variable name="intervalPosition" select="1"/>
                <!-- Set the max value on the y-axis to be a bit above the level of the last plot -->
                <xsl:variable name="yaxismaxvalueInterval" select="($intervalStep * count($chartVariables/variable[@plotType='interval'])) + 1"/>
                <!-- Show x-axis categories if no timeseries plot -->
                <xsl:variable name="showNames" select="if (count($timeseriesPlotScales) gt 0) then 0 else 1"/>

                <xsl:if test="$intervalPlot='true'">
                    <xsl:variable name="graphId" select="concat($idRoot,'interval')"/>

                    <graph graphId="{$graphId}" caption="" xAxisName="Date" yAxisName="" hovercapbg="FFECAA" hovercapborder="F47E00" formatNumberScale="0" decimalPrecision="2" showvalues="0" showLimits="0" showNames="{$showNames}" animation="0" numdivlines="0" numVdivlines="{$plotDivisions}" yaxisminvalue="" yaxismaxvalue="{$yaxismaxvalueInterval}" lineThickness="5" lineShadow="0" zeroPlaneThickness="3" rotateNames="1" showLegend="1">
                        <!-- Output the X-Axis categories -->
                        <xsl:call-template name="outputX-Axis">
                            <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                        </xsl:call-template>

                        <xsl:for-each select="$chartVariables/variable[@plotType='interval']">
                            <xsl:variable name="variable" select="."/>
                            <xsl:variable name="intervalPlotNumber" select="count($variable/preceding-sibling::variable[@plotType='interval'])+1"/>
                            <xsl:variable name="intervalStepValue" select="$intervalStep * $intervalPlotNumber * $intervalPosition"/>

                            <xsl:call-template name="generateIntervalPlot">
                                <xsl:with-param name="variable" select="$variable"/>
                                <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                                <xsl:with-param name="intervalStepValue" select="$intervalStepValue"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </graph>
                </xsl:if>
            </xsl:if>

            <!-- Multiple graphs for single plots -->
            <xsl:if test="$plotGraphs!='combined'">
                <!-- Create graph for each variable to be plotted -->

                <!-- timeseries -->
                <xsl:for-each select="$chartVariables/variable[@plotType='timeseries']">
                    <xsl:variable name="variable" select="."/>
                    <xsl:variable name="variableElementDisplayName" select="$variable/@variableElementDisplayName"/>

                    <!-- Get the maximum values in the plotted variable, and the number of division lines -->
                    <xsl:variable name="scaleDivisions" select="round($variable/@maxValue div $variable/@scale)"/>
                    <xsl:variable name="yaxismaxvalue" select="($scaleDivisions + 1 ) * $variable/@scale"/>
                    <xsl:variable name="divLines" select="if ($scaleDivisions le 5) then ($scaleDivisions * 2) + 1 else $scaleDivisions"/>

                    <xsl:variable name="graphId" select="concat($idRoot,$variableElementDisplayName)"/>

                    <graph graphId="{$graphId}" caption="" xAxisName="Date" yAxisName="{$variableElementDisplayName}" hovercapbg="FFECAA" hovercapborder="F47E00" formatNumberScale="1" decimalPrecision="2" showvalues="0" showLimits="0" showNames="1" animation="0" numdivlines="{$divLines}" numVdivlines="{$plotDivisions}" yaxisminvalue="0" yaxismaxvalue="{$yaxismaxvalue}" lineThickness="1" lineShadow="0" zeroPlaneThickness="3" rotateNames="1" showLegend="0">
                        <!-- Output the X-Axis categories -->
                        <xsl:call-template name="outputX-Axis">
                            <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                        </xsl:call-template>

                        <!-- Create dataset for the variable to be plotted. -->
                        <xsl:call-template name="generateTimeseriesPlot">
                            <xsl:with-param name="variable" select="$variable"/>
                            <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                        </xsl:call-template>
                    </graph>
                </xsl:for-each>

                <!-- interval -->
                <xsl:for-each select="$chartVariables/variable[@plotType='interval']">
                    <xsl:variable name="variable" select="."/>
                    <xsl:variable name="variableElementDisplayName" select="$variable/@variableElementDisplayName"/>

                    <!-- Interval position is -1 for below the zero plane, 1 for above it -->
                    <xsl:variable name="intervalPosition" select="1"/>
                    <xsl:variable name="intervalStep" select="1"/>
                    <xsl:variable name="yaxismaxvalueInterval" select="2"/>

                    <!-- Just one plot when on its own chart -->
                    <xsl:variable name="intervalPlotNumber" select="1"/>
                    <xsl:variable name="intervalStepValue" select="$intervalStep * $intervalPlotNumber * $intervalPosition"/>

                    <xsl:variable name="graphId" select="concat($idRoot,$variableElementDisplayName)"/>

                    <graph graphId="{$graphId}" caption="" xAxisName="Date" yAxisName="{$variableElementDisplayName}" hovercapbg="FFECAA" hovercapborder="F47E00" formatNumberScale="1" decimalPrecision="2" showvalues="0" showLimits="0" showNames="0" animation="0" numdivlines="0" numVdivlines="{$plotDivisions}" yaxisminvalue="" yaxismaxvalue="{$yaxismaxvalueInterval}" lineThickness="5" lineShadow="0" zeroPlaneThickness="3" rotateNames="1" showLegend="0">
                        <!-- Output the X-Axis categories -->
                        <xsl:call-template name="outputX-Axis">
                            <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                        </xsl:call-template>

                        <xsl:call-template name="generateIntervalPlot">
                            <xsl:with-param name="variable" select="$variable"/>
                            <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                            <xsl:with-param name="intervalStepValue" select="$intervalStepValue"/>
                        </xsl:call-template>
                    </graph>

                </xsl:for-each>

            </xsl:if>

        </chartSet>

    </xsl:template>


    <!-- ===
         Output a timeseries plot
         === -->
    <xsl:template name="generateTimeseriesPlot">
        <xsl:param name="variable"/>
        <xsl:param name="distinctDateSet"/>

        <!-- Get the list of x-axis positions where there is a value -->
        <xsl:variable name="X-AxisPositions">
            <xsl:call-template name="getX-AxisPositions">
                <xsl:with-param name="variable" select="$variable"/>
                <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="X-AxisPositionsSet" select="distinct-values(tokenize($X-AxisPositions,'@@@'))"/>

        <!-- debugging 
        <X-AxisPositions><xsl:value-of select="$X-AxisPositions"></xsl:value-of></X-AxisPositions>                        
        <X-AxisPositionsSet><xsl:value-of select="$X-AxisPositionsSet[1]"></xsl:value-of></X-AxisPositionsSet>
    -->

        <!-- If Y-axis data exists then output the data sets. -->
        <xsl:if test="$X-AxisPositionsSet[1] castable as xs:integer">
            <xsl:call-template name="generateY-AxisDataSet">
                <xsl:with-param name="variable" select="$variable"/>
                <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                <xsl:with-param name="X-AxisPositionsSet" select="$X-AxisPositionsSet"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>


    <!-- ===
        Output an interval plot
            startDates for the interval are in dateElement
            endDates are in valueElement
        === -->

    <xsl:template name="generateIntervalPlot">
        <xsl:param name="variable"/>
        <xsl:param name="distinctDateSet"/>
        <xsl:param name="intervalStepValue"/>

        <xsl:variable name="entryId" select="$variable/@entryId"/>
        <xsl:variable name="variableElementExtension" select="$variable/@variableElementExtension"/>
        <xsl:variable name="variableElementValue" select="$variable/@variableElementValue"/>
        <xsl:variable name="variableElementDisplayName" select="$variable/@variableElementDisplayName"/>
        <xsl:variable name="dateElementExtension" select="$variable/@dateElementExtension"/>
        <xsl:variable name="valueElementExtension" select="$variable/@valueElementExtension"/>
        <xsl:variable name="color" select="$variable/@plotColour"/>

        <xsl:variable name="startDateList" select="distinct-values($rootNode//cda:observation[cda:id/@extension=$entryId][cda:value[@extension=$variableElementExtension][@value=$variableElementValue]]/cda:value[@extension=$dateElementExtension]/@value)"/>
        <xsl:variable name="endDateList" select="distinct-values($rootNode//cda:observation[cda:id/@extension=$entryId][cda:value[@extension=$variableElementExtension][@value=$variableElementValue]]/cda:value[@extension=$valueElementExtension]/@value)"/>

        <xsl:call-template name="generateY-AxisDataSetForIntervals">
            <xsl:with-param name="intervalStepValue" select="$intervalStepValue"/>
            <xsl:with-param name="variableElementDisplayName" select="$variableElementDisplayName"/>
            <xsl:with-param name="color" select="$color"/>
            <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
            <xsl:with-param name="startDateList" select="$startDateList"/>
            <xsl:with-param name="endDateList" select="$endDateList"/>
        </xsl:call-template>

    </xsl:template>



    <!-- ===
         Get set of time intervals for x-axis for a particular variable
         <variable entryId="#ISO-13606:Entry:OsteoporosisBoneChemistry" dateElementExtension="#ISO-13606:Element:SampleDate" variableElementExtension="#ISO-13606:Element:BoneChemistryTest" variableElementValue="CTX" valueElementExtension="#ISO-13606:Element:Double"/>
    -->
    <xsl:template name="generateDateSet">
        <xsl:param name="rootNode"/>
        <xsl:param name="variable"/>
        <xsl:param name="startTime"/>
        <xsl:param name="endTime"/>

        <xsl:variable name="entryId" select="$variable/@entryId"/>
        <xsl:variable name="dateElementExtension" select="$variable/@dateElementExtension"/>
        <xsl:variable name="variableElementExtension" select="$variable/@variableElementExtension"/>
        <xsl:variable name="variableElementValue" select="$variable/@variableElementValue"/>

        <xsl:value-of select="$rootNode/descendant::cda:observation[cda:id/@extension=$entryId][cda:value[@extension=$variableElementExtension][@value=$variableElementValue][@value ge $startTime][@value le $endTime]]/cda:value[@extension=$dateElementExtension]/@value" separator="@@@"/>

    </xsl:template>

    <!-- ===
        Get set of time intervals for x-axis.
        Recursive call until the endTime is reached
    -->
    <xsl:template name="generateFullDateSet">
        <xsl:param name="startTime" as="xs:date"/>
        <xsl:param name="endTime" as="xs:date"/>
        <xsl:param name="step"/>

        <xsl:variable name="nextTime" as="xs:date" select="if ($step castable as xs:yearMonthDuration) then $startTime + xs:yearMonthDuration($step) else $startTime + xs:dayTimeDuration($step)"/>

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
         Generate categories for x-axis -->
    <xsl:template name="generateX-Axis">
        <xsl:param name="i"/>
        <xsl:param name="count"/>

        <xsl:if test="$i &lt;= $count">
            <!-- Output category -->
            <category name="{$i}"/>

            <!-- Recursive call to generate all categories -->
            <xsl:call-template name="generateX-Axis">
                <xsl:with-param name="i" select="$i + 1"/>
                <xsl:with-param name="count" select="$count"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- ===
         Output the x-axis categories -->
    <xsl:template name="outputX-Axis">
        <xsl:param name="distinctDateSet"/>
        <categories>

            <xsl:for-each select="$distinctDateSet">
                <xsl:variable name="date" select="."/>
                <xsl:variable name="count" select="position()"/>

                <xsl:variable name="showName" select="if (round($count div $divisionStep)*$divisionStep eq $count) then '1' else '0'"/>

                <xsl:variable name="formattedDate" select="substring($date,1,10)"/>

                <category name="{$formattedDate}" showName="{$showName}"/>
            </xsl:for-each>

        </categories>
    </xsl:template>

    <!-- ===
         Get x-axis positions.
         Generates a list of the x-axis positions where there is a value to plot. -->
    <xsl:template name="getX-AxisPositions">
        <xsl:param name="variable"/>
        <xsl:param name="distinctDateSet"/>


        <xsl:for-each select="$distinctDateSet">
            <xsl:variable name="position" select="position()"/>
            <xsl:variable name="startDate" select="."/>
            <xsl:variable name="endDate" select="$distinctDateSet[$position + 1]"/>

            <xsl:if test="cityEHRFunction:getValueInInterval($variable,$startDate,$endDate)!=''">
                <xsl:value-of select="$position"/>
                <xsl:value-of select="'@@@'"/>
            </xsl:if>
        </xsl:for-each>

    </xsl:template>

    <!-- === 
        Generate data set for y-axis. Used for timeseries only.
        
        <dataset>
          <set>
          <set>
          ..
          <set>
        </dataset>  
        
        Each set is a value for the plot, either a charted value, or an incremental value used to draw the line joining the charted values.
        
        Steps are:
            1. Output sets with zero value up to the first charted value
            2. For each charted value
                a. output a set for the value
                b. get the position of the next charted value
                c. find the incremental step between each value in between the two charted values
                d. output the sets with the incremental values
                
        Make two datasets for each plot - first one draws the line, second shows the anchors
        TBD - need to allow more datasets to cater for having multiple y-axis values for a single x-axis position.
        -->
    <xsl:template name="generateY-AxisDataSet">
        <xsl:param name="variable"/>
        <xsl:param name="distinctDateSet"/>
        <xsl:param name="X-AxisPositionsSet"/>

        <xsl:variable name="entryId" select="$variable/@entryId"/>
        <xsl:variable name="dateElementExtension" select="$variable/@dateElementExtension"/>
        <xsl:variable name="variableElementExtension" select="$variable/@variableElementExtension"/>
        <xsl:variable name="variableElementValue" select="$variable/@variableElementValue"/>
        <xsl:variable name="valueElementExtension" select="$variable/@valueElementExtension"/>
        <xsl:variable name="color" select="$variable/@plotColour"/>

        <!-- First dataset draws the line -->
        <dataset seriesname="{$variableElementValue}" color="{$color}" showValue="1" alpha="100" showAnchors="0">

            <!-- Output the initial set of empty y-axis values -->
            <xsl:call-template name="outputEmptyY-AxisDataSet">
                <xsl:with-param name="variable" select="$variable"/>
                <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                <xsl:with-param name="startPos" as="xs:integer" select="1"/>
                <xsl:with-param name="endPos" as="xs:integer" select="xs:integer($X-AxisPositionsSet[1])"/>
            </xsl:call-template>

            <!-- Output the plots connecting all charted y-axis values.
                 -->
            <xsl:for-each select="$X-AxisPositionsSet">
                <xsl:variable name="setPosition" select="position()"/>
                <xsl:variable name="startPos" select="."/>
                <xsl:variable name="nextPos" select="$X-AxisPositionsSet[$setPosition +1]"/>
                <xsl:variable name="endPos" select="if (exists($nextPos)) then $nextPos else $startPos"/>

                <xsl:if test="$startPos castable as xs:integer and $endPos castable as xs:integer">
                    <xsl:call-template name="outputY-AxisPlot">
                        <xsl:with-param name="variable" select="$variable"/>
                        <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                        <xsl:with-param name="startPos" as="xs:integer" select="xs:integer($startPos)"/>
                        <xsl:with-param name="endPos" as="xs:integer" select="xs:integer($endPos)"/>
                    </xsl:call-template>
                </xsl:if>

            </xsl:for-each>

        </dataset>

        <!-- Second dataset draws the anchors.
             This should actually repeat to show multiple values stacked in x-axis positions, if necessary - TBD.
        
             This one has 
                 alpha="0" so that the line and anchors do not display (alpha overrides in the <set> elements where we do want the anchor displayed
                 showAnchors="1" so that the anchors do display
             -->
        <dataset seriesname="" color="{$color}" showValue="1" alpha="0" lineThickness="0" showAnchors="1" anchorSides="3" anchorRadius="5">

            <!-- Output the initial set of empty y-axis values -->
            <xsl:call-template name="outputEmptyY-AxisDataSet">
                <xsl:with-param name="variable" select="$variable"/>
                <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                <xsl:with-param name="startPos" as="xs:integer" select="1"/>
                <xsl:with-param name="endPos" as="xs:integer" select="xs:integer($X-AxisPositionsSet[1])"/>
            </xsl:call-template>

            <!-- Output the plots connecting all charted y-axis values.
            -->
            <xsl:for-each select="$X-AxisPositionsSet">
                <xsl:variable name="setPosition" select="position()"/>
                <xsl:variable name="startPos" select="."/>
                <xsl:variable name="nextPos" select="$X-AxisPositionsSet[$setPosition +1]"/>
                <xsl:variable name="endPos" select="if (exists($nextPos)) then $nextPos else $startPos"/>

                <xsl:if test="$startPos castable as xs:integer and $endPos castable as xs:integer">
                    <xsl:call-template name="outputY-AxisPlot">
                        <xsl:with-param name="variable" select="$variable"/>
                        <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                        <xsl:with-param name="startPos" as="xs:integer" select="xs:integer($startPos)"/>
                        <xsl:with-param name="endPos" as="xs:integer" select="xs:integer($endPos)"/>
                    </xsl:call-template>
                </xsl:if>

            </xsl:for-each>

        </dataset>

    </xsl:template>


    <!-- === 
        Generate data set for y-axis.
        Used for interval plots only
    -->
    <xsl:template name="generateY-AxisDataSetForIntervals">
        <xsl:param name="intervalStepValue"/>
        <xsl:param name="variableElementDisplayName"/>
        <xsl:param name="color"/>
        <xsl:param name="distinctDateSet"/>
        <xsl:param name="startDateList"/>
        <xsl:param name="endDateList"/>

        <dataset seriesname="{$variableElementDisplayName}" color="{$color}" showValue="1" alpha="100" lineThickness="5" showAnchors="0" anchorSides="3" anchorRadius="5">
            <xsl:for-each select="$distinctDateSet">
                <xsl:variable name="date" select="."/>

                <xsl:variable name="startDateCount" select="count($startDateList[. le $date])"/>
                <xsl:variable name="endDateCount" select="count($endDateList[. lt $date])"/>

                <xsl:variable name="value" select="if ($startDateCount gt $endDateCount) then $intervalStepValue else ''"/>

                <set value="{$value}" alpha="100" name="{$startDateCount} - {$endDateCount}" showName="1"/>
            </xsl:for-each>
        </dataset>
    </xsl:template>


    <!-- === 
        Output empty data slots for y-axis.
        Creates a set with no value between the startPos and endPos.
        Then outputs the set for the value at endPos -->
    <xsl:template name="outputEmptyY-AxisDataSet">
        <xsl:param name="variable"/>
        <xsl:param name="distinctDateSet"/>
        <xsl:param name="startPos" as="xs:integer"/>
        <xsl:param name="endPos" as="xs:integer"/>

        <xsl:if test="$startPos lt $endPos">
            <set value=""/>
            <xsl:variable name="newStartPos" as="xs:integer" select="$startPos + 1"/>
            <xsl:call-template name="outputEmptyY-AxisDataSet">
                <xsl:with-param name="variable" select="$variable"/>
                <xsl:with-param name="distinctDateSet" select="$distinctDateSet"/>
                <xsl:with-param name="startPos" as="xs:integer" select="$newStartPos"/>
                <xsl:with-param name="endPos" as="xs:integer" select="$endPos"/>
            </xsl:call-template>
        </xsl:if>

        <!-- Output the set for the charted value at the endPos.
             Has large alpha value so that the value and its anchor are displayed -->
        <xsl:if test="$startPos eq $endPos">
            <xsl:variable name="value" select="cityEHRFunction:getY-axisValue($variable,$endPos,$distinctDateSet)"/>
            <set value="{$value}" name="{$value}" alpha="100" showName="1"/>
        </xsl:if>
    </xsl:template>

    <!-- === 
        Output data slots for y-axis plot between two x-axis positions.
        Steps are:
            1. Output the set with the charted value.
            2. Find the next charted value and the size of the incremental steps to it.
            3. Output a set for each of the incremental values.
    
        Note that this does not output the value at endPos, so need to do that for the last value in the set (which is not folowed by an outputY-AxisPlot) -->
    <xsl:template name="outputY-AxisPlot">
        <xsl:param name="variable"/>
        <xsl:param name="distinctDateSet"/>
        <xsl:param name="startPos" as="xs:integer"/>
        <xsl:param name="endPos" as="xs:integer"/>

        <xsl:variable name="value" select="cityEHRFunction:getY-axisValue($variable,$startPos,$distinctDateSet)"/>
        <xsl:variable name="nextValue" select="cityEHRFunction:getY-axisValue($variable,$endPos,$distinctDateSet)"/>
        <xsl:variable name="steps" as="xs:integer" select="$endPos - $startPos"/>
        <xsl:variable name="increment" as="xs:double" select="($nextValue - $value) div $steps"/>

        <xsl:call-template name="outputY-AxisIncrement">
            <xsl:with-param name="step" as="xs:integer" select="1"/>
            <xsl:with-param name="value" as="xs:double" select="$value + $increment"/>
            <xsl:with-param name="steps" as="xs:integer" select="$steps"/>
            <xsl:with-param name="increment" as="xs:double" select="$increment"/>
        </xsl:call-template>

        <!-- Output the set for the charted value.
            Has large alpha value so that the value and its anchor are displayed -->
        <set value="{$nextValue}" name="{$nextValue}" alpha="100" showName="1"/>

    </xsl:template>

    <!-- === 
         Output y-axis data for an incremental step on the x-axis.
         Recursive so that a <set> is output for each incremental value. -->
    <xsl:template name="outputY-AxisIncrement">
        <xsl:param name="step" as="xs:integer"/>
        <xsl:param name="value" as="xs:double"/>
        <xsl:param name="steps" as="xs:integer"/>
        <xsl:param name="increment" as="xs:double"/>

        <xsl:if test="$step &lt; $steps">
            <!-- Output the value. Alpha is inherited from the dataset. -->
            <set value="{$value}"/>

            <!-- Recursive call to output all the incremental values -->
            <xsl:call-template name="outputY-AxisIncrement">
                <xsl:with-param name="step" as="xs:integer" select="$step + 1"/>
                <xsl:with-param name="value" as="xs:double" select="$value + $increment"/>
                <xsl:with-param name="steps" as="xs:integer" select="$steps"/>
                <xsl:with-param name="increment" as="xs:double" select="$increment"/>
            </xsl:call-template>

        </xsl:if>

    </xsl:template>


    <!-- === 
        Generate data for y-axis -->
    <xsl:template name="generateY-AxisData">
        <xsl:param name="i"/>
        <xsl:param name="count"/>
        <xsl:param name="series"/>

        <xsl:if test="$i &lt;= $count">
            <!-- Output category -->
            <set value="{($i * 10) * $series}"/>

            <!-- Recursive call to generate all categories -->
            <xsl:call-template name="generateY-AxisData">
                <xsl:with-param name="i" select="$i + 1"/>
                <xsl:with-param name="count" select="$count"/>
                <xsl:with-param name="series" select="$series"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <!-- === 
        Function to get y-axis value.
        Gets the value of the variable at a specified position.
    -->
    <xsl:function name="cityEHRFunction:getY-axisValue">
        <xsl:param name="variable"/>
        <xsl:param name="x-axisPosition"/>
        <xsl:param name="distinctDateSet"/>

        <xsl:variable name="startDate" select="$distinctDateSet[$x-axisPosition]"/>
        <xsl:variable name="endDate" select="$distinctDateSet[$x-axisPosition +1]"/>

        <xsl:value-of select="cityEHRFunction:getValueInInterval($variable,$startDate,$endDate)"/>
    </xsl:function>

    <!-- === 
        Function to get value in a time interval
        Gets the value of the variable within the specified time interval.
        There may be more than one value in the interval, so get the first one only
    -->
    <xsl:function name="cityEHRFunction:getValueInInterval">
        <xsl:param name="variable"/>
        <xsl:param name="startDate"/>
        <xsl:param name="endDate"/>

        <xsl:variable name="plotType" select="$variable/@plotType"/>
        <xsl:variable name="entryId" select="$variable/@entryId"/>
        <xsl:variable name="dateElementExtension" select="$variable/@dateElementExtension"/>
        <xsl:variable name="variableElementExtension" select="$variable/@variableElementExtension"/>
        <xsl:variable name="variableElementValue" select="$variable/@variableElementValue"/>
        <xsl:variable name="valueElementExtension" select="$variable/@valueElementExtension"/>

        <!-- For timeseries plots.
            If $dateElementExtension is empty then look for the effectiveTime on the observation
            If $variableElementExtension is empty then look for any entry with the correct entryId
            
            So there are four cases to consider
        -->
        <xsl:if test="$plotType='timeseries'">

            <!-- Using dateElementExtension -->
            <xsl:if test="$dateElementExtension!=''">
                <!-- Using variableElementExtension -->
                <xsl:if test="$variableElementExtension!=''">
                    <xsl:if test="exists($rootNode/descendant::cda:observation[cda:id/@extension=$entryId][cda:value[@extension=$dateElementExtension][@value ge $startDate and @value lt $endDate]][cda:value[@extension=$variableElementExtension][@value=$variableElementValue]][cda:value[@extension=$valueElementExtension][@value castable as xs:double]])">
                        <xsl:value-of select="$rootNode/descendant::cda:observation[cda:id/@extension=$entryId][cda:value[@extension=$dateElementExtension][@value ge $startDate and @value lt $endDate]][cda:value[@extension=$variableElementExtension][@value=$variableElementValue]][1]/cda:value[@extension=$valueElementExtension][@value castable as xs:double]/@value"/>
                    </xsl:if>
                </xsl:if>
                <!-- Using any entry with entryId -->
                <xsl:if test="$variableElementExtension=''">
                    <xsl:if test="exists($rootNode/descendant::cda:observation[cda:id/@extension=$entryId][cda:value[@extension=$dateElementExtension][@value ge $startDate and @value lt $endDate]][cda:value[@extension=$valueElementExtension][@value castable as xs:double]])">
                        <xsl:value-of select="$rootNode/descendant::cda:observation[cda:id/@extension=$entryId][cda:value[@extension=$dateElementExtension][@value ge $startDate and @value lt $endDate]][1]/cda:value[@extension=$valueElementExtension][@value castable as xs:double]/@value"/>
                    </xsl:if>
                </xsl:if>
            </xsl:if>


            <!-- Using effectiveTime -->
            <xsl:if test="$dateElementExtension=''">
                <!-- Using variableElementExtension -->
                <xsl:if test="$variableElementExtension!=''">
                    <xsl:if test="exists($rootNode/descendant::cda:observation[cda:id/@extension=$entryId][@effectiveTime ge $startDate and @effectiveTime lt $endDate][cda:value[@extension=$variableElementExtension][@value=$variableElementValue]][cda:value[@extension=$valueElementExtension][@value castable as xs:double]])">
                        <xsl:value-of select="$rootNode/descendant::cda:observation[cda:id/@extension=$entryId][@effectiveTime ge $startDate and @effectiveTime lt $endDate][cda:value[@extension=$variableElementExtension][@value=$variableElementValue]][1]/cda:value[@extension=$valueElementExtension][@value castable as xs:double]/@value"/>
                    </xsl:if>
                </xsl:if>
                <!-- Using any entry with entryId -->
                <xsl:if test="$variableElementExtension=''">
                    <xsl:if test="exists($rootNode/descendant::cda:observation[cda:id/@extension=$entryId][@effectiveTime ge $startDate and @effectiveTime lt $endDate][cda:value[@extension=$valueElementExtension][@value castable as xs:double]])">
                        <xsl:value-of select="$rootNode/descendant::cda:observation[cda:id/@extension=$entryId][@effectiveTime ge $startDate and @effectiveTime lt $endDate][1]/cda:value[@extension=$valueElementExtension][@value castable as xs:double]/@value"/>
                    </xsl:if>
                </xsl:if>
            </xsl:if>
        </xsl:if>

        <!-- For interval type plots, get the set of intervals to plot for the specified variable.
            Each interval runs from the start to end date, with the value set to 1, 2, 3, etc based on the number of the interval.
            Start date is in $dateElementExtension
            End date is in $valueElementExtension
            Note that the end date may be missing (i.e. has @value="") so don't need to check for this
        -->
        <xsl:if test="$plotType='interval'"> </xsl:if>
    </xsl:function>

    <!-- === 
        Function returns true if value is in range
    -->
    <xsl:function name="cityEHRFunction:inRange">
        <xsl:param name="value"/>
        <xsl:param name="lowValue"/>
        <xsl:param name="highValue"/>

        <xsl:variable name="result" select="if ($value ge $lowValue and $value lt $highValue) then 'true' else 'false'"/>

        <xsl:value-of select="$result"/>

    </xsl:function>

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
        Function returns the list of variableValues keys
        variableValues concatenates the entryId, variableElementExtension, variableElementValue and valueElementExtension -->

    <xsl:function name="cityEHRFunction:getVariableValuesKey">
        <xsl:param name="variable"/>

        <xsl:value-of select="concat($variable/@entryId, $variable/@variableElementExtension, $variable/@variableElementValue, $variable/@valueElementExtension)"/>

    </xsl:function>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>
</xsl:stylesheet>
