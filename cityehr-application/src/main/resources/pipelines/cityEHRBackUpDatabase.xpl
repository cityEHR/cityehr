<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRBackUpDatabase.xpl
    
    Pipeline to backup the cityEHR database.
    Called with view-parameters as input.
    
    Sets up query to back up using system:export-silently function.
    Sets up and calls:
       
    system:export-silently($dir as xs:string, $incremental as xs:boolean?, $zip as 
    xs:boolean?) as xs:boolean
    
    So can test in cityEHRAdmin runXQuery using:
       
    system:export-silently('export','true','true')    
        
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
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xdb="http://orbeon.org/oxf/xml/xmldb">

    <!-- Input to pipeline is view-parameters.xml -->
    <p:param name="instance" type="input"/>
    
    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Get the system-parameters -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get" action="{systemResourcesURL/@localPrefix}{systemResourcesURL/@storageLocation}{systemResourcesURL/@systemParametersResource}"/>
        </p:input>
        <p:input name="request" href="#instance"/>
        <p:output name="response" id="systemParametersReturned"/>
    </p:processor>
    
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="aggregate('config',#systemParametersReturned,#instance)"/>
        <p:output name="data" id="combinedParameters"/>
    </p:processor>
    
    <!-- Configure data source for query -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <datasource xsl:version="2.0">
                <xsl:variable name="activeXMLstore"
                    select="config/parameters/coreParameters/databaseConfiguration/activeDatabases/xmlstore[@system={config/parameters/backupPipeline/databaseRoot}]"/>
                <xsl:variable name="xmlstore"
                    select="config/parameters/coreParameters/databaseConfiguration/installedDatabases/xmlstore[@value=$activeXMLstore/@value]"/>
                <driver-class-name>org.exist.xmldb.DatabaseImpl</driver-class-name>
                <uri>
                    <xsl:value-of select="$xmlstore/databaseURI"/>
                </uri>
                <username>
                    <xsl:value-of select="$xmlstore/username"/>
                </username>
                <password>
                    <xsl:value-of select="$xmlstore/password"/>
                </password>
            </datasource>
        </p:input>
        <p:input name="data" href="#combinedParameters"/>
        <p:output name="data" id="datasource"/>
    </p:processor>
    
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#datasource"/>
        <p:output name="data" id="datasourceChecked"/>
    </p:processor>

    <!-- Generate query text to backup the specified database root -->
    <!-- Input is the view-parameters. -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <xdb:query xsl:version="2.0" collection="{parameters/backupPipeline/storageLocation}">
                xquery version "1.0"; 
                let $result := system:export-silently('<xsl:value-of select="parameters/backupPipeline/backupDirectory"/>',false(),true()) 
                return
                &lt;result>{$result}&lt;/result> 
            </xdb:query>
        </p:input>
        <p:input name="data" href="#instance"/>
        <p:output name="data" id="query"/>
    </p:processor>

    <!-- Submit query to the xmlstore -->
    <p:processor name="oxf:xmldb-query">
        <p:input name="datasource" href="#datasourceChecked"/>
        <p:input name="query" href="#query"/>
        <p:output name="data" id="queryResponse"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#queryResponse"/>
        <p:output name="data" ref="data"/>
    </p:processor>

</p:pipeline>
