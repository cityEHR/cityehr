<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRExportResourceAsODFSpreadsheet.xpl
    
    Pipleline to export a resource from the cityEHR xmlstore as an ODF spreadsheet
    Parameters are passed in:
        resourceHandle - the database resource
        externalId - the id for the generated file
        templateURL - the URL (file location) of the template ODF spreadsheet
        transformationXSL - the XSLT to use for transforming the resource to the ODF content file
    
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

    <!-- Standard pipeline output.
        Not needed for this pipeline since it runs as a 'model' and serializes its output back to the bowser -->
    <!--
        <p:param name="data" type="output"/>
    -->


    <!-- URL Generator with REST to get XML document for the resource -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="parameters/resourceHandle"/>
                </url>
                <content-type>application/xml</content-type>
            </config>
        </p:input>
        <p:output name="response" id="ehrResource"/>
    </p:processor>


    <!-- Get the template spreadsheet document.
         The location of the template is set in the templateURL parameter. -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="parameters/appPath"/>
                    <xsl:value-of select="parameters/templateURL"
                    />
                </url>
                <content-type>multipart/x-zip</content-type>
            </config>
        </p:input>
        <p:output name="data" id="zip"/>
    </p:processor> 

    <!-- Unzip template spreadsheet document.
        The contents are put into temporary files.
        Output <files> element specfies the location.
    -->
    <p:processor name="oxf:unzip">
        <p:input name="data" href="#zip"/>
        <p:output name="data" id="zip-file-list-return"/>
    </p:processor>


    <!-- Catch exception if anything goes wrong unzipping the template -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#zip-file-list-return"/>
        <p:output name="data" id="zip-file-list"/>
    </p:processor>
    

    <!-- Get the XSLT for the transformation
    The location of the XSLT is set in the transformationXSL parameter -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <url>
                    ../xslt/<xsl:value-of select="parameters/transformationXSL"/>
                </url>
                <content-type>application/xml</content-type>
            </config>
        </p:input>
        <p:output name="data" id="stylesheetReturn"/>
    </p:processor>

    <!-- Catch exception if anything goes wrong loading the stylesheet -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#stylesheetReturn"/>
        <p:output name="data" id="stylesheet"/>
    </p:processor>


    <!-- Get the content.xml file from the unzipped spreadsheet template 
    This is used as the template for generating the output document -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#zip-file-list">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="files/file[@name='content.xml']"/>
                </url>
                <content-type>application/xml</content-type>
            </config>
        </p:input>
        <p:output name="data" id="spreadsheetTemplateReturn"/>
    </p:processor>
    
    <!-- Catch exception if anything goes wrong getting content.xml -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#spreadsheetTemplateReturn"/>
        <p:output name="data" id="spreadsheetTemplate"/>
    </p:processor>


    <!-- Generate spreadsheet document (content.xml) from the resource  -->
    <!-- Inputs are the resource to be output, the template content and the view-parameters. -->
    <p:processor name="oxf:xslt">
        <p:input name="config" href="#stylesheet"/>
        <p:input name="data" href="#ehrResource"/>
        <p:input name="parameters" href="#instance"/>
        <p:input name="spreadsheetTemplate" href="#spreadsheetTemplate"/>
        <p:output name="data" id="spreadsheetContentResult"/>
    </p:processor>

    <!-- Catch exception if anything goes wrong with the transformation -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#spreadsheetContentResult"/>
        <p:output name="data" id="spreadsheetContent"/>
    </p:processor>


    <!-- Convert the content document instance to serialized XML.
    Note that the indent element is needed to prevent the serializer inserting whitspace in the output -->
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
                <indent>false</indent>
            </config>
        </p:input>
        <p:input name="data" href="#spreadsheetContent"/>
        <p:output name="data" id="serializedSpreadsheetContent"/>
    </p:processor>
 

    <!-- Write the spreadsheet content to a temporary file.
    File name is passed out on data as <url>...</url>-->
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#serializedSpreadsheetContent"/>
        <p:output name="data" id="spreadsheetContentLocation"/>
    </p:processor>

    <!-- Zip complete document to create spreadsheet file -->
    <p:processor name="oxf:zip">
        <p:input name="data" transform="oxf:xslt"
            href="aggregate('zipData',#zip-file-list,#spreadsheetContentLocation)">
            <files xsl:version="2.0">
                <xsl:copy-of select="zipData/files/file[not(@name='content.xml')]"/>
                <file name="content.xml">
                    <xsl:value-of select="zipData/url[1]"/>
                </file>
            </files>
        </p:input>
        <p:output name="data" id="zipped-doc"/>
    </p:processor>

    <!-- Serialize to return to browser.
    The filename is set in externalId -->
    <p:processor name="oxf:http-serializer">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=<xsl:value-of
                        select="parameters/externalId"/>.ods</value>
                </header>
                <content-type>application/vnd.oasis.opendocument.spreadsheet</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#zipped-doc"/>
    </p:processor> 


</p:pipeline>
