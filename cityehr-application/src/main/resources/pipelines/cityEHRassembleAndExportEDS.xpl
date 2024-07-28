<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRassembleAndExportEDS.xpl
    
    Pipeline to generate an export data set and return to the browser in the specified format.
    
    Input is parameters instance with exportQuery set to the query that will assemble the data set.
    The return from this query is pre-configured with the id, displayName and format for export.
    
    The format of the data set is:
    
    <dataSet outputFormat="odf-spreadsheet" templateURL="oxf:/apps/ehr/resources/templates/exportDataSet.ods">
        <demographics>
        ...
        </demographics>
        <data>
        ...
        </data>
    </dataSet>
    
    The type of spreadsheet output depends on the outputFormat attribute (odf-spreadsheet or ms-spreadsheet)
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

<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cityEHR="http://openhealthinformatics.org/ehr">

    <!-- Input to pipeline is the data set instance -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output.
         Not needed for this pipeline since it runs as a 'model' and serializes its output back to the bowser -->
    <!--
    <p:param name="data" type="output"/>
    -->


    <!-- Processing depends on the type of spreadsheet required -->
    <p:choose href="#instance">
        <!-- If cached form exists it should have a root element. -->
        <p:when test="//@outputFormat='odf-spreadsheet'">

            <!-- Get the template export data set spreadsheet.
                 The location of the template is set in the templateURL parameter -->
            <p:processor name="oxf:url-generator">
                <p:input name="config" transform="oxf:xslt" href="#instance">
                    <config xsl:version="2.0">
                        <url>../resources/templates/exportDataSet.ods</url>
                        <content-type>multipart/x-zip</content-type>
                    </config>
                </p:input>
                <p:output name="data" id="zip"/>
            </p:processor>

            <!-- Unzip template spreadsheet.
                The contents are output into temporary files.
                Output <files> element specfies the location.
                
                <files>
                <file name="file1.txt" size="123" dateTime="2007-09-11T18:23:04">file:///tmp/somefile.txt</file>
                <file name="dir/file2.txt" size="456" dateTime="2007-09-11T18:23:04">file:///tmp/someotherfile.txt</file>
                </files>
            -->
            <p:processor name="oxf:unzip">
                <p:input name="data" href="#zip"/>
                <p:output name="data" id="zip-file-list"/>
            </p:processor>

            <!-- Get the content.xml file from the unzipped spreadsheet template 
            This is the file used as the template for generating the output document -->
            <p:processor name="oxf:url-generator">
                <p:input name="config" transform="oxf:xslt" href="#zip-file-list">
                    <config xsl:version="2.0">
                        <url>
                            <xsl:value-of select="files/file[@name='content.xml']"/>
                        </url>
                        <content-type>application/xml</content-type>
                    </config>
                </p:input>
                <p:output name="data" id="template"/>
            </p:processor>

            <!-- Generate spreadsheetML document from data set -->
            <!-- Inputs are the data set to be rendered and the view-parameters. -->
            <p:processor name="oxf:xslt">
                <p:input name="config" href="../xslt/DataSet2Spreadsheet.xsl"/>
                <p:input name="data" href="#instance"/>
                <p:input name="template" href="#template"/>
                <p:output name="data" id="odfSpreadsheet"/>
            </p:processor>

            <!-- Convert the spreadsheet document instance to serialized XML.
            Note that the indent element is needed to prevent the serializer inserting whitspace in the output -->
            <p:processor name="oxf:xml-serializer">
                <p:input name="config">
                    <config>
                        <encoding>utf-8</encoding>
                        <indent>false</indent>
                    </config>
                </p:input>
                <p:input name="data" href="#odfSpreadsheet"/>
                <p:output name="data" id="serializedODFSpreadsheet"/>
            </p:processor>

            <!-- Write the spreadsheet document to a temporary file.
                 File name is passed out on data as <url>...</url>-->
            <p:processor name="oxf:file-serializer">
                <p:input name="config">
                    <config>
                        <scope>session</scope>
                    </config>
                </p:input>
                <p:input name="data" href="#serializedODFSpreadsheet"/>
                <p:output name="data" id="spreadsheetDocumentLocation"/>
            </p:processor>

            <!-- Merge zip file list and generated spreadsheet location -->
            <p:processor name="oxf:identity">
                <p:input name="data" href="aggregate('manifest',#zip-file-list,#spreadsheetDocumentLocation)"/>
                <p:output name="data" id="zipManifest"/>
            </p:processor>

            <!-- Zip complete document to create ODF spreadsheet file -->
            <p:processor name="oxf:zip">
                <p:input name="data" transform="oxf:xslt" href="#zipManifest">
                    <files xsl:version="2.0">
                        <xsl:copy-of select="//file[not(@name='content.xml')]"/>
                        <file name="content.xml">
                            <xsl:value-of select="//url[1]"/>
                        </file>
                    </files>
                </p:input>
                <p:output name="data" id="zipped-doc"/>
            </p:processor>

            <!-- Serialize to return to browser.
                The filename is concatenated from:
                data set name
                current time stamp -->
            <p:processor name="oxf:http-serializer">
                <p:input name="config" transform="oxf:xslt" href="#instance">
                    <config xsl:version="2.0">
                        <header>
                            <name>Content-Disposition</name>
                            <value>attachement; filename=<xsl:value-of select="concat('dataset',replace(replace(string(current-dateTime()),':','-'),'\+','*'))"/>.ods</value>
                        </header>
                        <content-type>application/application/vnd.oasis.opendocument.spreadsheet</content-type>
                        <force-content-type>true</force-content-type>
                    </config>
                </p:input>
                <p:input name="data" href="#zipped-doc"/>
            </p:processor>
            

            <!-- Debugging - Don't need to do anything with the zipped-doc -->
<!--
            <p:processor name="oxf:null-serializer">
                <p:input name="data" href="#zipped-doc"/>
            </p:processor>

            <p:processor name="oxf:http-serializer">
                <p:input name="config">
                    <config>
                        <content-type>text-plain</content-type>
                        <force-content-type>true</force-content-type>
                        <encoding>utf-8</encoding>
                        <force-encoding>true</force-encoding>
                    </config>
                </p:input>
                <p:input name="data" transform="oxf:xslt" href="#template">
                    <document xsl:version="2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string" content-type="text/plain">
                        <xsl:value-of select="*"/>
                    </document>
                </p:input>
            </p:processor>
-->


            <!-- Catch exception if anything goes wrong -->
            <!--
                <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#zip-file-list"/>
                <p:output name="data" id="zip-manifest"/>
                </p:processor>
-->

        </p:when>


        <!--
        <p:when test="//@outputFormat='ms-spreadsheet'">
            
        </p:when>
        
-->

        <!-- Otherwise something has gone wrong.
             Just send an error message to the browser -->
        <p:otherwise>
            <p:processor name="oxf:http-serializer">
                <p:input name="config">
                    <config>
                        <!-- Make sure the client receives the text/plain content type -->
                        <content-type>text-plain</content-type>
                        <force-content-type>true</force-content-type>
                        <!-- We specify another encoding, and force it -->
                        <encoding>utf-8</encoding>
                        <force-encoding>true</force-encoding>
                    </config>
                </p:input>
                <p:input name="data">
                    <document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string" content-type="text/plain"> Error in cityEHRExportDataSet pipeline. </document>
                </p:input>
            </p:processor>
        </p:otherwise>
    </p:choose>



</p:pipeline>
