<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRDownloadResources.xpl
    
    Pipeline to zip up the server directory specified in parameters/resourceDirectory and return to the browser
    Input is view-parameters with resourceDirectory and externalId set
    
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

    <!-- Input to pipeline is view-parameters.xml as set in the page-flow.xml file 
         with parameters set in the page element -->
    <p:param name="instance" type="input"/>

    <!-- Run the getPipelineParameters pipeline.
         Returns the combined application-parameters, session-parameters, system-parameters, database-parameters,  view-parameters -->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="getPipelineParameters.xpl"/>
        <p:input name="instance" href="#instance"/>
        <p:output name="parameters" id="parameters"/>
    </p:processor>


    <!-- Get list of files/folders in specified folder -->
    <p:processor name="oxf:directory-scanner">
        <p:input name="config" transform="oxf:xslt" href="#parameters">
            <config xsl:version="2.0">
                <base-directory>../resources/userResources</base-directory>
                <include> *.* </include>
                <include> */*.* </include>
                <case-sensitive>false</case-sensitive>
            </config>
        </p:input>
        <p:output name="data" id="fileInfo"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#fileInfo"/>
        <p:output name="data" id="fileInfo-checked"/>
    </p:processor>


    <p:processor name="oxf:identity">
        <p:input name="data" transform="oxf:xslt" href="#fileInfo-checked">
            <files xsl:version="2.0">
                <xsl:variable name="basePath" select="directory[1]/@path"/>
                <xsl:value-of select="$basePath"/>
                
                <xsl:for-each select="//file">
                    <xsl:variable name="file" select="."/>
                    <file name="{$file/@path}">
                        <xsl:value-of select="concat('file:',$basePath,'/',$file/@path)"/>
                    </file>
                </xsl:for-each>

            </files>
        </p:input>
        <p:output name="data" id="manifest"/>
    </p:processor>

    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#manifest"/>
        <p:output name="data" id="manifest-checked"/>
    </p:processor>

<!-- These nest processors for testing -->
    <!--
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" href="#manifest-checked"/>
        <p:output name="data" id="serializedResource"/>
    </p:processor>

    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#serializedResource"/>
        <p:output name="data" id="exportFileLocation"/>
    </p:processor>

    <p:processor name="oxf:zip">
        <p:input name="data" transform="oxf:xslt"
            href="aggregate('config',#exportFileLocation,#parameters)">
            <files xsl:version="2.0">
                <xsl:variable name="fileName"
                    select="if (//parameters[@type='session']/externalId!='') then //parameters[@type='session']/externalId else concat(replace(replace(string(current-dateTime()),':','-'),'\+','*'),'-cityEHR-export')"/>
                <xsl:variable name="fileExtension"
                    select="if (//parameters[@type='session']/resourceFileExtension!='') then //parameters[@type='session']/resourceFileExtension else 'xml'"/>
                <file name="{$fileName}.{$fileExtension}">
                    <xsl:value-of select="config/url"/>
                </file>
            </files>
        </p:input>
        <p:output name="data" id="zippedFolder"/>
    </p:processor>
-->

    <!-- Zip complete list of files --> 
    <p:processor name="oxf:zip">
        <p:input name="data"  href="#manifest-checked"/>
        <p:output name="data" id="zippedFolder"/>
    </p:processor>


    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#zippedFolder"/>
        <p:output name="data" id="zippedFolder-checked"/>
    </p:processor>


    <!-- Serialize to return to browser.
         The filename is set from externalId or current-dataTime() -->
    <p:processor name="oxf:http-serializer">
        <p:input name="config" transform="oxf:xslt" href="#parameters">
            <config xsl:version="2.0">
                <xsl:variable name="fileName"
                    select="if (//parameters[@type='session']/externalId!='') then //parameters[@type='session']/externalId else concat(replace(replace(string(current-dateTime()),':','-'),'\+','*'),'-cityEHR-export')"/>
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=<xsl:value-of select="concat($fileName,'.zip')"
                        /></value>
                </header>
                <content-type>application/zip</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#zippedFolder-checked"/>
    </p:processor>

</p:pipeline>
