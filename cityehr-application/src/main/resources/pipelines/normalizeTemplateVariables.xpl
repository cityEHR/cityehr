<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    normalizeTemplateVariables.xpl
    
    Pipeline to normalize the variables in a wordprocessor template
    Gets the wordprocessor template (MS Word or ODF Text)
    Transforms the content to fix (normlize) the variables in the template
    Then zips back up to return the document
    
    This is needed because some formatting can get inserted in the template that breaks up the variables
    Need to have all variables as complete text strings, without formatting
    
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

    <!-- Input to pipeline is .docx or .odt wordprocessor document -->
    <p:param name="instance" type="input"/>
    
    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>
    
    
    <!-- Unzip template wordprocessor document.
         The contents are put into temporary files.
         Output <files> element specfies the location.
         
         <files>
             <file name="file1.txt" size="123" dateTime="2007-09-11T18:23:04">file:///tmp/somefile.txt</file>
             <file name="dir/file2.txt" size="456" dateTime="2007-09-11T18:23:04">file:///tmp/someotherfile.txt</file>
         </files>
    -->
    <p:processor name="oxf:unzip">
        <p:input name="data" href="#instance"/>
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
            
            <!-- Normalize variables in the ODF template -->
            <p:processor name="oxf:xslt">
                <p:input name="config" href="../xslt/WordProcessorNormalizeVariables.xsl"/>
                <p:input name="data" href="#odfTemplate"/>
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
                    <!-- Return the error -->
                    <p:processor name="oxf:identity">
                        <p:input name="data" href="#odfContent"/>
                        <p:output name="data" ref="data"/>
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
                        <p:output name="data" ref="data"/>
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
            
            
            <!-- Normalize variables in the ODF template -->
            <p:processor name="oxf:xslt">
                <p:input name="config" href="../xslt/WordProcessorNormalizeVariables.xsl"/>
                <p:input name="data" href="#wordTemplate"/>
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
                    <!-- Return the error -->
                    <p:processor name="oxf:identity">
                        <p:input name="data" href="#wordContent"/>
                        <p:output name="data" ref="data"/>
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
                        <p:output name="data" ref="data"/>
                    </p:processor>           
                </p:otherwise>
            </p:choose>
            
            
        </p:when>
        

        <!-- ==== 
             Anything else, just return the result of unzipping
             This will either be a list of file, or an exception if the template wasn't a zip file ==== -->
        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data" href="#zip-file-list"/>
                <p:output name="data" ref="data"/>
            </p:processor>  
        </p:otherwise>

    </p:choose>




</p:pipeline>
