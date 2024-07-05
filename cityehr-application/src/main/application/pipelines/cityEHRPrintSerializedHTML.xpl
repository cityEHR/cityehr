<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRPrintSerializedHTML.xpl
    
    Pipeline to render HTML document as XSL-FO and then deliver to browser as a PDF.
    HTML is passed as through parameter renderHTML (serialized)
    
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
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Input to pipeline is renderHTML element -->

    <p:param name="instance" type="input"/>
    
    <!-- Create XML (HTML) document from the input string -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
                <xsl:template match="parameters">
                    <xsl:copy-of
                        select="saxon:parse(xs:string(renderHTML))"/>
                </xsl:template>
            </xsl:stylesheet>           
        </p:input>
        <p:input name="data" href="#instance"/>
        <p:output name="data" id="htmlDocument"/>
    </p:processor>
    
    <!--
        <xsl:copy-of
        select="saxon:parse(xs:string(parameters/renderHTML))"/>
    -->


    <!-- Produce XSL-FO -->
    <!-- Input is the HTML to be rendered. -->
    <!--
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/HTML2FO.xsl"/>
        <p:input name="data" href="#htmlDocument"/>
        <p:output name="data" id="foDocument"/>
    </p:processor>
    -->
    
    <!--
        <p:input name="data" transform="oxf:xslt" href="#instance">
        <xsl:copy-of select="saxon:parse(xs:string(parameters/renderHTML))"/>
        </p:input>
    -->


    <p:processor name="oxf:xml-converter">
        <p:input name="config">
            <config>
                <content-type>application/xml</content-type>
                <encoding>iso-8859-1</encoding>
                <version>1.0</version>
            </config>
        </p:input>
        <p:input name="data" href="#htmlDocument"/>
        <p:output name="data" id="xmlDocument"/>
    </p:processor>

    <!-- Write to a temporary file.
    File name is passed out on data as <url>...</url>-->
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#xmlDocument"/>
        <p:output name="data" id="fileList"/>
    </p:processor>

    <!-- Zip up the file -->
    <p:processor name="oxf:zip">
        <p:input name="data" transform="oxf:xslt" href="#fileList">
            <files xsl:version="2.0">
                <file name="test.xml">
                    <xsl:value-of select="url"/>
                </file>
            </files>
        </p:input>
        <p:output name="data" id="zipped-doc"/>
    </p:processor>


    <!-- Serialize to return to browser.
    The filename is set in externalId -->
    <p:processor name="oxf:http-serializer">
        <p:input name="config">
            <config>
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=test.zip</value>
                </header>
                <content-type>application/zip</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#zipped-doc"/>
    </p:processor>


    <!-- Run FO Processor to generate PDF-->
    <!--
    <p:processor name="oxf:xslfo-serializer">
        <p:input name="config">
            <config>
                <content-type>application/pdf</content-type>
            </config>
        </p:input>
        <p:input name="data" href="#foDocument"/>
        <p:output name="data" id="pdfDocument"/>
    </p:processor>
-->

    <!-- Serialize to return to browser.
    The filename is set in externalId -->
    <!--
    <p:processor name="oxf:http-serializer">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=<xsl:value-of
                            select="'print'"/>.pdf</value>
                </header>
                <content-type>application/pdf</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#pdfDocument"/>
    </p:processor>
    -->


    <!-- This one is making XSL-FO directly from CDA
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/CDA2FO.xsl"/>
        <p:input name="data" href="#cda"/>
        <p:input name="parameters" href="#instance"/>
        <p:output name="data" ref="data"/>
    </p:processor>
    -->


    <!-- Run FO Processor to generate PDF-->
    <!--
    <p:processor name="oxf:xslfo-serializer">    
        <p:input name="config" >        
            <config>     
                <content-type>application/pdf</content-type>  
            </config>
        </p:input>
        <p:input name="data" href="#FOdocument"/>   
        <p:output name="data" ref="data"/>  
    </p:processor>
    -->


</p:pipeline>
