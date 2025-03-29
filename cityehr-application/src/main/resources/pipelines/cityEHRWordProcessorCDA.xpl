<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRWordProcessorCDA.xpl
    
    Pipeline to generate a word processor document from CDA
    Converts the CDA to HTML first
    Then gets the wordprocessor template (MS Word or ODF Text)
    Transforms the HTML to replace the variables in the template
    Then zips back up to return the document
    
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

    <!-- Submission to get XML document for the CDA
         The resourceHandle is for the composition which has been saved in the xnlcache for the user-->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get" action="{//parameters[@type='session']/resourceHandle}"/>
        </p:input>
        <p:input name="request" href="#parameters"/>
        <p:output name="response" id="cdaReturned"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception
         However if there is an exception, it catches it, and you get a serialized form of the exception. -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#cdaReturned"/>
        <p:output name="data" id="cda"/>
    </p:processor>


    <!-- Produce HTML -->
    <!-- Inputs are the composition (CDA) to be rendered and the view-parameters. -->
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/CDA2HTML.xsl"/>
        <p:input name="data" href="#cda"/>
        <p:input name="parameters" href="#parameters"/>
        <p:output name="data" id="htmlReturned"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception
         However if there is an exception, it catches it, and you get a serialized form of the exception. -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#htmlReturned"/>
        <p:output name="data" id="html"/>
    </p:processor>
       
    <!-- Debugging - Write the HTML to a temporary file. 
         File name is passed out on data as <url>...</url>-->
    <!-- Crashes
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#html"/>
        <p:output name="data" id="exportHTMLLocation"/>
    </p:processor>
    <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#exportHTMLLocation"/>
    </p:processor>
    -->
    
    <!-- Debugging - Write the HTML to the htmlCache. -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="#parameters">
            <xf:submission xsl:version="2.0" action="{//parameters[@type='session']/htmlCacheHandle}" validate="false" method="put" replace="none" includenamespacesprefixes=""/>
        </p:input>
        <p:input name="request" href="#html"/>
        <p:output name="response" id="SaveResponse"/>
    </p:processor>
    
    <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#SaveResponse"/>
    </p:processor>
    

    <!-- Get the template word processor document.
         The location of the template is set in the binaryCacheHandle parameter -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get" action="{//parameters[@type='session']/binaryCacheHandle}"/>
        </p:input>
        <p:input name="request" href="#parameters"/>
        <p:output name="response" id="wordProcessorZipReturned"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception
         However if there is an exception, it catches it, and you get a serialized form of the exception. -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#wordProcessorZipReturned"/>
        <p:output name="data" id="wordProcessorZip"/>
    </p:processor>

    <!-- Unzip template wordprocessor document.
         The contents are put into temporary files.
         Output <files> element specfies the location.
         
         <files>
             <file name="file1.txt" size="123" dateTime="2007-09-11T18:23:04">file:///tmp/somefile.txt</file>
             <file name="dir/file2.txt" size="456" dateTime="2007-09-11T18:23:04">file:///tmp/someotherfile.txt</file>
         </files>
    -->
    <p:processor name="oxf:unzip">
        <p:input name="data" href="#wordProcessorZip"/>
        <p:output name="data" id="zip-file-listReturned"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#zip-file-listReturned"/>
        <p:output name="data" id="zip-file-list"/>
    </p:processor>


    <!-- Remaining processing depends on the type of template document found
         Check whether we had an exception.
         If there was an exception (i.e. not a zip) then return the error
         If not, get the XML content file that we are interested in (for .docx or .odt)
         If that doesn't exist, then just return an error. -->
    <p:choose href="#zip-file-list">

        <!-- ====
             There was an ODF document (.odt)
             ==== -->
        <p:when test="exists(files/file[@name='content.xml'])">
            
            <!-- Get the content.xml file from the unzipped word template or the content.xml from an ODF document
                 This is the WordML file used as the template for generating the output document -->
            <p:processor name="oxf:url-generator">
                <p:input name="config" transform="oxf:xslt" href="#zip-file-list">
                    <config xsl:version="2.0">
                        <url>
                            <xsl:value-of select="files/file[@name='content.xml']"/>
                        </url>
                        <content-type>application/xml</content-type>
                    </config>
                </p:input>
                <p:output name="data" id="odfTemplateReturned"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#odfTemplateReturned"/>
                <p:output name="data" id="odfTemplate"/>
            </p:processor>
            
            <!-- Replace variables in the ODF template -->
            <p:processor name="oxf:xslt">
                <p:input name="config" href="../xslt/WordProcessorReplaceVariables.xsl"/>
                <p:input name="data" href="#odfTemplate"/>
                <p:input name="parameters" href="#parameters"/>
                <p:input name="html" href="#html"/>
                <p:input name="image-file-info">
                    <blank/>
                </p:input>
                <p:output name="data" id="odfContentReturned"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#odfContentReturned"/>
                <p:output name="data" id="odfContent"/>
            </p:processor>
            
            <p:choose href="#odfContent">
                <!-- There was an error in the transformation.-->
                <p:when test="/exceptions">
                    
                    <!-- Serialize the error -->
                    <p:processor name="oxf:xml-serializer">
                        <p:input name="config">
                            <config>
                                <encoding>utf-8</encoding>
                            </config>
                        </p:input>
                        <p:input name="data" href="#odfContent"/>
                        <p:output name="data" id="serializedError"/>
                    </p:processor>
                    
                    <!-- Write the error content to a temporary file.
                         File name is passed out on data as <url>...</url> -->
                    <p:processor name="oxf:file-serializer">
                        <p:input name="config">
                            <config>
                                <scope>session</scope>
                            </config>
                        </p:input>
                        <p:input name="data" href="#serializedError"/>
                        <p:output name="data" id="errorLocation"/>
                    </p:processor>
                    
                    <!-- Zip the error file -->
                    <p:processor name="oxf:zip">
                        <p:input name="data" transform="oxf:xslt" href="#errorLocation">
                            <files xsl:version="2.0">
                                <file name="error.xml">
                                    <xsl:value-of select="url"/>
                                </file>
                            </files>
                        </p:input>
                        <p:output name="data" id="zippedError"/>
                    </p:processor>
                    
                    <!-- Return the exceptions XML to the browser -->
                    <p:processor name="oxf:http-serializer">
                        <p:input name="config">
                            <config>
                                <header>
                                    <name>Content-Disposition</name>
                                    <value>attachement; filename=error.zip</value>
                                </header>
                                <content-type>application/zip</content-type>
                                <force-content-type>true</force-content-type>
                            </config>
                        </p:input>
                        <p:input name="data" href="#zippedError"/>
                    </p:processor>
                    
                </p:when>
                
                
                <!-- ODF content was generated -->
                <p:otherwise>
                    
                    <!-- Convert the ODF content instance to serialized XML.
                      Note that the indent element is needed to prevent the serializer inserting whitspace in the output -->
                    <p:processor name="oxf:xml-serializer">
                        <p:input name="config">
                            <config>
                                <encoding>utf-8</encoding>
                                <indent>false</indent>
                            </config>
                        </p:input>
                        <p:input name="data" href="#odfContent"/>
                        <p:output name="data" id="serializedODF"/>
                    </p:processor>
                    
                    <!-- Write the ODF content to a temporary file.
                         File name is passed out on data as <url>...</url>-->
                    <p:processor name="oxf:file-serializer">
                        <p:input name="config">
                            <config>
                                <scope>session</scope>
                            </config>
                        </p:input>
                        <p:input name="data" href="#serializedODF"/>
                        <p:output name="data" id="odfContentLocation"/>
                    </p:processor>
                    
                    <!-- Zip complete document to create ODF file -->
                    <p:processor name="oxf:zip">
                        <p:input name="data" transform="oxf:xslt" href="aggregate('zipData',#zip-file-list,#odfContentLocation)">
                            <files xsl:version="2.0">
                                <xsl:copy-of select="zipData/files/file[not(@name='content.xml')]"/>
                                <file name="content.xml">
                                    <xsl:value-of select="zipData/url[1]"/>
                                </file>
                            </files>
                        </p:input>
                        <p:output name="data" id="zipped-doc"/>
                    </p:processor>
                    
                    <!-- Return the ODF file to the browser -->
                    <p:processor name="oxf:http-serializer">
                        <p:input name="config" transform="oxf:xslt" href="#parameters">
                            <config xsl:version="2.0">
                                <header>
                                    <name>Content-Disposition</name>
                                    <value>attachement; filename=<xsl:value-of select="//parameters[@type='session']/externalId"/>.odt</value>
                                </header>
                                <content-type>application/vnd.oasis.opendocument.text</content-type>
                                <force-content-type>true</force-content-type>
                            </config>
                        </p:input>
                        <p:input name="data" href="#zipped-doc"/>
                    </p:processor>
                    
                </p:otherwise>
            </p:choose>
            
        </p:when>

        <!-- ====
             There was a wordML document (.docx) 
             ==== -->
        <p:when test="exists(files/file[@name='word/document.xml'])">

            <!-- Get the document.xml file from the unzipped word template 
                 This is the WordML file used as the template for generating the output document -->
            <p:processor name="oxf:url-generator">
                <p:input name="config" transform="oxf:xslt" href="#zip-file-list">
                    <config xsl:version="2.0">
                        <url>
                            <xsl:value-of select="files/file[@name='word/document.xml']"/>
                        </url>
                        <content-type>application/xml</content-type>
                    </config>
                </p:input>
                <p:output name="data" id="wordTemplateReturned"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#wordTemplateReturned"/>
                <p:output name="data" id="wordTemplate"/>
            </p:processor>
            
            <!-- Replace variables in the Word template -->
            <p:processor name="oxf:xslt">
                <p:input name="config" href="../xslt/WordProcessorReplaceVariables.xsl"/>
                <p:input name="data" href="#wordTemplate"/>
                <p:input name="parameters" href="#parameters"/>
                <p:input name="html" href="#html"/>
                <p:input name="image-file-info">
                    <blank/>
                </p:input>
                <p:output name="data" id="wordContentReturned"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#wordContentReturned"/>
                <p:output name="data" id="wordContent"/>
            </p:processor>
            
            
            <p:choose href="#wordContent">
                <!-- There was an error in the transformation.-->
                <p:when test="/exceptions">
                    
                    <!-- Serialize the error -->
                    <p:processor name="oxf:xml-serializer">
                        <p:input name="config">
                            <config>
                                <encoding>utf-8</encoding>
                            </config>
                        </p:input>
                        <p:input name="data" href="#wordContent"/>
                        <p:output name="data" id="serializedError"/>
                    </p:processor>
                    
                    <!-- Write the error content to a temporary file.
                         File name is passed out on data as <url>...</url> -->
                    <p:processor name="oxf:file-serializer">
                        <p:input name="config">
                            <config>
                                <scope>session</scope>
                            </config>
                        </p:input>
                        <p:input name="data" href="#serializedError"/>
                        <p:output name="data" id="errorLocation"/>
                    </p:processor>
                    
                    <!-- Zip the error file -->
                    <p:processor name="oxf:zip">
                        <p:input name="data" transform="oxf:xslt" href="#errorLocation">
                            <files xsl:version="2.0">
                                <file name="error.xml">
                                    <xsl:value-of select="url"/>
                                </file>
                            </files>
                        </p:input>
                        <p:output name="data" id="zippedError"/>
                    </p:processor>
                    
                    <!-- Return the exceptions XML to the browser -->
                    <p:processor name="oxf:http-serializer">
                        <p:input name="config">
                            <config>
                                <header>
                                    <name>Content-Disposition</name>
                                    <value>attachement; filename=error.zip</value>
                                </header>
                                <content-type>application/zip</content-type>
                                <force-content-type>true</force-content-type>
                            </config>
                        </p:input>
                        <p:input name="data" href="#zippedError"/>
                    </p:processor>
                    
                </p:when>
                
                
                <!-- Word content was generated -->
                <p:otherwise>
                    
                    <!-- Convert the Word content instance to serialized XML.
                      Note that the indent element is needed to prevent the serializer inserting whitspace in the output -->
                    <p:processor name="oxf:xml-serializer">
                        <p:input name="config">
                            <config>
                                <encoding>utf-8</encoding>
                                <indent>false</indent>
                            </config>
                        </p:input>
                        <p:input name="data" href="#wordContent"/>
                        <p:output name="data" id="serializedWord"/>
                    </p:processor>
                    
                    <!-- Write the Word content to a temporary file.
                         File name is passed out on data as <url>...</url>-->
                    <p:processor name="oxf:file-serializer">
                        <p:input name="config">
                            <config>
                                <scope>session</scope>
                            </config>
                        </p:input>
                        <p:input name="data" href="#serializedWord"/>
                        <p:output name="data" id="wordContentLocation"/>
                    </p:processor>
                    
                    <!-- Zip complete document to create Word file -->
                    <p:processor name="oxf:zip">
                        <p:input name="data" transform="oxf:xslt" href="aggregate('zipData',#zip-file-list,#wordContentLocation)">
                            <files xsl:version="2.0">
                                <xsl:copy-of select="zipData/files/file[not(@name='word/document.xml')]"/>
                                <file name="word/document.xml">
                                    <xsl:value-of select="zipData/url[1]"/>
                                </file>
                            </files>
                        </p:input>
                        <p:output name="data" id="zipped-doc"/>
                    </p:processor>
                    
                    <!-- Return the Word file to the browser -->
                    <p:processor name="oxf:http-serializer">
                        <p:input name="config" transform="oxf:xslt" href="#parameters">
                            <config xsl:version="2.0">
                                <header>
                                    <name>Content-Disposition</name>
                                    <value>attachement; filename=<xsl:value-of select="//parameters[@type='session']/externalId"/>.docx</value>
                                </header>
                                <content-type>application/vnd.openxmlformats-officedocument.wordprocessingml.document</content-type>
                                <force-content-type>true</force-content-type>
                            </config>
                        </p:input>
                        <p:input name="data" href="#zipped-doc"/>
                    </p:processor>               
                </p:otherwise>
            </p:choose>
            
          
        </p:when>

        <!-- ==== 
             Anything else, just return the result of unzipping
             This will either be a list of file, or an exception if the template wasn't a zip file ==== -->
        <p:otherwise>

            <!-- Not using the html, so need to consume it -->
            <p:processor name="oxf:null-serializer">
                <p:input name="data" href="#zip-file-list"/>
            </p:processor>
            
            <!-- Not using the wordProcessorZip, so need to consume it -->
            <p:processor name="oxf:null-serializer">
                <p:input name="data" href="#wordProcessorZip"/>
            </p:processor>
            
            <!-- Convert the exportResource to serialized XML -->
            <p:processor name="oxf:xml-serializer">
                <p:input name="config">
                    <config>
                        <encoding>utf-8</encoding>
                    </config>
                </p:input>
                <p:input name="data" href="#html"/>
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



        </p:otherwise>

    </p:choose>




</p:pipeline>
