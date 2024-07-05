<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRWordProcessorCDA.xpl
    
    Pipeline to generate a MS Word document from CDA.
    
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

<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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
         The compositionHandle is for the composition which has been saved in the data collection for the patient record -->   
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

    <!-- Get the template word document.
         The location of the template is set in the wordTemplateURL parameter -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#parameters">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="//parameters[@type='view']/wordTemplateURL"/>
                </url>
                <content-type>multipart/x-zip</content-type>
            </config>
        </p:input>
        <p:output name="data" id="wordZipReturned"/>
    </p:processor>
    
    <!-- The exception catcher behaves like the identity processor if there is no exception
         However if there is an exception, it catches it, and you get a serialized form of the exception. -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#wordZipReturned"/>
        <p:output name="data" id="wordZip"/>
    </p:processor>   

    <!-- Unzip template word document.
         The contents are put into temporary files.
         Output <files> element specfies the location.
         
         <files>
             <file name="file1.txt" size="123" dateTime="2007-09-11T18:23:04">file:///tmp/somefile.txt</file>
             <file name="dir/file2.txt" size="456" dateTime="2007-09-11T18:23:04">file:///tmp/someotherfile.txt</file>
         </files>
    -->
    <p:processor name="oxf:unzip">
        <p:input name="data" href="#wordZip"/>
        <p:output name="data" id="zip-file-list"/>
    </p:processor>

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
        <p:output name="data" id="wordTemplate"/>
    </p:processor>
    
    <!-- Get the document.xml.rels file from the unzipped word template -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#zip-file-list">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="files/file[@name='word/_rels/document.xml.rels']"/>
                </url>
                <content-type>application/xml</content-type>
            </config>
        </p:input>
        <p:output name="data" id="templateWordRelationshipsXML"/>
    </p:processor>


    <!-- Get image references from HTML.
         Uses inline XSLT since the extraction is very simple.
         Outputs image file list in the same format as the zip processor -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <files xsl:version="2.0">
                <xsl:variable name="appPath" select="document('input:parameters')//parameters[@type='view']/appPath"/>
                <xsl:for-each select="//imgXXX">
                    <file name="word/media/{@name}.png">
                        <xsl:value-of select="concat($appPath,'/resources/',substring-after(./@src,'/resources/'))"/>
                    </file>
                </xsl:for-each>
            </files>
        </p:input>
        <p:input name="data" href="#html"/>
        <p:input name="parameters" href="#parameters"/>
        <p:output name="data" id="image-file-list"/>
    </p:processor>

    <!-- Use directory scan to get file sizes.
         All media files are in the resources directory.
         (Patient media must be stored with the size extracted when they are first uploaded - TBD 
    
         image-file-info is of the form:
         
         <directory name="media"
         path="C:\cityEHR\tomcat7\webapps\orbeon\WEB-INF\resources\apps\ehr\resources\configuration\ISO-13606-EHR_Extract-Elfin\media">
             <file last-modified-ms="1368590738000" last-modified-date="2013-05-15T05:05:38.000"
                    size="16982"
                    path="alcoholgraphic.png"
                     name="alcoholgraphic.png">
                <image-metadata>
                    <basic-info>
                        <content-type>image/png</content-type>
                        <width>153</width>
                        <height>153</height>
                    </basic-info>
                </image-metadata>
            </file>
            ...
            </directory>
    -->
    <p:processor name="oxf:directory-scanner">
        <p:input name="config" transform="oxf:xslt" href="aggregate('config',#image-file-list,#parameters)">
            <config xsl:version="2.0">
                <base-directory>
                    <xsl:value-of select="concat(config//parameters[@type='view']/appPath,'/resources/configuration/',config//parameters[@type='view']/applicationId,'/media')"/>
                </base-directory>
                <xsl:for-each select="config/files/file">
                    <include>
                        <xsl:value-of select="substring-after(./@name,'/media/')"/>
                    </include>
                </xsl:for-each>
                <case-sensitive>false</case-sensitive>
                <image-metadata>
                    <basic-info>true</basic-info>
                </image-metadata>
            </config>
        </p:input>
        <p:output name="data" id="image-file-info"/>
    </p:processor>
    
    
    <!-- Debugging -->
    <!-- Convert the instance to serialized XML -->
    <!--
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" href="#image-file-info"/>
        <p:output name="data" id="serializedDebugInfo"/>
    </p:processor>
    -->
    
    <!-- Write the debugging document to a named file. 
    Directory path is relative to the Apache home directory -->
    <!--
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <directory>../temp/cityEHRDebug</directory>
                <file>debugInfo.xml</file>
                <make-directories>true</make-directories>
                <append>false</append>
            </config>
        </p:input>
        <p:input name="data" href="#serializedDebugInfo"/>
    </p:processor>    
    -->
    <!-- End of debugging -->
    

    <!-- Generate wordML document from HTML (document.xml) -->
    <!-- Inputs are the HTML to be rendered and the view-parameters. -->
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/HTML2WordML.xsl"/>
        <p:input name="data" href="#html"/>
        <p:input name="parameters" href="#parameters"/>
        <p:input name="wordTemplate" href="#wordTemplate"/>
        <p:input name="image-file-info" href="#image-file-info"/>
        <p:output name="data" id="wordMLdocument"/>
    </p:processor>

    <!-- Convert the wordML document instance to serialized XML.
         Note that the indent element is needed to prevent the serializer inserting whitspace in the output -->
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
                <indent>false</indent>
            </config>
        </p:input>
        <p:input name="data" href="#wordMLdocument"/>
        <p:output name="data" id="serializedWordML"/>
    </p:processor>

    <!-- Write the wordML document to a temporary file.
         File name is passed out on data as <url>...</url>-->
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#serializedWordML"/>
        <p:output name="data" id="wordMLdocumentLocation"/>
    </p:processor>

    <!-- Generate the word relationships XML instance -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships" xsl:version="2.0">
                <!-- Copy all elements from the template file
                      Use /*/* - takes care of problem with namespaces here -->
                <xsl:copy-of select="/*/*"/>
                <xsl:variable name="imageFiles" select="distinct-values(document('input:images')/files/file/@name)"/>
                <xsl:for-each select="$imageFiles">
                    <xsl:variable name="fileName" select="substring-after(.,'word/media/')"/>
                    <xsl:variable name="fileId" select="substring-before($fileName,'.png')"/>
                    <Relationship Id="{$fileId}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/{$fileName}"/>
                </xsl:for-each>
            </Relationships>
        </p:input>
        <p:input name="data" href="#templateWordRelationshipsXML"/>
        <p:input name="images" href="#image-file-list"/>
        <p:output name="data" id="wordRelationshipsXML"/>
    </p:processor>

    <!-- Convert the word relationships XML instance to serialized XML -->
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" href="#wordRelationshipsXML"/>
        <p:output name="data" id="serializedRelationshipsXML"/>
    </p:processor>

    <!-- Write the wordML relationships to a temporary file.
    File name is passed out on data as <url>...</url>-->
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#serializedRelationshipsXML"/>
        <p:output name="data" id="wordMLrelsLocation"/>
    </p:processor>

    <!-- Merge zip manifest and image files manifest -->
    <p:processor name="oxf:identity">
        <p:input name="data" href="aggregate('manifest',#zip-file-list,#image-file-list)"/>
        <p:output name="data" id="zipManifest"/>
    </p:processor>

    <!-- Merge locations of the document and relationship files -->
    <p:processor name="oxf:identity">
        <p:input name="data" href="aggregate('locations',#wordMLdocumentLocation,#wordMLrelsLocation)"/>
        <p:output name="data" id="fileLocations"/>
    </p:processor>

    <!-- Zip complete document to create MS Word file -->
    <p:processor name="oxf:zip">
        <p:input name="data" transform="oxf:xslt" href="aggregate('zipData',#zipManifest,#fileLocations)">
            <files xsl:version="2.0">
                <xsl:copy-of select="zipData/manifest/files/file[not(@name=('word/document.xml','word/_rels/document.xml.rels'))]"/>
                <file name="word/document.xml">
                    <xsl:value-of select="zipData/locations/url[1]"/>
                </file>
                <file name="word/_rels/document.xml.rels">
                    <xsl:value-of select="zipData/locations/url[2]"/>
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

</p:pipeline>
