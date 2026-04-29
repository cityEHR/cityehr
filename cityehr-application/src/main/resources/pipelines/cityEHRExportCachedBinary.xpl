<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRExportCachedBinary.xpl
    
    Pipeline to export the binary cache
    Gets the cached binary document
    Then returns directly to the browser
    
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

    <!-- Get the document stored in the binary cache
         The location of the document is set in the binaryCacheHandle parameter -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get"
                action="{//parameters[@type='session']/binaryCacheHandle}"/>
        </p:input>
        <p:input name="request" href="#parameters"/>
        <p:output name="response" id="binaryDocumentReturned"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception
         However if there is an exception, it catches it, and you get a serialized form of the exception. -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#binaryDocumentReturned"/>
        <p:output name="data" id="binaryDocument"/>
    </p:processor>

    <!-- Serialize to return to browser.
         The filename is set in externalId-->
    <p:processor name="oxf:http-serializer">
        <p:input name="config" transform="oxf:xslt" href="#parameters">
            <config xsl:version="2.0">
                <xsl:variable name="fileName"
                    select="if (//parameters[@type='session']/externalId!='') then //parameters[@type='session']/externalId else concat(replace(replace(string(current-dateTime()),':','-'),'\+','*'),'-cityEHR-export')"/>
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=<xsl:value-of select="$fileName"/></value>
                </header>
                <content-type>application/*</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#binaryDocument"/>
    </p:processor>

</p:pipeline>
