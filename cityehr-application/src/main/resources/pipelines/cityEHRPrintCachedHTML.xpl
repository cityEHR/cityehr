<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRPrintCachedHTML.xpl
    
    Pipeline to render HTML document as XSL-FO and then deliver to browser as a PDF.
    The HTML is cached for the user at the database location defined by htmlCacheHandle
    The full database URL must be set in htmlCacheHandle before this pipeline is invoked
    HTML is then retrieved through htmlCacheHandle
    
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
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:saxon="http://saxon.sf.net/"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">

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

    <p:choose href="#parameters">
        <!-- Check that the htmlCacheHandle is set -->
        <p:when test="//parameters[@type='session']/htmlCacheHandle != ''">

            <!-- Get the HTML document for the resource
                 This is located in the database at xmlstore/users/<userId>/htmlCache
                 The full htmlCacheHandle is found in the session parameters -->
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission">
                    <xf:submission serialization="none" method="get"
                        action="{//parameters[@type='session']/htmlCacheHandle}"/>
                </p:input>
                <p:input name="request" href="#parameters"/>
                <p:output name="response" id="htmlReturned"/>
            </p:processor>

            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#htmlReturned"/>
                <p:output name="data" id="html"/>
            </p:processor>
        </p:when>

        <!-- No htmlCacheHandle supplied - output an error -->
        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data">
                    <html>
                        <body>
                            <p> Error - HTML not found. </p>
                        </body>
                    </html>
                </p:input>
                <p:output name="data" id="html"/>
            </p:processor>
        </p:otherwise>
    </p:choose>

    <!-- Produce XSL-FO -->
    <!-- Input is the HTML to be rendered. -->
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/HTML2FO.xsl"/>
        <p:input name="data" href="#html"/>
        <p:input name="parameters" href="#parameters"/>
        <p:output name="data" id="foDocument"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#foDocument"/>
        <p:output name="data" id="foDocument-checked"/>
    </p:processor>

    <!-- Create a PDF error message if there was a problem -->
    <p:choose href="#foDocument-checked">
        <!-- fo document was found, so pass straight through to xslfo-serializer -->
        <p:when test="exists(fo:root)">
            <p:processor name="oxf:identity">
                <p:input name="data" href="#foDocument-checked"/>
                <p:output name="data" id="foDocument-output"/>
            </p:processor>
        </p:when>

        <!-- No fo document was found -->
        <p:otherwise>
            <!-- Produce an error message -->
            <p:processor name="oxf:identity">
                <p:input name="data" transform="oxf:xslt" href="#parameters">
                    <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format" xsl:version="2.0">
                        <fo:layout-master-set xmlns:xf="http://www.w3.org/2002/xforms"
                            xmlns:xhtml="http://www.w3.org/1999/xhtml">
                            <fo:simple-page-master master-name="simple" page-height="29.7cm"
                                page-width="21cm" margin-top="1.3" margin-bottom="1cm"
                                margin-left="2.5cm" margin-right="2.5cm">
                                <fo:region-body margin-top="2cm" margin-bottom="1cm"/>
                                <fo:region-before extent="1.2cm"/>
                                <fo:region-after extent="1cm"/>
                            </fo:simple-page-master>
                        </fo:layout-master-set>

                        <fo:page-sequence master-reference="simple">
                            <fo:flow flow-name="xsl-region-body" font-family="serif"
                                font-size="10pt">
                                <fo:block>
                                    <xsl:value-of
                                        select="//parameters[@type='view']/printPipeline/errorMessage"
                                    />
                                </fo:block>
                            </fo:flow>
                        </fo:page-sequence>

                    </fo:root>
                </p:input>

                <p:output name="data" id="foDocument-output"/>
            </p:processor>
        </p:otherwise>
    </p:choose>

    <!-- Debugging - save the FO in xml-cache -->
    <p:choose href="#parameters">
        <p:when test="//parameters[@type='session']/xmlCacheHandle != ''">
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission" transform="oxf:xslt" href="#parameters">
                    <xf:submission xsl:version="2.0"
                        action="{//parameters[@type='session']/xmlCacheHandle}" validate="false"
                        method="put" replace="none" includenamespacesprefixes=""/>
                </p:input>
                <p:input name="request" href="#foDocument-output"/>
                <p:output name="response" id="SaveResponse"/>
            </p:processor>

            <p:processor name="oxf:null-serializer">
                <p:input name="data" href="#SaveResponse"/>
            </p:processor>
        </p:when>
    </p:choose>

    <!-- Run FO Processor to generate PDF-->
    <p:processor name="oxf:xslfo-serializer">
        <p:input name="config">
            <config>
                <content-type>application/pdf</content-type>
            </config>
        </p:input>
        <p:input name="data" href="#foDocument-output"/>
        <p:output name="data" id="pdfDocument"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#pdfDocument"/>
        <p:output name="data" id="pdfDocument-checked"/>
    </p:processor>


    <p:choose href="#pdfDocument-checked">
        <!-- There was an error in the FOP processor.-->
        <p:when test="/exceptions">
            <p:processor name="oxf:xml-serializer">
                <p:input name="config">
                    <config>
                        <encoding>utf-8</encoding>
                    </config>
                </p:input>
                <p:input name="data" href="#pdfDocument-checked"/>
                <p:output name="data" id="serializedResource"/>
            </p:processor>

            <p:processor name="oxf:file-serializer">
                <p:input name="config">
                    <config>
                        <scope>session</scope>
                    </config>
                </p:input>
                <p:input name="data" href="#serializedResource"/>
                <p:output name="data" id="exportFileLocation"/>
            </p:processor>

            <p:processor name="oxf:zip">
                <p:input name="data" transform="oxf:xslt"
                    href="aggregate('config',#exportFileLocation,#parameters)">
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

            <p:processor name="oxf:http-serializer">
                <p:input name="config" transform="oxf:xslt" href="#parameters">
                    <config xsl:version="2.0">
                        <xsl:variable name="fileName"
                            select="if (//parameters[@type='session']/externalId!='') then //parameters[@type='session']/externalId else concat(replace(replace(string(current-dateTime()),':','-'),'\+','*'),'-cityEHR-export')"/>
                        <header>
                            <name>Content-Disposition</name>
                            <value>attachement; filename=<xsl:value-of
                                    select="concat($fileName,'.zip')"/></value>
                        </header>
                        <content-type>application/zip</content-type>
                        <force-content-type>true</force-content-type>
                    </config>
                </p:input>
                <p:input name="data" href="#zipped-doc"/>
            </p:processor>
        </p:when>

        <!-- PDF content was generated -->
        <p:otherwise>
            <!-- Serialize to return to browser.
        The filename is concatenated from:
        patientId
        suffix set in view-parameters.xml
        current time stamp -->
            <p:processor name="oxf:http-serializer">
                <p:input name="config" transform="oxf:xslt" href="#parameters">
                    <config xsl:version="2.0">
                        <xsl:variable name="fileName"
                            select="if (//parameters[@type='session']/externalId!='') then //parameters[@type='session']/externalId else concat(replace(replace(string(current-dateTime()),':','-'),'\+','*'),'-cityEHR-print')"/>
                        <header>
                            <name>Content-Disposition</name>
                            <value>attachement; filename=<xsl:value-of
                                    select="concat($fileName,'.pdf')"/></value>
                        </header>
                        <content-type>application/pdf</content-type>
                        <force-content-type>false</force-content-type>
                    </config>
                </p:input>
                <p:input name="data" href="#pdfDocument-checked"/>
            </p:processor>
        </p:otherwise>
    </p:choose>



    <!-- Debugging -->
    <!--
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" href="#pdfDocument-checked"/>
        <p:output name="data" id="serializedResource"/>
    </p:processor>

    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#serializedResource"/>
        <p:output name="data" id="exportFileLocation"/>
    </p:processor>

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
    -->

</p:pipeline>
