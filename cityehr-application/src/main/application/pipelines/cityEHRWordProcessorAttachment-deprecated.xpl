<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRWordProcessorAttachment.xpl
    
    Pipeline to generate an attachment in ODF or MS Word format.
    
    The process is:
    
    1) Get the attachment template (ODF or MS Word)
    2) Unzip the template
    3) Get the document content file (file location depends on whether ODF or MS Word)
    4) Extract the cityEHR:variable values
    5) Construct query to get values
    6) Run query to return the values for this patient
    7) Run transformation to replace variables in the template content
    8) Write the new template content to temporary file
    9) Rezip the attachement, using the new template content
    10) Serialize to return to browser
    
    
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

    <!-- Get the template word processor document.
         The location of the template is set in the attachmentTemplateURL parameter -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="parameters/attachmentTemplateURL"/>
                </url>
                <content-type>multipart/x-zip</content-type>
            </config>
        </p:input>
        <p:output name="data" id="attachmentTemplate"/>
    </p:processor>


    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#attachmentTemplate"/>
        <p:output name="data" id="attachmentTemplateChecked"/>
    </p:processor>

    <!-- Unzip template word processor document.
         The contents are put into temporary files.
         Output <files> element specfies the location.
         
         <files>
             <file name="file1.txt" size="123" dateTime="2007-09-11T18:23:04">file:///tmp/somefile.txt</file>
             <file name="dir/file2.txt" size="456" dateTime="2007-09-11T18:23:04">file:///tmp/someotherfile.txt</file>
         </files>
    -->
    <p:processor name="oxf:unzip">
        <p:input name="data" href="#attachmentTemplateChecked"/>
        <p:output name="data" id="zipManifest"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#zipManifest"/>
        <p:output name="data" id="zipManifestChecked"/>
    </p:processor>

    <!-- Get the document content from the unzipped word processor template
         This is the WordML file document.xml or the ODF file content.xml   
         Used as the template for generating the output document -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#zipManifestChecked">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="files/file[@name=('word/document.xml','content.xml')]"/>
                </url>
                <content-type>application/xml</content-type>
            </config>
        </p:input>
        <p:output name="data" id="attachmentTemplateContent"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#attachmentTemplateContent"/>
        <p:output name="data" id="attachmentTemplateContentChecked"/>
    </p:processor>

    <!-- Extract variables from the attachment template -->
    <!-- Inputs are the attachmentTemplate and the view-parameters. -->
    <!--
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/HTML2WordML.xsl"/>
        <p:input name="data" href="#html"/>
        <p:input name="parameters" href="#instance"/>
        <p:input name="wordTemplate" href="#wordTemplate"/>
        <p:input name="image-file-info" href="#image-file-info"/>
        <p:output name="data" id="wordMLdocument"/>
    </p:processor>
    -->

    <!-- Construct the query to find values of the variables -->

    <!-- Run the query to get the values -->

    <!-- Replace variable values in the attachmentTemplate -->


    <!-- Convert the attachmentTemplate document instance to serialized XML.
         Note that the indent element is needed to prevent the serializer inserting whitspace in the output -->
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
                <indent>false</indent>
            </config>
        </p:input>
        <p:input name="data" href="#attachmentTemplateContentChecked"/>
        <p:output name="data" id="serializedAttachmentContent"/>
    </p:processor>

    <!-- Write the attachmentTemplate document to a temporary file.
         File name is passed out on data as <url>...</url>-->
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#serializedAttachmentContent"/>
        <p:output name="data" id="attachmentDocumentLocation"/>
    </p:processor>

    <!-- Zip complete document to create word processor file.
         This is either ODF or MS Word, depending on the format of the template -->
    <p:processor name="oxf:zip">
        <p:input name="data" transform="oxf:xslt" href="aggregate('zipData',#zipManifestChecked,#attachmentDocumentLocation)">
            <files xsl:version="2.0">
                <xsl:copy-of select="zipData/files/file[not(@name=('word/document.xml','content.xml'))]"/>
                <!-- Add content - depends on whether ODF or MS Word -->
                <xsl:if test="exists(zipData/files/file[@name='word/document.xml'])">
                    <file name="word/document.xml">
                        <xsl:value-of select="zipData/url[1]"/>
                    </file>
                </xsl:if>
                <xsl:if test="exists(zipData/files/file[@name='content.xml'])">
                    <file name="content.xml">
                        <xsl:value-of select="zipData/url[1]"/>
                    </file>
                </xsl:if>
            </files>
        </p:input>
        <p:output name="data" id="zipped-doc"/>
    </p:processor>

    <!-- Serialize to return to browser.
         The filename is concatenated from:
           patientId
           suffix set in view-parameters.xml
           current time stamp
    
          The file extension and content type depend on whether ODF or MS Word
    -->
    <p:choose href="#zipManifestChecked">
        <!-- MS Word -->
        <p:when test="exists(files/file[@name='word/document.xml'])">
            <p:processor name="oxf:http-serializer">
                <p:input name="config" transform="oxf:xslt" href="#instance">
                    <config xsl:version="2.0">
                        <header>
                            <name>Content-Disposition</name>
                            <value>attachement; filename=<xsl:value-of select="parameters/externalId"/>.docx</value>
                        </header>
                        <content-type>application/vnd.openxmlformats-officedocument.wordprocessingml.document</content-type>
                        <force-content-type>true</force-content-type>
                    </config>
                </p:input>
                <p:input name="data" href="#zipped-doc"/>
            </p:processor>
        </p:when>

        <!-- ODF -->
        <p:when test="exists(files/file[@name='content.xml'])">
            <p:processor name="oxf:http-serializer">
                <p:input name="config" transform="oxf:xslt" href="#instance">
                    <config xsl:version="2.0">
                        <header>
                            <name>Content-Disposition</name>
                            <value>attachement; filename=<xsl:value-of select="parameters/externalId"/>.odt</value>
                        </header>
                        <content-type>application/vnd.oasis.opendocument.text</content-type>
                        <force-content-type>true</force-content-type>
                    </config>
                </p:input>
                <p:input name="data" href="#zipped-doc"/>
            </p:processor>
        </p:when>

        <!-- Not a recognised format -->
        <p:otherwise>
            <p:processor name="oxf:null-serializer">
                <p:input name="data" href="#zipped-doc"/>
            </p:processor>

            <!-- Genertate xml error -->
            <p:processor name="oxf:xml-converter">
                <p:input name="config">
                    <config/>
                </p:input>
                <p:input name="data" transform="oxf:xslt" href="aggregate('errorInfo',#instance,#zipManifestChecked)">
                    <error xsl:version="2.0">
                        <message>
                            An error has occurred loading: <xsl:value-of select="errorInfo/parameters/attachmentTemplateURL"/>
                        </message>
                        <details>
                            <xsl:copy-of select="errorInfo/*[2]"/>
                        </details>
                    </error>
                </p:input>
                <p:output name="data" id="converted"/>
            </p:processor>

            <!-- Return error to browser -->
            <p:processor name="oxf:http-serializer">
                <p:input name="config">
                    <config>
                        <status-code>500</status-code>
                    </config>
                </p:input>
                <p:input name="data" href="#converted"/>
            </p:processor>

        </p:otherwise>

    </p:choose>

</p:pipeline>
