<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRPrintHTML.xpl
    
    Pipleline to transform input to HTML, XSL-FO and return PDF to browser
    Input is the HTML document to be printed
    
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
    xmlns:oxf="http://www.orbeon.com/oxf/processors"
    xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xdb="http://orbeon.org/oxf/xml/xmldb">

    <!-- Input to pipeline is html-instance -->
    <p:param name="instance" type="input"/>
    
    <!-- Produce XSL-FO -->
    <!-- Input is the HTML to be rendered. -->
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/HTML2FO.xsl"/>
        <p:input name="data" href="#instance"/>
        <p:output name="data" id="foDocument"/>
    </p:processor>

    <!-- Run FO Processor to generate PDF-->
    <p:processor name="oxf:xslfo-serializer">
        <p:input name="config">
            <config>
                <content-type>application/pdf</content-type>
            </config>
        </p:input>
        <p:input name="data" href="#foDocument"/>
        <p:output name="data" id="pdfDocument"/>
    </p:processor>

    <!-- Serialize to return to browser.
         The document id is set in the meta data (externalId) -->
    <p:processor name="oxf:http-serializer">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=<xsl:value-of select="//head/meta[@name='externalId']/@content"/>.pdf</value>
                </header>
                <content-type>application/pdf</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#pdfDocument"/>
    </p:processor>

</p:pipeline>
