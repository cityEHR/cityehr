<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRExportCohortData.xpl
    
    Pipeline to assemble data for a cohort of patients and return in the specified format.
    Input is view-parameters on #instance
    Format is specified in #instance/parameters/exportPipeline/exportDataFormat as one of:
        xml
        odf-spreadsheet
        ms-spreadsheet
        
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
        <p:input name="data" href="#systemParametersReturned"/>
        <p:output name="data" id="systemParameters"/>
    </p:processor>
    
    <!-- Configure data source for query -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <datasource xsl:version="2.0">
                <xsl:variable name="activeXMLstore"
                    select="parameters/coreParameters/databaseConfiguration/activeDatabases/xmlstore[@system='ehr']"/>
                <xsl:variable name="xmlstore"
                    select="parameters/coreParameters/databaseConfiguration/installedDatabases/xmlstore[@value=$activeXMLstore/@value]"/>
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
        <p:input name="data" href="#systemParameters"/>
        <p:output name="data" id="datasourceGenerated"/>
    </p:processor>
    
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#datasourceGenerated"/>
        <p:output name="data" id="datasource"/>
    </p:processor>

    <!-- Generate query text -->
    <!-- Input is the view-parameters. -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <xdb:query xsl:version="2.0" collection="{parameters/exportPipeline/queryContext}">
                <xsl:value-of select="parameters/exportPipeline/queryText"/>
            </xdb:query>
        </p:input>
        <p:input name="data" href="#instance"/>
        <p:output name="data" id="query"/>
    </p:processor>

    <!-- Submit query to the xmlstore -->
    <p:processor name="oxf:xmldb-query">
        <p:input name="datasource" href="#datasource"/>
        <p:input name="query" href="#query"/>
        <p:output name="data" id="queryResponse"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#queryResponse"/>
        <p:output name="data" id="queryResponse-checked"/>
    </p:processor>
    
    <!-- Execute REST submission to get the data dictionary-->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="#instance">
            <xf:submission  xsl:version="2.0"  serialization="none" method="get" action="{parameters/dictionaryHandle}"/>
        </p:input>
        <p:input name="request" href="#instance"/>
        <p:output name="response" id="dictionaryReturn"/>
    </p:processor>
    
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#dictionaryReturn"/>
        <p:output name="data" id="dictionary"/>
    </p:processor>    
    
    <!-- Transformation to anonymise data.
         If an exception was raised then this transformation just passes input straight through -->
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/AnonymiseDataSet.xsl"/>
        <p:input name="data" href="#queryResponse-checked"/>
        <p:input name="parameters" href="#instance"/>
        <p:output name="data" id="anonymisedData"/>
    </p:processor>
    

    <!-- Check whether we had an exception.
         If so, then just return an error.
         If not, then the query should have returned a valid XML document.
          -->
    <p:choose href="#anonymisedData">
        <!-- Exception thrown by xquery processor -->
        <p:when test="//exceptions">
            <!-- Produce an error message -->
            <p:processor name="oxf:xslt">
                <p:input name="config">
                    <errorMessage xsl:version="2.0">
                        <error>
                            <xsl:value-of select="(//method-name)[1]"/>
                        </error>
                    </errorMessage>
                </p:input>
                <p:input name="data" href="#queryResponse-checked"/>
                <p:output name="data" id="errorMessage"/>
            </p:processor>
            <!-- Serialize to XML -->
            <p:processor name="oxf:xml-converter">
                <p:input name="config">
                    <config/>
                </p:input>
                <p:input name="data" href="#errorMessage"/>
                <p:output name="data" id="errorMessage-xml"/>
            </p:processor>
            <!-- Send response -->
            <p:processor name="oxf:http-serializer">
                <p:input name="config">
                    <config>
                        <status-code>500</status-code>
                    </config>
                </p:input>
                <p:input name="data" href="#errorMessage-xml"/>
            </p:processor>
        </p:when>

        <!-- Otherwise process the query response.
             Processing depends on the exportDataFormat -->
        <p:otherwise>
            <p:choose href="#instance">
                <p:when test="parameters/exportPipeline/exportDataFormat='xml'">
                    <!-- Serialize the XML document produced by the query
                         to a textual representation of XML -->
                    <p:processor name="oxf:xml-converter">
                        <p:input name="config">
                            <config>
                                <encoding>utf-8</encoding>
                            </config>
                        </p:input>
                        <p:input name="data" href="#queryResponse-checked"/>
                        <p:output name="data" id="queryResponseDocument"/>
                    </p:processor>

                    <!-- Write the document to a temporary file. 
                         File name is passed out on data as <url>...</url>-->
                    <p:processor name="oxf:file-serializer">
                        <p:input name="config">
                            <config>
                                <scope>session</scope>
                            </config>
                        </p:input>
                        <p:input name="data" href="#queryResponseDocument"/>
                        <p:output name="data" id="exportLocation"/>
                    </p:processor>

                    <!-- Zip complete document -->
                    <p:processor name="oxf:zip">
                        <p:input name="data" transform="oxf:xslt"
                            href="aggregate('config',#instance,#exportLocation)">
                            <files xsl:version="2.0">
                                <file name="{config/parameters/externalId}.xml">
                                    <xsl:value-of select="config/url"/>
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
                                            select="parameters/externalId"/>.zip</value>
                                </header>
                                <content-type>application/zip</content-type>
                                <force-content-type>true</force-content-type>
                            </config>
                        </p:input>
                        <p:input name="data" href="#zipped-doc"/>
                    </p:processor>
                </p:when>

                <!-- ODF Spreadsheet -->
                <p:when test="parameters/exportPipeline/exportDataFormat='odf-spreadsheet'">
                    <!-- Get the template spreadsheet document.
                         The location of the template is set in the exportCohortDataODFTemplateURL parameter -->
                    <p:processor name="oxf:url-generator">
                        <p:input name="config" transform="oxf:xslt" href="#instance">
                            <config xsl:version="2.0">
                                <url>
                                    <xsl:value-of select="parameters/appPath"/>
                                    <xsl:value-of select="parameters/exportCohortDataODFTemplateURL"
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
                        <p:output name="data" id="zip-file-list"/>
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
                        <p:output name="data" id="spreadsheetTemplate"/>
                    </p:processor>

                    <!-- Generate spreadsheet document (content.xml) from dataSet  -->
                    <!-- Inputs are the dataSet to be rendered, the template content and the view-parameters. -->
                    <p:processor name="oxf:xslt">
                        <p:input name="config" href="../xslt/DataSet2Spreadsheet.xsl"/>
                        <p:input name="data" href="#anonymisedData"/>
                        <p:input name="parameters" href="#instance"/>
                        <p:input name="spreadsheetTemplate" href="#spreadsheetTemplate"/>
                        <p:input name="dictionary" href="#dictionary"/>
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
                </p:when>

                <!-- MS Spreadsheet -->
                <p:when test="parameters/exportPipeline/exportDataFormat='ms-spreadsheet'">
                    <!-- Get the template spreadsheet document.
                        The location of the template is set in the exportCohortDataMSTemplateURL parameter -->
                    <p:processor name="oxf:url-generator">
                        <p:input name="config" transform="oxf:xslt" href="#instance">
                            <config xsl:version="2.0">
                                <url>
                                    <xsl:value-of select="parameters/appPath"/>
                                    <xsl:value-of select="parameters/exportCohortDataMSTemplateURL"
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
                        <p:output name="data" id="zip-file-list"/>
                    </p:processor>

                    <!-- Get the required files from the unzipped spreadsheet template 
                         These are used as the templates for generating the output documents.
                         We are interested in:
                                docProps/app.xml
                                xl/_rels/workbook.xml.rels
                                xl/worksheets/sheet1.xml
                                xl/workbook.xml
                                [Content_Types].xml
                    -->
                    <p:for-each href="#zip-file-list"
                        select="files/file[@name=('docProps/app.xml','xl/_rels/workbook.xml.rels','xl/worksheets/sheet1.xml','xl/workbook.xml','[Content_Types].xml')]"
                        root="spreadsheetML" id="spreadsheetTemplate">
                        <p:processor name="oxf:url-generator">
                            <p:input name="config" transform="oxf:xslt" href="current()">
                                <config xsl:version="2.0">
                                    <url>
                                        <xsl:value-of select="file"/>
                                    </url>
                                    <content-type>application/xml</content-type>
                                </config>
                            </p:input>
                            <p:output name="data" ref="spreadsheetTemplate"/>
                        </p:processor>
                    </p:for-each>

                    <!-- Generate spreadsheet document from dataSet  -->
                    <!-- Inputs are the dataSet to be rendered, the template content and the view-parameters.
                         The output spreadsheet contains the set of sheets and relationships that must be split into separate files -->
                    <p:processor name="oxf:xslt">
                        <p:input name="config" href="../xslt/DataSet2Spreadsheet.xsl"/>
                        <p:input name="data" href="#anonymisedData"/>
                        <p:input name="parameters" href="#instance"/>
                        <p:input name="spreadsheetTemplate" href="#spreadsheetTemplate"/>
                        <p:input name="dictionary" href="#dictionary"/>
                        <p:output name="data" id="spreadsheetContent"/>
                    </p:processor>

                    <!-- Iterate through the spreadsheetContent, writing to separate files
                         There should be a set of file elements, each containing the content to be writen
                         The name of the file is extracted from the filename attribute -->
                    <p:for-each href="#spreadsheetContent" select="spreadsheetML/file/*"
                        root="spreadsheetFileList" id="spreadsheetFileList">

                        <!-- Convert the spreadsheetML content to serialized XML.
                             Note that the indent element is needed to prevent the serializer inserting whitspace in the output -->
                        <p:processor name="oxf:xml-serializer">
                            <p:input name="config">
                                <config>
                                    <encoding>utf-8</encoding>
                                    <indent>false</indent>
                                </config>
                            </p:input>
                            <p:input name="data" href="current()"/>
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
                            <p:output name="data" ref="spreadsheetFileList"/>
                        </p:processor>
                    </p:for-each>

                    <!-- Debugging - Return zip of debug information -->
                    <!--  
                    <p:processor name="oxf:xml-serializer">
                        <p:input name="config">
                            <config>
                                <encoding>utf-8</encoding>
                                <indent>false</indent>
                            </config>
                        </p:input>
                        <p:input name="data" href="aggregate('zipData',#zip-file-list,#spreadsheetContent,#spreadsheetFileList)"/>
                        <p:output name="data" id="serializedDebugData"/>
                    </p:processor>
                    
                    <p:processor name="oxf:file-serializer">
                        <p:input name="config">
                            <config>
                                <scope>session</scope>
                            </config>
                        </p:input>
                        <p:input name="data" href="#serializedDebugData"/>
                        <p:output name="data" id="debug"/>
                    </p:processor>
                    
                    <p:processor name="oxf:zip">
                        <p:input name="data" transform="oxf:xslt"
                            href="#debug">
                            <files xsl:version="2.0">
                                    <file name="debug.xml">
                                        <xsl:value-of select="url"/>
                                    </file>
                            </files>
                        </p:input>
                        <p:output name="data" id="zipped-doc"/>
                    </p:processor>
                    -->

                    <!-- Debug - Consume spreadsheetFileList and return zip of the original spreadsheet content -->
                    <!--
                    <p:processor name="oxf:null-serializer">
                        <p:input name="data" href="#spreadsheetFileList"/>
                    </p:processor>
                    <p:processor name="oxf:zip">
                        <p:input name="data" href="#zip-file-list"/>
                        <p:output name="data" id="zipped-doc"/>
                    </p:processor>
                    -->

                    <!-- Zip complete document to create spreadsheet file -->
                    <p:processor name="oxf:zip">
                        <p:input name="data" transform="oxf:xslt"
                            href="aggregate('zipData',#zip-file-list,#spreadsheetContent,#spreadsheetFileList)">
                            <files xsl:version="2.0">
                                <xsl:variable name="zipData" select="zipData"/>

                                <xsl:copy-of
                                    select="zipData/files/file[not(@name=('docProps/app.xml','xl/_rels/workbook.xml.rels','xl/worksheets/sheet1.xml','xl/workbook.xml','[Content_Types].xml'))]"/>

                                <xsl:for-each select="zipData/spreadsheetFileList/url">
                                    <xsl:variable name="url" select="."/>
                                    <xsl:variable name="position" select="position()"/>
                                    <xsl:variable name="fileName"
                                        select="$zipData/spreadsheetML/file[position()=$position]/@name"/>
                                    <file name="{$fileName}">
                                        <xsl:value-of select="$url"/>
                                    </file>
                                </xsl:for-each>
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
                                            select="parameters/externalId"/>.xlsx</value>
                                </header>
                                <content-type>application/vnd.openxmlformats-officedocument.spreadsheetml.sheet</content-type>
                                <force-content-type>true</force-content-type>
                            </config>
                        </p:input>
                        <p:input name="data" href="#zipped-doc"/>
                    </p:processor>
                </p:when>

                <!-- Not a recognised format - just consume the query response -->
                <p:otherwise>
                    <p:processor name="oxf:null-serializer">
                        <p:input name="data" href="#queryResponse-checked"/>
                    </p:processor>
                </p:otherwise>
            </p:choose>
        </p:otherwise>
    </p:choose>

</p:pipeline>
