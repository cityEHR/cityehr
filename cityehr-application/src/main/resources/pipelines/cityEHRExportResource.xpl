<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRExportResource
    
    Pipleline to export a resource from the cityEHR xmlstore and return as a zipped file to the browser
    The database location of the resource is passed in xmlCacheHandle and the transformation in transformationXSL
    
    Invokes the readResource.xpl pipeline to
        Read the resource from the specified xmlCacheHandle
        The resource is transformed using transformationXSL (passed without a .xsl extension) if specified
        
    The externalId and resourceFileExtension are used to create the file name exported
    
    The file is zipped up and returned to the browser.
    
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

    <!-- Run the readResource pipeline.
         Returns the resource from the database, transformed if necessary
         Input to pipeline is the combined parameters as returned by getPipelineParameters.xpl
         The database location of the resource is passed in xmlCacheHandle
         The resource is transformed using transformationXSL (passed without a .xsl extension) if specified -->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="readResource.xpl"/>
        <p:input name="parameters" href="#parameters"/>
        <p:output name="serializedResource" id="serializedResourceReturned"/>
    </p:processor>
    
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#serializedResourceReturned"/>
        <p:output name="data" id="serializedResource"/>
    </p:processor>
    
   
    <!-- Write the document to a temporary file. 
         File name is passed out on data as <url>...</url>-->
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#serializedResource"/>
        <p:output name="data" id="exportFileLocation"/>
    </p:processor>

    <!-- Zip complete document -->
    <p:processor name="oxf:zip">
        <p:input name="data" transform="oxf:xslt" href="aggregate('config',#exportFileLocation,#parameters)">
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
        <p:output name="data" id="zipped-doc"/>
    </p:processor>

    <!-- Serialize to return to browser.
        The filename is concatenated from:
        patientId
        suffix set in view-parameters.xml
        current time stamp -->
    <p:processor name="oxf:http-serializer">
        <p:input name="config" transform="oxf:xslt" href="#parameters">
            <config xsl:version="2.0">
                <xsl:variable name="fileName"
                    select="if (//parameters[@type='session']/externalId!='') then //parameters[@type='session']/externalId else concat(replace(replace(string(current-dateTime()),':','-'),'\+','*'),'-cityEHR-export')"/>
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=<xsl:value-of select="concat($fileName,'.zip')"/></value>
                </header>
                <content-type>application/zip</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#zipped-doc"/>
    </p:processor>

</p:pipeline>
