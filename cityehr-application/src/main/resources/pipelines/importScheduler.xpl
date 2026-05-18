<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    importScheduler.xpl
    
    Pipeline to start or stop the scheduler that runs importWatchedResources.xpl
    Input is scheduler-parameters with schedulerLogURL, schedulerCommand and pollingInterval set
    
    Start and stop commands to the oxf:scheduler processor
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    **********************************************************************************************************
-->

<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline"
    xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Input to pipeline is view-parameters.xml -->
    <p:param name="instance" type="input"/>    
    
    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Check the schedulerCommand to start or stop -->
    <p:choose href="#instance">
        <!-- schedulerCommand is start -->
        <p:when test="//schedulerCommand = 'start'">

            <p:processor name="oxf:scheduler">
                <p:input name="config" transform="oxf:xslt" href="#instance">
                    <config xsl:version="2.0">
                        <start-task>
                            <name>importWatchedResources</name>
                            <start-time>now</start-time>
                            <interval><xsl:value-of select="//pollingInterval"/></interval>
                            <processor-name>oxf:pipeline</processor-name>
                            <input name="config"
                                url="oxf:/apps/ehr/pipelines/importWatchedResources.xpl"/>
                        </start-task>
                    </config>
                </p:input>
            </p:processor>
            
            <!-- Record the scheduler command -->
            <!--
            <p:processor name="oxf:exception-catcher">
                <p:input name="data">
                    <schedulerResult>
                        start
                    </schedulerResult>
                </p:input>
                <p:output name="data" id="schedulerCommand"/>
            </p:processor>
            -->

        </p:when>

        <!-- No start command - stop the scheduler -->
        <p:otherwise>
            <p:processor name="oxf:scheduler">
                <p:input name="config">
                    <config>
                        <stop-task>
                            <name>importWatchedResources</name>
                        </stop-task>
                    </config>
                </p:input>
            </p:processor>
            
            <!-- Record the scheduler command -->
            <!--
            <p:processor name="oxf:exception-catcher">
                <p:input name="data">
                    <schedulerResult>
                        stop
                    </schedulerResult>
                </p:input>
                <p:output name="data" id="schedulerCommand"/>
            </p:processor>
            -->
                       
        </p:otherwise>

    </p:choose>
        
    <!-- Write the schedulerLog.
         This will get overwritten on the first scheduled importWatchedResources
         So only useful for debugging if that doesn't run (or if the command was to stop) -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="#instance">
            <xf:submission xsl:version="2.0" action="{//schedulerLogURL}"
                validate="false" method="put" replace="none" includenamespacesprefixes=""/>
        </p:input>
        <p:input name="request" transform="oxf:xslt" href="#instance">
            <schedulerLog xsl:version="2.0">
                <process>importScheduler</process>
                <timeStamp>
                    <xsl:value-of select="current-dateTime()"/>
                </timeStamp>
                <command>
                    <xsl:value-of select="//schedulerCommand"/>
                </command>
                <interval><xsl:value-of select="//pollingInterval"/></interval>
            </schedulerLog>
        </p:input>
        <p:output name="response" id="saveResponse"/>
    </p:processor>
    
    <!-- Exception catcher - audit information -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#saveResponse"/>
        <p:output name="data" ref="data"/>
    </p:processor>

</p:pipeline>
