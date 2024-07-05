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

<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Input to pipeline is xml/patient-view-parameters.xml as set in the page-flow.xml file 
         with parameters set in the page element -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Get list of files/folders in watchedDirectory folder.
        <directory name="address-book" path="c:\Documents and Settings\John Doe\OPS\src\examples\web\examples\address-book">
            <file last-modified-ms="1120343217984" last-modified-date="2005-07-03T00:26:57.984" size="961130" path="image0001.jpg" name="image0001.jpg"/>
        </directory>    
         -->
    <p:processor name="oxf:directory-scanner">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <base-directory>
                    <xsl:value-of select="parameters/watchedDirectory"/>
                </base-directory>
                <include> *.* </include>
                <include> */*.* </include>
                <case-sensitive>false</case-sensitive>
            </config>
        </p:input>
        <p:output name="data" id="directoryListing"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#directoryListing"/>
        <p:output name="data" ref="directoryListingChecked"/>
    </p:processor>

    <!-- Iterate through the directoryListing
         Read each file
         -->
    <p:for-each href="#directoryListingChecked" select="//file" root="fileLocations" id="fileInfoChecked">

        <!-- Convert the XML instance to serialized XML -->
        <p:processor name="oxf:text-serializer">
            <p:input name="config">
                <config>
                    <encoding>utf-8</encoding>
                </config>
            </p:input>
            <p:input name="data" href="current()"/>
            <p:output name="data" id="serializedFile"/>
        </p:processor>

        <!-- Write the serializedFile to the processed directory
             File name is passed out on data as <url>...</url>-->
        <p:processor name="oxf:file-serializer">
            <p:input name="config">
                <config>
                    <scope>session</scope>
                </config>
            </p:input>
            <p:input name="data" href="#serializedFile"/>
            <p:output name="data" ref="imageFileLocations"/>
        </p:processor>

        <!-- Remove the file from the watchedDirectory -->
        <p:config xmlns:oxf="http://www.orbeon.com/oxf/processors">
            <p:processor name="oxf:file">
                <p:input name="config">
                    <config>
                        <delete>
                            <file>SomeImpossibleFileName.jpg</file>
                            <directory>C:/TEMP</directory>
                        </delete>
                    </config>
                </p:input>
            </p:processor>
        </p:config>

    </p:for-each>

    <!-- Not using the location -->
    <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#imageFileLocations"/>
    </p:processor>


</p:pipeline>
