<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    importWatchedResources.xpl
    
    Pipeline to import patient records from the server directory specified in parameters/watchedDirectory
    Input is session-parameters with watchedDirectory, processedDirectory and errorDirectory set
    
    Get the list of files in the directory
    Iterate through the files
    Iterate through records in the file
    Import each record if patientId is specified
    Write the file to the processedDirectory or errorDirectory
    Delete the file
    
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


    <p:choose href="#instance">
        <!-- Check the schedulerCommand -->
        <p:when test="/parameters/schedulerCommand = 'start'">

            <p:processor name="oxf:scheduler">
                <p:input name="config">
                    <config>
                        <start-task>
                            <name>importWatchedResources</name>
                            <start-time>now</start-time>
                            <interval>10000</interval>
                            <processor-name>oxf:pipeline</processor-name>
                            <input name="config"
                                url="oxf:/apps/ehr/pipelines/importWatchedResources.xpl"/>
                        </start-task>
                    </config>
                </p:input>
            </p:processor>
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
        </p:otherwise>

    </p:choose>



</p:pipeline>
