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

    <!-- Input to pipeline is xml/patient-view-parameters.xml as set in the page-flow.xml file 
         with parameters set in the page element -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Run the getPipelineParameters pipeline.
         Returns the combined application-parameters, session-parameters, system-parameters, database-parameters,  view-parameters -->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="getPipelineParameters.xpl"/>
        <p:input name="instance" href="#instance"/>
        <p:output name="parameters" id="parameters"/>
    </p:processor>

    <!-- Get list of files/folders in watchedDirectory folder.
       <directory name="address-book" path="c:\Documents and Settings\John Doe\OPS\src\examples\web\examples\address-book">
            <file last-modified-ms="1120343217984" last-modified-date="2005-07-03T00:26:57.984" size="961130" path="image0001.jpg" name="image0001.jpg"/>
        </directory>    
         -->
    <p:processor name="oxf:directory-scanner">
        <p:input name="config" transform="oxf:xslt" href="#parameters">
            <config xsl:version="2.0">
                <base-directory>
                    <xsl:value-of
                        select="concat('file://',//parameters/importPipeline/watchedDirectory)"/>
                </base-directory>
                <include> *.* </include>
                <include> */*.* </include>
                <case-sensitive>false</case-sensitive>
            </config>
        </p:input>
        <p:output name="data" id="directoryListing"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#directoryListing"/>
        <p:output name="data" id="directoryListingChecked"/>
    </p:processor>

    <!-- Iterate through the directoryListing
         Read each file which is defined bt
         
            <file last-modified-ms="1719915616000" last-modified-date="2024-07-02T11:20:16.000" size="23" path="test.xml" name="test.xml"/>      
         -->

    <p:for-each href="#directoryListingChecked" select="//file" root="fileOperations"
        id="fileOperationChecked">

        <!-- Read file -->
        <p:processor name="oxf:url-generator">
            <p:input name="config" transform="oxf:xslt"
                href="aggregate('configuration',current(),#parameters)">
                <config xsl:version="2.0">
                    <url>
                        <xsl:value-of
                            select="concat('file://',//parameters/importPipeline/watchedDirectory,'/',configuration/file/@name)"
                        />
                    </url>
                    <content-type>application/xml</content-type>
                </config>
            </p:input>
            <p:output name="data" id="fileContent"/>
        </p:processor>

        <!-- Exception catcher - reading file content -->
        <p:processor name="oxf:exception-catcher">
            <p:input name="data" href="#fileContent"/>
            <p:output name="data" id="fileContentChecked"/>
        </p:processor>


        <!-- Convert the XML instance to serialized XML -->
        <p:processor name="oxf:text-serializer">
            <p:input name="config">
                <config>
                    <encoding>utf-8</encoding>
                </config>
            </p:input>
            <p:input name="data" href="#fileContentChecked"/>
            <p:output name="data" id="serializedFile"/>
        </p:processor>

        <!-- Exception catcher - serializing file -->
        <p:processor name="oxf:exception-catcher">
            <p:input name="data" href="#serializedFile"/>
            <p:output name="data" id="serializedFileChecked"/>
        </p:processor>


        <!-- Write file -->
        <p:processor name="oxf:file-serializer">
            <p:input name="config" transform="oxf:xslt"
                href="aggregate('configuration',current(),#parameters)">
                <config xsl:version="2.0">
                    <directory>
                        <xsl:value-of select="//parameters/exportPipeline/exportDirectory"/>
                    </directory>
                    <file>
                        <xsl:value-of select="configuration/file/@name"/>
                    </file>
                    <make-directories>true</make-directories>
                    <append>false</append>
                </config>
            </p:input>
            <p:input name="data" href="#serializedFileChecked"/>
        </p:processor>

        <!-- Exception catcher - writing file -->
        <p:processor name="oxf:exception-catcher">
            <p:input name="data" transform="oxf:xslt"
                href="aggregate('configuration',current(),#parameters)">
                <fileWrite xsl:version="2.0">
                    <xsl:value-of select="configuration/file/@name"/>
                </fileWrite>
            </p:input>
            <p:output name="data" id="fileWritehecked"/>
        </p:processor>


        <!-- Delete the file from the watchedDirectory -->
        <p:processor name="oxf:file">
            <p:input name="config" transform="oxf:xslt"
                href="aggregate('configuration',current(),#parameters)">
                <config xsl:version="2.0">
                    <delete>
                        <directory>
                            <xsl:value-of select="//parameters/importPipeline/watchedDirectory"/>
                        </directory>
                        <file>
                            <xsl:value-of select="configuration/file/@name"/>
                        </file>
                    </delete>
                </config>
            </p:input>
        </p:processor>

        <!-- Exception catcher - deleting file -->
        <p:processor name="oxf:exception-catcher">
            <p:input name="data" transform="oxf:xslt"
                href="aggregate('configuration',current(),#parameters)">
                <fileDelete xsl:version="2.0">
                    <xsl:value-of select="configuration/file/@name"/>
                </fileDelete>
            </p:input>
            <p:output name="data" id="fileDeleteChecked"/>
        </p:processor>

        <!-- Report file operations -->
        <p:processor name="oxf:identity">
            <p:input name="data"
                href="aggregate('processedFile',#fileWritehecked,#fileDeleteChecked)"/>
            <p:output name="data" ref="fileOperationChecked"/>
        </p:processor>
    </p:for-each>


    <!-- REST submission to record audit information.
         Write fileOperationChecked to the database each time the pipeline is run -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="#parameters">
            <xf:submission xsl:version="2.0"
                action="{//parameters[@type='session']/resourceHandle}" validate="false"
                method="put" replace="none" includenamespacesprefixes=""/>
        </p:input>
        <p:input name="request" transform="oxf:xslt" href="#fileOperationChecked">
            <schedulerLog xsl:version="2.0"> 
                <timeStamp>
                    <xsl:value-of select="current-dateTime()"/>
                </timeStamp>
                <xsl:copy-of select="fileOperations"/>
            </schedulerLog>
        </p:input>
        <p:output name="response" id="saveResponse"/>
    </p:processor>
    
    
    <!-- Exception catcher - audit information -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="aggregate('status',#saveResponse,#fileOperationChecked)"/>
        <p:output name="data" ref="data"/>
    </p:processor>


</p:pipeline>
