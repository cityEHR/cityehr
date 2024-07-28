<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRGetUploadedData.xpl
    
    Pipeline to get data content from a file uploaded by the user.
    Input is the view-paraemters, with sourceHandle set.
    
    If the file is not a zip file, then check to see if its XML or plain text
    If the file is a zip which is an ODF document then unzip and transform its content to cityEHR database format.
    If the file is a zip which is an MS document then unzip, aggregate its content (which is in separate files) and transform to cityEHR database format.
    If the file is a zip of a single XML file then return it
    If the file is a zip of multiple files then return the list
    
    Otherwise send back an exception.
    
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
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:office2003Spreadsheet="urn:schemas-microsoft-com:office:spreadsheet"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0">

    <!-- Input to pipeline is xml instance with parameters set in the page element -->
    <p:param name="instance" type="input"/>
    <p:param name="parameters" type="input"/>
    
    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>
    
    <!-- Run the getPipelineParameters pipeline.
         Returns the combined application-parameters, session-parameters, system-parameters, database-parameters,  view-parameters -->
    <!--
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="getPipelineParameters.xpl"/>               
        <p:input name="instance" href="#view-parameters"/>
        <p:output name="parameters" id="parameters"/>
    </p:processor>
    -->

    <!-- Get the uploaded document.
         The location of the document is set in view-parameters/sourceHandle. -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#parameters">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="//sourceHandle[1]"/>
                </url>
                <content-type>multipart/x-zip</content-type>
            </config>
        </p:input>
        <p:output name="data" id="zipFile"/>
    </p:processor>

    <!-- Try to unzip it -->
    <p:processor name="oxf:unzip">
        <p:input name="data" href="#zipFile"/>
        <p:output name="data" id="zip-file-list"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#zip-file-list"/>
        <p:output name="data" id="zip-file-list-checked"/>
    </p:processor>

    <!-- Check whether we had an exception.
         If there was an exception (i.e. not a zip, then try to load XML, then plain text
         If not, get the XML file that we are interested in.
         If that doesn't exist, then just return an error. -->
    <p:choose href="#zip-file-list-checked">
        <!-- Exception thrown by unzip processor -->
        <p:when test="/exceptions">

            <!-- Reload the file to see if its XML without an XML declaration -->
            <p:processor name="oxf:url-generator">
                <p:input name="config" transform="oxf:xslt" href="#parameters">
                    <config xsl:version="2.0">
                        <url>
                            <xsl:value-of select="//sourceHandle[1]"/>
                        </url>
                        <content-type>text/xml</content-type>
                    </config>
                </p:input>
                <p:output name="data" id="xmlFile"/>
            </p:processor>

            <!-- If file is not XML an exception is raised and the exception XML is passed as the output.
                 If file is XML then the exception catcher behaves like the identity processor and passes it straight out -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#xmlFile"/>
                <p:output name="data" id="xmlFileChecked"/>
            </p:processor>

            <!-- Output is the text file, or an exception -->
            <p:choose href="#xmlFileChecked">
                <!-- Exception thrown by url generator, looking for XML -->
                <p:when test="/exceptions">

                    <!-- Don't need to do anything to xmlFileChecked -->
                    <p:processor name="oxf:null-serializer">
                        <p:input name="data" href="#xmlFileChecked"/>
                    </p:processor>

                    <!-- Reload the file to see if its plain text -->
                    <p:processor name="oxf:url-generator">
                        <p:input name="config" transform="oxf:xslt" href="#parameters">
                            <config xsl:version="2.0">
                                <url>
                                    <xsl:value-of select="//sourceHandle[1]"/>
                                </url>
                                <content-type>text/plain</content-type>
                            </config>
                        </p:input>
                        <p:output name="data" id="textFile"/>
                    </p:processor>

                    <!-- If file is not plain text an exception is raised and the exception XML is passed as the output.
                         If file is plain text then the exception catcher behaves like the identity processor and passes it straight out
                         (but as content within a document element) -->
                    <p:processor name="oxf:exception-catcher">
                        <p:input name="data" href="#textFile"/>
                        <p:output name="data" ref="data"/>
                    </p:processor>

                </p:when>

                <!-- Found MS 2003 XML.
                     Transform to cityEHR database format and return 
                     *** Can be disabled to support legacy processing of pre-2018 OWL architecture.
                     New OWL architecture is generated directly from .ods -->
                <p:when test="/office2003Spreadsheet:WorkbookXX">
                    <!-- Run XSLT to convert MS 2003 XML spreadsheet to cityEHR database format -->
                    <p:processor name="oxf:xslt">
                        <p:input name="config" href="../xslt/Spreadsheet2Database.xsl"/>
                        <p:input name="data" href="#xmlFileChecked"/>
                        <p:output name="data" id="databaseContent"/>
                    </p:processor>

                    <!-- Return databaseContent as XML or the exception that was raised in the transformation -->
                    <p:processor name="oxf:exception-catcher">
                        <p:input name="data" href="#databaseContent"/>
                        <p:output name="data" ref="data"/>
                    </p:processor>

                </p:when>

                <!-- URL generator found XML, so return it as output -->
                <p:otherwise>
                    <p:processor name="oxf:identity">
                        <p:input name="data" href="#xmlFileChecked"/>
                        <p:output name="data" ref="data"/>
                    </p:processor>
                </p:otherwise>

            </p:choose>

        </p:when>

        <!-- There was only one file in the zip, and its an XML document -->
        <p:when test="count(files/file) = 1">
            <p:processor name="oxf:url-generator">
                <p:input name="config" transform="oxf:xslt" href="#zip-file-list-checked">
                    <config xsl:version="2.0">
                        <url>
                            <xsl:value-of select="files/file[1]"/>
                        </url>
                        <content-type>text/xml</content-type>
                    </config>
                </p:input>
                <p:output name="data" id="zippedXML"/>
            </p:processor>
            
            <!-- The XML could be a MS 2003 XML spreadsheet -->
            <p:choose href="#zippedXML">
                <p:when test="/office2003Spreadsheet:Workbook">
                    <!-- Run XSLT to convert MS 2003 XML spreadsheet to cityEHR database format -->
                    <p:processor name="oxf:xslt">
                        <p:input name="config" href="../xslt/Spreadsheet2Database.xsl"/>
                        <p:input name="data" href="#zippedXML"/>
                        <p:output name="data" id="databaseContent"/>
                    </p:processor>
                    
                    <!-- Return databaseContent as XML or the exception that was raised in the transformation -->
                    <p:processor name="oxf:exception-catcher">
                        <p:input name="data" href="#databaseContent"/>
                        <p:output name="data" ref="data"/>
                    </p:processor>
                    
                </p:when>
                
                <!-- Just found XML, so return it as output -->
                <p:otherwise>
                    <p:processor name="oxf:identity">
                        <p:input name="data" href="#zippedXML"/>
                        <p:output name="data" ref="data"/>
                    </p:processor>
                </p:otherwise>
                
            </p:choose>
            
        </p:when>

        <!-- There was an ODF spreadsheet, return the content XML -->
        <p:when test="exists(files/file[@name='content.xml'])">
            <!-- Get the spreadsheet content -->
            <p:processor name="oxf:url-generator">
                <p:input name="config" transform="oxf:xslt" href="#zip-file-list-checked">
                    <config xsl:version="2.0">
                        <url>
                            <xsl:value-of select="files/file[@name='content.xml']"/>
                        </url>
                        <content-type>application/xml</content-type>
                    </config>
                </p:input>
                <p:output name="data" id="content"/>
            </p:processor>

            <!-- Run XSLT to convert ODF spreadsheet to cityEHR database format -->
            <p:processor name="oxf:xslt">
                <p:input name="config" href="../xslt/Spreadsheet2Database.xsl"/>
                <p:input name="data" href="#content"/>
                <p:output name="data" id="databaseContent"/>
            </p:processor>

            <!-- Return databaseContent as XML or the exception that was raised in the transformation -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#databaseContent"/>
                <p:output name="data" ref="data"/>
            </p:processor>

        </p:when>

        <!-- There was an MS spreadsheet, return the sharedStrings and worksheets as an aggregated document.
             The for-each iterates through each file listed in the zip
             current() is set to the file element on each iteration 
             aggregates the content in a document with base document element spreadsheetML -->
        <p:when test="exists(files/file[starts-with(@name,'xl/worksheets')])">
            <!-- Get spreadsheet content - aggregate content from the required files -->
            <p:for-each href="#zip-file-list-checked" select="files/file[starts-with(@name,'xl/_rels') or starts-with(@name,'xl/worksheets') or starts-with(@name,'xl/sharedStrings') or starts-with(@name,'xl/workbook')]"
                root="spreadsheetML" id="content">

                <p:processor name="oxf:url-generator">
                    <p:input name="config" transform="oxf:xslt" href="current()">
                        <config xsl:version="2.0">
                            <url>
                                <xsl:value-of select="file"/>
                            </url>
                            <content-type>application/xml</content-type>
                        </config>
                    </p:input>
                    <p:output name="data" id="fileContent"/>
                </p:processor>

                <p:processor name="oxf:xslt">
                    <p:input name="config">
                        <file xsl:version="2.0" name="{config/file/@name}">
                            <xsl:copy-of select="config/*[2]"/>
                        </file>
                    </p:input>
                    <p:input name="data" href="aggregate('config',current(),#fileContent)"/>
                    <p:output name="data" ref="content"/>
                </p:processor>

            </p:for-each>

            <!-- Run XSLT to convert ODF spreadsheet to cityEHR database format -->
            <p:processor name="oxf:xslt">
                <p:input name="config" href="../xslt/Spreadsheet2Database.xsl"/>
                <p:input name="data" href="#content"/>
                <p:output name="data" id="databaseContent"/>
            </p:processor>

            <!-- Return databaseContent as XML or the exception that was raised in the transformation -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#databaseContent"/>
                <p:output name="data" ref="data"/>
            </p:processor>
        </p:when>

        <!-- Anything else, just return the list of files -->
        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data" href="#zip-file-list-checked"/>
                <p:output name="data" ref="data"/>
            </p:processor>
        </p:otherwise>
    </p:choose>


</p:pipeline>
