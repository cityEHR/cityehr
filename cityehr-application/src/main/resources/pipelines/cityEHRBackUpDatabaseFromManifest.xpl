<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRBackUpDatabaseFromManifest.xpl
    
    Pipeline to backup the cityEHR database.
    Called with view-parameters as input.
    The database manifest has been stored in the xmlCache
    
    Manifest is of the form:
    
        <node type="collection" path="">
            <node type="collection" path="">
                <node path="">
                    <node type="resource" path=""/>
                    <node type="resource" path=""/>
                    <node type="resource" path=""/>
                </node>
            </node>
        </node>
        
    Where each path is relative to the databaseLocation.
    
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
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xdb="http://orbeon.org/oxf/xml/xmldb">

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

    <!-- URL Generator with REST to get XML document for the manifest -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="parameters/resourceHandle"/>
                </url>
                <content-type>application/xml</content-type>
            </config>
        </p:input>
        <p:output name="response" id="manifest"/>
    </p:processor>

    <!-- Get databaseLocation from the view-parameters -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <databaseLocation xsl:version="2.0">
                <xsl:value-of select="parameters/databaseLocation"/>
            </databaseLocation>
        </p:input>
        <p:input name="data" href="#instance"/>
        <p:output name="data" id="databaseLocation"/>
    </p:processor>

    <!-- For each resource in the manifest.
            Get resource from database
            Write to file
    
         Returns aggregate of file location and path -->
    <p:for-each href="#manifest" select="//node[@type='resource']" root="fileLocations" id="fileLocations">

        <!-- URL Generator with REST to get XML document for the resource -->
        <p:processor name="oxf:url-generator">
            <p:input name="config" transform="oxf:xslt" href="aggregate('nodeLocation',#databaseLocation,current())">
                <config xsl:version="2.0">
                    <url>
                        <xsl:value-of select="concat(nodeLocation/databaseLocation,nodeLocation/node/@path)"/>
                    </url>
                    <content-type>application/xml</content-type>
                </config>
            </p:input>
            <p:output name="response" id="databaseResource"/>
        </p:processor>

        <!-- Serialize the resource -->
        <p:processor name="oxf:xml-serializer">
            <p:input name="config">
                <config>
                    <encoding>utf-8</encoding>
                </config>
            </p:input>
            <p:input name="data" href="#databaseResource"/>
            <p:output name="data" id="serializedResource"/>
        </p:processor>

        <!-- Write the resource to a temporary file. 
             File name is passed out on data as <url>...</url> -->
        <p:processor name="oxf:file-serializer">
            <p:input name="config">
                <config>
                    <scope>session</scope>
                </config>
            </p:input>
            <p:input name="data" href="#serializedResource"/>
            <p:output name="data" id="fileLocation"/>
        </p:processor>

        <!-- Merge node (current()) and fileLocation and add to fileLocations -->
        <p:processor name="oxf:identity">
            <p:input name="data" href="aggregate('file',current(),#fileLocation)"/>
            <p:output name="data" ref="fileLocations"/>
        </p:processor>

    </p:for-each>


    <!-- Zip complete set of files to create database backup.
         The leading '/' must be removed from the path to make the filename (otherwise zip starts with a nameless folder -->
    <p:processor name="oxf:zip">
        <p:input name="data" transform="oxf:xslt" href="#fileLocations">
            <files xsl:version="2.0">
                <xsl:for-each select="fileLocations/file">
                    <file name="{substring-after(node/@path,'/')}">
                        <xsl:value-of select="url"/>
                    </file>
                </xsl:for-each>
            </files>
        </p:input>
        <p:output name="data" id="zippedDatabase"/>
    </p:processor>

    <!-- Serialize to return to browser.
         The filename is set in the manifest @externalId  -->
    <p:processor name="oxf:http-serializer">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=<xsl:value-of select="parameters/externalId"/>.zip</value>
                </header>
                <content-type>application/zip</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#zippedDatabase"/>
    </p:processor>

</p:pipeline>
